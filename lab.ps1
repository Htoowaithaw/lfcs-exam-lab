param(
  [ValidateSet("Menu", "Practice", "Exam")]
  [string]$Mode = "Menu",
  [int]$ExamDurationMinutes = 120,
  [int]$ExamQuestionCount = 20,
  [int]$PassThresholdPct = 66,
  [int]$Seed = 0,
  [switch]$UseSeed,
  [int]$AutoApplySolutions = -1,
  [switch]$AutoRunExam,
  [string]$AutoPracticeQuestionId = "",
  [switch]$AutoPracticeSolve
)

$ErrorActionPreference = "Stop"

$LabRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:VAGRANT_HOME = Join-Path $LabRoot ".vagrant.d"
$ProgressPath = Join-Path $LabRoot "progress.json"
$DataDir = Join-Path $LabRoot "data"
$ExamSessionsPath = Join-Path $DataDir "exam-sessions.json"
$SshCachePath = Join-Path $LabRoot ".ssh-cache.json"
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$UseVagrantRestore = $false

function ConvertTo-Hashtable($obj) {
  $hash = @{}
  if ($null -eq $obj) { return $hash }
  foreach ($prop in $obj.PSObject.Properties) {
    $value = $prop.Value
    if ($null -ne $value -and $value.PSObject.Properties.Name -contains "status") {
      $hash[$prop.Name] = @{
        status = $value.status
        attempts = $(if ($value.PSObject.Properties.Name -contains "attempts") { [int]$value.attempts } else { 0 })
        last_ts = $(if ($value.PSObject.Properties.Name -contains "last_ts") { $value.last_ts } elseif ($value.PSObject.Properties.Name -contains "ts") { $value.ts } else { $null })
      }
    } else {
      $hash[$prop.Name] = $value
    }
  }
  return $hash
}

function Read-Progress {
  if (!(Test-Path $ProgressPath)) { return @{} }
  $raw = Get-Content -Raw -LiteralPath $ProgressPath
  if ([string]::IsNullOrWhiteSpace($raw)) { return @{} }
  return ConvertTo-Hashtable ($raw | ConvertFrom-Json)
}

function Save-Progress($progress) {
  $progress | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ProgressPath -Encoding ascii
}

function Update-Progress($qid, $status, [bool]$CountAttempt) {
  $progress = Read-Progress
  $existing = if ($progress.ContainsKey($qid)) { $progress[$qid] } else { @{} }
  $attempts = if ($existing.ContainsKey("attempts")) { [int]$existing.attempts } else { 0 }
  if ($CountAttempt) { $attempts++ }
  $progress[$qid] = @{
    status = $status
    attempts = $attempts
    last_ts = (Get-Date).ToString("o")
  }
  Save-Progress $progress
}

function Ensure-DataFiles {
  if (!(Test-Path $DataDir)) { New-Item -ItemType Directory -Path $DataDir | Out-Null }
  if (!(Test-Path $ExamSessionsPath)) { "[]" | Set-Content -LiteralPath $ExamSessionsPath -Encoding ascii }
}

