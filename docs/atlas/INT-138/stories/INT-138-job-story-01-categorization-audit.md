# Job story 01: Categorization audit

| Field | Value |
| --- | --- |
| Ticket | INT-138 |
| Project | atlas |
| Date | 2026-09-23 |
| Status | draft |
| Source | [INT-138-original-ticket.md](../INT-138-original-ticket.md) |

## Evidence

Each claim this story makes, the question it answers, and the ticket text it rests on.

| Claim | Question it answers | Reason (ticket text) |
| --- | --- | --- |
| The user is an Ops manager | Who is this for? | "As an Ops manager"; "Ops can view a log" |
| They want who, what and when | Why do they care? | "so that I can see the "who, what, when" for these critical functions" |
| Categorization is a Client Access action | Why this action? | "key actions related to Client Access"; "a log in Europa for **deliverable type categorization**" |
| Categorizations can't currently be found as their own action | What is in the way? | "A new Event Type is created for this action: **Categorize**". It does not say whether categorizations are logged today under some other type (see OQ-02) |
| A record shows file, who, when and what was set | What does done show? | "file path", "user info", "date/time", "**categorization** actions taken" |
| The record is labelled Categorize on a File | How is it named? | "A new Event Type is created for this action: **Categorize**"; "Resource Type for this action is: **File**" |
| The record reads in a fixed format | How does it read? | "Path format: Filepath: \[file path\]; Deliverable Type: \[deliverable type\]; Collection: if applicable, \[collection\], if not, "N/A"" |
| Ops can narrow to just these records | How do they find them? | "This event type is added to the Event Type drop down in Europa" |
| Each file gets its own record | What happens when many files are categorized at once? | "The log displays… file path": each record names one file. *Phase 1 evidence:* approve and recategorize take many files per request, and Europa shows only the first file of a multi-file event (`search-audit-events-paginated.transaction.script.ts:98-100`) |
| One story, not two | Does the request need splitting? | One motivation (who, what, when) over one action (categorization). The event-type requirement is how Ops finds the records. It is not a second problem |

## 1. Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | An Ops manager doesn't want a file's deliverable type to change without knowing who changed it or when. |
| Context + Intent | *While [context], they want to [action].* | While reviewing the key actions that affect Client Access, they want to look up each time a file's deliverable type was categorized. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that there is no Categorize event type in the Europa audit log's Event Type dropdown, so they want every categorization logged as a Categorize event on a File resource, with its file path, deliverable type and collection. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to see who categorized each file, when, and what they set it to. |

## 2. Revision Matrix

| Component | Before | Issue | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that there is no Categorize event type in the Europa audit log's Event Type dropdown, so they want every categorization logged as a Categorize event on a File resource, with its file path, deliverable type and collection. | Solution-speak: "event type", "dropdown", "resource" and "logged as" describe the design, not the obstacle. | Except that categorizations can't be picked out from the other actions Ops reviews, so they want each one kept on record with the file, the deliverable type and the collection it touched. |

The other three rows carried no design words.

## 3. Delivery Acceptance Statement (DAS)

> *We know this story is considered complete when:*
> - Each time someone categorizes a file's deliverable type, a record of it shows up in the audit log in Europa.
> - Each record shows who made the categorization and the date and time it happened.
> - Each record is labeled as a Categorize action taken on a File.
> - Each record reads "Filepath: [file path]", then "Deliverable Type: [deliverable type]", then "Collection: [collection]".
> - When no collection applies, the record reads "Collection: N/A".
> - Ops can narrow the audit log down to only Categorize records.
> - When several files are categorized at the same time, a record shows up for each one of them. *(added Phase 1)*

## 4. Concatenated Story

An Ops manager doesn't want a file's deliverable type to change without knowing who changed it or when. While reviewing the key actions that affect Client Access, they want to look up each time a file's deliverable type was categorized. Except that categorizations can't be picked out from the other actions Ops reviews, so they want each one kept on record with the file, the deliverable type and the collection it touched. Now they'll be able to see who categorized each file, when, and what they set it to.

