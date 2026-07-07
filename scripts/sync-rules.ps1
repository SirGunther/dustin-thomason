#Requires -Version 5.1
<#
.SYNOPSIS
  Generate every tool-specific rule artifact from the single neutral source of truth (rules/*.md).

.DESCRIPTION
  rules/*.md is the ONLY hand-edited location. Each rule carries its own per-tool directives in
  frontmatter, so there is no classification manifest living apart from the rule:

    ---
    description: <shared one-line summary>
    scope: always | scoped        # always = load unconditionally; scoped = load on demand
    globs: <comma,list>           # required iff scope: scoped (Cursor globs / Claude paths)
    codex: include | exclude      # whether the rule appears in AGENTS.md
    ---
    <body>

  From that, three outputs are generated (all committed, all machine-neutral):
    1. .cursor/rules/*.mdc  - Cursor: description + globs + alwaysApply frontmatter + body
    2. .claude/rules/*.md   - Claude Code: full body (always) or paths-scoped body (scoped)
    3. AGENTS.md            - Codex: concatenated bodies of every codex:include rule

  Every rules/*.md must have valid scope/codex (and globs when scoped) or the script throws,
  so a malformed or half-specified rule fails loudly instead of silently mis-generating.

.PARAMETER Check
  Build all artifacts in memory and compare to disk. Writes nothing. Exit 1 if any output is
  missing, stale, or orphaned (a generated file with no source rule). Used by the validator,
  the pre-commit hook, and CI.

.NOTES
  PS 5.1 safe: source is pure ASCII (em-dash via [char]0x2014); files are read with
  [IO.File]::ReadAllText (BOM-aware UTF-8) and written UTF-8 no-BOM with LF.
#>
param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot 'rules'
$agentsPath = Join-Path $repoRoot 'AGENTS.md'
$cursorDir = Join-Path $repoRoot '.cursor\rules'
$claudeDir = Join-Path $repoRoot '.claude\rules'
$skillsSource = Join-Path $repoRoot 'skills'
$cursorSkills = Join-Path $repoRoot '.cursor\skills'
$claudeSkills = Join-Path $repoRoot '.claude\skills'

function ConvertTo-Lf([string]$Text) {
    return ($Text -replace "`r`n", "`n") -replace "`r", "`n"
}
function Read-Utf8([string]$Path) {
    return [System.IO.File]::ReadAllText($Path)
}
function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $normalized = (ConvertTo-Lf $Content).TrimEnd() + "`n"
    [System.IO.File]::WriteAllText($Path, $normalized, [System.Text.UTF8Encoding]::new($false))
}
function Get-Marker([string]$Name) {
    return "<!-- generated from rules/$Name.md by scripts/sync-rules.ps1; edit the source, not this file -->"
}

function Get-Rules {
    $result = [System.Collections.Generic.List[object]]::new()
    foreach ($f in (Get-ChildItem -LiteralPath $sourceDir -Filter '*.md' -File | Sort-Object Name)) {
        $name = $f.BaseName
        $raw = ConvertTo-Lf (Read-Utf8 $f.FullName)
        $fm = @{}
        $body = $raw
        if ($raw -match '(?s)^---\n(.*?)\n---\n(.*)$') {
            $fmText = $Matches[1]
            $body = $Matches[2]
            foreach ($line in ($fmText -split "`n")) {
                if ($line -match '^\s*([A-Za-z][A-Za-z0-9_]*):\s*(.*)$') {
                    $fm[$Matches[1]] = $Matches[2].Trim()
                }
            }
        }
        else {
            throw "rules/$name.md has no YAML frontmatter (--- ... ---)."
        }

        $desc = $fm['description']
        $scope = $fm['scope']
        $globsRaw = $fm['globs']
        $codex = $fm['codex']

        if (-not $desc) { throw "rules/$name.md: missing 'description'." }
        if ($scope -ne 'always' -and $scope -ne 'scoped') {
            throw "rules/$name.md: 'scope' must be 'always' or 'scoped' (got '$scope')."
        }
        if ($codex -ne 'include' -and $codex -ne 'exclude') {
            throw "rules/$name.md: 'codex' must be 'include' or 'exclude' (got '$codex')."
        }
        $globs = @()
        if ($scope -eq 'scoped') {
            if (-not $globsRaw) { throw "rules/$name.md: scope 'scoped' requires 'globs'." }
            $globs = @($globsRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }

        $result.Add([pscustomobject]@{
                Name        = $name
                Description = $desc
                Scope       = $scope
                GlobsRaw    = $globsRaw
                Globs       = $globs
                Codex       = $codex
                Body        = $body.Trim()
            })
    }
    return $result
}

function Build-Agents($Rules) {
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("# AGENTS.md (generated $([char]0x2014) do not edit)")
    $parts.Add('')
    $parts.Add('Source: `rules/*.md`. Regenerate with `.\scripts\sync-rules.ps1`.')
    $parts.Add('')
    foreach ($r in ($Rules | Where-Object { $_.Codex -eq 'include' } | Sort-Object Name)) {
        $parts.Add("## $($r.Name)")
        $parts.Add('')
        $parts.Add($r.Body)
        $parts.Add('')
    }
    return ($parts -join "`n")
}

function Build-Cursor($Rule) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('---')
    $lines.Add("description: $($Rule.Description)")
    if ($Rule.Scope -eq 'scoped') {
        $lines.Add("globs: $($Rule.GlobsRaw)")
        $lines.Add('alwaysApply: false')
    }
    else {
        $lines.Add('alwaysApply: true')
    }
    $lines.Add('---')
    $lines.Add((Get-Marker $Rule.Name))
    $lines.Add('')
    $lines.Add($Rule.Body)
    return ($lines -join "`n")
}

function Build-Claude($Rule) {
    $lines = [System.Collections.Generic.List[string]]::new()
    if ($Rule.Scope -eq 'scoped') {
        $lines.Add('---')
        $lines.Add('paths:')
        foreach ($g in $Rule.Globs) { $lines.Add("  - `"$g`"") }
        $lines.Add('---')
    }
    $lines.Add((Get-Marker $Rule.Name))
    $lines.Add('')
    $lines.Add($Rule.Body)
    return ($lines -join "`n")
}

# --- Build every artifact in memory ---
$rules = Get-Rules
if ($rules.Count -eq 0) { throw "No rules found in $sourceDir." }

$agentsContent = (ConvertTo-Lf (Build-Agents $rules)).TrimEnd() + "`n"

$cursorExpected = @{}  # <name>.mdc -> content
$claudeExpected = @{}  # <name>.md  -> content
foreach ($r in $rules) {
    $cursorExpected["$($r.Name).mdc"] = (ConvertTo-Lf (Build-Cursor $r)).TrimEnd() + "`n"
    $claudeExpected["$($r.Name).md"] = (ConvertTo-Lf (Build-Claude $r)).TrimEnd() + "`n"
}

# Skills: mirror skills/<name>/** verbatim (LF-normalized) into .cursor/skills and .claude/skills.
# relpath key uses forward slashes, e.g. investigation/SKILL.md.
$skillExpected = @{}
if (Test-Path -LiteralPath $skillsSource) {
    foreach ($f in (Get-ChildItem -LiteralPath $skillsSource -Recurse -File)) {
        $rel = ($f.FullName.Substring($skillsSource.Length).TrimStart('\', '/')) -replace '\\', '/'
        $skillExpected[$rel] = (ConvertTo-Lf (Read-Utf8 $f.FullName)).TrimEnd() + "`n"
    }
}

function Test-Artifact([string]$Path, [string]$Expected, [System.Collections.Generic.List[string]]$Stale, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path)) { $Stale.Add("$Label missing"); return }
    if ((ConvertTo-Lf (Read-Utf8 $Path)) -ne $Expected) { $Stale.Add("$Label out of date") }
}

if ($Check) {
    $stale = [System.Collections.Generic.List[string]]::new()
    Test-Artifact $agentsPath $agentsContent $stale 'AGENTS.md'

    foreach ($fname in $cursorExpected.Keys) {
        Test-Artifact (Join-Path $cursorDir $fname) $cursorExpected[$fname] $stale ".cursor/rules/$fname"
    }
    foreach ($fname in $claudeExpected.Keys) {
        Test-Artifact (Join-Path $claudeDir $fname) $claudeExpected[$fname] $stale ".claude/rules/$fname"
    }
    if (Test-Path -LiteralPath $cursorDir) {
        foreach ($e in (Get-ChildItem -LiteralPath $cursorDir -Filter '*.mdc' -File)) {
            if (-not $cursorExpected.ContainsKey($e.Name)) { $stale.Add(".cursor/rules/$($e.Name) is orphaned (no source rule)") }
        }
    }
    if (Test-Path -LiteralPath $claudeDir) {
        foreach ($e in (Get-ChildItem -LiteralPath $claudeDir -Filter '*.md' -File)) {
            if (-not $claudeExpected.ContainsKey($e.Name)) { $stale.Add(".claude/rules/$($e.Name) is orphaned (no source rule)") }
        }
    }
    foreach ($rel in $skillExpected.Keys) {
        Test-Artifact (Join-Path $cursorSkills ($rel -replace '/', '\')) $skillExpected[$rel] $stale ".cursor/skills/$rel"
        Test-Artifact (Join-Path $claudeSkills ($rel -replace '/', '\')) $skillExpected[$rel] $stale ".claude/skills/$rel"
    }
    foreach ($t in @($cursorSkills, $claudeSkills)) {
        if (Test-Path -LiteralPath $t) {
            foreach ($e in (Get-ChildItem -LiteralPath $t -Recurse -File)) {
                $rel = ($e.FullName.Substring($t.Length).TrimStart('\', '/')) -replace '\\', '/'
                if (-not $skillExpected.ContainsKey($rel)) { $stale.Add("$($t.Substring($repoRoot.Length + 1) -replace '\\','/')/$rel is orphaned (no source skill)") }
            }
        }
    }

    if ($stale.Count -gt 0) {
        Write-Host 'STALE - regenerate with .\scripts\sync-rules.ps1:'
        foreach ($s in $stale) { Write-Host "  - $s" }
        exit 1
    }
    Write-Host 'Generated rule artifacts are up to date.'
    exit 0
}

# --- Write mode ---
foreach ($dir in @($cursorDir, $claudeDir)) {
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

Write-Utf8NoBom $agentsPath $agentsContent
foreach ($fname in $cursorExpected.Keys) { Write-Utf8NoBom (Join-Path $cursorDir $fname) $cursorExpected[$fname] }
foreach ($fname in $claudeExpected.Keys) { Write-Utf8NoBom (Join-Path $claudeDir $fname) $claudeExpected[$fname] }

# Remove orphaned generated files (source rule renamed/deleted).
foreach ($e in (Get-ChildItem -LiteralPath $cursorDir -Filter '*.mdc' -File)) {
    if (-not $cursorExpected.ContainsKey($e.Name)) { Remove-Item -LiteralPath $e.FullName -Force }
}
foreach ($e in (Get-ChildItem -LiteralPath $claudeDir -Filter '*.md' -File)) {
    if (-not $claudeExpected.ContainsKey($e.Name)) { Remove-Item -LiteralPath $e.FullName -Force }
}

# Mirror skills into both tool locations, then prune orphan files and empty dirs.
foreach ($rel in $skillExpected.Keys) {
    foreach ($t in @($cursorSkills, $claudeSkills)) {
        $dest = Join-Path $t ($rel -replace '/', '\')
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Write-Utf8NoBom $dest $skillExpected[$rel]
    }
}
foreach ($t in @($cursorSkills, $claudeSkills)) {
    if (Test-Path -LiteralPath $t) {
        foreach ($e in (Get-ChildItem -LiteralPath $t -Recurse -File)) {
            $rel = ($e.FullName.Substring($t.Length).TrimStart('\', '/')) -replace '\\', '/'
            if (-not $skillExpected.ContainsKey($rel)) { Remove-Item -LiteralPath $e.FullName -Force }
        }
        Get-ChildItem -LiteralPath $t -Recurse -Directory |
            Sort-Object { $_.FullName.Length } -Descending |
            Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Recurse -File) } |
            Remove-Item -Force -Recurse
    }
}

$codexCount = @($rules | Where-Object { $_.Codex -eq 'include' }).Count
$skillCount = @(Get-ChildItem -LiteralPath $skillsSource -Directory -ErrorAction SilentlyContinue).Count
Write-Host "Wrote AGENTS.md ($codexCount rules), .cursor/rules/ ($($cursorExpected.Count)), .claude/rules/ ($($claudeExpected.Count)), skills ($skillCount) to .cursor/skills + .claude/skills."
