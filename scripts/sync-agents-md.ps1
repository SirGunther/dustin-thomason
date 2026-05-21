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
    $raw = Get-Content -LiteralPath $Path -Raw
    if ($raw -match '(?s)^---\r?\n.*?\r?\n---\r?\n(.*)$') {
        return $Matches[1].Trim()
    }
    return $raw.Trim()
}

$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add('# AGENTS.md (generated — do not edit)')
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

$content = ($parts -join "`n").TrimEnd() + "`n"
Set-Content -LiteralPath $outPath -Value $content -Encoding utf8NoBOM -NoNewline
Write-Host "Wrote $outPath ($($ruleFiles.Count) rules)"
