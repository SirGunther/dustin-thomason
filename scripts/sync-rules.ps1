#Requires -Version 5.1
<#
.SYNOPSIS
  Generate every downstream rule artifact from the source of truth (.cursor/rules/*.mdc).

.DESCRIPTION
  Two targets, one manifest:
    1. AGENTS.md          - committed, machine-neutral mirror for Codex (full rule bodies).
    2. .claude/rules/*.md - per-machine, git-ignored rules for Claude Code, one file per
                            source rule, shaped by the rule's manifest class:
         full    -> full body, always-on (no paths: frontmatter)
         pointer -> short stanza (description + MUST-read imperative + absolute .mdc path),
                    keeps heavy rules out of always-on context
         scoped  -> full body + paths: frontmatter translated from the Cursor globs, so the
                    rule loads on-demand only when Claude touches matching files

  Every .mdc under .cursor/rules MUST appear in $Manifest and vice versa; an unclassified or
  dangling rule is a hard error, so a new rule can never be silently dropped from an output.

.PARAMETER Check
  Build every artifact in memory and compare to disk. Writes nothing. Exit 1 if any committed
  artifact (AGENTS.md) is stale, or if .claude/rules exists but has drifted. Exit 0 if fresh.
  Used by validate-workflows.ps1 and CI to fail on stale generated output.

.NOTES
  PS 5.1 safe: source is pure ASCII (em-dash emitted via [char]0x2014); files are read with
  [IO.File]::ReadAllText (BOM-aware UTF-8, unlike Get-Content -Raw which is ANSI on 5.1) and
  written UTF-8 no-BOM with LF via [IO.File]::WriteAllText.
#>
param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$rulesDir = Join-Path $repoRoot '.cursor\rules'
$agentsPath = Join-Path $repoRoot 'AGENTS.md'
$claudeRulesDir = Join-Path $repoRoot '.claude\rules'
$repoRootFwd = $repoRoot -replace '\\', '/'

# Excluded from AGENTS.md only: the meta rule about regenerating outputs is noise to Codex.
# It is still emitted to .claude/rules (scoped) so Claude is reminded to regenerate in-repo.
$agentsExclude = 'agents-sync'

# Every rule's classification. Keys must match .cursor/rules/<key>.mdc exactly.
$Manifest = [ordered]@{
    'personal-methodology'            = 'full'
    'problem-requirement-solution'    = 'full'
    'context-fanout'                  = 'full'
    'agent-completion-notification'   = 'full'
    'browser-loop-guardrails'         = 'full'
    'build-implementation-guardrails' = 'pointer'
    'git-commit-workflow'             = 'pointer'
    'spec-writing'                    = 'pointer'
    'ticket-changelog'                = 'pointer'
    'agents-sync'                     = 'scoped'
    'workflow-housekeeping'           = 'scoped'
}

function ConvertTo-Lf([string]$Text) {
    return ($Text -replace "`r`n", "`n") -replace "`r", "`n"
}

function Read-Utf8([string]$Path) {
    # BOM-aware; defaults to UTF-8 for no-BOM files (Get-Content -Raw is ANSI on PS 5.1).
    return [System.IO.File]::ReadAllText($Path)
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $normalized = (ConvertTo-Lf $Content).TrimEnd() + "`n"
    [System.IO.File]::WriteAllText($Path, $normalized, [System.Text.UTF8Encoding]::new($false))
}

function Split-Mdc([string]$Path) {
    $raw = ConvertTo-Lf (Read-Utf8 $Path)
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
    return @{ Frontmatter = $fm; Body = $body.Trim() }
}

function Build-Agents([System.Collections.Generic.List[string]]$RuleNames) {
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("# AGENTS.md (generated $([char]0x2014) do not edit)")
    $parts.Add('')
    $parts.Add('Source: `.cursor/rules/*.mdc`. Regenerate with `.\scripts\sync-agents-md.ps1`.')
    $parts.Add('')
    foreach ($name in ($RuleNames | Sort-Object)) {
        if ($name -eq $agentsExclude) { continue }
        $parsed = Split-Mdc (Join-Path $rulesDir "$name.mdc")
        $parts.Add("## $name")
        $parts.Add('')
        $parts.Add($parsed.Body)
        $parts.Add('')
    }
    return ($parts -join "`n")
}

function Build-ClaudeRule([string]$Name, [string]$Class, [hashtable]$Parsed) {
    $gen = "<!-- Generated from .cursor/rules/$Name.mdc by scripts/sync-rules.ps1. Do not edit; edit the source .mdc and regenerate. -->"
    switch ($Class) {
        'full' {
            return "$gen`n`n$($Parsed.Body)"
        }
        'pointer' {
            $desc = $Parsed.Frontmatter['description']
            if (-not $desc) { $desc = "See the source rule." }
            $src = "$repoRootFwd/.cursor/rules/$Name.mdc"
            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add($gen)
            $lines.Add('')
            $lines.Add("# $Name")
            $lines.Add('')
            $lines.Add($desc)
            $lines.Add('')
            $lines.Add('You MUST read and follow the full rule before doing the work it governs:')
            $lines.Add('')
            $lines.Add("``$src``")
            $lines.Add('')
            $lines.Add('This rule is kept as a pointer, not inlined, to limit always-on context. The')
            $lines.Add('source .mdc is authoritative; read it whenever the description above applies.')
            return ($lines -join "`n")
        }
        'scoped' {
            $globs = $Parsed.Frontmatter['globs']
            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add('---')
            $lines.Add('paths:')
            if ($globs) {
                foreach ($g in ($globs -split ',')) {
                    $gt = $g.Trim()
                    if ($gt) { $lines.Add("  - `"$gt`"") }
                }
            }
            $lines.Add('---')
            $lines.Add($gen)
            $lines.Add('')
            $lines.Add($Parsed.Body)
            return ($lines -join "`n")
        }
    }
    throw "Unknown manifest class '$Class' for rule '$Name'."
}

# --- Discover rules and enforce bidirectional manifest coverage ---
$ruleFiles = Get-ChildItem -LiteralPath $rulesDir -Filter '*.mdc' -File
$ruleNames = [System.Collections.Generic.List[string]]::new()
foreach ($f in $ruleFiles) { $ruleNames.Add($f.BaseName) }

$unclassified = $ruleNames | Where-Object { -not $Manifest.Contains($_) }
if ($unclassified) {
    throw "Unclassified rule(s) in .cursor/rules with no manifest entry in sync-rules.ps1: $($unclassified -join ', '). Add each to `$Manifest (full|pointer|scoped)."
}
$dangling = $Manifest.Keys | Where-Object { $ruleNames -notcontains $_ }
if ($dangling) {
    throw "Manifest references rule(s) with no .cursor/rules/<name>.mdc file: $($dangling -join ', '). Remove from `$Manifest or add the rule."
}

# --- Build every artifact in memory ---
$agentsContent = (ConvertTo-Lf (Build-Agents $ruleNames)).TrimEnd() + "`n"

$claudeExpected = @{}  # relative filename -> content (normalized, trailing LF)
foreach ($name in $Manifest.Keys) {
    $parsed = Split-Mdc (Join-Path $rulesDir "$name.mdc")
    $content = Build-ClaudeRule $name $Manifest[$name] $parsed
    $claudeExpected["$name.md"] = (ConvertTo-Lf $content).TrimEnd() + "`n"
}

if ($Check) {
    $stale = [System.Collections.Generic.List[string]]::new()

    # AGENTS.md is committed: always required and must be fresh.
    if (-not (Test-Path -LiteralPath $agentsPath)) {
        $stale.Add('AGENTS.md missing')
    }
    elseif ((ConvertTo-Lf (Read-Utf8 $agentsPath)) -ne $agentsContent) {
        $stale.Add('AGENTS.md out of date')
    }

    # .claude/rules is per-machine local output: only checked if it already exists.
    if (Test-Path -LiteralPath $claudeRulesDir) {
        foreach ($fname in $claudeExpected.Keys) {
            $p = Join-Path $claudeRulesDir $fname
            if (-not (Test-Path -LiteralPath $p)) {
                $stale.Add(".claude/rules/$fname missing")
            }
            elseif ((ConvertTo-Lf (Read-Utf8 $p)) -ne $claudeExpected[$fname]) {
                $stale.Add(".claude/rules/$fname out of date")
            }
        }
        foreach ($existing in (Get-ChildItem -LiteralPath $claudeRulesDir -Filter '*.md' -File)) {
            if (-not $claudeExpected.ContainsKey($existing.Name)) {
                $stale.Add(".claude/rules/$($existing.Name) is orphaned (no source rule)")
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
Write-Utf8NoBom $agentsPath $agentsContent

if (-not (Test-Path -LiteralPath $claudeRulesDir)) {
    New-Item -ItemType Directory -Path $claudeRulesDir -Force | Out-Null
}
foreach ($fname in $claudeExpected.Keys) {
    Write-Utf8NoBom (Join-Path $claudeRulesDir $fname) $claudeExpected[$fname]
}
# Remove orphaned rule files (source rule deleted/renamed).
foreach ($existing in (Get-ChildItem -LiteralPath $claudeRulesDir -Filter '*.md' -File)) {
    if (-not $claudeExpected.ContainsKey($existing.Name)) {
        Remove-Item -LiteralPath $existing.FullName -Force
    }
}

$agentsRuleCount = @($ruleNames | Where-Object { $_ -ne $agentsExclude }).Count
Write-Host "Wrote AGENTS.md ($agentsRuleCount rules) and .claude/rules/ ($($claudeExpected.Count) files)."
