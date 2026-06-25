#requires -Version 5.1
<#
.SYNOPSIS
  Smart installer / preflight for the LFCS Exam Lab (Windows).

.DESCRIPTION
  Wraps the lab in a one-command setup:
    1. checks this machine can run the lab (OS, CPU virtualization, RAM, disk)
    2. detects conflicting virtualization (Hyper-V / WSL2 / Memory Integrity)
    3. detects / installs Vagrant + VirtualBox
    4. builds the VMs (delegates to setup.ps1) and saves base snapshots
  Then you practice with: .\lfcs.ps1

.PARAMETER CheckOnly
  Run only the preflight checks and print a readiness report. Changes nothing.

.PARAMETER Yes
  Assume "yes" for prompts (non-interactive). Still refuses clearly unsafe steps.

.PARAMETER Rebuild
  Rebuild the base snapshots even if they already exist.

.PARAMETER SkipBuild
  Do everything except the (long) vagrant build step.

.EXAMPLE
  .\install.ps1 -CheckOnly      # safe: just tells you if you're ready
.EXAMPLE
  .\install.ps1                 # full guided install
#>
param(
  [switch]$CheckOnly,
  [switch]$Yes,
  [switch]$Rebuild,
  [switch]$SkipBuild,
  [switch]$SkipSmoke,
  [switch]$DisableHyperV
)

$ErrorActionPreference = "Stop"
$LabRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- requirements (derived from the Vagrantfile resource asks) ---------------
$MIN_RAM_GB  = 8     # node1 (4G) + node2 (3G) for the two-node questions
$REC_RAM_GB  = 16
$MIN_DISK_GB = 30    # boxes (~1.5G) + 3 VM disks + node1's 8x1G scratch disks
$REC_DISK_GB = 50
$MIN_CPU     = 2     # each VM is given 2 vCPUs
$REC_CPU     = 4

# ---- output helpers (ForegroundColor: no ANSI/encoding pitfalls) -------------
$script:Problems = 0
$script:Warnings = 0
function Head($t) { Write-Host ""; Write-Host "== $t ==" -ForegroundColor Cyan }
function Ok($t)   { Write-Host "  [ OK ] $t" -ForegroundColor Green }
function Warn($t) { Write-Host "  [WARN] $t" -ForegroundColor Yellow; $script:Warnings++ }
function Bad($t)  { Write-Host "  [FAIL] $t" -ForegroundColor Red; $script:Problems++ }
function Info($t) { Write-Host "  $t" -ForegroundColor Gray }

function Ask-YesNo($question, $defaultYes = $true) {
  if ($Yes) { return $true }
  $suffix = if ($defaultYes) { "[Y/n]" } else { "[y/N]" }
  $ans = Read-Host "  $question $suffix"
  if ([string]::IsNullOrWhiteSpace($ans)) { return $defaultYes }
  return $ans -match '^(y|yes)$'
}

# ---- detection ---------------------------------------------------------------

