#Requires -Version 5.1
<#
.SYNOPSIS
  POST agent session completion to a Power Automate manual-trigger webhook.

.EXAMPLE
  .\scripts\notify-agent-complete.ps1 -Status "Completed" -Message "Work finished; all tests passed."

.NOTES
  Optional override: set $env:AGENT_COMPLETE_WEBHOOK_URL before invoking.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Completed')]
    [string]$Status,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Message
)

$ErrorActionPreference = 'Stop'

$Url = $env:AGENT_COMPLETE_WEBHOOK_URL
if (-not $Url) {
    $Url = 'https://default7318a4272f81408f83866569e958a8.70.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/f2a0e9254fd449419d56fe073a5c2c92/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=JCFHJI0-IFhMnbW8KKb_u2U5l71lGAwC9t7twob_P2E'
}

$Body = @{
    status  = $Status
    message = $Message
} | ConvertTo-Json -Compress

try {
    Invoke-RestMethod `
        -Uri $Url `
        -Method Post `
        -ContentType 'application/json' `
        -Body $Body
    Write-Host 'Agent completion notification sent.'
}
catch {
    Write-Error "Failed to send agent completion notification: $_"
    exit 1
}
