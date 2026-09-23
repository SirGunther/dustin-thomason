#Requires -Version 5.1
<#
.SYNOPSIS
  Down-and-dirty two-way sync for Claude Code auto-memory (and anything else you point it at)
  between machines, using this repo as the transport.

.DESCRIPTION
  Claude Code auto-memory lives under ~/.claude/projects/<sanitized-cwd>/memory/ - local to
  one machine, not git-tracked, not touched by sync-rules.ps1 or bootstrap.ps1. This script
  moves memory files (or any folder you name) through a staging folder in this repo so the
  normal git workflow (add/commit/push here, pull on the other machine) carries them across.

    Push: copies memory files FROM your local ~/.claude/projects/*/memory/  INTO
          agents/memory-sync/<project-folder-name>/  (commit + push this repo afterward).

    Pull: copies memory files FROM agents/memory-sync/<project-folder-name>/  INTO
          your local ~/.claude/projects/<project-folder-name>/memory/  (run after a git pull).

  Matching is by project-folder name (the sanitized-cwd hash Claude Code already uses), so
  this works cleanly when both machines use the same Windows username and the same OneDrive/
  repo path layout - which is the normal case for one person's own machines.

.PARAMETER Mode
  'Push' (local -> repo staging) or 'Pull' (repo staging -> local). Default: Push.

.PARAMETER Only
  Optional list of project-folder names to limit the sync to (e.g. the WorkLists folder name).
  Default: every project folder under the memory root.

.PARAMETER MemoryRoot
  Local auto-memory root. Default: $env:USERPROFILE\.claude\projects

.PARAMETER DryRun
  Print what would be copied without writing anything.

.EXAMPLE
  # On machine A: stage this machine's memory into the repo, then commit/push as usual.
  .\agents\scripts\sync-memory.ps1 -Mode Push

.EXAMPLE
  # On machine B: after `git pull`, drop the staged memory into place.
  .\agents\scripts\sync-memory.ps1 -Mode Pull
#>
param(
    [ValidateSet('Push', 'Pull')]
    [string]$Mode = 'Push',
    [string[]]$Only,
    [string]$MemoryRoot = (Join-Path $env:USERPROFILE '.claude\projects'),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# This script lives in agents/scripts/. Repo root is two levels up.
$agentsDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $agentsDir
$stagingRoot = Join-Path $repoRoot 'agents\memory-sync'

function Copy-Tree([string]$From, [string]$To) {
    if (-not (Test-Path -LiteralPath $From)) { return $false }
    if ($DryRun) {
        Write-Host "  [dry-run] would copy $From -> $To"
        return $true
    }
    if (-not (Test-Path -LiteralPath $To)) { New-Item -ItemType Directory -Path $To -Force | Out-Null }
    Get-ChildItem -LiteralPath $From -File | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $To -Force
    }
    return $true
}

# Push discovers project folders from the local memory root (what this machine has).
# Pull discovers them from the repo staging folder (what's available to bring down) - a
# machine that has never opened a given project yet has no folder under $MemoryRoot at all.
$scanRoot = if ($Mode -eq 'Push') { $MemoryRoot } else { $stagingRoot }

if (-not (Test-Path -LiteralPath $scanRoot)) {
    throw "Nothing to scan: $scanRoot does not exist."
}

$projectDirs = Get-ChildItem -LiteralPath $scanRoot -Directory
if ($Only) {
    $projectDirs = $projectDirs | Where-Object { $Only -contains $_.Name }
}

if ($projectDirs.Count -eq 0) {
    Write-Host "No matching project memory folders under $scanRoot."
    exit 0
}

Write-Host "Mode: $Mode"
Write-Host "Memory root: $MemoryRoot"
Write-Host "Staging root: $stagingRoot"
Write-Host ''

$touched = 0
foreach ($proj in $projectDirs) {
    # $proj.Name is the project-folder key either way; resolve both sides from it rather than
    # from $proj.FullName, since $proj was enumerated from $scanRoot (local root for Push,
    # staging root for Pull) and its FullName only makes sense on that one side.
    $localMemory = Join-Path (Join-Path $MemoryRoot $proj.Name) 'memory'
    $stagedMemory = Join-Path $stagingRoot $proj.Name

    if ($Mode -eq 'Push') {
        if (Copy-Tree $localMemory $stagedMemory) {
            Write-Host "Pushed: $($proj.Name)"
            $touched++
        }
    }
    else {
        if (Copy-Tree $stagedMemory $localMemory) {
            Write-Host "Pulled: $($proj.Name)"
            $touched++
        }
    }
}

Write-Host ''
Write-Host "$touched project folder(s) synced."
if ($Mode -eq 'Push' -and -not $DryRun -and $touched -gt 0) {
    Write-Host "Next: git add agents/memory-sync, commit, and push from $repoRoot."
}
if ($Mode -eq 'Pull' -and -not $DryRun -and $touched -gt 0) {
    Write-Host "Done - restart Claude Code sessions in the affected projects to pick up the memory."
}
