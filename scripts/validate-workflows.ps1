#Requires -Version 5.1
<#
.SYNOPSIS
  Audits dustin-thomason workflow wiring: rules, playbooks, skills, scripts, duplicates.
#>
$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent $PSScriptRoot
$issues = [System.Collections.Generic.List[string]]::new()

function Add-Issue([string]$Message, [string]$Severity = 'WARN') {
    $issues.Add("[$Severity] $Message")
}

function Get-MdcAlwaysApply([string]$Path) {
    $head = (Get-Content -LiteralPath $Path -TotalCount 8 -ErrorAction SilentlyContinue) -join "`n"
    return $head -match 'alwaysApply:\s*true'
}

# Sources live under agents/; generated outputs at repo root. Check sources for existence and
# the generated .cursor/rules output for alwaysApply (kept in sync by sync-rules.ps1 -Check).
$indexPath = Join-Path $repoRoot 'agents\docs\workflow-index.md'
$rulesDir = Join-Path $repoRoot '.cursor\rules'
$playbooksDir = Join-Path $repoRoot 'agents\docs'
$skillsDir = Join-Path $repoRoot 'agents\skills'
$templatePath = Join-Path $repoRoot 'docs\_templates\TICKET-changelog.template.md'
$scaffoldPath = Join-Path $repoRoot 'scripts\new-ticket-changelog.ps1'
$routerPath = Join-Path $rulesDir 'personal-methodology.mdc'
$readmePath = Join-Path $repoRoot 'README.md'

# Derived from the source of truth, not hand-listed: every rule whose frontmatter is scope: always.
# This is what keeps the validator itself from drifting when a rule is added/retired.
$rulesSourceDir = Join-Path $repoRoot 'agents\rules'
$requiredAlwaysApply = @(
    Get-ChildItem -LiteralPath $rulesSourceDir -Filter '*.md' -File -ErrorAction SilentlyContinue |
        Where-Object { ((Get-Content -LiteralPath $_.FullName -TotalCount 10) -join "`n") -match 'scope:\s*always' } |
        ForEach-Object { $_.BaseName } | Sort-Object
)

$expectedScripts = @(
    'new-ticket-changelog.ps1',
    'notify-agent-complete.ps1',
    'validate-workflows.ps1'
)
$expectedAgentScripts = @(
    'sync-rules.ps1',
    'sync-agents-md.ps1',
    'bootstrap.ps1'
)

$requiredPlaybooks = @(
    'new-branch-get-started.md',
    'pull-request-workflow.md',
    'browser-loop-setup.md'
)

# Derived from the folder, not hand-listed: every skill directory under agents/skills/.
$expectedSkills = @(
    Get-ChildItem -LiteralPath $skillsDir -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Name } | Sort-Object
)

foreach ($path in @($indexPath, $templatePath, $scaffoldPath, $routerPath, $readmePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Issue "Missing required file: $path" 'ERROR'
    }
}

# README is the entry point for any arriving system; it must point at the generator.
if (Test-Path -LiteralPath $readmePath) {
    if ((Get-Content -LiteralPath $readmePath -Raw) -notmatch 'sync-rules\.ps1') {
        Add-Issue 'README.md should document sync-rules.ps1 (the rule generator)' 'WARN'
    }
}

$scriptsDir = Join-Path $repoRoot 'scripts'
foreach ($scriptName in $expectedScripts) {
    $scriptPath = Join-Path $scriptsDir $scriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Add-Issue "Missing expected script: scripts/$scriptName" 'ERROR'
        continue
    }
    if (Test-Path $indexPath) {
        $indexText = Get-Content -LiteralPath $indexPath -Raw
        if ($indexText -notmatch [regex]::Escape($scriptName)) {
            Add-Issue "Script not listed in workflow-index: $scriptName" 'WARN'
        }
    }
}

$agentScriptsDir = Join-Path $repoRoot 'agents\scripts'
foreach ($scriptName in $expectedAgentScripts) {
    if (-not (Test-Path -LiteralPath (Join-Path $agentScriptsDir $scriptName))) {
        Add-Issue "Missing expected script: agents/scripts/$scriptName" 'ERROR'
    }
}

$changelogUnderCursor = Get-ChildItem -LiteralPath $playbooksDir -Recurse -Filter '*-changelog.md' -ErrorAction SilentlyContinue
foreach ($f in $changelogUnderCursor) {
    Add-Issue "Ticket changelog must be under docs/<system>/ only, not: $($f.FullName)" 'ERROR'
}

$rules = Get-ChildItem -LiteralPath $rulesDir -Filter '*.mdc' -ErrorAction SilentlyContinue
foreach ($name in $requiredAlwaysApply) {
    $ruleFile = Join-Path $rulesDir "$name.mdc"
    if (-not (Test-Path -LiteralPath $ruleFile)) {
        Add-Issue "Missing required alwaysApply rule: $name.mdc" 'ERROR'
        continue
    }
    if (-not (Get-MdcAlwaysApply -Path $ruleFile)) {
        Add-Issue "Rule must have alwaysApply: true - $name.mdc" 'ERROR'
    }
}

