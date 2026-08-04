<#
.SYNOPSIS
    Renders the orchestration sequence diagram from steps.csv.

.DESCRIPTION
    steps.csv is the single source of truth. Three row kinds only - participant,
    phase, step. Four columns reach the diagram: actor, target, label and mode;
    verb decides the arrow style and seq decides the order. done, check_by and
    governs are for the checklist and render nowhere.

    There is no detail column. The skill is always loaded before any of this runs,
    so the CSV never repeats what a source doc already holds - governs names the
    doc instead.

    Rules enforced here rather than by hand - see decisions.md:
      D1  participant order from seq
      D3  a self-loop is only ever on the agent
      D4  short labels; long text stays in detail
      D6  the phase band is the only note, spanning what the phase touches,
          actors excluded
      D7  arrow style from verb
      D8  only actors send
      D9  governs is a column and is never put in the label
      D10 parens, semicolons and hash are escaped, not banned from authoring
      15  label hard cap of 60 characters

    This source file is deliberately pure ASCII. Windows PowerShell 5.1 reads .ps1
    as ANSI when there is no BOM, which mangles em-dash and middot.

    -Check validates without rendering.
#>
[CmdletBinding()]
param(
    [int]    $Phase,
    [string] $OutFile,
    [switch] $Check
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$EM  = [string][char]0x2014
$DOT = [string][char]0x00B7
$SEP = ' ' + $DOT + ' '
$LABEL_CAP = 60

$rows         = Import-Csv (Join-Path $here 'steps.csv') -Encoding UTF8
$participants = @($rows | Where-Object { $_.kind -eq 'participant' } | Sort-Object { [int]$_.seq })

$order = @{}
$byPos = @{}
foreach ($p in $participants) { $order[$p.id] = [int]$p.seq; $byPos[[int]$p.seq] = $p.id }
$actors = @($participants | Where-Object { $_.role -eq 'actor' } | ForEach-Object { $_.id })

# verb -> arrow style. read additionally emits the dashed return.
$verbArrow = @{
    read = 'solid'; write = 'solid'; run = 'solid'; notify = 'solid'; ask = 'solid'
    stage = 'dashed'; approve = 'dashed'
}

function Protect-Mermaid([string]$s) {
    if (-not $s) { return $s }
    # hash first - the others substitute into entity codes that start with it
    $s = $s.Replace('#', '#35;')
    $s = $s.Replace('(', '#40;').Replace(')', '#41;').Replace(';', '#59;')
    return $s
}

# ---------- validation ------------------------------------------------------
$findings = New-Object System.Collections.Generic.List[string]
$seen     = @{}

foreach ($s in $rows) {
    $ctx = "$($s.kind) $($s.id)"

    if ($s.id) {
        if ($seen.ContainsKey("id:$($s.id)")) { $findings.Add("$ctx : duplicate id") }
        $seen["id:$($s.id)"] = $true
    }
    if (@('participant', 'phase', 'step') -notcontains $s.kind) {
        $findings.Add("$ctx : kind '$($s.kind)' is not participant, phase or step")
    }
    foreach ($col in $s.PSObject.Properties) {
        $v = [string]$col.Value
        if ($v.Length -gt 0 -and '=+-@'.Contains($v.Substring(0, 1))) {
            $findings.Add("$ctx : column $($col.Name) starts with '$($v.Substring(0,1))' - Excel reads that as a formula")
        }
    }
    $lbl = [string]$s.label
    if ($lbl.Length -gt $LABEL_CAP) {
        $findings.Add("$ctx : label is $($lbl.Length) chars, cap is $LABEL_CAP")
    }

    if ($s.kind -eq 'participant') {
        if (-not $s.label) { $findings.Add("$ctx : no display label") }
        if (-not $s.role)  { $findings.Add("$ctx : no role") }
        $k = "pseq:$($s.seq)"
        if ($seen.ContainsKey($k)) { $findings.Add("$ctx : duplicate participant seq") }
        $seen[$k] = $true
    }

    if ($s.kind -eq 'phase') {
        if (-not $s.label) { $findings.Add("$ctx : phase has no name") }
        if (-not $s.mode)  { $findings.Add("$ctx : phase has no mode") }
    }

    if ($s.kind -eq 'step') {
        if (-not $verbArrow.ContainsKey($s.verb)) { $findings.Add("$ctx : verb '$($s.verb)' not in the closed set") }
        if (-not $order.ContainsKey($s.actor))    { $findings.Add("$ctx : actor '$($s.actor)' is not a participant") }
        if (-not $order.ContainsKey($s.target))   { $findings.Add("$ctx : target '$($s.target)' is not a participant") }
        if ($actors -notcontains $s.actor)        { $findings.Add("$ctx : sender '$($s.actor)' is not an actor - D8") }
        if ($s.actor -eq $s.target -and $actors -notcontains $s.target) {
            $findings.Add("$ctx : self-loop on a document - D3 allows one only on the agent")
        }
        if (-not $s.label)   { $findings.Add("$ctx : no label") }
        if (-not $s.done)    { $findings.Add("$ctx : no done") }
        # every step must name its authority - it is how Q3 is answerable at all
        if (-not $s.governs) { $findings.Add("$ctx : no governs - a step that cannot name its authority cannot tell the agent what it should or should not do") }
        if (@('script', 'human') -notcontains $s.check_by) { $findings.Add("$ctx : check_by must be script or human") }
        if ($s.label -like "*$($s.governs)*" -and $s.governs) {
            $findings.Add("$ctx : governs is in the label - D9 says it stays a column")
        }
        $k = "seq:$($s.phase)/$($s.seq)"
        if ($seen.ContainsKey($k)) { $findings.Add("$ctx : duplicate seq within phase $($s.phase)") }
        $seen[$k] = $true
    }
}

if ($findings.Count -gt 0) {
    Write-Host "VALIDATION FAILED - $($findings.Count) finding(s):" -ForegroundColor Red
    foreach ($f in $findings) { Write-Host "  $f" }
    exit 1
}
$stepCount = @($rows | Where-Object { $_.kind -eq 'step' }).Count
Write-Host "validation OK - $stepCount steps, $($participants.Count) participants" -ForegroundColor Green
if ($Check) { exit 0 }

# ---------- render ----------------------------------------------------------
function Get-Span($phaseSteps) {
    $touched = New-Object System.Collections.Generic.List[int]
    foreach ($s in $phaseSteps) {
        foreach ($a in @($s.actor, $s.target)) {
            if ($a -and ($actors -notcontains $a)) { $touched.Add($order[$a]) }
        }
    }
    if ($touched.Count -eq 0) { return $null }
    # cast is load-bearing: Measure-Object returns a double, $byPos is int-keyed
    $lo = [int]($touched | Measure-Object -Minimum).Minimum
    $hi = [int]($touched | Measure-Object -Maximum).Maximum
    if ($lo -eq $hi) { return $byPos[$lo] }
    return "$($byPos[$lo]),$($byPos[$hi])"
}

$out = New-Object System.Collections.Generic.List[string]
$out.Add('sequenceDiagram')
foreach ($p in $participants) { $out.Add("    participant $($p.id) as $(Protect-Mermaid $p.label)") }

$phaseNums = @($rows | Where-Object { $_.kind -eq 'phase' } | ForEach-Object { [int]$_.phase } | Sort-Object)
if ($PSBoundParameters.ContainsKey('Phase')) { $phaseNums = @($Phase) }

foreach ($n in $phaseNums) {
    $pr       = @($rows | Where-Object { $_.kind -ne 'participant' -and [int]$_.phase -eq $n })
    $phaseRow = @($pr | Where-Object { $_.kind -eq 'phase' })[0]
    $stepRows = @($pr | Where-Object { $_.kind -eq 'step' } | Sort-Object { [int]$_.seq })
    $span     = Get-Span $stepRows

    $out.Add('')
    $out.Add("    Note over ${span}: PHASE $n " + $EM + " $(Protect-Mermaid $phaseRow.label)$SEP$($phaseRow.mode)")

    foreach ($s in $stepRows) {
        if ($verbArrow[$s.verb] -eq 'dashed') { $arrow = '-->>' } else { $arrow = '->>' }
        $out.Add("    $($s.actor)$arrow$($s.target): $(Protect-Mermaid $s.label)")
    }
}

$text = ($out -join "`n") + "`n"

# always land on the clipboard, ready to paste into LucidChart
try {
    Set-Clipboard -Value $text
    Write-Host "copied to clipboard - ready to paste" -ForegroundColor Cyan
}
catch { Write-Host "clipboard unavailable in this host - output shown below" -ForegroundColor Yellow }

if ($OutFile) {
    [System.IO.File]::WriteAllText($OutFile, $text, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "wrote $OutFile"
}
else { Write-Output $text }
