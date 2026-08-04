# 2026 Sprint Harvest — Reference Inventory

**Source:** WorkLists board `Sprints 2026` (`board-22`), pulled 2026-07-31 from `http://localhost:3010/data`
**Volume:** 17 columns · 142 cards · 135 notes
**Purpose:** Raw inventory behind [2026-accomplishments.md](./2026-accomplishments.md). Reference only — not for sending.

---

## 1. Coverage — and the documentation ramp

Sprint date ranges derived from card creation timestamps, not from titles.

| Sprint | Date range | Cards | Notes |
| --- | --- | --- | --- |
| Sprint 01 | 2026-01-07 → 01-14 | 2 | 0 |
| Sprint 02 | 2026-01-12 → 01-21 | 4 | 0 |
| Sprint 03 | 2026-02-03 → 02-17 | 2 | 0 |
| Sprint 04 | 2026-02-19 → 03-17 | 13 | 0 |
| Sprint 05 | 2026-03-17 → 03-31 | 20 | 0 |
| Sprint 06 | 2026-04-01 → 04-02 | 3 | 0 |
| Sprint 07 | 2026-04-06 → 04-09 | 9 | 0 |
| Sprint 08 | 2026-04-15 → 06-02 | 6 | 2 |
| Sprint 09 | — | 0 | 0 |
| Sprint 10 | 2026-05-19 → 05-26 | 3 | 0 |
| Sprint 11 | 2026-05-29 → 06-09 | 8 | 13 |
| Sprint 12 | 2026-06-11 → 06-22 | 8 | 12 |
| Sprint 13 | 2026-06-11 → 07-06 | 24 | 51 |
| Sprint 14 | 2026-07-01 → 07-20 | 12 | 21 |
| Sprint 15 | 2026-07-16 → 07-31 | 24 | 22 |
| General Work | 2026-07-22 → 07-31 | 3 | 13 |
| Upcoming Work | 2026-07-29 | 1 | 1 |

**Coverage now runs 2026-01-07 → 2026-07-31** — the full calendar year to date, versus the six weeks the Weekly Accomplishments column gave us.

**The ramp is measurable.** Sprints 01–10 (Jan 7 – May 26): **62 cards, 0 notes.** Sprints 11 onward (May 29 – Jul 31): **80 cards, 135 notes.** Sprint 08's 2 notes were backfilled on 06-02, after the shift. Dustin's own read — that he only recently got good at capturing and labeling — is exactly right, and the inflection point is **late May / Sprint 11**.

**Consequence for the review:** January–May work is recoverable as *titles and tickets* but not as narrative. Everything before Sprint 11 in the accomplishments doc is reconstructed from card titles plus Dustin's recollection, not from contemporaneous notes. Flagged where it matters.

---

## 2. PRDV tickets named in the board

| Ticket | Title | Status on card |
| --- | --- | --- |
| PRDV-16423 | Investigate and remediate high/critical security vulnerabilities | Upcoming |
| PRDV-16402 | Transcode additional video uploads to Submitted AJSFs | In Progress |
| PRDV-16398 | Nova applies selected video transcode preset (Video Mix) | In Review |
| PRDV-16345 | Spike — Investigate Hubble error logs | Ready |
| PRDV-16290 | Hubble Investigation Spike | In Review |
| PRDV-16216 | Add media duration to transcoded files | **Done** |
| PRDV-16150 | NPM vulnerabilities in Atlas | In Progress |
| PRDV-16142 | Investigate Email Recipient Request | Unrefined |
| PRDV-16085 | Pre-Production Environment for Lagrange Data | Meeting/Data |
| PRDV-16047 | User sees withdraw option in menu from all tracks when no access | In Review |
| PRDV-16034 | Reconfigure the ADB Data Source | In Review |
| PRDV-15776 | Facilities role can't manage files despite CRU permissions | **Shipped** — Atlas PR #511, Callisto PR #340 |
| PRDV-15619 | AJSF refresh Proceedings button | In Review |
| PRDV-14055 | Make Upload Manager count up instead of down | In Progress |

Additional non-PRDV delivery items: Power BI report for jobs present in Atlas but missing from AJSF; Triton deploy to TST; `callisto.proceeding.file.video-transcode-completed.v1` event emission; Power BI semantic model GitHub backup automation; audit column standardization; LocalStack full-pipeline local run.

---

## 3. Systems and initiatives touched

**Nova / Rhea** (video transcode) · **Atlas** / AJSF · **Callisto** · **Triton** · **Neptune** · **Hubble** · **Lagrange** (AWS/Postgres target) · **OMTI / RB9** (legacy source) · **ADB** (Automated Double Board) · **OJB** (Operations Job Board) · **NASA** (refinement track) · **Tesseract** (weekly) · **Power Platform / Power Apps / Power BI / Power Automate** · **Azure Functions** · **AWS** (Lambda, Fargate, EC2, RDS, S3, DynamoDB, EventBridge, Step Functions, LocalStack) · **OCR** · **Lit Tech grading & metrics** · **SharePoint**

---

## 4. People appearing in the board

