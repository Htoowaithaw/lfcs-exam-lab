$ErrorActionPreference = "Stop"

$LabRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:VAGRANT_HOME = Join-Path $LabRoot ".vagrant.d"
$ProgressPath = Join-Path $LabRoot "progress.json"
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
        ts = $value.ts
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
  $obj = $raw | ConvertFrom-Json
  return ConvertTo-Hashtable $obj
}

function Save-Progress($progress) {
  $progress | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ProgressPath -Encoding ascii
}

function Read-Question($path) {
  $lines = Get-Content -LiteralPath $path
  $q = [ordered]@{ id=""; title=""; domain=""; difficulty=""; distro=""; question=""; hints=@() }
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^id:\s*(.+)$') { $q.id = $Matches[1].Trim('" ') }
    elseif ($line -match '^title:\s*(.+)$') { $q.title = $Matches[1].Trim('" ') }
    elseif ($line -match '^domain:\s*(.+)$') { $q.domain = $Matches[1].Trim('" ') }
    elseif ($line -match '^difficulty:\s*(.+)$') { $q.difficulty = $Matches[1].Trim('" ') }
    elseif ($line -match '^distro:\s*(.+)$') { $q.distro = $Matches[1].Trim('" ') }
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
        $q.hints = $items -split '",\s*"' | ForEach-Object { $_.Trim(' "[', ']') }
      }
    }
  }
  return [pscustomobject]$q
}

function Get-Questions {
  Get-ChildItem -LiteralPath (Join-Path $LabRoot "questions") -Filter "*.yaml" |
    Sort-Object Name |
    ForEach-Object { Read-Question $_.FullName }
}

function Invoke-Vagrant {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )
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
  $distro = $question.distro
  if ([string]::IsNullOrWhiteSpace($distro)) { $distro = "ubuntu" }
  switch ($distro.ToLowerInvariant()) {
    "ubuntu" { return "node1" }
    "rocky" { return "lfcs-rocky1" }
    default { throw "Unsupported distro '$distro' for $($question.id)" }
  }
}

function Get-VBoxName($machine) {
  switch ($machine) {
    "node1" { return "lfcs-node1" }
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

function Get-SshInfo($machine) {
  $cache = Read-SshCache
  if ($cache.ContainsKey($machine)) { return $cache[$machine] }

  Push-Location $LabRoot
  try {
    $config = & vagrant ssh-config $machine
    if ($LASTEXITCODE -ne 0) { throw "vagrant ssh-config failed for $machine" }
  }
  finally {
    Pop-Location
  }

  $info = @{
    HostName = ""
    Port = ""
    IdentityFile = ""
    User = "vagrant"
  }
  foreach ($line in $config) {
    if ($line -match '^\s*HostName\s+(.+)\s*$') { $info.HostName = $Matches[1].Trim() }
    elseif ($line -match '^\s*Port\s+(.+)\s*$') { $info.Port = $Matches[1].Trim() }
    elseif ($line -match '^\s*IdentityFile\s+(.+)\s*$') { $info.IdentityFile = $Matches[1].Trim('" ') }
    elseif ($line -match '^\s*User\s+(.+)\s*$') { $info.User = $Matches[1].Trim() }
  }
  if (!$info.HostName -or !$info.Port -or !$info.IdentityFile) {
    throw "Incomplete SSH config for $machine"
  }
  $cache[$machine] = $info
  Save-SshCache $cache
  return $info
}

function Invoke-DirectSsh($machine, $command) {
  $info = Get-SshInfo $machine
  $knownHosts = if ($IsWindows -or $env:OS -eq "Windows_NT") { "NUL" } else { "/dev/null" }
  $output = & ssh `
    "-o" "StrictHostKeyChecking=no" `
    "-o" "UserKnownHostsFile=$knownHosts" `
    "-o" "PasswordAuthentication=no" `
    "-o" "IdentitiesOnly=yes" `
    "-i" $info.IdentityFile `
    "-p" $info.Port `
    "$($info.User)@$($info.HostName)" `
    $command 2>&1
  return [pscustomobject]@{
    Code = $LASTEXITCODE
    Output = @($output)
  }
}

function Wait-DirectSsh($machine) {
  $deadline = (Get-Date).AddSeconds(90)
  while ((Get-Date) -lt $deadline) {
    $result = Invoke-DirectSsh $machine "true"
    if ($result.Code -eq 0) { return }
    Start-Sleep -Seconds 2
  }
  throw "SSH did not become ready for $machine"
}

function Restore-BaseSnapshot($machine) {
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

function Load-Question($question) {
  $qid = $question.id
  $target = Get-TargetMachine $question
  Write-Host "Restoring $target base snapshot..."
  Restore-BaseSnapshot $target

  Write-Host "Injecting $qid..."
  $result = Invoke-DirectSsh $target "sudo bash /vagrant/inject/$qid.sh"
  $result.Output | ForEach-Object { Write-Host $_ }
  if ($result.Code -ne 0) { throw "Inject failed for $qid on $target" }
}

function Validate-Question($question) {
  $qid = $question.id
  $target = Get-TargetMachine $question
  $result = Invoke-DirectSsh $target "sudo bash /vagrant/validate/$qid.sh"
  $output = $result.Output
  $rc = $result.Code

  $output | ForEach-Object { Write-Host $_ }
  $progress = Read-Progress
  $progress[$qid] = @{
    status = $(if ($rc -eq 0) { "pass" } else { "fail" })
    ts = (Get-Date).ToString("o")
  }
  Save-Progress $progress
  return $rc
}

function Show-QuestionMenu {
  $progress = Read-Progress
  $questions = @(Get-Questions)
  Write-Host ""
  Write-Host "LFCS Practice Questions"
  Write-Host "======================="
  for ($i = 0; $i -lt $questions.Count; $i++) {
    $q = $questions[$i]
    $status = if ($progress.ContainsKey($q.id)) { $progress[$q.id].status } else { "new" }
    "{0,2}. {1} [{2}] - {3} ({4})" -f ($i + 1), $q.id, $status, $q.title, $q.domain
  }
  Write-Host " q. quit"
  return $questions
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
  Load-Question $current
  $showHints = $false

  while ($true) {
    Clear-Host
    Write-Host "$($current.id): $($current.title)"
    Write-Host "Domain: $($current.domain) | Difficulty: $($current.difficulty) | Target: $(Get-TargetMachine $current)"
    Write-Host ""
    Write-Host $current.question
    if ($showHints) {
      Write-Host ""
      Write-Host "Hints:"
      $current.hints | ForEach-Object { Write-Host " - $_" }
    }
    Write-Host ""
    Write-Host "[v] validate  [s] ssh  [r] reload/reset  [h] toggle hints  [q] question menu"
    $action = Read-Host "Action"
    if ($action -eq "v") { [void](Validate-Question $current); Read-Host "Press Enter" }
    elseif ($action -eq "s") { [void](Invoke-Vagrant "ssh" (Get-TargetMachine $current)) }
    elseif ($action -eq "r") { Load-Question $current }
    elseif ($action -eq "h") { $showHints = !$showHints }
    elseif ($action -eq "q") { break }
  }
}