function Test-Command($name) {
  return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Get-VBoxManagePath {
  if (Test-Command "VBoxManage") { return (Get-Command VBoxManage).Source }
  $p = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
  if (Test-Path $p) { return $p }
  return $null
}

function Check-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Preflight {
  Head "System"
  $os = Get-CimInstance Win32_OperatingSystem
  $cs = Get-CimInstance Win32_ComputerSystem
  Info ("OS   : {0} ({1})" -f $os.Caption, $os.Version)
  $arch = $env:PROCESSOR_ARCHITECTURE
  Info ("Arch : {0}" -f $arch)
  if ($arch -match 'ARM') {
    Bad "ARM/Apple-Silicon-class CPU: VirtualBox cannot run the x86 Ubuntu/Rocky VMs this lab uses."
    Info "On ARM you'd need a cloud option (future Track 2). This installer targets x86-64 Windows."
  } else {
    Ok "x86-64 architecture"
  }

  Head "CPU"
  $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
  $cores = [int]$cs.NumberOfLogicalProcessors
  Info ("Logical processors: {0}" -f $cores)
  if ($cores -ge $REC_CPU) { Ok "$cores logical processors (>= $REC_CPU recommended)" }
  elseif ($cores -ge $MIN_CPU) { Warn "$cores logical processors (>= $MIN_CPU min; $REC_CPU recommended)" }
  else { Bad "$cores logical processors (need >= $MIN_CPU)" }

  # Virtualization firmware + whether a hypervisor already owns it.
  $hypervisorPresent = [bool]$cs.HypervisorPresent
  $vtEnabled = $null
  try { $vtEnabled = [bool]$cpu.VirtualizationFirmwareEnabled } catch { $vtEnabled = $null }
  if ($hypervisorPresent) {
    Info "A hypervisor is currently active (Hyper-V / WSL2 / Memory Integrity)."
  } elseif ($vtEnabled -eq $true) {
    Ok "Hardware virtualization (VT-x/AMD-V) is enabled in firmware"
  } elseif ($vtEnabled -eq $false) {
    Bad "Hardware virtualization (VT-x/AMD-V) appears DISABLED in BIOS/UEFI - enable it, or VMs cannot start"
  } else {
    Warn "Could not determine VT-x/AMD-V state; if VMs fail to start, enable virtualization in BIOS"
  }

  Head "Conflicting virtualization (Hyper-V / WSL2 / Memory Integrity)"
  $conflict = Detect-HyperVConflict
  if ($conflict.Active) {
    Warn "Active: $($conflict.Reasons -join '; ')"
    Info "VirtualBox runs slowly or fails when these are on. The full installer can offer to disable them"
    Info "(needs admin + a reboot, and will disable Docker Desktop/WSL2 if you rely on them)."
  } else {
    Ok "No conflicting hypervisor detected"
  }

  Head "Memory"
  $totalGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
  $freeGB = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 1)
  Info ("Total RAM: {0} GB | Free now: {1} GB" -f $totalGB, $freeGB)
  if ($totalGB -ge $REC_RAM_GB) { Ok "$totalGB GB RAM (>= $REC_RAM_GB recommended)" }
  elseif ($totalGB -ge $MIN_RAM_GB) { Warn "$totalGB GB RAM (>= $MIN_RAM_GB min; $REC_RAM_GB recommended for all 3 VMs)" }
  else { Bad "$totalGB GB RAM (need >= $MIN_RAM_GB; node1+node2 alone want ~7 GB)" }

  Head "Disk"
  $drive = (Get-Item $LabRoot).PSDrive.Name
  $d = Get-PSDrive $drive
  $freeDiskGB = [math]::Round($d.Free / 1GB, 1)
  Info ("Drive {0}: {1} GB free" -f $drive, $freeDiskGB)
  if ($freeDiskGB -ge $REC_DISK_GB) { Ok "$freeDiskGB GB free (>= $REC_DISK_GB recommended)" }
  elseif ($freeDiskGB -ge $MIN_DISK_GB) { Warn "$freeDiskGB GB free (>= $MIN_DISK_GB min; $REC_DISK_GB recommended)" }
  else { Bad "$freeDiskGB GB free (need >= $MIN_DISK_GB for boxes + VM disks + scratch disks)" }

  Head "Lab tooling"
  if (Check-Admin) { Ok "Running elevated (Administrator)" }
  else { Info "Not elevated - installing tools / toggling Hyper-V will need an admin run" }

  if (Test-Command "vagrant") {
    $vv = (& vagrant --version 2>$null)
    Ok "Vagrant present: $vv"
  } else { Warn "Vagrant not found (installer can add it via winget)" }

  $vbox = Get-VBoxManagePath
  if ($vbox) {
    $vbv = (& $vbox --version 2>$null)
    Ok "VirtualBox present: $vbv"
  } else { Warn "VirtualBox not found (installer can add it via winget)" }

  if (Test-Command "winget") { Ok "winget available (used to auto-install missing tools)" }
  else { Warn "winget not found - auto-install unavailable; you'd install Vagrant/VirtualBox manually" }

  # Boxes + base snapshots (only meaningful if vagrant/vbox exist)
  if (Test-Command "vagrant") {
    Head "Images & build state"
    $boxes = (& vagrant box list 2>$null) -join "`n"
    foreach ($b in @("bento/ubuntu-22.04", "bento/rockylinux-9")) {
      if ($boxes -match [regex]::Escape($b)) { Ok "box present: $b" }
      else { Info "box not downloaded yet: $b (vagrant up will fetch it)" }
    }
    if ($vbox) {
      foreach ($vm in @("lfcs-node1", "lfcs-node2", "lfcs-rocky1")) {
        $snaps = (& $vbox snapshot $vm list --machinereadable 2>$null) -join "`n"
        if ($snaps -match 'SnapshotName="base"') { Ok "$vm : base snapshot present (built)" }
        else { Info "$vm : not built yet" }
      }
    }
  }
}

