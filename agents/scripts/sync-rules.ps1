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
    codex: include | exclude      # whether the rule appears in agents-rules.md
    ---
    <body>

  From that, three outputs are generated (all committed, all machine-neutral):
    1. .cursor/rules/*.mdc  - Cursor: description + globs + alwaysApply frontmatter + body
    2. .claude/rules/*.md   - Claude Code: full body (always) or paths-scoped body (scoped)
    3. agents-rules.md      - Codex: concatenated bodies of every codex:include rule

  Every rules/*.md must have valid scope/codex (and globs when scoped) or the script throws,
  so a malformed or half-specified rule fails loudly instead of silently mis-generating.

.PARAMETER Check
  Build all artifacts in memory and compare to disk. Writes nothing. Exit 1 if any output is
  missing, stale, or orphaned (a generated file with no source rule). Used by the validator,
  the pre-commit hook, and CI.

.NOTES
  PS 5.1 safe: source is pure ASCII (em-dash via [char]0x2014); files are read with
  [IO.File]::ReadAllText (BOM-aware UTF-8) and written UTF-8 no-BOM with LF.
  Path/name ordering uses Ordinal string compare (not Sort-Object's culture word-sort) so
  pwsh and Windows PowerShell 5.1 produce byte-identical artifacts; the pre-commit hook
  always invokes powershell.exe, while interactive shells are often pwsh.
#>
param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
# This script lives in agents/scripts/. Sources live under agents/; outputs live at each
# tool's canonical location under the repo root (one level above agents/).
$agentsDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $agentsDir

# Sources (the single hand-edited home).
$sourceDir = Join-Path $agentsDir 'rules'
$skillsSource = Join-Path $agentsDir 'skills'
$docsSource = Join-Path $agentsDir 'docs'

# workflow-index.md is a hybrid: hand-edited editorial + one generated "Complete inventory"
# block (between the markers below) that this script rebuilds from the folder so nothing added
# under agents/ can silently miss the index.
$indexPath = Join-Path $docsSource 'workflow-index.md'
$inventoryBegin = '<!-- BEGIN generated:inventory (agents/scripts/sync-rules.ps1) - do not edit; regenerate with sync-rules.ps1 -->'
$inventoryEnd = '<!-- END generated:inventory -->'

# Outputs (generated; each at the location its tool reads).
$cursorDir = Join-Path $repoRoot '.cursor\rules'
$claudeDir = Join-Path $repoRoot '.claude\rules'
$cursorSkills = Join-Path $repoRoot '.cursor\skills'
$claudeSkills = Join-Path $repoRoot '.claude\skills'
$cursorDocs = Join-Path $repoRoot '.cursor\docs'
$claudeDocs = Join-Path $repoRoot '.claude\docs'
# Claude-global manifest: a portable CLAUDE.md (relative @imports of the scope:always rules)
# that ~/.claude/CLAUDE.md imports so the always-on rules load in every session, every repo.
$claudeManifestPath = Join-Path $repoRoot '.claude\CLAUDE.md'
# Compiled single-file surfaces for Codex (which can't read folders): one per source type.
$agentsRulesPath = Join-Path $repoRoot 'agents-rules.md'
$agentsSkillsPath = Join-Path $repoRoot 'agents-skills.md'
$agentsDocsPath = Join-Path $repoRoot 'agents-docs.md'

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
function Get-OrdinalSortedStrings([string[]]$Values) {
    # Ordinal (not culture) sort so pwsh and Windows PowerShell 5.1 emit identical concat order.
    # PS 5.1 Sort-Object uses word-sort that ignores hyphens, so test-plan vs testing-* diverge.
    $arr = [string[]]@($Values)
    if ($arr.Count -gt 1) {
        [array]::Sort($arr, [System.StringComparer]::Ordinal)
    }
    return $arr
}
function Get-OrdinalSortedByName {
    param([object[]]$Items)
    $arr = @($Items)
    if ($arr.Count -le 1) { return $arr }
    $comparison = [System.Comparison[object]] {
        param($a, $b)
        [string]::Compare([string]$a.Name, [string]$b.Name, [System.StringComparison]::Ordinal)
    }
    [array]::Sort($arr, $comparison)
    return $arr
}
function Build-Concat([string]$Title, [string]$SourceDesc, [hashtable]$FileMap) {
    # Compile a file map (relpath -> content) into one flat artifact: header + '## <relpath>' sections.
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("# $Title (generated $([char]0x2014) do not edit)")
    $parts.Add('')
    $parts.Add("Source: $SourceDesc. Regenerate with ``.\agents\scripts\sync-rules.ps1``.")
    $parts.Add('')
    foreach ($rel in (Get-OrdinalSortedStrings @($FileMap.Keys))) {
        $parts.Add("## $rel")
        $parts.Add('')
        $parts.Add($FileMap[$rel].TrimEnd())
        $parts.Add('')
    }
    return ($parts -join "`n")
}

function Get-FmField([string]$Path, [string]$Field) {
    # First value of a frontmatter field (--- ... ---), or '' if absent.
    $raw = ConvertTo-Lf (Read-Utf8 $Path)
    if ($raw -match '(?s)^---\n(.*?)\n---\n') {
        foreach ($line in ($Matches[1] -split "`n")) {
            if ($line -match "^\s*$([regex]::Escape($Field)):\s*(.*)$") { return $Matches[1].Trim() }
        }
    }
    return ''
}
function Get-FirstHeading([string]$Path) {
    foreach ($line in ((ConvertTo-Lf (Read-Utf8 $Path)) -split "`n")) {
        if ($line -match '^#\s+(.*)$') { return $Matches[1].Trim() }
    }
    return ''
}
function Get-Synopsis([string]$Path) {
    # First non-empty line of the comment-based-help .SYNOPSIS block.
    $lines = (ConvertTo-Lf (Read-Utf8 $Path)) -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\.SYNOPSIS\s*$') {
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                $t = $lines[$j].Trim()
                if ($t -eq '') { continue }
                if ($t -match '^\.[A-Za-z]' -or $t -match '#>') { break }
                return $t
            }
        }
    }
    return ''
}
function Format-Cell([string]$Text) {
    # One-line, table-safe: collapse newlines, escape pipes.
    if (-not $Text) { return '' }
    return ((($Text -replace "`n", ' ') -replace '\|', '\|').Trim())
}
function Build-Inventory($Rules) {
    # The generated "Complete inventory" block: every rule/skill/doc/script + its own description,
    # so adding anything under agents/ (or scripts/) auto-populates the index on the next sync.
    $l = [System.Collections.Generic.List[string]]::new()
    $l.Add($inventoryBegin)
    $l.Add('## Complete inventory (generated)')
    $l.Add('')
    $l.Add('Every rule, skill, doc, and script under `agents/` (and `scripts/`), auto-built from the folder + frontmatter by `agents/scripts/sync-rules.ps1`. `-Check` fails if this is stale, so nothing you add can silently miss the index. The routing/editorial sections above are hand-written.')
    $l.Add('')
    $l.Add('### Rules (`agents/rules/`)')
    $l.Add('')
    $l.Add('| Rule | Load | Purpose |')
    $l.Add('| ---- | ---- | ------- |')
    foreach ($r in (Get-OrdinalSortedByName @($Rules))) {
        $l.Add("| ``$($r.Name)`` | $($r.Scope) | $(Format-Cell $r.Description) |")
    }
    $l.Add('')
    $l.Add('### Skills (`agents/skills/`)')
    $l.Add('')
    $l.Add('| Skill | Purpose |')
    $l.Add('| ----- | ------- |')
    foreach ($d in (Get-OrdinalSortedByName @(Get-ChildItem -LiteralPath $skillsSource -Directory -ErrorAction SilentlyContinue))) {
        $l.Add("| ``$($d.Name)`` | $(Format-Cell (Get-FmField (Join-Path $d.FullName 'SKILL.md') 'description')) |")
    }
    $l.Add('')
    $l.Add('### Docs & playbooks (`agents/docs/`)')
    $l.Add('')
    $l.Add('| Doc | About |')
    $l.Add('| --- | ----- |')
    foreach ($f in (Get-OrdinalSortedByName @(Get-ChildItem -LiteralPath $docsSource -Filter '*.md' -File -ErrorAction SilentlyContinue))) {
        if ($f.Name -eq 'workflow-index.md') { continue }
        $l.Add("| ``$($f.Name)`` | $(Format-Cell (Get-FirstHeading $f.FullName)) |")
    }
    $l.Add('')
    $l.Add('### Scripts (`scripts/`, `agents/scripts/`)')
    $l.Add('')
    $l.Add('| Script | Purpose |')
    $l.Add('| ------ | ------- |')
    $scriptFiles = @()
    $scriptFiles += Get-ChildItem -LiteralPath (Join-Path $repoRoot 'scripts') -Filter '*.ps1' -File -ErrorAction SilentlyContinue
    $scriptFiles += Get-ChildItem -LiteralPath (Join-Path $agentsDir 'scripts') -Filter '*.ps1' -File -ErrorAction SilentlyContinue
    foreach ($s in (Get-OrdinalSortedByName @($scriptFiles))) {
        $l.Add("| ``$($s.Name)`` | $(Format-Cell (Get-Synopsis $s.FullName)) |")
    }
    $l.Add($inventoryEnd)
    return ($l -join "`n")
}

function Get-Rules {
    $result = [System.Collections.Generic.List[object]]::new()
    foreach ($f in (Get-OrdinalSortedByName @(Get-ChildItem -LiteralPath $sourceDir -Filter '*.md' -File))) {
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
    $parts.Add("# agents-rules.md (generated $([char]0x2014) do not edit)")
    $parts.Add('')
    $parts.Add('Source: `rules/*.md`. Regenerate with `.\scripts\sync-rules.ps1`.')
    $parts.Add('')
    foreach ($r in (Get-OrdinalSortedByName @($Rules | Where-Object { $_.Codex -eq 'include' }))) {
        $parts.Add("## $($r.Name)")
        $parts.Add('')
        $parts.Add($r.Body)
        $parts.Add('')
    }
    return ($parts -join "`n")
}

function Build-ClaudeManifest($Rules) {
    # Portable manifest: relative @imports resolve against .claude/, so no absolute paths live here.
    # The only machine-specific line is the @import of this file from ~/.claude/CLAUDE.md (bootstrap.ps1).
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('<!-- generated from agents/ by scripts/sync-rules.ps1; edit the sources under agents/, not this file -->')
    $lines.Add('# dustin-thomason always-on context')
    $lines.Add('')
    $lines.Add('Imported by `~/.claude/CLAUDE.md` (wired by `agents/scripts/bootstrap.ps1`) so it loads in every')
    $lines.Add('Claude Code session, in every repo. Pulls in the scope:always rules plus the workflow index;')
    $lines.Add('scope:scoped rules stay on-demand via `.claude/rules/` path matching.')
    $lines.Add('')
    foreach ($r in (Get-OrdinalSortedByName @($Rules | Where-Object { $_.Scope -eq 'always' }))) {
        $lines.Add("@rules/$($r.Name).md")
    }
    if (Test-Path -LiteralPath (Join-Path $docsSource 'workflow-index.md')) {
        $lines.Add('@docs/workflow-index.md')
    }
    return ($lines -join "`n")
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
$claudeManifestContent = (ConvertTo-Lf (Build-ClaudeManifest $rules)).TrimEnd() + "`n"

# workflow-index.md: strip any prior generated inventory block, append a freshly built one.
# Idempotent - the block is replaced, never duplicated. Editorial content above is untouched.
$inventoryBlock = (ConvertTo-Lf (Build-Inventory $rules)).Trim()
$currentIndex = if (Test-Path -LiteralPath $indexPath) { ConvertTo-Lf (Read-Utf8 $indexPath) } else { '' }
$stripPattern = "(?s)\s*" + [regex]::Escape($inventoryBegin) + ".*?" + [regex]::Escape($inventoryEnd)
$baseIndex = ([regex]::Replace($currentIndex, $stripPattern, '')).TrimEnd()
$expectedIndexContent = ($baseIndex + "`n`n" + $inventoryBlock).TrimEnd() + "`n"

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

# Docs: mirror docs/** (playbooks + guides) verbatim into .cursor/docs and .claude/docs.
$docExpected = @{}
if (Test-Path -LiteralPath $docsSource) {
    foreach ($f in (Get-ChildItem -LiteralPath $docsSource -Recurse -File)) {
        $rel = ($f.FullName.Substring($docsSource.Length).TrimStart('\', '/')) -replace '\\', '/'
        # The index carries the generated inventory block; mirror the injected form, not raw disk.
        if ($rel -eq 'workflow-index.md') {
            $docExpected[$rel] = $expectedIndexContent
        }
        else {
            $docExpected[$rel] = (ConvertTo-Lf (Read-Utf8 $f.FullName)).TrimEnd() + "`n"
        }
    }
}

# Compiled single-file Codex surfaces.
$agentsSkillsContent = (ConvertTo-Lf (Build-Concat 'agents-skills' '`agents/skills/**`' $skillExpected)).TrimEnd() + "`n"
$agentsDocsContent = (ConvertTo-Lf (Build-Concat 'agents-docs' '`agents/docs/**`' $docExpected)).TrimEnd() + "`n"

function Test-Artifact([string]$Path, [string]$Expected, [System.Collections.Generic.List[string]]$Stale, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path)) { $Stale.Add("$Label missing"); return }
    if ((ConvertTo-Lf (Read-Utf8 $Path)) -ne $Expected) { $Stale.Add("$Label out of date") }
}

if ($Check) {
    $stale = [System.Collections.Generic.List[string]]::new()

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
    foreach ($rel in $docExpected.Keys) {
        Test-Artifact (Join-Path $cursorDocs ($rel -replace '/', '\')) $docExpected[$rel] $stale ".cursor/docs/$rel"
        Test-Artifact (Join-Path $claudeDocs ($rel -replace '/', '\')) $docExpected[$rel] $stale ".claude/docs/$rel"
    }
    foreach ($t in @($cursorDocs, $claudeDocs)) {
        if (Test-Path -LiteralPath $t) {
            foreach ($e in (Get-ChildItem -LiteralPath $t -Recurse -File)) {
                $rel = ($e.FullName.Substring($t.Length).TrimStart('\', '/')) -replace '\\', '/'
                if (-not $docExpected.ContainsKey($rel)) { $stale.Add("$($t.Substring($repoRoot.Length + 1) -replace '\\','/')/$rel is orphaned (no source doc)") }
            }
        }
    }
    Test-Artifact $indexPath $expectedIndexContent $stale 'agents/docs/workflow-index.md (inventory block)'
    Test-Artifact $claudeManifestPath $claudeManifestContent $stale '.claude/CLAUDE.md'
    Test-Artifact $agentsRulesPath $agentsContent $stale 'agents-rules.md'
    Test-Artifact $agentsSkillsPath $agentsSkillsContent $stale 'agents-skills.md'
    Test-Artifact $agentsDocsPath $agentsDocsContent $stale 'agents-docs.md'
    foreach ($t in @($cursorSkills, $claudeSkills)) {
        if (Test-Path -LiteralPath $t) {
            foreach ($e in (Get-ChildItem -LiteralPath $t -Recurse -File)) {
                $rel = ($e.FullName.Substring($t.Length).TrimStart('\', '/')) -replace '\\', '/'
                if (-not $skillExpected.ContainsKey($rel)) { $stale.Add("$($t.Substring($repoRoot.Length + 1) -replace '\\','/')/$rel is orphaned (no source skill)") }
            }
        }
    }

    if ($stale.Count -gt 0) {
        Write-Host 'STALE - regenerate with .\agents\scripts\sync-rules.ps1:'
        foreach ($s in $stale) { Write-Host "  - $s" }
        exit 1
    }
    Write-Host 'Generated rule artifacts are up to date.'
    exit 0
}

# --- Write mode ---
foreach ($dir in @($cursorDir, $claudeDir, $cursorDocs, $claudeDocs)) {
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# Write the injected index back to its source (hand-edited editorial + regenerated inventory block).
Write-Utf8NoBom $indexPath $expectedIndexContent
Write-Utf8NoBom $claudeManifestPath $claudeManifestContent
Write-Utf8NoBom $agentsRulesPath $agentsContent
Write-Utf8NoBom $agentsSkillsPath $agentsSkillsContent
Write-Utf8NoBom $agentsDocsPath $agentsDocsContent
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

# Mirror docs into .cursor/docs and .claude/docs, then prune orphans in each.
foreach ($rel in $docExpected.Keys) {
    foreach ($t in @($cursorDocs, $claudeDocs)) {
        $dest = Join-Path $t ($rel -replace '/', '\')
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Write-Utf8NoBom $dest $docExpected[$rel]
    }
}
foreach ($t in @($cursorDocs, $claudeDocs)) {
    if (Test-Path -LiteralPath $t) {
        foreach ($e in (Get-ChildItem -LiteralPath $t -Recurse -File)) {
            $rel = ($e.FullName.Substring($t.Length).TrimStart('\', '/')) -replace '\\', '/'
            if (-not $docExpected.ContainsKey($rel)) { Remove-Item -LiteralPath $e.FullName -Force }
        }
    }
}

$codexCount = @($rules | Where-Object { $_.Codex -eq 'include' }).Count
$skillCount = @(Get-ChildItem -LiteralPath $skillsSource -Directory -ErrorAction SilentlyContinue).Count
Write-Host "Mirrored to .cursor + .claude: rules ($($cursorExpected.Count)), skills ($skillCount), docs ($($docExpected.Count))."
Write-Host "Compiled for Codex: agents-rules.md ($codexCount rules), agents-skills.md, agents-docs.md."
$alwaysCount = @($rules | Where-Object { $_.Scope -eq 'always' }).Count
Write-Host "Claude-global manifest: .claude/CLAUDE.md ($alwaysCount always-on rules + workflow index)."
Write-Host "Rebuilt inventory block in agents/docs/workflow-index.md (rules, skills, docs, scripts)."