function Read-Question($path) {
  $lines = Get-Content -LiteralPath $path
  $q = [ordered]@{ id=""; title=""; domain=""; topic=""; difficulty=""; distro="ubuntu"; vms=@(); question=""; hints=@(); path=$path }
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^id:\s*(.+)$') { $q.id = $Matches[1].Trim('" ') }
    elseif ($line -match '^title:\s*(.+)$') { $q.title = $Matches[1].Trim('" ') }
    elseif ($line -match '^domain:\s*(.+)$') { $q.domain = $Matches[1].Trim('" ') }
    elseif ($line -match '^topic:\s*(.+)$') { $q.topic = $Matches[1].Trim('" ') }
    elseif ($line -match '^difficulty:\s*(.+)$') { $q.difficulty = $Matches[1].Trim('" ') }
    elseif ($line -match '^distro:\s*(.+)$') { $q.distro = $Matches[1].Trim('" ') }
    elseif ($line -match '^vms:\s*\[(.*)\]\s*$') {
      $items = $Matches[1]
      $q.vms = @($items -split ',' | ForEach-Object { $_.Trim().Trim('" ') } | Where-Object { $_ })
    }
    elseif ($line -match '^question:\s*\|') {
      $buf = New-Object System.Collections.Generic.List[string]
      $i++
      while ($i -lt $lines.Count -and $lines[$i] -match '^\s{2}(.*)$') {
        $buf.Add($Matches[1])
        $i++
      }
      $i--
      $q.question = ($buf -join [Environment]::NewLine)
    }
    elseif ($line -match '^hints:\s*\[(.*)\]\s*$') {
      $items = $Matches[1]
      if (![string]::IsNullOrWhiteSpace($items)) {
        $q.hints = $items -split '",\s*"' | ForEach-Object { $_.Trim().Trim('"').Trim('[').Trim(']') }
      }
    }
  }
  if ([string]::IsNullOrWhiteSpace($q.id)) {
    throw "Question file '$path' has no id"
  }
  return [pscustomobject]$q
}

function Get-Questions {
  $questionDir = Join-Path $LabRoot "questions"
  @(
    Get-ChildItem -LiteralPath $questionDir -Filter "*.yaml" |
      ForEach-Object { Read-Question $_.FullName } |
      Sort-Object @{ Expression = {
        if ($_.id -match '^qR(\d+)$') { return 10000 + [int]$Matches[1] }
        if ($_.id -match '^q(\d+)$') { return [int]$Matches[1] }
        return 99999
      }}, id
  )
}

function Invoke-Vagrant {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  Push-Location $LabRoot
  try {
    & vagrant @Arguments
    return $LASTEXITCODE
  }
  finally {
    Pop-Location
  }
}

function Get-TargetMachine($question) {
  $machines = @(Get-QuestionMachines $question)
  if ($machines.Count -gt 0) { return $machines[0] }
  $distro = $question.distro
  if ([string]::IsNullOrWhiteSpace($distro)) { $distro = "ubuntu" }
  switch ($distro.ToLowerInvariant()) {
    "ubuntu" { return "node1" }
    "rocky" { return "lfcs-rocky1" }
    default { throw "Unsupported distro '$distro' for $($question.id)" }
  }
}

