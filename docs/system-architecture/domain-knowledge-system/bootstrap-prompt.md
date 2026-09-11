# Bootstrap prompt

Run once, during instantiation (`TEMPLATE-USAGE.md`), after the universal area
stubs under `domains/` have been reduced to the ones that apply to this system.
Its job is to name the areas the universal list does not cover, not to decide the
system's full domain decomposition.

## What this prompt does not do

An agent running this prompt has read the application's source for the first time
and nothing else. `domains/README.md` states that a node's Decisions, Invariants,
Not owned, and History cannot be reconstructed from the repository, because a
rejected alternative, a required invariant, a deliberate exclusion, and an
abandoned attempt each leave no trace in the code. An agent limited to reading
source can therefore not fill any of those four fields accurately. Writing them
anyway would record the code's current behavior in a field meant to hold a
decision, an invariant, an exclusion, or an abandoned attempt, none of which the
code itself states. §32 prohibits recording a second copy of the source code in
this form.

This prompt writes area files with empty fields marked as unrecorded, and nothing
past that. It never writes a feature file, because `domains/README.md`'s
three-condition rule (a decision with a rejected alternative, a tested invariant,
or a recorded regression) cannot be satisfied by anything this prompt can produce.

## The prompt

```text
Target application source root: <path>
Existing area files under domains/: <list of file names already present>

1. Do not read directory names as area names. Read interface definitions instead:
   contract and schema file contents, public route definitions, message or event
   type names, public entry points, and test file names with their describe or
   test block titles.
2. For each area name under consideration, find how many of the five signal
   types in step 1 name that same subject, from different source locations.
   Record which signals and where each was found. Do this before checking
   which areas the universal stubs already cover, so the count in step 4
   measures how much the interfaces actually reveal, not how much is left
   over after known subjects are set aside.
3. If one candidate's signals are entirely contained within a broader
   candidate's signals, meaning every route, event type, schema, entry point,
   or test naming the narrower candidate also relates to the broader one, fold
   the narrower candidate into the broader one rather than counting it
   separately. The narrower subject is a feature within the broader area, not
   a second area (section 3.2 defines an area as broader than a feature); it
   is reported in step 8 as a candidate feature under the area it was folded
   into, not written as a file, since no candidate can meet the tested-decision
   or tested-invariant bar for a feature file at this point (domains/README.md).
4. If fewer than three candidates remaining after step 3 are supported by two
   or more signals, stop. Report that this source tree does not expose areas
   through its interfaces, list every candidate found regardless of signal
   count, and take no further action.
5. Otherwise, discard any candidate already covered by an existing file under
   domains/. Do not propose a second name for an already-covered subject.
6. Discard any remaining candidate supported by only one signal from being
   written as a file. Keep it in the report as an uncertain candidate.
7. For each candidate that survives steps 5 and 6, write one file at
   domains/<area>.md containing only:
   - frontmatter: id, kind: area, area, status: Proposed, and empty answers,
     governs, affects, not_owned, decisions, invariants, and reviewed_by lists
   - the six section headings from templates/feature-node.template.md
   - under Decisions, the words "No decision recorded"
   - under Invariants, the words "No invariant recorded"
   - under Not owned, Affects, and History, the words "None recorded"
   - under Governs, a rule citation only if a signal in step 1 named a rule
     already written under specs/ directly, otherwise "None recorded"
   Do not write prose describing what the area does. That restates the source
   rather than recording a decision.
8. Report:
   - every area file written, with its signals and where each was found
   - every candidate folded into a broader area per step 3, and which area
   - every candidate found but not written, with its signal count
   - whether step 4's stop condition was reached
```

## Diff mode

Re-running this prompt after the tree already has area files, following an
application change, uses the same signal-finding steps with two differences:
compare the candidate list against the files that already exist, and never
rewrite a file this prompt or a task has already written.

```text
Target application source root: <path>
Existing area files under domains/: <list, with each file's status>

Run steps 1 through 6 above unchanged. Then, instead of step 7, report:
- areas with two or more signals that have no corresponding file
- files that exist whose area no longer has any signal in the current source
Write no files. A human or a task decides what to do with each reported line.
```

## Why a node is reported as over-decomposition, not deleted

`domains/README.md` states that a node left `Status: Proposed` after several
tasks have run without selecting it is reported as over-decomposition. This
prompt does not delete such a node itself, because a task not yet having reached
an area is not evidence the area is wrong, only that no task has needed it yet.
Deciding to remove it is the same kind of decision the node's own Decisions
section exists to record, so it is made by whoever reviews the report, not by this
prompt.
