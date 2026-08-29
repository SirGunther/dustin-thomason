# Future development concerns — WorkLists/attach-repository-files-as-notes

Concerns surfaced during this ticket that are **not** in its scope, recorded so they are not lost. Created at Phase 2 on the first concern.

---

## FDC-01 — The server binds all interfaces, has no authentication, and open CORS

**Surfaced:** Phase 1 (recon), while establishing what a filesystem read/write endpoint would be exposed to.

**What was found**

- `server.js:3615` — `app.listen(port, …)` is called with **no host argument**, so Node binds `0.0.0.0`. The server is reachable from any device on the same network, not only from `localhost`.
- `server.js:39` — `app.use(cors())` with no options: every origin is allowed.
- A grep for `authenticate`, `authorization`, `Bearer`, `passport` across `server.js` returns only Gemini API-key configuration. **There is no authentication middleware anywhere.**

**Why it matters to this ticket specifically**

This is pre-existing and this ticket did not cause it. But this ticket **widens what it exposes**. Today the reachable surface is the board's own data — boards, columns, cards, notes, tags. Add `/api/files/read` and `/api/files/write` and the reachable surface becomes *every file under the configured repository root*, read and write, to anything on the LAN. That is a different category of exposure, and the change of category is what makes it worth naming rather than inheriting quietly.

**The fix, and its cost**

One argument: `app.listen(port, "127.0.0.1")`. It costs minutes.

The cost is not zero, though: it would break any deliberate access to the board from another device. The pinned-board sync feature ("persist as shared server data … synchronize across devices", changelog) suggests cross-device use may be intended, even though the host-scoped data files turned out to be inert. So this is a decision, not an obviously-correct patch — which is why it is recorded here and raised as open variable 8 rather than fixed unilaterally.

**Disposition — DECIDED 2026-08-28 (Phase 3, LD-002)**

Bind `127.0.0.1`. It lands **before** the first file route, as a gate on shipping them. No longer a concern to carry — a work item.

**Accepted cost:** cross-device access to the board breaks. **Residual risk after the fix:** none for this vector; a local process on the same machine is still unauthenticated, which is unchanged and out of scope.

---

## FDC-02 — `SECTIONS` and `TEMP_FILE_PATTERN` duplicate the same list

**Surfaced:** Phase 1 (recon), during the contract-alignment pass.

**What was found**

`dal.js:59` declares `SECTIONS` as an array of thirteen section names. Immediately below it, `TEMP_FILE_PATTERN` is a hand-written regular expression containing **the same thirteen names as a literal alternation**. Two hand-maintained copies of one list, adjacent in the file, with nothing tying them together.

**Why it matters**

A new section added to the array but not the regex leaves that section's temp files unrecognised by the orphan sweep. The failure is silent — nothing errors; leftover temp files simply accumulate in the data directory. Adjacency makes it *likelier* to be caught, not guaranteed.

**Why it is not fixed here**

The recommended design for this ticket deliberately adds no new DAL section, so this ticket never touches the pair. Fixing it — deriving the pattern from the array — is a small, safe change with its own regression surface (the orphan sweep), and it belongs to whoever next adds a section.

**Recommended disposition:** derive `TEMP_FILE_PATTERN` from `SECTIONS` at module load. Trigger: the next ticket that adds a section. **Residual risk until then:** low and bounded — silent temp-file accumulation, no data loss.

---

## FDC-04 — Autosave writes a real file in a git repo on focus exit

**Surfaced:** Phase 3, as the accepted risk of LD-006.

**The decision that created it.** The owner chose to inherit the existing focus-exit autosave for file-backed notes rather than require an explicit save. That is defensible — story 02's criterion is that a pulled-in document behaves like anything else in that spot, and a different save gesture bends it.

**What is accepted.** Clicking away from a file-backed note after any keystroke writes `C:\dustin-thomason\<path>`. There is no confirmation and no undo inside the app. With two cards open on the same document, both autosaving, the second write is refused by the mtime precondition (LD-017) — but the *first* stray write already landed.

**What makes it tolerable, and it is not luck.** The root is a git repo (LD-003). Every stray write appears in `git status` and reverts with one command. LD-012 declined to build in-app history for exactly this reason. **This concern therefore has a hard dependency: if the repository root is ever pointed at a folder that is not version-controlled, the accepted risk changes character entirely** — from "visible and revertible" to "silent and permanent".

**Partial mitigation already decided:** LD-021 shows the file's path on the note, so a person can tell which notes write to disk. That reduces the accident; it does not remove it.

**Recommended follow-up (not in scope):** validate at root-save time that the chosen folder is version-controlled, and warn plainly if it is not. Cheap, and it keeps the tolerability argument true rather than assumed.

---

## FDC-05 — A rename outside the app breaks every reference to that file at once

**Surfaced:** Phase 3, as the accepted risk of LD-009.

**The decision that created it.** A `source` reference stores the root-relative path. Both durable alternatives were worse: injecting a front-matter id mutates documents the app does not own and would appear in every git diff in the workflow repo; a sidecar index is a second source of truth for something the filesystem already answers.

**What is accepted.** `git mv` a document, or rename it in Explorer, and every card holding it shows `not-found` simultaneously. The repair is manual re-attach, once per card. Nothing warns beforehand — and LD-008 deliberately declined to build the "where else is this used" view that would have made the blast radius visible first.

**Why it is still the right call.** Renames of long-lived documents in this repo are rare; the failure is loud rather than silent (the note says it cannot be found — story 02's sixth criterion, test NP-3); and the record survives, so re-attach is a repair, not a re-creation.

**Recommended follow-up (not in scope):** story 06's inventory view is the natural home for finding broken references in bulk — its fourth criterion already says so. If FDC-05 ever bites in practice, that is the signal to build story 06.

---

## FDC-03 — The changelog's Current state contradicts its own session log

**Surfaced:** Phase 0, during changelog alignment.

`docs/WorkLists/worklists-app-changelog.md` **Current state** (line 3927) says the markdown-kit extraction is "written and ready for implementation planning… **Not yet implemented**." The 2026-08-27 session-log entry records it as implemented, and `WorkLists/packages/markdown-kit/` exists with its own package boundary and a hash-guard test.

**Why it matters:** Current state is the section the `ticket-changelog` rule tells every agent to read first for task-start alignment. A stale line there mis-aligns the next agent before it reads anything else.

**Recommended disposition:** correct that bullet. Carried to this ticket's Phase 6 cruft check; also a candidate for `docs/cleanup-candidates.md`.
