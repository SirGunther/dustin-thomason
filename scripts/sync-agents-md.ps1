#Requires -Version 5.1
<#
.SYNOPSIS
  Backwards-compatible shim. The generator is now scripts/sync-rules.ps1, which produces
  AGENTS.md (for Codex) and .claude/rules (for Claude Code) from .cursor/rules/*.mdc.
  Kept so existing muscle memory, rule text, and index references keep working.
#>
& (Join-Path $PSScriptRoot 'sync-rules.ps1') @args
exit $LASTEXITCODE
