#requires -Version 5.1
<#
  lfcs.ps1 - friendly entry point for the LFCS Exam Lab (Windows).
  Thin wrapper around lab.ps1 so users can just run:  .\lfcs.ps1
  All arguments are passed straight through to lab.ps1.
#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$lab = Join-Path $here "lab.ps1"
if (-not (Test-Path $lab)) {
  Write-Host "lab.ps1 not found next to lfcs.ps1 - is the repo intact?" -ForegroundColor Red
  exit 1
}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $lab @args
