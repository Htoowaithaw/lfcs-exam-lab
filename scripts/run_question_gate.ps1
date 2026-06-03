param(
  [Parameter(Mandatory=$true)]
  [string[]]$QuestionIds,
  [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
$LabRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$ProgressPath = Join-Path $LabRoot "progress.json"

function Read-Question($qid) {
  $path = Join-Path $LabRoot "questions\$qid.yaml"
  $lines = Get-Content -LiteralPath $path
  $distro = "ubuntu"
  $domain = ""
  $topic = ""
  $vms = @()
  foreach ($line in $lines) {
    if ($line -match '^distro:\s*(.+)$') { $distro = $Matches[1].Trim('" ') }
    elseif ($line -match '^domain:\s*(.+)$') { $domain = $Matches[1].Trim('" ') }
    elseif ($line -match '^topic:\s*(.+)$') { $topic = $Matches[1].Trim('" ') }
    elseif ($line -match '^vms:\s*\[(.*)\]\s*$') {
      $vms = @($Matches[1] -split "," | ForEach-Object { $_.Trim().Trim('" ') } | Where-Object { $_ })
    }
  }
  return [pscustomobject]@{ id=$qid; distro=$distro; domain=$domain; topic=$topic; vms=$vms }
}

function Get-Machine($distro) {
  if ($distro -eq "rocky") { return "lfcs-rocky1" }
  return "node1"
}

function Get-Machines($q) {
  if ($q.vms -and @($q.vms).Count -gt 0) { return @($q.vms) }
  return @((Get-Machine $q.distro))
}

function Get-SolutionMachines($q) {
  $machines = @(Get-Machines $q)
  if ($machines.Count -le 1) { return $machines }
  if ($q.topic -eq "SSH server & client") { return $machines }
  return @($machines[($machines.Count - 1)..0])
}

function Get-VBoxName($machine) {
  if ($machine -eq "node1") { return "lfcs-node1" }
  if ($machine -eq "node2") { return "lfcs-node2" }
  if ($machine -eq "lfcs-rocky1") { return "lfcs-rocky1" }
  throw "Unknown machine $machine"
}

function Get-SshInfo($machine) {
  Push-Location $LabRoot
  try {
    $config = & vagrant ssh-config $machine
    if ($LASTEXITCODE -ne 0) { throw "vagrant ssh-config failed for $machine" }
  } finally {
    Pop-Location
  }
  $info = @{ HostName=""; Port=""; IdentityFile=""; User="vagrant" }
  foreach ($line in $config) {
    if ($line -match '^\s*HostName\s+(.+)\s*$') { $info.HostName = $Matches[1].Trim() }
    elseif ($line -match '^\s*Port\s+(.+)\s*$') { $info.Port = $Matches[1].Trim() }
    elseif ($line -match '^\s*IdentityFile\s+(.+)\s*$') { $info.IdentityFile = $Matches[1].Trim('" ') }
    elseif ($line -match '^\s*User\s+(.+)\s*$') { $info.User = $Matches[1].Trim() }
  }
  return $info
}

function Invoke-Ssh($machine, $command) {
  $info = Get-SshInfo $machine
  $old = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $out = & ssh `
      "-o" "StrictHostKeyChecking=no" `
      "-o" "UserKnownHostsFile=NUL" `
      "-o" "LogLevel=ERROR" `
      "-o" "PasswordAuthentication=no" `
      "-o" "IdentitiesOnly=yes" `
      "-i" $info.IdentityFile `
      "-p" $info.Port `
      "$($info.User)@$($info.HostName)" `
      $command 2>&1
    return [pscustomobject]@{ Code=$LASTEXITCODE; Output=@($out) }
  } finally {
    $ErrorActionPreference = $old
  }
}

function Wait-Ssh($machine) {
  $timeoutSeconds = if ($machine -eq "lfcs-rocky1") { 300 } else { 300 }
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $r = Invoke-Ssh $machine "true"
    if ($r.Code -eq 0) { return }
    Start-Sleep -Seconds 2
  }
  throw "SSH not ready for $machine"
}

function Invoke-VagrantUpNoProvision($machine) {
  Push-Location $LabRoot
  try {
    & vagrant up $machine --no-provision | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "vagrant up --no-provision failed for $machine" }
  } finally {
    Pop-Location
  }
}

function Invoke-VagrantReloadNoProvision($machine) {
  Push-Location $LabRoot
  try {
    & vagrant reload $machine --no-provision | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "vagrant reload --no-provision failed for $machine" }
  } finally {
    Pop-Location
  }
}

function Invoke-VagrantSnapshotRestore($machine) {
  $vbox = Get-VBoxName $machine
  $info = & $VBoxManage showvminfo $vbox --machinereadable
  $state = ($info | Where-Object { $_ -match '^VMState=' } | Select-Object -First 1)
  if ($state -match '"running"') {
    & $VBoxManage controlvm $vbox poweroff | Out-Null
    Start-Sleep -Seconds 3
  }
  Push-Location $LabRoot
  try {
    & vagrant snapshot restore $machine base --no-provision | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "vagrant snapshot restore failed for $machine" }
  } finally {
    Pop-Location
  }
}

function Restore-Base($machine) {
  $vbox = Get-VBoxName $machine
  $lastError = $null
  for ($attempt = 1; $attempt -le 2; $attempt++) {
    try {
      $info = & $VBoxManage showvminfo $vbox --machinereadable
      $state = ($info | Where-Object { $_ -match '^VMState=' } | Select-Object -First 1)
      if ($state -match '"running"') {
        & $VBoxManage controlvm $vbox poweroff | Out-Null
        Start-Sleep -Seconds 3
      }
      & $VBoxManage snapshot $vbox restore base | Out-Null
      if ($LASTEXITCODE -ne 0) { throw "snapshot restore failed for $vbox" }
      & $VBoxManage startvm $vbox --type headless | Out-Null
      if ($LASTEXITCODE -ne 0) { throw "startvm failed for $vbox" }
      try {
        Wait-Ssh $machine
      } catch {
        Invoke-VagrantReloadNoProvision $machine
        Wait-Ssh $machine
      }
      return
    } catch {
      $lastError = $_
      if ($attempt -lt 2) {
        Start-Sleep -Seconds 5
      }
    }
  }
  throw $lastError
}

function Read-Progress {
  if (!(Test-Path $ProgressPath)) { return @{} }
  $raw = Get-Content -Raw -LiteralPath $ProgressPath
  if ([string]::IsNullOrWhiteSpace($raw)) { return @{} }
  $obj = $raw | ConvertFrom-Json
  $h = @{}
  foreach ($p in $obj.PSObject.Properties) {
    $h[$p.Name] = @{ status=$p.Value.status; attempts=[int]$p.Value.attempts; last_ts=$p.Value.last_ts }
  }
  return $h
}

function Save-Progress($progress) {
  $progress | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ProgressPath -Encoding ascii
}

function Update-Progress($qid, $status) {
  $p = Read-Progress
  $attempts = if ($p.ContainsKey($qid)) { [int]$p[$qid].attempts } else { 0 }
  $p[$qid] = @{ status=$status; attempts=($attempts + 1); last_ts=(Get-Date).ToString("o") }
  Save-Progress $p
}

$ExpandedQuestionIds = @($QuestionIds | ForEach-Object { $_ -split "," } | Where-Object { ![string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })

$rows = New-Object System.Collections.Generic.List[object]
foreach ($qid in $ExpandedQuestionIds) {
  $q = Read-Question $qid
  $machines = @(Get-Machines $q)
  $primary = $machines[0]
  $row = [ordered]@{ id=$qid; topic=$q.topic; distro=$q.distro; vms=($machines -join ","); load="FAIL"; unsolved="FAIL"; solved="FAIL"; restored="FAIL"; unsolved_last=""; solved_last="" }
  try {
    foreach ($machine in $machines) { Restore-Base $machine }
    foreach ($machine in $machines) {
      $machineInject = Join-Path $LabRoot "inject\$qid.$machine.sh"
      $defaultInject = Join-Path $LabRoot "inject\$qid.sh"
      if (Test-Path $machineInject) {
        $inject = Invoke-Ssh $machine "sudo bash /vagrant/inject/$qid.$machine.sh"
        if ($inject.Code -ne 0) { throw "inject failed on ${machine}: $($inject.Output -join ' ')" }
      } elseif ($machines.Count -eq 1 -and (Test-Path $defaultInject)) {
        $inject = Invoke-Ssh $machine "sudo bash /vagrant/inject/$qid.sh"
        if ($inject.Code -ne 0) { throw "inject failed on ${machine}: $($inject.Output -join ' ')" }
      }
    }
    $row.load = "PASS"

    $unsolved = Invoke-Ssh $primary "sudo bash /vagrant/validate/$qid.sh"
    $row.unsolved_last = (($unsolved.Output | Select-Object -Last 1) -join "")
    if ($unsolved.Code -ne 0 -and $row.unsolved_last -match '^RESULT: FAIL - ') {
      $row.unsolved = "PASS"
      Update-Progress $qid "fail"
    } else {
      throw "unsolved validate did not fail correctly: code=$($unsolved.Code) last=$($row.unsolved_last)"
    }

    foreach ($machine in @(Get-SolutionMachines $q)) {
      $machineSolution = Join-Path $LabRoot "solution\$qid.$machine.sh"
      $defaultSolution = Join-Path $LabRoot "solution\$qid.sh"
      if (Test-Path $machineSolution) {
        $solvedApply = Invoke-Ssh $machine "sudo bash /vagrant/solution/$qid.$machine.sh"
        if ($solvedApply.Code -ne 0) { throw "solution failed on ${machine}: $($solvedApply.Output -join ' ')" }
      } elseif ($machines.Count -eq 1 -and (Test-Path $defaultSolution)) {
        $solvedApply = Invoke-Ssh $machine "sudo bash /vagrant/solution/$qid.sh"
        if ($solvedApply.Code -ne 0) { throw "solution failed on ${machine}: $($solvedApply.Output -join ' ')" }
      }
    }

    $solved = Invoke-Ssh $primary "sudo bash /vagrant/validate/$qid.sh"
    $row.solved_last = (($solved.Output | Select-Object -Last 1) -join "")
    if ($solved.Code -eq 0 -and $row.solved_last -eq "RESULT: PASS") {
      $row.solved = "PASS"
      Update-Progress $qid "pass"
    } else {
      throw "solved validate did not pass: code=$($solved.Code) last=$($row.solved_last)"
    }

    foreach ($machine in $machines) { Restore-Base $machine }
    $row.restored = "PASS"
  } catch {
    $row.error = $_.Exception.Message
  }
  [void]$rows.Add([pscustomobject]$row)
  "{0} {1}/{2}/{3}/{4}" -f $qid, $row.load, $row.unsolved, $row.solved, $row.restored | Write-Host
}

if ($OutputPath) {
  $rows | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $LabRoot $OutputPath) -Encoding ascii
}

$failed = @($rows | Where-Object { $_.load -ne "PASS" -or $_.unsolved -ne "PASS" -or $_.solved -ne "PASS" -or $_.restored -ne "PASS" })
if ($failed.Count -gt 0) {
  $failed | Format-Table id,topic,distro,load,unsolved,solved,restored,error -AutoSize | Out-Host
  exit 1
}
