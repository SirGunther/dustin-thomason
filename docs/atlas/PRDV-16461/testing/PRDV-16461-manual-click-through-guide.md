# PRDV-16461 — Manual click-through guide

For testing by hand in the browser. No AI, no scripts — just click, look, compare.

**What this proves:** that the "default collection" feature actually works the way the ticket asked for, and that the new "(default)" badge shows up correctly.

---

## Before you start

- **URL:** `http://localhost:9000/callisto-stuff/job/112233/proceeding/3001?tab=client-deliverables`
  (This is the "Deposition - John Smith" test proceeding, Client Deliverables tab.)
- Atlas must be running (`localhost:9000`) and Callisto must be running and seeded — if the page shows a database error instead of the page below, the seed needs to be re-run first (see `docs/atlas/local/callisto-local.mdc`).
- You should land on a page that looks like this — a case/job/proceeding summary on the left, and four sections on the right: **Transcript**, **Exhibits**, **Video**, **MVC**, each showing a file count and an "Upload" button.

---

## Test 1 — Drag and drop, choosing Transcript

**Do this:**
1. Drag one or two files onto the page (anywhere in the Client Deliverables area).
2. A window pops up titled "Set deliverable type for 1 file" (or however many files you dragged).
3. Look at the **first** dropdown, labeled "Select track to upload files." Click it and choose **Transcript**.

**You should see:**
- A **second** field, labeled "Select Track / Collection," automatically fills in with **"Full Transcript"** — you did not click that field yourself, it just appeared.
- Next to "Full Transcript," there should be a small badge/pill that says **"(default)"** or similar wording — this is the new part being tested. If today's badge text differs, whatever it says should clearly signal "the system picked this, not you."

**If it fails:** the second field stays blank, or shows something other than "Full Transcript," or shows "Full Transcript" with no badge next to it.

---

## Test 2 — Same, but choose Video instead

**Do this:**
1. Repeat Test 1, but this time pick **Video** in the first dropdown instead of Transcript.

**You should see:**
- The second field fills in with **"MP4 Video"**, with the same "(default)" badge next to it.

**If it fails:** blank field, wrong value, or no badge.

---

## Test 3 — Changing your mind about the track

**Do this:**
1. Do Test 1 (choose Transcript, see "Full Transcript" appear).
2. Now change the first dropdown from Transcript to **Video**.

**You should see:**
- The second field switches from "Full Transcript" to **"MP4 Video"** automatically.
- If you had picked something different before switching tracks, that manual pick should be thrown away — the field should show the new track's default, not your old choice.

**If it fails:** the field still shows "Full Transcript" after switching to Video, or shows nothing.

---

## Test 4 — Overriding the default, then closing and reopening

**Do this:**
1. Do Test 1 (Transcript → "Full Transcript" appears).
2. Click the second field yourself and change it to a different option (e.g., "Redacted").
3. Close the popup window (X or Cancel) without submitting.
4. Drag the same file(s) in again, fresh.
5. Choose Transcript again.

**You should see:**
- The field should go back to showing **"Full Transcript"** with the "(default)" badge — your earlier override from step 2 should **not** be remembered. Every new attempt starts fresh.

**If it fails:** the field remembers "Redacted" from before, instead of resetting to the default.

---

## Test 5 — Uploading directly from one track's "Upload" button

**Do this:**
1. On the main page (not drag-and-drop), find the **Transcript** section and click its **Upload** button.

**You should see:**
- The popup opens with the track **already set to Transcript** (you can't change it here — it's locked in).
- The Track/Collection field is **already filled in** with "Full Transcript" and the "(default)" badge, without you touching anything.

**If it fails:** the field is blank when the popup opens.

---

## Test 6 — Same thing, but for Video

**Do this:**
1. Click **Upload** in the **Video** section instead.

**You should see:**
- Popup opens locked to Video, with **"MP4 Video"** already filled in and badged.

**If it fails:** blank field.

---

## Test 7 — Making sure the badge disappears once you actually choose something

**Do this:**
1. Do Test 5 or Test 6 (get a default value with a badge showing).
2. Click the Track/Collection field yourself and pick a different value (or even re-pick the same one, if that's possible).

**You should see:**
- The "(default)" badge should **disappear** — once you've made a real choice, it shouldn't look like the system chose it for you anymore.

**If it fails:** the badge stays even after you've clicked and chosen something yourself.

---

## Test 8 — Recategorizing existing files (should NOT get a default)

**Do this:**
1. Find files that are already uploaded (not new ones) — this only works if there are already files sitting in one of the four sections.
2. Select one or more of those files and choose the "Recategorize" action.

**You should see:**
- The existing collection is shown as-is. **No badge**, and nothing should be auto-picked for you here — this feature is specifically supposed to leave recategorizing alone.

**If it fails:** a collection gets auto-picked or a badge shows up here — this would be a real bug, since this flow is supposed to be completely unaffected.

---

## Test 9 — A track you don't have permission for

**Do this:**
(Only relevant if you're testing with a user who lacks permission on some track — skip if not applicable.)
1. Open the drag-and-drop track dropdown (Test 1, step 2) as that restricted user.

**You should see:**
- The restricted track is still **listed** in the dropdown, just grayed out/disabled, with a tooltip explaining why (something like "you don't have permission").

**If it fails:** the track is completely missing from the list instead of shown-but-disabled.

---

## Quick summary table

| # | What you do | What "pass" looks like |
|---|---|---|
| 1 | Drag files, choose Transcript | "Full Transcript" auto-fills, with "(default)" badge |
| 2 | Drag files, choose Video | "MP4 Video" auto-fills, with badge |
| 3 | Switch track after choosing | Collection updates to match new track |
| 4 | Override, close, reopen | Default comes back, override is forgotten |
| 5 | Upload button on Transcript | Opens locked to Transcript, pre-filled, badged |
| 6 | Upload button on Video | Opens locked to Video, pre-filled, badged |
| 7 | Manually pick a value | Badge disappears |
| 8 | Recategorize existing files | Nothing auto-picked, no badge |
| 9 | Restricted track (if testable) | Shown, disabled, with explanation |

If everything in this table matches "pass," the feature is working as the ticket described.
