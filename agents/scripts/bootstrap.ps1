#Requires -Version 5.1
<#
.SYNOPSIS
  One-time per-machine baseline: wire dustin-thomason's agent rules into Claude Code globally.

.DESCRIPTION
  Run once after cloning dustin-thomason on a new machine (idempotent - safe to re-run):

    1. Enable the pre-commit hook (git config core.hooksPath scripts/git-hooks) so every future
       commit auto-regenerates and re-stages the outputs - this is what keeps new rules flowing.
    2. Regenerate every sync output (sync-rules.ps1), including the .claude/CLAUDE.md manifest.
    3. Ensure ~/.claude/CLAUDE.md imports this repo's .claude/CLAUDE.md inside a managed marker
       block, so the scope:always rules load in EVERY Claude Code session, in every repo -
       even ones that do not include dustin-thomason as a workspace folder.
    4. Set user env var CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 so path-scoped rules and
       CLAUDE.md also load natively when dustin-thomason IS an --add-dir workspace root.
    5. (-MirrorSkills) Copy agents/skills/** into ~/.claude/skills so skills work even in
       sessions that do not include dustin-thomason as a workspace root.

  Steps 1-2 write inside the repo; steps 3-5 modify your user profile (~/.claude, user env) and
  are deliberately NOT run by the pre-commit hook - this installer owns all outside-repo changes.
  Env var and skills mirror take effect in NEW Claude Code sessions.

  This supersedes the old manual "junction .claude/rules into ~/.claude/rules" setup: the
  ~/.claude/CLAUDE.md import (step 3) is what now loads these rules in every project.

.PARAMETER SkipEnvVar
  Do not set CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD.

.PARAMETER MirrorSkills
  Also mirror skills into ~/.claude/skills. Off by default (skills already load from --add-dir
  workspace roots); re-run bootstrap after changing skills to refresh the mirror.

.PARAMETER DryRun
  Print what would change without writing anything.
#>
param(
    [switch]$SkipEnvVar,
    [switch]$MirrorSkills,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
# This script lives in agents/scripts/. Sources live under agents/; the repo root is one level up.
$agentsDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $agentsDir
$syncScript = Join-Path $PSScriptRoot 'sync-rules.ps1'
$repoManifest = Join-Path $repoRoot '.claude\CLAUDE.md'

$beginMarker = '<!-- dustin-thomason:begin (managed by agents/scripts/bootstrap.ps1) -->'
$endMarker = '<!-- dustin-thomason:end -->'

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $normalized = (($Content -replace "`r`n", "`n") -replace "`r", "`n").TrimEnd() + "`n"
    [System.IO.File]::WriteAllText($Path, $normalized, [System.Text.UTF8Encoding]::new($false))
}

# --- Step 1: enable the auto-regeneration pre-commit hook (in-repo git config) ---
Write-Host '[1/5] Enabling pre-commit hook (git config core.hooksPath scripts/git-hooks)...'
if (-not $DryRun) {
    Push-Location $repoRoot
    try { & git config core.hooksPath scripts/git-hooks } finally { Pop-Location }
}

# --- Step 2: regenerate every sync output ---
Write-Host '[2/5] Regenerating sync outputs (sync-rules.ps1)...'
if ($DryRun) { Write-Host '  (dry run - skipped)' } else { & $syncScript }
if (-not $DryRun -and -not (Test-Path -LiteralPath $repoManifest)) {
    throw "Expected manifest not found at $repoManifest - did sync-rules.ps1 run?"
}

# --- Step 3: wire ~/.claude/CLAUDE.md import (managed block, idempotent) ---
$userClaudeDir = Join-Path $HOME '.claude'
$userClaude = Join-Path $userClaudeDir 'CLAUDE.md'
$importPath = ($repoManifest -replace '\\', '/')   # forward slashes are safe for the @import parser
$block = "$beginMarker`n@$importPath`n$endMarker"

Write-Host "[3/5] Wiring $userClaude -> @$importPath"
$existing = ''
if (Test-Path -LiteralPath $userClaude) {
    $existing = ([System.IO.File]::ReadAllText($userClaude) -replace "`r`n", "`n") -replace "`r", "`n"
}
# Strip any prior managed block (so re-runs refresh in place), then append a fresh one.
$pattern = "(?s)\n?" + [regex]::Escape($beginMarker) + ".*?" + [regex]::Escape($endMarker) + "\n?"
$stripped = [regex]::Replace($existing, $pattern, "`n").Trim()
$newContent = if ($stripped) { "$stripped`n`n$block" } else { $block }
if ($DryRun) {
    Write-Host "  would ensure this block is present:`n$block"
}
else {
    if (-not (Test-Path -LiteralPath $userClaudeDir)) { New-Item -ItemType Directory -Path $userClaudeDir -Force | Out-Null }
    Write-Utf8NoBom $userClaude $newContent
}

# --- Step 4: env var so add-dir workspace roots contribute CLAUDE.md + path-scoped rules ---
if ($SkipEnvVar) {
    Write-Host '[4/5] Skipping env var (per -SkipEnvVar).'
}
else {
    Write-Host '[4/5] Setting user env var CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1'
    if (-not $DryRun) { [Environment]::SetEnvironmentVariable('CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD', '1', 'User') }
}

# --- Step 5: optional skills mirror for solo-repo sessions ---
if ($MirrorSkills) {
    $skillsSource = Join-Path $agentsDir 'skills'
    $skillsDest = Join-Path $userClaudeDir 'skills'
    Write-Host "[5/5] Mirroring skills -> $skillsDest"
    if (-not $DryRun) {
        if (-not (Test-Path -LiteralPath $skillsDest)) { New-Item -ItemType Directory -Path $skillsDest -Force | Out-Null }
        foreach ($skill in (Get-ChildItem -LiteralPath $skillsSource -Directory -ErrorAction SilentlyContinue)) {
            $dest = Join-Path $skillsDest $skill.Name
            if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
            Copy-Item -LiteralPath $skill.FullName -Destination $dest -Recurse -Force
        }
    }
}
else {
    Write-Host '[5/5] Skipping skills mirror (skills already load from --add-dir roots; use -MirrorSkills for solo sessions).'
}

Write-Host ''
Write-Host 'Bootstrap complete. Start a new Claude Code session to pick up env var / user-memory changes.'
