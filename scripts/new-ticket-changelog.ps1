#Requires -Version 5.1
<#
.SYNOPSIS
  Scaffold docs/<system>/PRDV-XXXXX-changelog.md from the ticket template.

.EXAMPLE
  .\scripts\new-ticket-changelog.ps1 -Ticket PRDV-15263 -System atlas -Title "Truncate long filenames"

.EXAMPLE
  .\scripts\new-ticket-changelog.ps1 -Ticket PRDV-15263 -System atlas -RequirementsFile .\requirements.txt
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^PRDV-\d+$')]
    [string]$Ticket,

    [Parameter(Mandatory)]
    [ValidateSet('atlas', 'callisto', 'europa', 'triton', 'other')]
    [string]$System,

    [string]$Title = 'Short title from ticket',

    [string]$Repo,

    [string]$RequirementsFile,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$templatePath = Join-Path $repoRoot 'docs\_templates\TICKET-changelog.template.md'
$outDir = Join-Path $repoRoot "docs\$System"
$outPath = Join-Path $outDir "$Ticket-changelog.md"

$defaultRepos = @{
    atlas    = 'atlas-front-end'
    callisto = 'callisto-back-end'
    europa   = 'europa-back-end'
    triton   = 'triton-back-end'
}

if (-not $Repo) {
    if ($System -eq 'other') {
        Write-Error 'When -System is other, pass -Repo explicitly (e.g. -Repo my-service).'
    }
    $Repo = $defaultRepos[$System]
}

if (-not (Test-Path -LiteralPath $templatePath)) {
    Write-Error "Template not found: $templatePath"
}

if ((Test-Path -LiteralPath $outPath) -and -not $Force) {
    Write-Error "Changelog already exists: $outPath`nUse -Force to overwrite, or edit the existing file."
}

if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$today = Get-Date -Format 'yyyy-MM-dd'
$content = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8

$content = $content.Replace('PRDV-XXXXX', $Ticket)
$content = $content.Replace('Short title from ticket', $Title)
$content = $content.Replace(
    '`atlas-front-end` | `callisto-back-end` | `europa-back-end` | `triton-back-end`',
    "``$Repo``"
)
$content = $content -replace 'as of YYYY-MM-DD', "as of $today"
$content = $content -replace '### YYYY-MM-DD — repo-name', "### $today — $Repo"

if ($RequirementsFile) {
    $reqPath = Resolve-Path -LiteralPath $RequirementsFile
    $verbatim = Get-Content -LiteralPath $reqPath -Raw -Encoding UTF8
    $verbatim = ($verbatim.Trim() -split "`r?`n" | ForEach-Object { "> $_" }) -join "`n"
    $content = $content -replace '(?s)(## Requirements \(verbatim\).*?)(> \s*\r?\n)', "`$1$verbatim`n`n"
}

if ($Force -and (Test-Path -LiteralPath $outPath)) {
    Remove-Item -LiteralPath $outPath -Force
}

Set-Content -LiteralPath $outPath -Value $content -Encoding UTF8 -NoNewline
Add-Content -LiteralPath $outPath -Value "`n" -Encoding UTF8

Write-Host "Created: $outPath"
Write-Host "Next: paste or verify Requirements (verbatim), then work / commit per ticket-changelog-workflow.md"
