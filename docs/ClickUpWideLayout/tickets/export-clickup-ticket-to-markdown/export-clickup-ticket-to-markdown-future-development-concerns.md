# Future Development Concerns - ClickUpWideLayout/export-clickup-ticket-to-markdown

## FDC-001 - DOM Capture May Miss Non-Visible ClickUp Fields

- **Status:** validated for PRDV-14055; future concern for hidden fields and ClickUp layout variants
- **Source decision:** LD-002, LD-003, LD-012, LD-013
- **Concern:** A DOM-first collector can only export fields visible in the active ClickUp task page. Hidden custom fields, collapsed sections, or ClickUp layout variants may be omitted.
- **Why accepted now:** Live DOM inspection confirmed the required visible field structures for PRDV-14055. The remaining risk is limited to fields that are hidden, collapsed, virtualized outside the current viewport, or rendered differently in another ClickUp layout.
- **Future trigger:** If manual validation shows required fields are not visible/reliably collectable, reopen API-backed export with token/OAuth storage and security decisions.

## FDC-002 - Save Dialog Cannot Force An Absolute Repo Folder

- **Status:** accepted browser limitation
- **Source decision:** LD-015
- **Concern:** Chrome can open Save As with the right filename, but extension APIs cannot force an arbitrary absolute folder such as `C:\dustin-thomason\docs`.
- **Why accepted now:** The user wants a save-location prompt rather than silent Downloads auto-save. `chrome.downloads.download({ saveAs: true })` is the supported extension path.
- **Future trigger:** If repeated exports need a one-click repo save target, evaluate a native helper or File System Access workflow with a user-granted directory handle.
