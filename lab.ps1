$ErrorActionPreference = "Stop"

$LabRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:VAGRANT_HOME = Join-Path $LabRoot ".vagrant.d"
$ProgressPath = Join-Path $LabRoot "progress.json"

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

function Invoke-Vagrant($arguments) {
  Push-Location $LabRoot
  try {
    & vagrant @arguments
    return $LASTEXITCODE
  }
  finally {
    Pop-Location
  }
}

function Load-Question($qid) {
  Write-Host "Restoring node1 base snapshot..."
  $rc = Invoke-Vagrant @("snapshot", "restore", "node1", "base", "--no-provision")
  if ($rc -ne 0) { throw "Snapshot restore failed for $qid" }

  Write-Host "Injecting $qid..."
  $rc = Invoke-Vagrant @("ssh", "node1", "-c", "sudo bash /vagrant/inject/$qid.sh")
  if ($rc -ne 0) { throw "Inject failed for $qid" }
}

function Validate-Question($qid) {
  Push-Location $LabRoot
  try {
    $output = & vagrant ssh node1 -c "sudo bash /vagrant/validate/$qid.sh" 2>&1
    $rc = $LASTEXITCODE
  }
  finally {
    Pop-Location
  }

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
  Load-Question $current.id
  $showHints = $false

  while ($true) {
    Clear-Host
    Write-Host "$($current.id): $($current.title)"
    Write-Host "Domain: $($current.domain) | Difficulty: $($current.difficulty)"
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
    if ($action -eq "v") { [void](Validate-Question $current.id); Read-Host "Press Enter" }
    elseif ($action -eq "s") { [void](Invoke-Vagrant @("ssh", "node1")) }
    elseif ($action -eq "r") { Load-Question $current.id }
    elseif ($action -eq "h") { $showHints = !$showHints }
    elseif ($action -eq "q") { break }
  }
}