| Person | Context in the data |
| --- | --- |
| **Jim** | New VP. Emails, operating-model feedback, 1:1, legacy-systems review, data-democratization sessions |
| **Joe DiMonte** | Cofounder / managing partner over technology *(per Dustin)*; appears in escalation path |
| **Joey Velazquez** | Litigation Technology Director *(per Dustin)* |
| **Karl** | Nova sequence diagram, environment creation (Sb/Dev/Tst/Prod), service task definition, alert dashboard |
| **Xavier** | Orbital package / outbox wiring, LocalStack full-stack, application-vs-domain layer rules, verified PRDV-15776 |
| **Larry Adams** | Nova tickets, refactor, AWS deploy, cursor rules, compile-list request |
| **Derrick** | PR approvals, Nova error report, VideoTranscode payload location |
| **Kat** | Nova BE test AC; authored the OJB/ADB Business Operations Alignment notes |
| **Caitlin** | Operations stakeholder on OJB/ADB; escalation source |
| **Christina** | Leadership escalation path (with Joe) |
| **Erik Johnson** | Hubble email-notification removal |
| **Lana** | PRs reviewed by Dustin |
| **Chris Schaffer** | Consult meeting (data/architecture) |
| **Jaimie** | Mentee — Sandbox ADB, her app, spike investigation, direct notes |
| **Shaye** | S3 input/output bucket access; long-running transcoding history |
| **Leah** | Video team requirements and usage sizing |
| **Nate Mollick** | Origin of the transcoding idea (~5 years prior) |
| **Julia White** | High-friction ticket resolved jointly |
| **Andrew** | Automatic file merging callout (metadata sort order) |
| **Gregg** | **No longer with the company** (departed week of 2026-07-27). Appears historically in Sprint 13 meeting, the DirectQuery 60-second concern, and a product-management framing note. **Excluded from stakeholder asks.** |

---

## 5. Hard numbers available

| Figure | Source |
| --- | --- |
| AWS Elemental MediaConvert ≈ **4× cost** of self-orchestrated pipeline | Nova research card |
| Typical video **3–4 hours**; ~**9 parallel jobs** per file at 30-min segments | Nova — Leah requirements |
| **~900 jobs/month** over 23 working days ≈ **40 users/day**; hypothetical cap 110 simultaneous | Nova — Leah requirements |
| OMTI **60-second hard query timeout**, non-negotiable, source-side | OJB/ADB restoration notes |
| RB9 connection **offline since May 21** | OJB reconnection strategy |
| OJB sync batch **10 → 3 items**; **3 consecutive days zero failures** | Weekly Accomplishments 06-27 |
| AAE query executes in **3–12 seconds** | DirectQuery evaluation |
| ADB legacy pattern: full DB refresh **on every user login** | ADB decoupling note |
| Atlas PR **#511**, Callisto PR **#340** | PRDV-15776 |
| Nova first commit **December 2025** | Dustin |

---

## 6. Action items flagged during the harvest

1. **Credential in plaintext — needs rotation.** The note dated **2026-06-16** attached to the *Power Platform to AWS* card (Sprint 13) contains an RB9 reference and what appears to be a plaintext password under a "Resources" heading. It is not reproduced here or in any other document. Recommend rotating the credential and replacing the note body with a secrets-manager pointer. Nothing was deleted or modified during this harvest.
2. **Two empty Weekly Accomplishments cards** (7/20–7/24, 7/27–7/31) — Sprint 14/15 material can backfill them if desired.
3. **Sprint 09 is empty** and Sprint 08's range overlaps oddly (04-15 → 06-02), suggesting cards were added late. Not an issue for the review, but the sprint boundaries there aren't reliable.

---

## 7. Hubble / OCR — the pre-2026 record

Separate source: board `Hubble` (`board-19`), spanning **2024-07-24 → 2026-01-14**. Establishes the two-year arc referenced in the accomplishments doc §8.

| Period | Evidence |
| --- | --- |
| Jul 2024 | OCR initiative starts. Goal stated as removing Adobe licensing and automating document OCR end to end. Tesseract vs AWS Textract evaluated; UML sequence diagram produced |
| Aug 2024 | Design notes name Java, CPU-bound vs I/O-bound, 10–20 threads for PDF stitching, SQS, SNS, container published to repo, **consumed as a Fargate task** — earliest Fargate reference in any board |
| Oct 2024 | Python/Tesseract prototyping (`pytesseract`, Pillow, fpdf, PyMuPDF); folder-structure and naming-convention work with Larry |
| Nov 2024 | Pilot with defined entry criteria (PDF, <300 pages, real file size); IT issue intake with Erik Johnson; pilot process with Caitlin; API Gateway error notification; parameter store for API/source protection; DLQ work |
| Dec 2024 – 2025 | Production ownership: Power BI dashboard so Caitlin can self-serve failures, metrics page, trace ID correctness, Aurora/RDS schema, `ocr_process_tracking` table, CloudWatch tracing, prod deploy coordinated with Karl, Atlas outbox integration |
| Bugs handled | DLQ vs CloudHQ error distinction, filenames with multiple spaces, failed-migration handling, 2000+ page files, flattened OneDrive structure, duplicate uploads. User-reported by Rachel, Colin, Alan |
| 2026 | Still owned — PRDV-16290 and PRDV-16345 Hubble investigation spikes, plus notification strategy with Larry, Karl, Erik |

**Naming:** the board carries both "OCR" (30-card column, 2024-07 → 2025-01) and "Hubble." Per Dustin, the project can be referred to as **Hubble**. The OCR column predates the Hubble name, so Jim may know it either way.

**Note:** this board also contains AWS Secrets Manager ARNs for dev and prod clusters. Those are resource identifiers rather than secrets, so no action taken — but worth knowing they're in plaintext notes.

---

## 8. Open questions carried into the accomplishments doc

- **Fargate vs. Lambda — resolved.** The Lambda-plus-Step-Functions schematic on the Nova board was the *initial* design, drawn before Fargate was on the table. The cost and fit investigation moved it to **Fargate tasks**, which is the shipping design. Nova is now in **beta, about to launch**. The board simply preserves the earlier draft — an artifact of the learning process, not a contradiction.
- **Nova vs. Rhea** as the outward-facing project name.
- **Derrick vs. Derek** spelling (People board says Derek; sprint cards say Derrick).
- **Karl and Xavier** are distinct in the data and neither appears on the People board.
