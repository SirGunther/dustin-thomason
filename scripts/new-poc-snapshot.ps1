#Requires -Version 5.1
<#
.SYNOPSIS
  Freeze a project as an immutable POC comparison baseline: a copy, a SNAPSHOT.md,
  a SHA-256 manifest, a ZIP, and the ZIP's checksum sidecar.

.DESCRIPTION
  Reproduces the sequence that produced Argus-POC-v1-2026-08-12, which until now
  existed only as its own output and could not be repeated.

  Creates, beside the source project:
    <Name>-POC-v<N>-<yyyy-MM-dd>\<Name>\      the copy, excluding build/VCS noise
    <Name>-POC-v<N>-<yyyy-MM-dd>\SNAPSHOT.md  rendered from the template
    <Name>-POC-v<N>-<yyyy-MM-dd>\SHA256SUMS.txt
    <Name>-POC-v<N>-<yyyy-MM-dd>\TEST-RESULT.txt   only with -VerifyCommand
    <Name>-POC-v<N>-<yyyy-MM-dd>.zip
    <Name>-POC-v<N>-<yyyy-MM-dd>.zip.sha256   beside the ZIP, not inside the folder

  SHA256SUMS.txt uses `<hash>  <relative/path>` with forward slashes, sorted, so
  `sha256sum -c` accepts it. Both checksum files are written UTF-8 **without** BOM:
  the existing Argus sidecar has a BOM, which makes `sha256sum -c` reject its only line.

.EXAMPLE
  .\scripts\new-poc-snapshot.ps1 -Project Cairn -RepoPath "C:\Users\dktho\OneDrive\PDProjects\Cairn"

.EXAMPLE
  .\scripts\new-poc-snapshot.ps1 -Project Cairn -RepoPath "C:\...\Cairn" -Version 2 -VerifyCommand "node --check app.js"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_-]*$')]
    [string]$Project,

    [Parameter(Mandatory)]
    [string]$RepoPath,

    [int]$Version = 1,

    # Destination for the snapshot folder and ZIP. Defaults to the project's parent.
    [string]$DestinationRoot,

    # Additional directory names to exclude, on top of the defaults below.
    [string[]]$ExcludeDir,

    # Run inside the snapshot copy and capture stdout+stderr to TEST-RESULT.txt.
    [string]$VerifyCommand,

    # Markdown for SNAPSHOT.md's narrative sections: Purpose, what the POC proves,
    # what is intentionally unresolved, strengths and weaknesses to compare. It is
    # rendered before hashing, because SNAPSHOT.md is itself covered by
    # SHA256SUMS.txt and the ZIP -- editing it afterwards invalidates both.
    [string]$NarrativeFile,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$templatePath = Join-Path $repoRoot 'docs\_templates\POC-SNAPSHOT.template.md'
if (-not (Test-Path -LiteralPath $templatePath)) { Write-Error "Template not found: $templatePath" }

if (-not (Test-Path -LiteralPath $RepoPath)) { Write-Error "Project not found: $RepoPath" }
$RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path

if (-not $DestinationRoot) { $DestinationRoot = Split-Path -Parent $RepoPath }
$DestinationRoot = (Resolve-Path -LiteralPath $DestinationRoot).Path

$today = Get-Date -Format 'yyyy-MM-dd'
$snapshotName = "$Project-POC-v$Version-$today"
$snapshotDir = Join-Path $DestinationRoot $snapshotName
$payloadDir = Join-Path $snapshotDir $Project
$zipPath = Join-Path $DestinationRoot "$snapshotName.zip"
$sidecarPath = "$zipPath.sha256"

$skipDirs = @('node_modules', '.git', 'dist', 'build', 'out', 'coverage', '.next', '.cache') + $ExcludeDir |
    Where-Object { $_ } | Select-Object -Unique

foreach ($path in @($snapshotDir, $zipPath, $sidecarPath)) {
    if (Test-Path -LiteralPath $path) {
        if (-not $Force) {
            Write-Error "Already exists: $path`nUse -Force to replace, or bump -Version. Prefer bumping: a snapshot is meant to be immutable."
        }
        # Read-only is set on the way out, so it has to be cleared before removal.
        Get-ChildItem -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue |
            ForEach-Object { try { $_.IsReadOnly = $false } catch {} }
        if (Test-Path -LiteralPath $path -PathType Leaf) { (Get-Item -LiteralPath $path).IsReadOnly = $false }
        Remove-Item -LiteralPath $path -Recurse -Force -Confirm:$false
    }
}

# ---------------------------------------------------------------- 1. copy ----
New-Item -ItemType Directory -Path $payloadDir -Force | Out-Null