foreach ($rule in $rules) {
    $name = $rule.BaseName
    if ($name -eq 'workflow-housekeeping') {
        if (Get-MdcAlwaysApply -Path $rule.FullName) {
            Add-Issue 'workflow-housekeeping should stay alwaysApply: false (file-scoped only)' 'WARN'
        }
        continue
    }
    $indexText = if (Test-Path $indexPath) { Get-Content -LiteralPath $indexPath -Raw } else { '' }
    if ($indexText -notmatch [regex]::Escape($name)) {
        Add-Issue "Rule not listed in workflow-index: $name" 'WARN'
    }
}

foreach ($pbName in $requiredPlaybooks) {
    $pbPath = Join-Path $playbooksDir $pbName
    if (-not (Test-Path -LiteralPath $pbPath)) {
        Add-Issue "Missing playbook: $pbPath" 'ERROR'
    }
}

if (Test-Path -LiteralPath $routerPath) {
    $routerRaw = Get-Content -LiteralPath $routerPath -Raw
    $playbookRefs = [regex]::Matches($routerRaw, '\[([^\]]+)\]\(\.\./docs/([^)]+\.md)\)')
    foreach ($m in $playbookRefs) {
        $target = Join-Path $repoRoot ".cursor\docs\$($m.Groups[2].Value -replace '/', '\')"
        if (-not (Test-Path -LiteralPath $target)) {
            Add-Issue "personal-methodology broken link: $($m.Groups[2].Value)" 'ERROR'
        }
    }
    $ruleRefs = [regex]::Matches($routerRaw, '\./([a-z0-9-]+\.mdc)\)')
    foreach ($m in $ruleRefs) {
        $target = Join-Path $rulesDir $m.Groups[1].Value
        if (-not (Test-Path -LiteralPath $target)) {
            Add-Issue "personal-methodology broken rule link: $($m.Groups[1].Value)" 'ERROR'
        }
    }
}

foreach ($skillName in $expectedSkills) {
    $skillMd = Join-Path $skillsDir "$skillName\SKILL.md"
    if (-not (Test-Path -LiteralPath $skillMd)) {
        Add-Issue "Missing skill: $skillMd" 'WARN'
    }
    elseif (Test-Path $indexPath) {
        $indexText = Get-Content -LiteralPath $indexPath -Raw
        if ($indexText -notmatch [regex]::Escape($skillName)) {
            Add-Issue "Skill not listed in workflow-index: $skillName" 'WARN'
        }
    }
}

$githubStub = Join-Path $repoRoot '.github\git-commit-workflow.md'
if (Test-Path -LiteralPath $githubStub) {
    $stubText = Get-Content -LiteralPath $githubStub -Raw
    if ($stubText -notmatch 'git-commit-workflow\.mdc') {
        Add-Issue '.github/git-commit-workflow.md should link to .cursor/rules/git-commit-workflow.mdc' 'WARN'
    }
}

if (Test-Path $indexPath) {
    $indexRaw = Get-Content -LiteralPath $indexPath -Raw
    $linkMatches = [regex]::Matches($indexRaw, '\]\((\.\./[^)]+)\)')
    foreach ($m in $linkMatches) {
        $rel = $m.Groups[1].Value
        if ($rel -match '^\.\./\.cursor/') {
            $target = Join-Path $repoRoot ($rel -replace '^\.\./', '' -replace '/', '\')
        }
        elseif ($rel -match '^\.\./docs/') {
            $target = Join-Path $repoRoot ($rel -replace '^\.\./', '' -replace '/', '\')
        }
        else {
            continue
        }
        if (-not (Test-Path -LiteralPath $target)) {
            Add-Issue "Broken link in workflow-index: $rel" 'WARN'
        }
    }
}

# Generated outputs must be fresh. sync-rules.ps1 -Check exits 1 when any output is stale
# (committed artifact) or when an existing .claude/rules has drifted. Run it isolated in a
# child process so its internal 'exit' cannot short-circuit this validator.
$syncScript = Join-Path $repoRoot 'agents\scripts\sync-rules.ps1'
if (Test-Path -LiteralPath $syncScript) {
    # Keep sync-rules stdout visible on failure (which files / why); silence only on success.
    $syncCheckOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $syncScript -Check 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-Issue 'Generated outputs are stale - run .\agents\scripts\sync-rules.ps1 and stage the outputs' 'ERROR'
        foreach ($line in @($syncCheckOutput)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
                Write-Host "  $line" -ForegroundColor DarkYellow
            }
        }
    }
}

# The auto-regeneration hook only runs when core.hooksPath points at the versioned hooks.
$hooksPath = git -C $repoRoot config core.hooksPath
if ($hooksPath -ne 'scripts/git-hooks') {
    Add-Issue 'core.hooksPath is not scripts/git-hooks - auto-regeneration hook inactive on this machine (see README one-time setup)' 'WARN'
}

Write-Host 'Workflow wiring audit'
Write-Host "Repo: $repoRoot"
Write-Host ''
Write-Host 'alwaysApply rules (auto-loaded when dustin-thomason in workspace):'
foreach ($name in $requiredAlwaysApply) {
    Write-Host "  - $name.mdc"
}
Write-Host ''
Write-Host 'Skills (invoke with @skill-name or plain request):'
foreach ($skillName in $expectedSkills) {
    Write-Host "  - $skillName"
}
Write-Host ''

if ($issues.Count -eq 0) {
    Write-Host 'OK - wiring complete.'
    exit 0
}

foreach ($i in $issues) {
    Write-Host $i
}

if ($issues | Where-Object { $_ -match '^\[ERROR\]' }) {
    exit 1
}
exit 0
