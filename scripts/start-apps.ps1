Start-Process pwsh -ArgumentList @(
    '-NoExit'
    '-Command'
    "Set-Location -LiteralPath 'C:\Users\dustin.thomason\OneDrive\Countdowns'; npm run start"
)

Start-Process pwsh -ArgumentList @(
    '-NoExit'
    '-Command'
    "Set-Location -LiteralPath 'C:\Users\dustin.thomason\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists'; npm run start"
)