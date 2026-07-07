#Requires -Version 5.1
<#
.SYNOPSIS
  Build AGENTS.md from .cursor/rules/*.mdc for Codex (strips YAML frontmatter).
#>
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$rulesDir = Join-Path $repoRoot '.cursor\rules'
$outPath = Join-Path $repoRoot 'AGENTS.md'

function Get-MdcBody([string]$Path) {
    # ReadAllText auto-detects BOM and defaults to UTF-8. Get-Content -Raw on PS 5.1
    # reads no-BOM files as ANSI and corrupts em-dashes / arrows / curly quotes.
    $raw = [System.IO.File]::ReadAllText($Path)
    if ($raw -match '(?s)^---\r?\n.*?\r?\n---\r?\n(.*)$') {
        return $Matches[1].Trim()
    }
    return $raw.Trim()
}

$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add("# AGENTS.md (generated $([char]0x2014) do not edit)")
$parts.Add('')
$parts.Add('Source: `.cursor/rules/*.mdc`. Regenerate with `.\scripts\sync-agents-md.ps1`.')
$parts.Add('')

$ruleFiles = Get-ChildItem -LiteralPath $rulesDir -Filter '*.mdc' -File |
    Where-Object { $_.BaseName -ne 'codex-agents-sync' } |
    Sort-Object Name

foreach ($f in $ruleFiles) {
    $parts.Add("## $($f.BaseName)")
    $parts.Add('')
    $parts.Add((Get-MdcBody -Path $f.FullName))
    $parts.Add('')
}

$content = $parts -join "`n"
# Normalize to LF regardless of source EOL (.mdc files checked out CRLF under
# autocrlf), so output is deterministic and matches .gitattributes (eol=lf).
$content = ($content -replace "`r`n", "`n") -replace "`r", "`n"
$content = $content.TrimEnd() + "`n"
# PS 5.1-safe UTF-8 (no BOM) writer; -Encoding utf8NoBOM is PowerShell 7+ only.
[System.IO.File]::WriteAllText($outPath, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote $outPath ($($ruleFiles.Count) rules)"