## 5. Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| An Ops manager doesn't want a file's deliverable type to change without knowing who changed it or when. | Vague phrasing: "change" assumes the file already had a type. The ticket's word is categorization, and whether a first-time type counts is still open (OQ-01). | An Ops manager doesn't want a file's deliverable type categorized with no record of who did it or when. |
| While reviewing the key actions that affect Client Access, they want to look up each time a file's deliverable type was categorized. | Wordiness. | While checking the actions that affect Client Access, they want to look up every categorization of a file's deliverable type. |
| Except that categorizations can't be picked out from the other actions Ops reviews, so they want each one kept on record with the file, the deliverable type and the collection it touched. | Vague phrasing: "kept on record" doesn't say where they will look. "Picked out from" also assumes categorizations are already recorded, which the ticket doesn't say (OQ-02). | Except that they can't find categorizations among the actions the audit log shows, so they want each one recorded there with the file, deliverable type and collection it set. |
| Now they'll be able to see who categorized each file, when, and what they set it to. | Vague phrasing: "what they set it to" leaves out the collection. | Now they'll be able to pull up who categorized any file, when, and to what deliverable type and collection. |
| Each time someone categorizes a file's deliverable type, a record of it shows up in the audit log in Europa. | Wordiness. | Every categorization of a file's deliverable type shows up in Europa's audit log. |
| Each record shows who made the categorization and the date and time it happened. | Wordiness. | Each categorization record shows who did it and the date and time. |
| Each record is labeled as a Categorize action taken on a File. | Vague phrasing: "labeled" doesn't say what a reader would see. | Each categorization record reads Categorize as its action and File as what was acted on. |
| Each record reads "Filepath: [file path]", then "Deliverable Type: [deliverable type]", then "Collection: [collection]". | Wordiness: the repeated "then" makes the order sound like steps. | Each categorization record reads "Filepath: [file path]", "Deliverable Type: [deliverable type]" and "Collection: [collection]", in that order. |
| When no collection applies, the record reads "Collection: N/A". | Vague phrasing: it doesn't say whose collection. When a collection applies is still open (OQ-06). | When no collection applies to the file, the record reads "Collection: N/A". |
| Ops can narrow the audit log down to only Categorize records. | Wordiness. | Ops can narrow the audit log to just Categorize records. |
| When several files are categorized at the same time, a record shows up for each one of them. | Wordiness. | When several files are categorized at once, each file gets its own record. |

## User Story

An Ops manager doesn't want a file's deliverable type categorized with no record of who did it or when. While checking the actions that affect Client Access, they want to look up every categorization of a file's deliverable type. Except that they can't find categorizations among the actions the audit log shows, so they want each one recorded there with the file, deliverable type and collection it set. Now they'll be able to pull up who categorized any file, when, and to what deliverable type and collection.

## Acceptance Criteria

- Every categorization of a file's deliverable type shows up in Europa's audit log.
- Each categorization record shows who did it and the date and time.
- Each categorization record reads Categorize as its action and File as what was acted on.
- Each categorization record reads "Filepath: [file path]", "Deliverable Type: [deliverable type]" and "Collection: [collection]", in that order.
- When no collection applies to the file, the record reads "Collection: N/A".
- Ops can narrow the audit log to just Categorize records.
- When several files are categorized at once, each file gets its own record.

## Open Questions

Carried, not decided. **Fact** means the code can answer it. **Decision** means someone has to choose. A decision half points at its row (`D#`) in [report §10](../investigations/INT-138-investigation.md).