$sourceFiles = Get-ChildItem -LiteralPath $RepoPath -Recurse -File -Force | Where-Object {
    $relative = $_.FullName.Substring($RepoPath.Length).TrimStart('\')
    $segments = $relative -split '\\'
    $dirSegments = if ($segments.Count -gt 1) { $segments[0..($segments.Count - 2)] } else { @() }
    -not ($dirSegments | Where-Object { $skipDirs -contains $_ })
}

foreach ($file in $sourceFiles) {
    $relative = $file.FullName.Substring($RepoPath.Length).TrimStart('\')
    $target = Join-Path $payloadDir $relative
    $targetDir = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
}

$fileCount = $sourceFiles.Count
$byteCount = ($sourceFiles | Measure-Object -Property Length -Sum).Sum
$byteLabel = '{0:N0}' -f $byteCount
Write-Host "Copied $fileCount files ($byteLabel bytes) to $payloadDir"

# ------------------------------------------------------------- 2. verify ----
$verifyBlock = "# No verification command was captured for this snapshot."
$verificationSummary = 'none captured'
if ($VerifyCommand) {
    Push-Location $payloadDir
    try {
        $output = & cmd /c "$VerifyCommand 2>&1"
        $exit = $LASTEXITCODE
    }
    finally { Pop-Location }

    $result = @(
        $snapshotName,
        "Captured: $today",
        "Command:  $VerifyCommand",
        "Exit code: $exit",
        "",
        "Output:",
        ($output -join "`n")
    ) -join "`n"

    Set-Content -LiteralPath (Join-Path $snapshotDir 'TEST-RESULT.txt') -Value $result -Encoding UTF8
    $verifyBlock = $VerifyCommand
    $verdict = if ($exit -eq 0) { 'passed' } else { "FAILED (exit $exit)" }
    $verificationSummary = "$verdict - see ``TEST-RESULT.txt``"
    Write-Host "Verification captured (exit $exit): TEST-RESULT.txt"
    if ($exit -ne 0) {
        Write-Warning "The verification command exited $exit. The snapshot still records it; a failing baseline recorded as failing is the point."
    }
}

# ---------------------------------------------------------- 3. SNAPSHOT.md ----
# Assigning a try/catch expression to a variable is PowerShell 7+ only; 5.1 needs
# the statement form. Node may not be on PATH for a non-JS project, which is fine.
$runtime = 'not recorded'
try {
    $nodeVersion = (& node --version) 2>$null
    if ($LASTEXITCODE -eq 0 -and $nodeVersion) {
        $trimmed = $nodeVersion -replace '^v', ''
        $runtime = "Node.js $trimmed"
    }
}
catch {
    $runtime = 'not recorded'
}
$timezone = (Get-TimeZone).Id

$narrative = @'
## Purpose

_Why this baseline is being preserved, and what it will later be compared against._

## What this POC proves

- _Claim a reader could check by opening the snapshot cold._

## Intentionally unresolved at this snapshot

- _Open item._

## Historical strengths to compare

- _What is worth not losing._

## Historical weaknesses to compare

- _What is weak, so later improvement is measurable rather than asserted._
'@

if ($NarrativeFile) {
    if (-not (Test-Path -LiteralPath $NarrativeFile)) {
        Write-Error "Narrative file not found: $NarrativeFile"
    }
    $narrative = (Get-Content -LiteralPath $NarrativeFile -Raw -Encoding UTF8).TrimEnd()
    Write-Host "Narrative: $NarrativeFile"
}
else {
    Write-Warning "No -NarrativeFile given. SNAPSHOT.md ships placeholder prose, and editing it later will invalidate SHA256SUMS.txt and the ZIP. Prefer authoring the narrative first."
}

$content = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$tokens = @{
    '{{PROJECT}}'         = $Project
    '{{SNAPSHOT_NAME}}'   = $snapshotName
    '{{DATE}}'            = $today
    '{{TIMEZONE}}'        = $timezone
    '{{REPO_PATH}}'       = $RepoPath
    '{{RUNTIME}}'         = $runtime
    '{{FILE_COUNT}}'      = "$fileCount"
    '{{BYTE_COUNT}}'      = $byteLabel
    '{{VERIFY_COMMANDS}}' = $verifyBlock
    '{{NARRATIVE}}'       = $narrative
    '{{VERIFICATION}}'    = $verificationSummary
}
foreach ($token in $tokens.Keys) { $content = $content.Replace($token, $tokens[$token]) }
Set-Content -LiteralPath (Join-Path $snapshotDir 'SNAPSHOT.md') -Value $content -Encoding UTF8 -NoNewline
Write-Host "Created: SNAPSHOT.md"

# ------------------------------------------------------- 4. SHA256SUMS.txt ----
# UTF-8 without BOM, forward slashes, sorted: the format `sha256sum -c` expects.
$noBom = New-Object System.Text.UTF8Encoding($false)

$lines = Get-ChildItem -LiteralPath $snapshotDir -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $relative = $_.FullName.Substring($snapshotDir.Length).TrimStart('\').Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $relative"
    }

[System.IO.File]::WriteAllText((Join-Path $snapshotDir 'SHA256SUMS.txt'), (($lines -join "`n") + "`n"), $noBom)
$lineCount = $lines.Count
Write-Host "Created: SHA256SUMS.txt ($lineCount entries)"

# ------------------------------------------------------------------ 5. zip ----
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($snapshotDir, $zipPath)

$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
[System.IO.File]::WriteAllText($sidecarPath, "$zipHash  $snapshotName.zip`n", $noBom)
Write-Host "Created: $zipPath"
Write-Host "Created: $sidecarPath"

# ------------------------------------------------------------ 6. read-only ----
# An accidental-edit deterrent, not immutability. SHA256SUMS.txt is what makes a
# later change detectable.
Get-ChildItem -LiteralPath $snapshotDir -Recurse -File | ForEach-Object { $_.IsReadOnly = $true }
(Get-Item -LiteralPath $zipPath).IsReadOnly = $true

Write-Host ""
Write-Host "Snapshot: $snapshotDir"
if (-not $NarrativeFile) {
    Write-Host "Next: author the narrative, then re-run with -NarrativeFile and -Force."
    Write-Host "      Editing SNAPSHOT.md in place would invalidate SHA256SUMS.txt and the ZIP."
}
else {
    Write-Host "Verify: sha256sum -c SHA256SUMS.txt   (from inside the snapshot folder)"
}
