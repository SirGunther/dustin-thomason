---
ticket: PRDV-16216
tags: [neptune, callisto, media-duration, transcode, files]
author: Dustin Thomason
created: 2026-07-14
modified: 2026-07-14
---

# Story: Display Source Duration on Transcoded Files (Read-Time Lookup)

> **Parent epic:** File length metadata (Atlas File Navigator)
>
> **Companion ticket:** Nova duration validation — see [[PRDV-16216-companion-nova-duration-validation-spec]] (separate ticket, product buy-in pending)
>
> **Prerequisites:** PRDV-9756 (Length column display — merged), PRDV-15875 (`files.length` column — merged)
>
> **Investigation:** [[PRDV-16216-lookup-display-investigation]]

---

## Summary

Nova-transcoded video files show "unavailable" in the Atlas Length column because the derived file's `length` is never populated. The system already knows exactly which source file each transcoded file came from (`file_derivations`, ID-linked, rename-proof) and the source's stored duration.

This story makes Callisto's file-list serve path fall back to the **source file's duration** when a converted file's own `length` is null. The key finding from investigation: the serve path **already fetches the entire source `File` row — including `length` — and discards it** (the lineage query uses `innerJoinAndSelect('derivation.sourceFile', …)`; the lineage-map assembler keeps only IDs). The change is therefore **in-memory only**: thread the already-fetched source length through the lineage map and apply the fallback where converted rows are tagged. No SQL change, no schema change, no new query, no Atlas change.

Because resolution happens at read time, **every historical transcoded file displays a duration immediately on deploy** — no backfill or migration.

A transcode does not change runtime, so the source's duration is the correct display value; the companion ticket makes that assumption an enforced invariant by failing any transcode whose output duration doesn't match its input.

---

## Acceptance Criteria

- `GET /proceedings/:proceedingId/files` returns, for each **converted** file, `length` = its own `length` when set, otherwise its **source file's** `length`, resolved through the completed-transcode `file_derivations` linkage (by ID — never by file name)
- The fallback applies to both consuming endpoints (proceedings and job-submission file lists — they share the same transaction script) and to the deliverables view (`isDeliverable=true`), including when the source row itself is not in the returned view
- When the source file's `length` is also null, the converted file's `length` remains null and Atlas shows the existing "unavailable" text — the fallback never invents a value
- Existing transcoded files display their duration with no migration or backfill
- Original and non-transcoded files are untouched; no value is written to the database anywhere
- No Atlas front-end change; the existing Length column formatting applies as-is

---

## Backend Changes (Callisto)

### 1. Modified classes

| Class / file | Path | Change |
|---|---|---|
| `ProceedingFilesProjection` (type `TranscodeLineageEntry`) | `src/proceedings/domain/transaction-scripts/fetch-files-by-proceeding-id-ts/proceeding-files.projection.ts` (lines 28–32) | Add `sourceLength: number \| null` to `TranscodeLineageEntry` |
| `TranscodeLineageMapAssembler` | `.../fetch-files-by-proceeding-id-ts/transcode-lineage-map-assembler/transcode-lineage-map.assembler.ts` (lines 28–32) | Populate `sourceLength: derivation.sourceFile.length ?? null` — the source row is already hydrated by the repository query; update the doc comment (lines 8–13) that currently says source metadata isn't projected |
| `PairOriginalAndProcessedConverter` | `.../proceeding-files-mapper/converters/pair-original-and-processed.converter.ts` (`tagFile`, CONVERTED branch, lines 35–41) | `length: file.length ?? derivedEntry.sourceLength ?? null` — own value wins when present |
| `ProceedingFileDTO` | `.../fetch-files-by-proceeding-id-action/fetch-files-by-proceeding-id.response.dto.ts` (lines 32–37) | Update the `length` `@ApiPropertyOptional` description: for converted files the value falls back to the source file's length |

### 2. New classes

None.

### 3. New migrations

None — no schema change, no data write.

---

## Data Flow

```
GET /proceedings/:id/files                      (same TS also serves the
    │                                            job-submission endpoint via
    ▼                                            ProceedingAggregator)
FetchFilesByProceedingIdTS
    │
    ├── file-attachment.repository — main file query        (unchanged)
    │
    └── file-derivation.repository
        .fetchCompletedTranscodeDerivationsByFileIds
        innerJoinAndSelect('derivation.sourceFile', ...)     (unchanged —
    │   source File row incl. length ALREADY fetched)        no SQL change)
    ▼
TranscodeLineageMapAssembler
    │   entry: { derivationId, sourceFileId, derivedFileId,
    │            sourceLength }                               ← NEW field
    ▼
PairOriginalAndProcessedConverter — CONVERTED branch
    │   length: file.length ?? entry.sourceLength ?? null    ← NEW fallback
    ▼
ProceedingFileDTO.length ──► Atlas Length column (existing display, no change)
```

---

## Spec Tests

| Test | Path |
|---|---|
| Lineage map assembler | `.../transcode-lineage-map-assembler/__specs__/transcode-lineage-map.assembler.spec.ts` |
| Pair converter (primary) | `.../converters/__specs__/pair-original-and-processed.converter.spec.ts` (8 scenarios exist, incl. "derived file in the list but source is not" at line 215) |
| Transaction script | `.../fetch-files-by-proceeding-id-ts/__specs__/fetch-files-by-proceeding-id.transaction.script.spec.ts` |
| Shared factories | `.../__specs__/transcode-lineage.test-utils.ts` (`createMockTranscodeLineageDerivation` already wires full `sourceFile` objects) |

**Key assertions:**

- Lineage entry carries `sourceLength` from the hydrated source row
- Converted row with null own `length` and source `length = 4500` → `length: 4500`
- Converted row with own `length` set → own value wins (fallback not applied)
- Source `length` null → converted `length` null (no invented value)
- Derived file in view, source file not in view → fallback still resolves
- Original / non-transcode / PDF rows → `length` mapping unchanged

Gates: `npm audit --audit-level=high` → `npm run lint` → `npm test -- --runInBand` (callisto-back-end).

---

## Scope Boundaries

- **No persisted copy** — the database stays honest (`derived.length` remains null = never measured); the fallback is presentation-time only
- **No Atlas, Nova, or protocol changes**
- **No backfill ticket** — read-time resolution covers all historical rows by construction
- **Known display limitation (accepted):** when the source's duration was never captured at upload (browser-unmeasurable formats such as `.mts`/AVCHD, `.mkv`, `.avi`, `.wmv`), both rows show "unavailable" — this story cannot recover a value that was never stored
- **Validation is the companion ticket's job** — until it ships, the displayed value asserts (rather than verifies) that the transcode preserved runtime

---

## Cross-cutting

- **API docs:** the `@ApiPropertyOptional` description change on `ProceedingFileDTO.length` is the Swagger surface for this story; no route/method/status change
- **Companion dependency:** none for shipping — this story is independently deployable; the companion strengthens the semantics of the displayed value but does not change this code
- **Job-submission endpoint:** inherits the fallback automatically (same TS); its response type omits `length` in its declared TS type while the runtime payload includes it (no serialization stripping) — pre-existing gap, unchanged by this story

---

## Suggested point range

**Small (1–2 points).** Four in-memory edit points on one code path, no query/schema change, existing spec files and factories cover every scenario shape needed.
