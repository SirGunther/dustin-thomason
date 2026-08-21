#Requires -Version 5.1
<#
.SYNOPSIS
  Scaffold the documentation spine for a personal project: the canonical record in
  docs/<project>/ and the code-adjacent documents in the project repository.

.DESCRIPTION
  Writes five files from docs/_templates/. Canonical record (this repo):
    docs/<slug>/README.md                 index, ownership, maintenance rules
    docs/<slug>/<slug>-app-changelog.md   newest-first session log
    docs/<slug>/capabilities.md           what works vs what is simulated
  Code-adjacent (the project repo, via -RepoPath):
    ROADMAP.md                            scope, status, Decisions resolved
    DECISIONS-PENDING.md                  deferred choices with triggers
    DOCS.md                               pointer back to the canonical record

  DECISIONS-PENDING.md lives beside the code on purpose, so implementation cannot
  bypass a deferred choice. Only one authoritative changelog is ever created.

.EXAMPLE
  .\scripts\new-project-docs.ps1 -Project Cairn -RepoPath "C:\Users\dktho\OneDrive\PDProjects\Cairn"

.EXAMPLE
  .\scripts\new-project-docs.ps1 -Project Cairn -RepoPath "C:\...\Cairn" -Force -WhatIfSummary
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9 _-]*$')]
    [string]$Project,

    [Parameter(Mandatory)]
    [string]$RepoPath,

    [string]$Slug,

    [switch]$Force,

    # Report what would be written without writing anything.
    [switch]$WhatIfSummary
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$templateDir = Join-Path $repoRoot 'docs\_templates'

if (-not $Slug) { $Slug = ($Project -replace '[^A-Za-z0-9]+', '-').Trim('-').ToLowerInvariant() }

if (-not (Test-Path -LiteralPath $RepoPath)) {
    Write-Error "Project repository not found: $RepoPath"
}
$RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path

$docsDir = Join-Path $repoRoot "docs\$Slug"
$today = Get-Date -Format 'yyyy-MM-dd'

# template file -> destination
$plan = [ordered]@{
    'project-docs-README.template.md'       = Join-Path $docsDir 'README.md'
    'PROJECT-changelog.template.md'         = Join-Path $docsDir "$Slug-app-changelog.md"
    'PROJECT-capabilities.template.md'      = Join-Path $docsDir 'capabilities.md'
    'PROJECT-roadmap.template.md'           = Join-Path $RepoPath 'ROADMAP.md'
    'PROJECT-decisions-pending.template.md' = Join-Path $RepoPath 'DECISIONS-PENDING.md'
}

foreach ($template in $plan.Keys) {
    $path = Join-Path $templateDir $template
    if (-not (Test-Path -LiteralPath $path)) { Write-Error "Template not found: $path" }
}

# Collect collisions before writing anything, so a partial scaffold is impossible.
$existing = @($plan.Values | Where-Object { Test-Path -LiteralPath $_ })
$docsPointer = Join-Path $RepoPath 'DOCS.md'
if (Test-Path -LiteralPath $docsPointer) { $existing += $docsPointer }

if ($existing.Count -gt 0 -and -not $Force) {
    Write-Error ("These files already exist:`n  " + ($existing -join "`n  ") + "`nUse -Force to overwrite, or edit them directly.")
}

if ($WhatIfSummary) {
    Write-Host "Would write:"
    $plan.Values | ForEach-Object { Write-Host "  $_" }
    Write-Host "  $docsPointer"
    return
}

if (-not (Test-Path -LiteralPath $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
}

$tokens = @{
    '{{PROJECT}}'   = $Project
    '{{SLUG}}'      = $Slug
    '{{REPO_PATH}}' = $RepoPath
    '{{DOCS_PATH}}' = $docsDir
    '{{DATE}}'      = $today
}

foreach ($template in $plan.Keys) {
    $content = Get-Content -LiteralPath (Join-Path $templateDir $template) -Raw -Encoding UTF8
    foreach ($token in $tokens.Keys) { $content = $content.Replace($token, $tokens[$token]) }

    $target = $plan[$template]
    Set-Content -LiteralPath $target -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Created: $target"
}

# DOCS.md is short and fully determined by the parameters, so it is generated here
# rather than carried as a seventh template.
$pointer = @"
# $Project project documentation

The canonical $Project project record is:

``$docsDir``

Start with that directory's ``README.md``. It indexes the newest-first development
changelog and the capability catalog.

Code-adjacent documents stay in this repository because they govern or gate
implementation:

| Document | Purpose |
| --- | --- |
| [``ROADMAP.md``](ROADMAP.md) | Feature scope, status, and the **Decisions resolved** register |
| [``DECISIONS-PENDING.md``](DECISIONS-PENDING.md) | Deferred choices, each with a safe default and a concrete decision trigger |
| [``README.md``](README.md) | How to run this project and what it does not do |

``DECISIONS-PENDING.md`` stays beside the executable backlog on purpose, so
implementation cannot bypass a deferred choice.

**Do not create a second authoritative changelog here.** Update the canonical record
after each implementation session.
"@

Set-Content -LiteralPath $docsPointer -Value $pointer -Encoding UTF8
Write-Host "Created: $docsPointer"

Write-Host ""
Write-Host "Next: fill Current state in the changelog, then replace the placeholder rows."
Write-Host "      Leftover markers:  Select-String -Path `"$docsDir\*.md`",`"$RepoPath\ROADMAP.md`",`"$RepoPath\DECISIONS-PENDING.md`" -Pattern '\{\{|_[a-z].*_'"