function Detect-HyperVConflict {
  $reasons = @()
  try {
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.HypervisorPresent) { $reasons += "HypervisorPresent=true" }
  } catch {}
  try {
    $bcd = & bcdedit /enum '{current}' 2>$null | Out-String
    if ($bcd -match 'hypervisorlaunchtype\s+Auto') { $reasons += "bcdedit hypervisorlaunchtype=Auto" }
  } catch {}
  try {
    $dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue
    if ($dg -and $dg.SecurityServicesRunning -and ($dg.SecurityServicesRunning -contains 1)) {
      $reasons += "Memory Integrity / Credential Guard running"
    }
  } catch {}
  return [pscustomobject]@{ Active = ($reasons.Count -gt 0); Reasons = $reasons }
}

# ---- actions -----------------------------------------------------------------

function Test-BuildNeeded {
  $vbox = Get-VBoxManagePath
  if (!$vbox) { return $true }
  foreach ($vm in @("lfcs-node1", "lfcs-node2", "lfcs-rocky1")) {
    $snaps = (& $vbox snapshot $vm list --machinereadable 2>$null) -join "`n"
    if ($snaps -notmatch 'SnapshotName="base"') { return $true }
  }
  return $false
}

function Request-Elevation {
  # Relaunch this script in an elevated window, preserving switches.
  $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-File", $PSCommandPath)
  foreach ($name in $PSBoundParameters.Keys) {
    if ($PSBoundParameters[$name] -is [switch] -and $PSBoundParameters[$name]) {
      $argList += "-$name"
    }
  }
  Write-Host ""
  Info "This step needs Administrator rights (install software / change Windows features)."
  if (-not (Ask-YesNo "Relaunch this installer as Administrator now?")) {
    Warn "Skipped elevation. Re-run from an elevated PowerShell to install tools."
    return $false
  }
  try {
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList | Out-Null
    Info "An elevated window was opened. Continue there; this window can be closed."
    return $true
  } catch {
    # User cancelled the UAC prompt, or the launch failed. Do NOT report success:
    # the caller does `if (Request-Elevation) { exit 0 }`, so returning $true here
    # would exit 0 having installed nothing.
    Bad "Could not elevate (UAC cancelled or blocked): $($_.Exception.Message)"
    Warn "Re-run from an elevated PowerShell to install the tools."
    return $false
  }
}

function Install-WithWinget($id, $label) {
  if (-not (Test-Command "winget")) {
    Bad "$label is missing and winget is unavailable. Install $label manually, then re-run."
    return $false
  }
  if (-not (Ask-YesNo "Install $label now (winget: $id)?")) {
    Warn "Skipped installing $label."
    return $false
  }
  Write-Host "  Installing $label via winget..." -ForegroundColor Gray
  & winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements
  if ($LASTEXITCODE -ne 0) {
    Bad "winget failed for $label (exit $LASTEXITCODE). Install it manually, then re-run."
    return $false
  }
  Ok "$label installed."
  return $true
}

function Refresh-Path {
  $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $user = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machine;$user"
}

function Disable-HyperVStack {
  Write-Host ""
  Warn "Disabling Hyper-V / Memory Integrity requires a REBOOT and will break Docker Desktop / WSL2."
  if (-not (Ask-YesNo "Disable the conflicting hypervisor now?" $false)) {
    Info "Left the hypervisor enabled. VirtualBox 7+ often still works (via Windows Hypervisor Platform)."
    return $false
  }
  if (-not (Check-Admin)) {
    Bad "Need Administrator rights to change this. Re-run elevated with -DisableHyperV."
    return $false
  }
  try {
    & bcdedit /set hypervisorlaunchtype off | Out-Null
    Info "Set bcdedit hypervisorlaunchtype = off."
    try {
      dism.exe /Online /Disable-Feature:Microsoft-Hyper-V-All /NoRestart | Out-Null
      Info "Disabled the Hyper-V Windows feature."
    } catch { }
    Warn "REBOOT now, then re-run .\install.ps1 to continue."
    return $true
  } catch {
    Bad "Failed to disable hypervisor: $($_.Exception.Message)"
    return $false
  }
}

function Invoke-Build {
  Write-Host ""
  Head "Build VMs"
  Info "First build downloads ~1.5 GB of images and provisions 3 VMs."
  Info "Expect roughly 20-45 minutes depending on network and disk speed."
  if (-not (Ask-YesNo "Start the build now?")) {
    Warn "Build skipped. Re-run without -CheckOnly when ready."
    return $false
  }
  $setup = Join-Path $LabRoot "setup.ps1"
  $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $setup)
  if ($Rebuild) { $args += "-Rebuild" }
  & powershell.exe @args
  if ($LASTEXITCODE -ne 0) {
    Bad "Build failed (setup.ps1 exit $LASTEXITCODE). See messages above."
    return $false
  }
  Ok "Build complete; base snapshots saved."
  return $true
}

