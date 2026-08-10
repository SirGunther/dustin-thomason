<#
.SYNOPSIS
    Checks a ticket folder against steps.csv - was each step's document authored.

.DESCRIPTION
    This is what makes check_by mean something. For every step whose target
    resolves to a file inside the ticket folder, the check is the same and it is
    mechanical: does the document exist and is it non-empty. Authored, even if it
    is only a placeholder.

    check_by then decides how the result is reported:

      script   the done condition is fully machine-checkable, so a present file
               means the step is VERIFIED
      human    the file being present is only half the answer - the done condition
               needs judgment, so it reports REVIEW

    Targets that cannot resolve to a file in the ticket folder are n/a and say why:
    actors, the implementation repo, a skill the agent executes, and the changelog
    which lives outside the ticket folder.

    NOT checked here: whether the content is correct. Accuracy is a separate
    revision pass - see the footnote in decisions.md.

    Pure ASCII on purpose - PowerShell 5.1 reads .ps1 as ANSI without a BOM.

.PARAMETER TicketFolder
    Path to docs/<Project>/tickets/<slug>/.

.PARAMETER ThroughPhase
    Only check phases up to and including this number. A stage step's file lands
    in the following phase, so a run stopped mid-flight legitimately shows later
    phases as missing.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $TicketFolder,
    [int] $ThroughPhase = 99
)

$ErrorActionPreference = 'Stop'
$here      = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillRoot = Split-Path -Parent $here   # steps.csv sits at the skill root, this script in scripts/

if (-not (Test-Path -LiteralPath $TicketFolder)) { throw "no such ticket folder: $TicketFolder" }
$slug = Split-Path -Leaf $TicketFolder

$rows  = Import-Csv (Join-Path $skillRoot 'steps.csv') -Encoding UTF8
$parts = @{}
foreach ($p in ($rows | Where-Object { $_.kind -eq 'participant' })) { $parts[$p.id] = $p }

function Resolve-Target($alias) {
    # returns @{ ok = $bool; reason = <string when not ok>; pattern = <glob when ok> }
    if (-not $parts.ContainsKey($alias)) { return @{ ok = $false; reason = 'unknown participant' } }
    $p = $parts[$alias]
    switch ($p.role) {
        'actor'              { return @{ ok = $false; reason = 'an actor, not a file' } }
        'external'           { return @{ ok = $false; reason = 'outside this repo' } }
        'skill'              { return @{ ok = $false; reason = 'a skill the agent runs, not a ticket file' } }
        'external-artifact'  { return @{ ok = $false; reason = 'lives outside the ticket folder' } }
    }
    if (-not $p.path) { return @{ ok = $false; reason = 'no path defined' } }
    # Every <placeholder> becomes a wildcard, so <slug>, <NN> and <short> all resolve.
    # <prefix> is the same mechanism used for a filename whose variation is a leading
    # segment rather than an embedded one: SKILL.md's layout lets a PRDV ticket name the
    # capture PRDV-16312-original-ticket.md while a personal project names it
    # original-ticket.md, and * matches zero characters, so one glob covers both.
    $pattern = [regex]::Replace($p.path, '<[^>]+>', '*')
    return @{ ok = $true; pattern = $pattern }
}

$results = New-Object System.Collections.Generic.List[object]

foreach ($s in ($rows | Where-Object { $_.kind -eq 'step' } | Sort-Object { [int]$_.phase }, { [int]$_.seq })) {
    if ([int]$s.phase -gt $ThroughPhase) { continue }

    $r = Resolve-Target $s.target
    if (-not $r.ok) {
        $results.Add([pscustomobject]@{
            Phase = $s.phase; Step = $s.id; Target = $s.target
            Status = 'n/a'; Note = $r.reason
        })
        continue
    }

    $full  = Join-Path $TicketFolder $r.pattern
    $found = @(Get-ChildItem -Path $full -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 0 })

    if ($found.Count -eq 0) {
        $exists = @(Get-ChildItem -Path $full -File -ErrorAction SilentlyContinue)
        if ($exists.Count -gt 0) { $status = 'EMPTY'; $note = 'file present but zero bytes' }
        else                     { $status = 'MISSING'; $note = $r.pattern }
    }
    elseif ($s.check_by -eq 'script') { $status = 'VERIFIED'; $note = $found[0].Name }
    else                              { $status = 'REVIEW';   $note = "authored - done needs you: $($s.done)" }

    $results.Add([pscustomobject]@{
        Phase = $s.phase; Step = $s.id; Target = $s.target; Status = $status; Note = $note
    })
}

Write-Host ""
Write-Host "ticket: $slug" -ForegroundColor Cyan
Write-Host ""
foreach ($g in ($results | Group-Object Phase)) {
    Write-Host "PHASE $($g.Name)" -ForegroundColor White
    foreach ($x in $g.Group) {
        switch ($x.Status) {
            'VERIFIED' { $c = 'Green' }
            'REVIEW'   { $c = 'Yellow' }
            'MISSING'  { $c = 'Red' }
            'EMPTY'    { $c = 'Red' }
            default    { $c = 'DarkGray' }
        }
        $note = $x.Note
        if ($note.Length -gt 70) { $note = $note.Substring(0, 67) + '...' }
        Write-Host ("  {0,-9} {1,-22} {2,-8} {3}" -f $x.Status, $x.Step, $x.Target, $note) -ForegroundColor $c
    }
    Write-Host ""
}

$summary = $results | Group-Object Status | Sort-Object Name
Write-Host "summary: $(($summary | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join '  ')" -ForegroundColor Cyan

$broken = @($results | Where-Object { $_.Status -in @('MISSING', 'EMPTY') })
if ($broken.Count -gt 0) { exit 1 }
exit 0