function Get-QuestionMachines($question) {
  if ($question.PSObject.Properties.Name -contains "vms" -and $question.vms -and @($question.vms).Count -gt 0) {
    return @($question.vms | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  }
  $distro = $question.distro
  if ([string]::IsNullOrWhiteSpace($distro)) { $distro = "ubuntu" }
  if ($distro.ToLowerInvariant() -eq "rocky") { return @("lfcs-rocky1") }
  return @("node1")
}

function Get-VBoxName($machine) {
  switch ($machine) {
    "node1" { return "lfcs-node1" }
    "node2" { return "lfcs-node2" }
    "lfcs-rocky1" { return "lfcs-rocky1" }
    default { throw "No VirtualBox VM mapping for $machine" }
  }
}

function Read-SshCache {
  if (!(Test-Path $SshCachePath)) { return @{} }
  $raw = Get-Content -Raw -LiteralPath $SshCachePath
  if ([string]::IsNullOrWhiteSpace($raw)) { return @{} }
  return ConvertTo-Hashtable ($raw | ConvertFrom-Json)
}

function Save-SshCache($cache) {
  $cache | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $SshCachePath -Encoding ascii
}

function Get-SshInfoFromVagrant($machine) {
  Push-Location $LabRoot
  try {
    $config = & vagrant ssh-config $machine
    if ($LASTEXITCODE -ne 0) { throw "vagrant ssh-config failed for $machine" }
  }
  finally {
    Pop-Location
  }

  $info = @{ HostName = ""; Port = ""; IdentityFile = ""; User = "vagrant" }
  foreach ($line in $config) {
    if ($line -match '^\s*HostName\s+(.+)\s*$') { $info.HostName = $Matches[1].Trim() }
    elseif ($line -match '^\s*Port\s+(.+)\s*$') { $info.Port = $Matches[1].Trim() }
    elseif ($line -match '^\s*IdentityFile\s+(.+)\s*$') { $info.IdentityFile = $Matches[1].Trim('" ') }
    elseif ($line -match '^\s*User\s+(.+)\s*$') { $info.User = $Matches[1].Trim() }
  }
  if (!$info.HostName -or !$info.Port -or !$info.IdentityFile) { throw "Incomplete SSH config for $machine" }
  return $info
}

function Refresh-SshCache {
  $cache = @{}
  foreach ($machine in @("node1", "node2", "lfcs-rocky1")) {
    $cache[$machine] = Get-SshInfoFromVagrant $machine
  }
  Save-SshCache $cache
  return $cache
}

function Get-SshInfo($machine) {
  $cache = Read-SshCache
  if (!$cache.ContainsKey("node1") -or !$cache.ContainsKey("node2") -or !$cache.ContainsKey("lfcs-rocky1")) {
    $cache = Refresh-SshCache
  }
  if ($cache.ContainsKey($machine)) {
    return $cache[$machine]
  }
  throw "No SSH cache entry for $machine"
}

function Invoke-InteractiveSsh($machine) {
  $info = Get-SshInfo $machine
  $knownHosts = if ($IsWindows -or $env:OS -eq "Windows_NT") { "NUL" } else { "/dev/null" }
  Write-Host "Opening SSH shell for $machine. Type 'exit' to return to the lab menu."
  $sshArgs = @(
    $(if ([Console]::IsInputRedirected) { "-T" } else { "-tt" }),
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=$knownHosts",
    "-o", "LogLevel=ERROR",
    "-o", "PasswordAuthentication=no",
    "-o", "IdentitiesOnly=yes",
    "-i", $info.IdentityFile,
    "-p", $info.Port,
    "$($info.User)@$($info.HostName)"
  )
  if ([Console]::IsInputRedirected) {
    $sshArgs += "bash -l"
  }
  & ssh @sshArgs
  if ($LASTEXITCODE -ne 0) { Write-Host "SSH exited with code $LASTEXITCODE" }
  Write-Host "Task shown above and saved to /root/TASK.md"
}

function Select-SshMachine($question) {
  $machines = @(Get-QuestionMachines $question)
  if ($machines.Count -le 1) { return $machines[0] }
  Write-Host "Select VM:"
  for ($i = 0; $i -lt $machines.Count; $i++) {
    Write-Host ("{0}. {1}" -f ($i + 1), $machines[$i])
  }
  $choice = Read-Host "VM"
  if (!($choice -as [int]) -or [int]$choice -lt 1 -or [int]$choice -gt $machines.Count) {
    Write-Host "Invalid VM selection; using $($machines[0])"
    return $machines[0]
  }
  return $machines[[int]$choice - 1]
}

function Get-SolutionMachines($question) {
  $machines = @(Get-QuestionMachines $question)
  if ($machines.Count -le 1) { return $machines }
  if ($question.topic -eq "SSH server & client") { return $machines }
  return @($machines[($machines.Count - 1)..0])
}

function Invoke-DirectSsh($machine, $command) {
  $info = Get-SshInfo $machine
  $knownHosts = if ($IsWindows -or $env:OS -eq "Windows_NT") { "NUL" } else { "/dev/null" }
  $oldErrorAction = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $output = & ssh `
      "-o" "StrictHostKeyChecking=no" `
      "-o" "UserKnownHostsFile=$knownHosts" `
      "-o" "LogLevel=ERROR" `
      "-o" "PasswordAuthentication=no" `
      "-o" "IdentitiesOnly=yes" `
      "-i" $info.IdentityFile `
      "-p" $info.Port `
      "$($info.User)@$($info.HostName)" `
      $command 2>&1
    return [pscustomobject]@{ Code = $LASTEXITCODE; Output = @($output) }
  }
  finally {
    $ErrorActionPreference = $oldErrorAction
  }
}

function Wait-DirectSsh($machine) {
  $timeoutSeconds = if ($machine -eq "lfcs-rocky1") { 300 } else { 120 }
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $result = Invoke-DirectSsh $machine "true"
    if ($result.Code -eq 0) { return }
    Start-Sleep -Seconds 2
  }
  throw "SSH did not become ready for $machine"
}

function Wait-PeerSsh($machines) {
  if (@($machines).Count -lt 2) { return }
  $checks = @(
    @{ machine="node1"; peer="192.168.56.12" },
    @{ machine="node2"; peer="192.168.56.11" }
  )
  foreach ($check in $checks) {
    if ($machines -notcontains $check.machine) { continue }
    $deadline = (Get-Date).AddSeconds(60)
    while ((Get-Date) -lt $deadline) {
      $result = Invoke-DirectSsh $check.machine "timeout 2 bash -c '</dev/tcp/$($check.peer)/22'"
      if ($result.Code -eq 0) { break }
      Start-Sleep -Seconds 2
    }
    if ((Get-Date) -ge $deadline) { throw "Peer SSH not ready from $($check.machine) to $($check.peer)" }
  }
}

function Get-ServiceReadinessCommands($question) {
  $qidNum = [int]$question.id.Substring(1)
  switch ($question.topic) {
    "NFS" { return @("timeout 2 bash -c '</dev/tcp/192.168.56.12/2049'") }
    "NBD" { return @("timeout 2 bash -c '</dev/tcp/192.168.56.12/10809'") }
    "reverse proxy & load balancer" {
      $n = $qidNum - 214
      $backend = 18700 + $n
      $listen = 18800 + $n
      return @("timeout 2 bash -c '</dev/tcp/192.168.56.12/$backend'", "timeout 2 bash -c '</dev/tcp/127.0.0.1/$listen'")
    }
    "port redirection & NAT" {
      $n = $qidNum - 208
      $port = 18600 + $n
      return @("timeout 2 bash -c '</dev/tcp/192.168.56.12/$port'")
    }
    "NTP time sync" { return @("chronyc sources -n | grep -q '192.168.56.12'") }
    "SSH server & client" { return @("timeout 2 bash -c '</dev/tcp/192.168.56.12/22'") }
    "LDAP accounts" { return @("timeout 2 bash -c '</dev/tcp/192.168.56.12/389'") }
    default { return @() }
  }
}

function Wait-ServiceReadiness($question, $primary) {
  $commands = @(Get-ServiceReadinessCommands $question)
  foreach ($command in $commands) {
    $deadline = (Get-Date).AddSeconds(60)
    while ((Get-Date) -lt $deadline) {
      $result = Invoke-DirectSsh $primary $command
      if ($result.Code -eq 0) { break }
      Start-Sleep -Seconds 2
    }
    if ((Get-Date) -ge $deadline) { throw "Readiness wait failed on ${primary}: $command" }
  }
}

function Restore-BaseSnapshot($machine) {
  if ($machine -eq "lfcs-rocky1") {
    $vboxName = Get-VBoxName $machine
    $info = & $VBoxManage showvminfo $vboxName --machinereadable
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage showvminfo failed for $vboxName" }
    $stateLine = $info | Where-Object { $_ -match '^VMState=' } | Select-Object -First 1
    if ($stateLine -match '"running"') {
      & $VBoxManage controlvm $vboxName poweroff | Out-Null
      if ($LASTEXITCODE -ne 0) { throw "VBoxManage poweroff failed for $vboxName" }
      Start-Sleep -Seconds 3
    }
    & $VBoxManage snapshot $vboxName restore base | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage snapshot restore failed for $vboxName" }
    & $VBoxManage startvm $vboxName --type headless | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage startvm failed for $vboxName" }
    Wait-DirectSsh $machine
    return
  }

  if ($UseVagrantRestore) {
    $rc = Invoke-Vagrant "snapshot" "restore" $machine "base" "--no-provision"
    if ($rc -ne 0) { throw "Vagrant snapshot restore failed for $machine" }
    return
  }

  $vboxName = Get-VBoxName $machine
  $info = & $VBoxManage showvminfo $vboxName --machinereadable
  if ($LASTEXITCODE -ne 0) { throw "VBoxManage showvminfo failed for $vboxName" }
  $stateLine = $info | Where-Object { $_ -match '^VMState=' } | Select-Object -First 1
  if ($stateLine -match '"running"') {
    & $VBoxManage controlvm $vboxName poweroff | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage poweroff failed for $vboxName" }
  }
  & $VBoxManage snapshot $vboxName restore base | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "VBoxManage snapshot restore failed for $vboxName" }
  & $VBoxManage startvm $vboxName --type headless | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "VBoxManage startvm failed for $vboxName" }
  Wait-DirectSsh $machine
}

function Format-TaskText($question) {
  $body = ($question.question -replace "`r`n", "`n") -replace "`r", ""
  $lines = @(
    "# $($question.id): $($question.title)",
    "",
    $body
  )
  return (($lines -join "`n").TrimEnd() + "`n")
}

function Show-TaskText($question) {
  Write-Host ""
  Write-Host (Format-TaskText $question)
}

function Install-TaskText($question, $target) {
  $taskText = Format-TaskText $question
  $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($taskText))
  $command = "printf '%s' '$encoded' | base64 -d | sudo tee /root/TASK.md >/dev/null && sudo cp /root/TASK.md /etc/motd && sudo chmod 0644 /root/TASK.md /etc/motd"
  $result = Invoke-DirectSsh $target $command
  $result.Output | ForEach-Object { Write-Host $_ }
  if ($result.Code -ne 0) { throw "Task publish failed for $($question.id) on $target" }
}

function Load-Question($question) {
  $qid = $question.id
  $machines = @(Get-QuestionMachines $question)
  foreach ($target in $machines) {
    Write-Host "Restoring $target base snapshot..."
    Restore-BaseSnapshot $target
  }
  Wait-PeerSsh $machines
  foreach ($target in $machines) {
    $machineScript = Join-Path $LabRoot "inject/$qid.$target.sh"
    $defaultScript = Join-Path $LabRoot "inject/$qid.sh"
    if (Test-Path $machineScript) {
      Write-Host "Injecting $qid on $target..."
      $result = Invoke-DirectSsh $target "sudo bash /vagrant/inject/$qid.$target.sh"
      $result.Output | ForEach-Object { Write-Host $_ }
      if ($result.Code -ne 0) { throw "Inject failed for $qid on $target" }
    } elseif ($machines.Count -eq 1 -and (Test-Path $defaultScript)) {
      Write-Host "Injecting $qid..."
      $result = Invoke-DirectSsh $target "sudo bash /vagrant/inject/$qid.sh"
      $result.Output | ForEach-Object { Write-Host $_ }
      if ($result.Code -ne 0) { throw "Inject failed for $qid on $target" }
    }
  }
  foreach ($target in $machines) {
    Install-TaskText $question $target
  }
  Update-Progress $qid "attempted" $false
}

function Validate-Question($question) {
  $qid = $question.id
  $target = Get-TargetMachine $question
  $machines = @(Get-QuestionMachines $question)
  if ($machines.Count -gt 1) { Wait-ServiceReadiness $question $target }
  $result = Invoke-DirectSsh $target "sudo bash /vagrant/validate/$qid.sh"
  $result.Output | ForEach-Object { Write-Host $_ }
  $status = if ($result.Code -eq 0) { "pass" } else { "fail" }
  Update-Progress $qid $status $true
  return $result.Code
}

function Invoke-Solution($question) {
  $qid = $question.id
  $questionMachines = @(Get-QuestionMachines $question)
  $solutionMachines = if ($questionMachines.Count -le 1) { $questionMachines } else { @(Get-SolutionMachines $question) }
  foreach ($target in $solutionMachines) {
    $machineScript = Join-Path $LabRoot "solution/$qid.$target.sh"
    $defaultScript = Join-Path $LabRoot "solution/$qid.sh"
    if (Test-Path $machineScript) {
      $result = Invoke-DirectSsh $target "sudo bash /vagrant/solution/$qid.$target.sh"
      $result.Output | ForEach-Object { Write-Host $_ }
      if ($result.Code -ne 0) { throw "Solution failed for $qid on $target" }
    } elseif ($questionMachines.Count -eq 1 -and (Test-Path $defaultScript)) {
      $result = Invoke-DirectSsh $target "sudo bash /vagrant/solution/$qid.sh"
      $result.Output | ForEach-Object { Write-Host $_ }
      if ($result.Code -ne 0) { throw "Solution failed for $qid on $target" }
    }
  }
}

function Get-RemainingText($endTs) {
  $remaining = [int][Math]::Max(0, [Math]::Ceiling(($endTs - (Get-Date)).TotalSeconds))
  return "{0:00}:{1:00}" -f [Math]::Floor($remaining / 60), ($remaining % 60)
}

function Show-QuestionMenu {
  $progress = Read-Progress
  $questions = @(Get-Questions)
  if ($questions.Count -eq 0) {
    throw "No questions found under $(Join-Path $LabRoot 'questions')"
  }
  Write-Host ""
  Write-Host "LFCS Practice Questions ($($questions.Count))"
  Write-Host "=============================="
  for ($i = 0; $i -lt $questions.Count; $i++) {
    $q = $questions[$i]
    $status = if ($progress.ContainsKey($q.id)) { $progress[$q.id].status } else { "new" }
    $attempts = if ($progress.ContainsKey($q.id)) { $progress[$q.id].attempts } else { 0 }
    Write-Host ("{0,3}. {1} [{2}, attempts={3}] - {4} ({5})" -f ($i + 1), $q.id, $status, $attempts, $q.title, $q.domain)
  }
  Write-Host " q. quit"
  return $questions
}

function Start-PracticeMode {
  if (![string]::IsNullOrWhiteSpace($AutoPracticeQuestionId)) {
    $question = @(Get-Questions | Where-Object { $_.id -eq $AutoPracticeQuestionId })[0]
    if ($null -eq $question) { throw "Practice question '$AutoPracticeQuestionId' not found" }
    Load-Question $question
    [void](Validate-Question $question)
    if ($AutoPracticeSolve) {
      Invoke-Solution $question
      [void](Validate-Question $question)
    }
    return
  }

  while ($true) {
    $questions = Show-QuestionMenu
    $choice = Read-Host "Select a question"
    if ($choice -eq "q") { break }
    if (!($choice -as [int]) -or [int]$choice -lt 1 -or [int]$choice -gt $questions.Count) {
      Write-Host "Invalid choice"
      continue
    }

    $current = $questions[[int]$choice - 1]
    if ($null -eq $current -or [string]::IsNullOrWhiteSpace($current.id)) {
      throw "Selected question number '$choice' did not resolve to a real qid"
    }
    Load-Question $current
    $showHints = $false

    while ($true) {
      Clear-Host
      Write-Host "$($current.id): $($current.title)"
      Write-Host "Domain: $($current.domain) | Difficulty: $($current.difficulty) | Targets: $((Get-QuestionMachines $current) -join ',')"
      Write-Host ""
      Write-Host $current.question
      if ($showHints) {
        Write-Host ""
        Write-Host "Hints:"
        $current.hints | ForEach-Object { Write-Host " - $_" }
      }
      Write-Host ""
      Write-Host "[v] validate  [s] ssh  [t] task  [r] reload/reset  [h] toggle hints  [q] question menu"
      $action = Read-Host "Action"
      if ($action -eq "v") { [void](Validate-Question $current); Read-Host "Press Enter" }
      elseif ($action -eq "s") { Invoke-InteractiveSsh (Select-SshMachine $current) }
      elseif ($action -eq "t") { Show-TaskText $current; Read-Host "Press Enter" }
      elseif ($action -eq "r") { Load-Question $current }
      elseif ($action -eq "h") { $showHints = !$showHints }
      elseif ($action -eq "q") { break }
    }
  }
}

function Select-ExamQuestions($questions) {
  $count = [Math]::Min($ExamQuestionCount, $questions.Count)
  $random = if ($UseSeed) { [Random]::new($Seed) } else { [Random]::new() }
  return @($questions | Sort-Object { $random.Next() } | Select-Object -First $count)
}

function Write-ScoreReport($session) {
  Write-Host ""
  Write-Host "Exam Score Report"
  Write-Host "================="
  Write-Host ("Score: {0}/{1} ({2}%)" -f $session.score, $session.total, $session.percentage)
  Write-Host ("Result: {0} vs approximate configurable threshold {1}% (not an official LFCS figure)" -f $(if ($session.pass_bool) { "PASS" } else { "FAIL" }), $session.threshold_used)
  Write-Host ("Time used: {0}s" -f $session.duration_used_sec)
  Write-Host ("End reason: {0}" -f $session.end_reason)
  Write-Host ""
  $session.per_question | Format-Table qid,domain,distro,result -AutoSize | Out-Host
}

function Save-ExamSession($session) {
  Ensure-DataFiles
  $existingRaw = Get-Content -Raw -LiteralPath $ExamSessionsPath
  $existing = New-Object System.Collections.Generic.List[object]
  if (![string]::IsNullOrWhiteSpace($existingRaw)) {
    $parsed = $existingRaw | ConvertFrom-Json
    @($parsed) | Where-Object { $null -ne $_ -and $_.PSObject.Properties.Name -contains "session_id" } | ForEach-Object {
      [void]$existing.Add($_)
    }
  }
  [void]$existing.Add([pscustomobject]$session)
  $all = $existing.ToArray()
  $all | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ExamSessionsPath -Encoding ascii
}

function Complete-ExamSession($session, $endReason, $started, $endTs) {
  $ended = Get-Date
  $passed = @($session.per_question | Where-Object { $_.result -eq "PASS" }).Count
  $total = $session.per_question.Count
  $percentage = if ($total -gt 0) { [Math]::Round(($passed / $total) * 100, 2) } else { 0 }
  $session.ended_ts = $ended.ToString("o")
  $session.duration_used_sec = [int][Math]::Round(($ended - $started).TotalSeconds)
  $session.score = $passed
  $session.total = $total
  $session.percentage = $percentage
  $session.pass_bool = ($percentage -ge $PassThresholdPct)
  $session.threshold_used = $PassThresholdPct
  $session.end_reason = $endReason
  Save-ExamSession $session
  Write-ScoreReport $session
  return $session
}

function Start-ExamMode {
  Ensure-DataFiles
  $questions = @(Select-ExamQuestions @(Get-Questions))
  $started = Get-Date
  $endTs = $started.AddMinutes($ExamDurationMinutes)
  $session = [ordered]@{
    session_id = [guid]::NewGuid().ToString()
    started_ts = $started.ToString("o")
    ended_ts = $null
    duration_used_sec = 0
    question_ids = @($questions | ForEach-Object { $_.id })
    per_question = @($questions | ForEach-Object {
      [pscustomobject]@{ qid = $_.id; domain = $_.domain; distro = $(if ($_.distro) { $_.distro } else { "ubuntu" }); result = "UNVALIDATED" }
    })
    score = 0
    total = $questions.Count
    percentage = 0
    pass_bool = $false
    threshold_used = $PassThresholdPct
    end_reason = $null
  }

  Write-Host "Exam Mode"
  Write-Host "========="
  Write-Host ("Duration: {0} minutes | Questions: {1} | Threshold: approximate configurable {2}% (not official)" -f $ExamDurationMinutes, $questions.Count, $PassThresholdPct)
  Write-Host "Warning: re-opening a question reloads it fresh; work is not preserved across switches. Finish before moving on."

  if ($ExamDurationMinutes -le 0) {
    return Complete-ExamSession $session "timeout" $started $endTs
  }

  if ($AutoRunExam) {
    for ($i = 0; $i -lt $questions.Count; $i++) {
      if ((Get-Date) -ge $endTs) { return Complete-ExamSession $session "timeout" $started $endTs }
      $q = $questions[$i]
      Load-Question $q
      if ($AutoApplySolutions -gt $i) { Invoke-Solution $q }
      $rc = Validate-Question $q
      $session.per_question[$i].result = if ($rc -eq 0) { "PASS" } else { "FAIL" }
    }
    return Complete-ExamSession $session "completed" $started $endTs
  }

  while ($true) {
    if ((Get-Date) -ge $endTs) { return Complete-ExamSession $session "timeout" $started $endTs }
    $remaining = Get-RemainingText $endTs
    Write-Host ""
    Write-Host "Exam Questions - time remaining $remaining"
    for ($i = 0; $i -lt $questions.Count; $i++) {
      $q = $questions[$i]
      Write-Host ("{0,2}. {1} [{2}] - {3} ({4}, {5})" -f ($i + 1), $q.id, $session.per_question[$i].result, $q.title, $q.domain, $(if ($q.distro) { $q.distro } else { "ubuntu" }))
    }
    Write-Host " e. end exam"
    if (@($session.per_question | Where-Object { $_.result -eq "UNVALIDATED" }).Count -eq 0) {
      return Complete-ExamSession $session "completed" $started $endTs
    }

    $choice = Read-Host "Open question"
    if ($choice -eq "e") { return Complete-ExamSession $session "completed" $started $endTs }
    if (!($choice -as [int]) -or [int]$choice -lt 1 -or [int]$choice -gt $questions.Count) {
      Write-Host "Invalid choice"
      continue
    }

    $idx = [int]$choice - 1
    $current = $questions[$idx]
    Write-Host "Reload warning: opening $($current.id) restores a fresh state for that VM."
    Load-Question $current
    while ($true) {
      if ((Get-Date) -ge $endTs) { return Complete-ExamSession $session "timeout" $started $endTs }
      Write-Host ""
      Write-Host "$($current.id): $($current.title) | Remaining $(Get-RemainingText $endTs)"
      Write-Host $current.question
      Write-Host "[v] validate  [s] ssh  [t] task  [b] back to exam list"
      $action = Read-Host "Action"
      if ($action -eq "v") {
        $rc = Validate-Question $current
        $session.per_question[$idx].result = if ($rc -eq 0) { "PASS" } else { "FAIL" }
      }
      elseif ($action -eq "s") { Invoke-InteractiveSsh (Select-SshMachine $current) }
      elseif ($action -eq "t") { Show-TaskText $current; Read-Host "Press Enter" }
      elseif ($action -eq "b") { break }
    }
  }
}

Ensure-DataFiles
Refresh-SshCache | Out-Null

if ($Mode -eq "Practice") {
  Start-PracticeMode
}
elseif ($Mode -eq "Exam") {
  [void](Start-ExamMode)
}
else {
  Write-Host "LFCS Lab"
  Write-Host "========"
  Write-Host "[1] Practice Mode - free navigation, no timer"
  Write-Host "[2] Exam Mode     - timed, random question set, scored"
  $choice = Read-Host "Select mode"
  if ($choice -eq "1") { Start-PracticeMode }
  elseif ($choice -eq "2") { [void](Start-ExamMode) }
  else { Write-Host "Invalid mode" }
}