function Invoke-SmokeTest {
  Write-Host ""
  Head "Self-verify (smoke test)"
  Info "Runs one real question (q005) end-to-end: load -> validate-fails -> solve -> validate-passes -> restore."
  if (-not (Ask-YesNo "Run the self-verify now? (boots a VM briefly)")) {
    Warn "Smoke test skipped - install is unverified on this machine."
    return $null
  }
  $gate = Join-Path $LabRoot "scripts\run_question_gate.ps1"
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $gate -QuestionIds q005
  if ($LASTEXITCODE -eq 0) {
    Ok "VERIFIED: q005 passed load/validate/solve/restore on this machine."
    return $true
  }
  Bad "Self-verify FAILED. The lab is installed but a question did not pass end-to-end."
  Info "Re-run '.\install.ps1' or check VirtualBox/Vagrant; the readiness report above shows the likely cause."
  return $false
}

# ---- verdict -----------------------------------------------------------------

function Show-Verdict {
  Head "Readiness"
  if ($script:Problems -gt 0) {
    Write-Host "  BLOCKED: $($script:Problems) problem(s), $($script:Warnings) warning(s)." -ForegroundColor Red
    Write-Host "  Resolve the [FAIL] items above, then re-run." -ForegroundColor Red
    return 2
  }
  if ($script:Warnings -gt 0) {
    Write-Host "  READY WITH WARNINGS: $($script:Warnings) warning(s) - review the [WARN] items above." -ForegroundColor Yellow
    return 1
  }
  Write-Host "  READY: this machine can build and run the lab." -ForegroundColor Green
  return 0
}

# ---- main --------------------------------------------------------------------

Write-Host ""
Write-Host "LFCS Exam Lab - smart installer" -ForegroundColor Cyan
Write-Host "Lab root: $LabRoot"
Preflight
$verdict = Show-Verdict

if ($CheckOnly) {
  Write-Host ""
  Write-Host "Check-only mode: nothing was changed. Re-run without -CheckOnly to install/build." -ForegroundColor Gray
  exit $verdict
}

if ($verdict -eq 2) {
  Write-Host ""
  Write-Host "Resolve the [FAIL] items above, then re-run .\install.ps1" -ForegroundColor Red
  exit 2
}

# What does this machine still need?
$needVagrant = -not (Test-Command "vagrant")
$needVbox    = ($null -eq (Get-VBoxManagePath))
$conflict    = Detect-HyperVConflict
$buildNeeded = Test-BuildNeeded

# Elevate up front if an admin action is required and we're not elevated.
$needsAdmin = $needVagrant -or $needVbox -or ($DisableHyperV)
if ($needsAdmin -and -not (Check-Admin)) {
  if (Request-Elevation) { exit 0 }     # elevated window spawned; this one is done
  exit 1                                # elevation cancelled/failed - stop, don't pretend success
}

# 1) Install missing tools.
if ($needVagrant) { [void](Install-WithWinget "Hashicorp.Vagrant" "Vagrant") }
if ($needVbox)    { [void](Install-WithWinget "Oracle.VirtualBox" "VirtualBox") }
if ($needVagrant -or $needVbox) {
  Refresh-Path
  if (-not (Test-Command "vagrant") -or ($null -eq (Get-VBoxManagePath))) {
    Write-Host ""
    Warn "Vagrant/VirtualBox still not visible in this session."
    Info "Close this window, open a new PowerShell, and re-run .\install.ps1 (a reboot may be needed after a VirtualBox install)."
    exit 1
  }
}

# 2) Conflicting hypervisor. Only nudge when VirtualBox was freshly installed or
#    the user explicitly asked; if VBox already works here, leave it alone.
if ($conflict.Active -and ($DisableHyperV -or $needVbox)) {
  if (Disable-HyperVStack) { exit 0 }  # rebooted path: user re-runs after restart
}

# 3) Build (only if base snapshots are missing).
if ($SkipBuild) {
  Info "SkipBuild set - not building."
} elseif ($buildNeeded) {
  if (-not (Invoke-Build)) { exit 1 }
} else {
  Write-Host ""
  Ok "VMs already built (base snapshots present) - skipping build."
}

# 4) Self-verify.
$smoke = $null
if (-not $SkipSmoke -and -not $SkipBuild) {
  $smoke = Invoke-SmokeTest
}

# 5) Done.
Write-Host ""
Head "Done"
if ($smoke -eq $true) {
  Write-Host "  Setup verified. Start practicing:" -ForegroundColor Green
} else {
  Write-Host "  Setup complete. Start practicing:" -ForegroundColor Green
}
Write-Host "    .\lfcs.ps1" -ForegroundColor White
exit 0