| # | Question | Kind | Owner / resolved by | Why it's open (ticket text) | Status |
| --- | --- | --- | --- | --- | --- |
| OQ-01 | Which moments count as a categorization: a file getting its first deliverable type, a change from one type to another, a type being cleared? Does a change to only the collection count? | Decision | Product | "**categorization** actions taken" doesn't say which | **open → D1** |
| OQ-02 | Are deliverable types set in more than one way, for example at upload or on many files at once? Does each file get its own record? Are categorizations already logged today under some other event type? | Fact, then decision | Phase 1 traced it. Product decides which paths count | "for **deliverable type categorization**" doesn't say how it happens | **Fact half closed (Phase 1).** Four user paths set a type or collection: upload (1 file), approve v1/v2 (many), recategorize (many), unapprove (clears). One system path exists (transcript summary). No path logs the type or collection today, and recategorize logs nothing at all (report F1). Each file needs its own record (criterion 7). **Decision half → D1** |
| OQ-03 | Should a record show what the file was categorized *from* as well as *to*? | Decision | Product | The path format has one value each: "\[deliverable type\]", "\[collection\]" | **open → D3** |
| OQ-04 | Does "user info" mean the same user details the audit log already shows for other actions? Same question for how date/time is shown. | Fact, then decision only if parity isn't wanted | Phase 1 (existing audit-log records) | "user info", "date/time" | **Closed (Phase 1).** Other records show User Email, User Name and a Date in local or UTC time, built from the whole signed-in user sent with each event. Categorize records get the same (report F3/F4). No decision is needed unless Product wants something beyond parity |
| OQ-05 | Which file path: the file's location as users see it in Atlas, or where it's stored? | Fact, then decision | Phase 1 (how existing File-resource records show a path) | "Filepath: \[file path\]" | **Fact half closed (Phase 1).** For every existing file record, the path shown is the storage key (e.g. `MMYYYY/jobId/proceedingId/<uuid>.ext`). The readable file name sits in the separate Resource column (report F5). **Decision half → D4:** is the storage key what Ops means? |
| OQ-06 | When does a collection "apply" to a file? | Fact | Phase 1 (how deliverable types relate to collections) | "if applicable, \[collection\], if not, "N/A"" | **Closed (Phase 1).** Only Transcript and Video files can be in a collection. Exhibits, MVC, Audio and Planet Suite have none, and a Transcript or Video file can still have none. "N/A" shows whenever the file has no collection after the action (report F5) |
| OQ-07 | Should categorizations made before this ships show up, or only new ones? | Fact, then decision | Product | The ticket doesn't mention history | **Fact half closed (Phase 1).** Callisto keeps no who/when history for past recategorizations, so there is nothing reliable to rebuild them from. The only partial trace is the outbox rows to Planet Portal, and only when that flag was on (report F5, §8). **Decision half → D5** |
| OQ-08 | Can anyone besides Ops see these records, and do they follow the audit log's existing access rules? | Fact | Phase 1 (audit-log access in Europa) | "Ops can view a log in Europa" | **Closed (Phase 1).** The audit page requires the `AUDIT` read permission (`atlas-front-end` `src/globalRouter/routes.ts:35-52`). Access is not set per event type, so Categorize records follow the existing rule (report F3/F4) |
| OQ-09 | Is deliverable type categorization all of INT-138, with other Client Access actions covered by other tickets? | Decision (scope) | Product / principal dev | The user story says "key actions related to Client Access". The criteria name only categorization | **open → D6** |
| OQ-10 | Does a record labelled `CATEGORIZED` satisfy "reads Categorize", or must the label read "Categorize"? (Criterion 3 depends on this.) | Decision | Product + principal dev | "A new Event Type is created for this action: **Categorize**". Every existing event type reads in upper-case past tense (`APPROVED`, `RENAMED`, …) with no separate label (report F2/F4) | **open → D2.** Added Phase 1 |

## Story log

- **2026-09-23 (Phase 1, applied at Phase 2's first action):**
  - Closed 3 questions by evidence (OQ-04, OQ-06, OQ-08).
  - Split 3 into fact and decision (OQ-02 → D1, OQ-05 → D4, OQ-07 → D5); the fact halves are closed.
  - Added OQ-10 for the event label (→ D2). Criterion 3 depends on it but is not invalidated.
  - Added criterion 7 ("each file gets its own record") through the DAS and the Final Review Matrix. It rests on the batch paths and on Europa showing only the first file of an event.
  - Now 7 criteria and 7 open questions, all decisions: 4 fully open (OQ-01, 03, 09, 10) and 3 decision halves (OQ-02, 05, 07). 3 are closed (OQ-04, 06, 08).
  - No split and no user-type change.
- **2026-09-23 (Phase 0):** Drafted from the verbatim request. 6 criteria, 9 open questions (5 fact, 4 decision). Kept as one story: there is one motivation over one action, and the event-type requirement is how Ops finds the records, not a second problem.
