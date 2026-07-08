# PRDV-16047 Local Validation Happy Path

## Purpose
Capture the repeatable local validation path for PRDV-16047 so future Atlas local testing can be repeated and automated.

## Live Browser Inspection Setup
Use Chrome remote debugging when Codex needs to inspect the live DOM/network during manual validation.

```powershell
Start-Process chrome.exe -ArgumentList '--remote-debugging-port=9222','--user-data-dir=C:\temp\atlas-cdp','http://localhost:9000/callisto-stuff/job/112233/proceeding/3001'
```

Then:
- Log in in that Chrome window.
- Navigate to the proceeding page.
- Tell Codex the browser is ready.
- Codex attaches to `http://localhost:9222/json/list` and uses the page websocket for DOM/network inspection.

## Validated Happy Path Steps

### 1. Authorized Transcript Withdraw Control
Status: Passed.

Path:
- Open `http://localhost:9000/callisto-stuff/job/112233/proceeding/3001`.
- Go to `Client Deliverables`.
- Select `smith_deposition_transcript_deliverable_evidence.docx`.
- Open the bottom floating action bar overflow menu.

Expected:
- `Withdraw approval for all selected` is visible and enabled.

Observed:
- `Withdraw approval for all selected` was visible and enabled.

Why this validates the feature:
- Transcript has `CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT create = ALLOW` under the spoofed partial-permission role.
- This confirms the positive control for withdraw approval permission.

## Notes For Automation
- Top-level file rows did not render per-row action menus in the live DOM for this data set.
- The practical validation surface was checkbox selection plus the bottom floating action bar overflow menu.
- Future automation should target visible file names, select their row checkboxes, then inspect the FAB overflow menu item state.
