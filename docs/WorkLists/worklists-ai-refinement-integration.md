# WorkLists AI Refinement Integration

Last updated: 2026-06-08T14:59:24Z

## Purpose

This document records where WorkLists AI prompts live, which prompt text is still hard-coded, how card and note refinement move through the app, and how many model calls are made today.

The main thing to remember: the current refinement path is a two-model-call flow for normal card and note refinement. The current `finalReview` object is deterministic server-side result shaping, not a third model call. If WorkLists should restore or add a third verifier/final-review model pass, that is future work and should be made explicit with its own prompt file and trace entry.

## Changelog-Backed History

Source of truth: `C:\Users\dustin.thomason\dustin-thomason\docs\WorkLists\worklists-app-changelog.md`.

Relevant history from the changelog:

- 2026-05-23: Card-level `Refine with Gemma` was added, with undo support and multi-card add/refine behavior.
- 2026-05-23: Server-backed async Gemma jobs were added for `add-task` and `refine-card`.
- 2026-05-24: Gemma process toasts were simplified and moved detail behind expansion.
- 2026-05-24/2026-05-25 era: Gemma response-shaping prompt instructions were centralized into `prompts/gemma-normalize-instructions.md`, and missing/empty prompt files became configuration errors instead of silently falling back to hard-coded prompt instructions.
- Later note work: AI note create/refine actions were added, then note-specific prompt constraints were injected so notes preserve explicit Markdown lists and return one complete note body.
- Tagging work: Primary/secondary tag determination was folded into the existing Gemma create/refine workflow, specifically avoiding a dedicated extra tagging model pass.
- Final-review work: `finalReview` was standardized so direct normalize and refine-card responses resolve an output from either the updated result or original fallback. The changelog and current code show this as response shaping, not a third model call.
- 2026-06-08: Refinement prompt tracing was added for card and note refinement. The trace reports prompt count and model-send stages.
- 2026-06-08: Classification context, tagging context, note context, and the user-text marker were moved out of `gemmaNormalize.js` into prompt-folder templates.

## Current Model Call Counts

These counts are for successful paths without SDK retries. Retries in `normalizeTextWithGemma` can add additional normalization send attempts.

| Surface                           | Client entry                               | Server path                  | Current model calls   | Stages                                              |
| --------------------------------- | ------------------------------------------ | ---------------------------- | --------------------- | --------------------------------------------------- |
| Direct normalize API              | `ApiService.normalizeWithGemma(input)`     | `POST /api/gemma-normalize`  | 1                     | normalization only                                  |
| Add task from UI                  | `runGemmaNormalizationForInput`            | `add-task` background job    | 2                     | classification, normalization                       |
| Add task job without full `input` | Non-UI/custom payload with candidates only | `add-task` background job    | `1 + candidate count` | one classification, one normalization per candidate |
| Card refine                       | `refineCardWithGemma`                      | `refine-card` background job | 2                     | classification, normalization                       |
| Card refine skipped               | source text changed before job runs        | `refine-card` background job | 0                     | no model call                                       |
| Note create                       | `createNoteWithAiFromPane`                 | `add-note` background job    | 2                     | classification, note normalization                  |
| Note refine                       | `refineNoteWithAi`                         | `refine-note` background job | 2                     | classification, note normalization                  |
| Note refine skipped               | source text changed before job runs        | `refine-note` background job | 0                     | no model call                                       |

## Prompt Inventory

| Prompt or directive              | Location                                                                                   | Abstracted?              | Used by                                      | Notes                                                                              |
| -------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------ | -------------------------------------------- | ---------------------------------------------------------------------------------- |
| Classification instructions      | `WorkLists/prompts/gemma-classify-instructions.md`                                         | Yes, file-based          | `createGemmaClassificationPrompt`            | Produces `card_count`, `markdown`, and `markdown_hint`.                            |
| Normalization instructions       | `WorkLists/prompts/gemma-normalize-instructions.md`                                        | Yes, file-based          | `createGemmaNormalizationPrompt`             | Main response-shaping instructions and JSON schema.                                |
| Classification context directive | `WorkLists/prompts/gemma-classification-directive-template.md`                             | Yes, file-based template | normalization prompt                         | Rendered by `buildClassificationDirective` with card count and Markdown variables. |
| Tagging context directive        | `WorkLists/prompts/gemma-tagging-directive-template.md`                                    | Yes, file-based template | normalization prompt when tag context exists | Rendered by `buildTaggingDirective` with tag inventory variables.                  |
| Note context directive           | `WorkLists/prompts/gemma-note-directive-template.md`                                       | Yes, file-based template | note create/refine normalization             | Rendered by `buildNoteDirective` with create/refine mode variables.                |
| User text marker                 | `WorkLists/prompts/gemma-user-text-label.md`                                               | Yes, file-based          | classification and normalization prompts     | Appended before the user-provided input.                                           |
| Final review payload             | `server.js` -> `createGemmaFinalReviewPayload`, `withGemmaRefineFinalReviewPayload`        | Not a prompt             | direct normalize and refine-card responses   | Deterministic server response shaping. It does not call the model.                 |
| Prompt trace log                 | `server.js` -> `createGemmaPromptTrace`, `recordGemmaPromptTrace`, `writeGemmaPromptTrace` | Not a prompt             | refine-card and refine-note jobs             | Logs `[gemma-trace]` with `promptCount`, stage, model, and prompt length.          |

