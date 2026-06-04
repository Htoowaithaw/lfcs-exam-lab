param(
  [switch]$Rebuild,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$LabRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$SshCachePath = Join-Path $LabRoot ".ssh-cache.json"

$Machines = @(
  @{ Name = "node1"; VBoxName = "lfcs-node1"; Ip = "192.168.56.11" },
  @{ Name = "node2"; VBoxName = "lfcs-node2"; Ip = "192.168.56.12" },
  @{ Name = "lfcs-rocky1"; VBoxName = "lfcs-rocky1"; Ip = "" }
)

function Write-Step($message) {
  Write-Host "[setup] $message"
}

function Invoke-Step($description, [scriptblock]$Action) {
  if ($DryRun) {
    Write-Step "DRY-RUN: $description"
    return $null
  }
  Write-Step $description
  & $Action
}

function Test-Command($name) {
  return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Test-BaseSnapshot($vboxName) {
  if (!(Test-Path $VBoxManage)) { return $false }
  $list = & $VBoxManage snapshot $vboxName list --machinereadable 2>$null
  if ($LASTEXITCODE -ne 0) { return $false }
  return ($list | Where-Object { $_ -eq 'SnapshotName="base"' }).Count -eq 1
}

function Stop-LabVmIfRunning($vboxName) {
  $info = & $VBoxManage showvminfo $vboxName --machinereadable 2>$null
  if ($LASTEXITCODE -ne 0) { return }
  $state = ($info | Where-Object { $_ -match '^VMState=' } | Select-Object -First 1)
  if ($state -match '"running"') {
    & $VBoxManage controlvm $vboxName poweroff | Out-Null
    Start-Sleep -Seconds 3
  }
}

function Remove-BaseSnapshot($vboxName) {
  if (Test-BaseSnapshot $vboxName) {
    Stop-LabVmIfRunning $vboxName
    & $VBoxManage snapshot $vboxName delete base | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "failed to delete base snapshot for $vboxName" }
  }
}

function Save-BaseSnapshot($machine, $vboxName) {
  Stop-LabVmIfRunning $vboxName
  Push-Location $LabRoot
  try {
    & vagrant snapshot save $machine base | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "failed to save base snapshot for $machine" }
  } finally {
    Pop-Location
  }
}

function Get-SshConfig($machine) {
  Push-Location $LabRoot
  try {
    $config = & vagrant ssh-config $machine
    if ($LASTEXITCODE -ne 0) { throw "vagrant ssh-config failed for $machine" }
  } finally {
    Pop-Location
  }

  $info = [ordered]@{ HostName = ""; Port = ""; User = "vagrant"; IdentityFile = "" }
  foreach ($line in $config) {
    if ($line -match '^\s*HostName\s+(.+)\s*$') { $info.HostName = $Matches[1].Trim() }
    elseif ($line -match '^\s*Port\s+(.+)\s*$') { $info.Port = $Matches[1].Trim() }
    elseif ($line -match '^\s*User\s+(.+)\s*$') { $info.User = $Matches[1].Trim() }
    elseif ($line -match '^\s*IdentityFile\s+(.+)\s*$') { $info.IdentityFile = $Matches[1].Trim('" ') }
  }
  return $info
}

function Build-SshCache {
  $cache = [ordered]@{}
  foreach ($machine in $Machines) {
    $cache[$machine.Name] = Get-SshConfig $machine.Name
  }
  $cache | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $SshCachePath -Encoding ascii
}

function Invoke-Vagrant([string[]]$Arguments) {
  Push-Location $LabRoot
  try {
    & vagrant @Arguments
    if ($LASTEXITCODE -ne 0) { throw "vagrant $($Arguments -join ' ') failed" }
  } finally {
    Pop-Location
  }
}

if (!(Test-Command "vagrant")) { throw "Vagrant was not found in PATH." }
if (!(Test-Path $VBoxManage)) { throw "VBoxManage was not found at $VBoxManage." }

Write-Host "LFCS exam lab setup"
Write-Host "Lab root: $LabRoot"
Write-Host "Mode: $(if ($DryRun) { 'dry-run' } elseif ($Rebuild) { 'rebuild' } else { 'normal' })"
Write-Host ""

foreach ($machine in $Machines) {
  $hasBase = Test-BaseSnapshot $machine.VBoxName
  if ($hasBase -and !$Rebuild) {
    Write-Step "$($machine.Name): base snapshot already exists; skipping rebuild"
    continue
  }

  if ($Rebuild -and $hasBase) {
    Invoke-Step "$($machine.Name): delete existing base snapshot" { Remove-BaseSnapshot $machine.VBoxName }
  }

  Invoke-Step "$($machine.Name): vagrant up with provisioning" { Invoke-Vagrant -Arguments @("up", $machine.Name, "--provision") }

  if (!(Test-BaseSnapshot $machine.VBoxName)) {
    Invoke-Step "$($machine.Name): save base snapshot" { Save-BaseSnapshot $machine.Name $machine.VBoxName }
  } else {
    Write-Step "$($machine.Name): base snapshot exists after provisioning"
  }
}

Invoke-Step "build .ssh-cache.json for node1, node2, and lfcs-rocky1" { Build-SshCache }

Invoke-Step "verify node1 to node2 host-only connectivity" {
  Invoke-Vagrant -Arguments @("ssh", "node1", "-c", "ping -c 2 192.168.56.12")
}

Invoke-Step "verify node2 to node1 host-only connectivity" {
  Invoke-Vagrant -Arguments @("ssh", "node2", "-c", "ping -c 2 192.168.56.11")
}

Write-Host ""
Write-Host "Setup summary"
foreach ($machine in $Machines) {
  $status = if (Test-BaseSnapshot $machine.VBoxName) { "base snapshot present" } else { "base snapshot missing" }
  Write-Host ("- {0}: {1}" -f $machine.Name, $status)
}
Write-Host "- SSH cache: $SshCachePath"
Write-Host ""
Write-Host "Provisioning pre-stages offline dependencies into the base snapshots: apt/dnf local repos, Docker base image tar, source tarballs, libvirt XML, NFS/NBD/chrony/LDAP tooling, and common LFCS utilities."
Write-Host "Launch the lab with: .\lab.ps1"
