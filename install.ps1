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
  [switch]$SkipBuild
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
  exit 2
}

Write-Host ""
Write-Host "(The install/build steps - tool install, optional Hyper-V toggle, vagrant build -" -ForegroundColor Gray
Write-Host " are added in the next layer. Preflight is complete and safe to run any time.)" -ForegroundColor Gray
exit $verdict