## Prompt Assembly Order

Normalization prompts are assembled in `createGemmaNormalizationPrompt` in this order:

1. Optional classification directive from `buildClassificationDirective`.
2. Optional tagging directive from `buildTaggingDirective`.
3. File-based normalize instructions from `prompts/gemma-normalize-instructions.md`.
4. Optional note directive from `buildNoteDirective`.
5. `User text:` and the input.

Classification prompts are assembled in `createGemmaClassificationPrompt` in this order:

1. File-based classify instructions from `prompts/gemma-classify-instructions.md`.
2. `User text:` and the input.

## Client Integration

Card refinement:

- UI entry: `refineCardWithGemma` in `public/todolist2.js`.
- Payload: `type: "refine-card"`, `taskId`, `sourceText`, and update-mode `tagContext`.
- API helper: `ApiService.startGemmaNormalizeJob` in `public/apiService.js`.
- Completion handling: `handleCompletedGemmaRefineJob` refreshes board data, shows process toast updates, and shows a short undo toast when applicable.

Note creation:

- UI entry: `createNoteWithAiFromPane` in `public/todolist2.js`.
- Payload: `type: "add-note"`, `eventId`, and `input`.
- Completion handling: `handleCompletedAiNoteJob` refreshes the active notes pane and reports note creation.

Note refinement:

- UI entry: `refineNoteWithAi` in `public/todolist2.js`.
- Payload: `type: "refine-note"`, `noteId`, and `sourceText`.
- Completion handling: `handleCompletedAiNoteJob` refreshes the active notes pane and offers undo for completed note refinement.

## Server Integration

Background jobs enter through `POST /api/gemma-normalize/jobs` and are built by `createGemmaJobDefinition`.

Dispatch is handled by `executeGemmaJob`:

- `add-task` -> `executeAddTaskGemmaJob`
- `refine-card` -> `executeRefineCardGemmaJob`
- `add-note` -> `executeAddNoteGemmaJob`
- `refine-note` -> `executeRefineNoteGemmaJob`

Model send helpers:

- `classifyGemmaJobInput` creates and sends the classification prompt.
- `normalizeGemmaJobInput` creates and sends the normalization prompt.
- `createModelGenerateContent` routes through the active model config and optional test override.
- `renderGemmaPromptTemplate` reads prompt-folder templates and substitutes data-only variables; instruction copy should not be embedded in infrastructure code.

## Cards vs Notes

Cards:

- May stay as one card or be replaced by multiple cards when classification says more than one card.
- Carry update-mode tag context during refinement.
- Can update card text, primary tags, secondary tags, or replace the original card.
- Multi-card replacement captures previous card and previous notes so undo can restore the original card/notes.
- Completed `refine-card` job responses get `finalReview` attached by `withGemmaRefineFinalReviewPayload`.

Notes:

- Always force a one-note response by converting classification through `createGemmaNoteClassification` and injecting `noteContext`.
- Treat `cleaned_text` as the full saved note body, not a task title.
- Preserve explicit Markdown, lists, named details, dates, ingredients, steps, and instructions.
- Do not use tag context.
- Use generic user-facing AI labels even though backend route/function names still use historical Gemma naming.
- Completed `refine-note` job responses currently do not get the same `finalReview` wrapper as card refinement.

## Current Final Review Reality

Current code has two different meanings that are easy to confuse:

1. `finalReview` payload: deterministic server-side result shaping. It compares the original output with candidate outputs and chooses an `output`, `updatedOutput`, and fallback status.
2. Potential third verifier model pass: not implemented today. This would be a new AI call whose job is to evaluate whether the classification/normalization result followed instructions and whether corrections or extra context are needed.

If the third verifier pass is restored or added, give it a separate prompt file, for example `prompts/gemma-final-review-instructions.md`, and trace it as a distinct stage such as `final-review` so refinement logs show `promptCount: 3` for the normal path.

## Abstraction Targets

Current completed abstraction:

1. File-backed base prompts: `gemma-classify-instructions.md` and `gemma-normalize-instructions.md`.
2. File-backed dynamic directive templates: classification context, tagging context, note context, and user-text marker.
3. Source-level regression coverage now checks that these directive strings remain in prompt files instead of `gemmaNormalize.js`.

Remaining prompt-work targets:

1. Consider adding a final-review/verifier prompt file only if WorkLists should make a third model call.
2. Add a prompt registry or manifest that records prompt id, file path, purpose, expected response shape, call stage, and template variables.
3. Extend prompt tracing beyond refine jobs if add-task and direct normalize prompt counts need the same visibility.
4. Keep future AI-facing copy out of `server.js`, `gemmaNormalize.js`, and UI infrastructure; add a prompt/template file first, then render it with data variables.

## Quick Verification Points

Use these checks when future behavior seems off:

- To verify prompt counts during refinement, look for `[gemma-trace]` log entries with `event: "gemma-refine-prompt-trace"`.
- Normal card refine should show `classification` then `normalization`.
- Normal note refine should show `classification` then `normalization`.
- A source-changed skip should show `promptCount: 0`.
- If a future final verifier pass is implemented, normal refine traces should show a third `final-review` stage.
