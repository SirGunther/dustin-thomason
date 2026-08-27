# Codex Sessions Navigator for Cursor — Implementation Handoff

## Objective

Build a very small companion Cursor/VS Code extension that gives Codex a Claude-like session navigation experience:

- A persistent **Codex Sessions** view in the left Activity Bar/sidebar.
- A list of existing local Codex conversations/sessions.
- Clicking a session opens the **real OpenAI Codex conversation UI** in the main editor area.
- Multiple Codex conversations can remain open simultaneously as editor tabs.
- A **New Session** action opens a new Codex agent/editor instance.
- A **Refresh** action reloads the session list.

This is intentionally a narrow utility. Do **not** build a replacement chat client, duplicate Codex UI, add publishing infrastructure, or turn this into a large extension project.

---

## Environment / Known Facts

Host:
- Cursor on Windows.

Active Codex extension:
- `openai.chatgpt-26.715.61943-win32-x64`
- Installed at:
  `C:\Users\dktho\.cursor\extensions\openai.chatgpt-26.715.61943-win32-x64`

A newer extension is also present on disk:
- `openai.chatgpt-26.721.30844-win32-x64`
- It is **not** the active extension.
- It has historically failed to load properly in Cursor, so do not target it.

The active extension works normally in a sidebar/panel and can authenticate and run Codex.

### Important Windows editor-route bug already fixed locally

`Codex: New Codex Agent` originally created a blank editor tab in Cursor.

In the active extension bundle:

`C:\Users\dktho\.cursor\extensions\openai.chatgpt-26.715.61943-win32-x64\out\extension.js`

this minified code existed:

```js
{path:t.fsPath,conversationId:s}
```

It was patched to:

```js
{path:n,conversationId:s}
```

After this change, the Codex editor UI began rendering correctly.

A backup exists at:

`C:\Users\dktho\.cursor\extensions\openai.chatgpt-26.715.61943-win32-x64\out\extension.js.backup`

Do not overwrite, revert, or broadly modify the official Codex extension unless absolutely necessary. The companion extension should be independent.

---

## Desired UX

Target mental model:

```text
CURSOR
┌──────────────────────┬────────────────────────────────────────────┐
│ CODEX SESSIONS       │ EDITOR                                     │
│                      │                                            │
│ + New Session        │ [Session A] [Session B] [Session C]        │
│ ↻ Refresh            │                                            │
│                      │ ┌────────────────────────────────────────┐ │
│ CURRENT PROJECT      │ │                                        │ │
│   Fix auth flow      │ │        Real Codex conversation         │ │
│   Dashboard work     │ │        rendered by OpenAI Codex        │ │
│   API refactor       │ │                                        │ │
│                      │ └────────────────────────────────────────┘ │
│ OTHER / RECENT       │                                            │
│   Research session   │                                            │
│   Database cleanup   │                                            │
└──────────────────────┴────────────────────────────────────────────┘
```

The sidebar is only a navigator. All actual chat/composer/tool activity remains inside the official Codex editor UI.

---

## Architectural Decision

Build a **separate companion extension**, tentatively named:

`codex-sessions-navigator`

It should use normal VS Code extension APIs:

- `viewsContainers.activitybar`
- `views`
- `TreeDataProvider`
- commands for Open, New, and Refresh

Do not attempt to modify Cursor internals.

Do not reimplement Codex authentication, chat rendering, model calls, tools, diffs, approvals, or session execution.

The extension has only two responsibilities:

1. Discover and display local Codex sessions.
2. Ask the installed Codex extension to open a selected session in its existing editor renderer.

---

## Session Discovery

Prefer a dependency-free, read-only source.

Primary source to inspect first:

`C:\Users\dktho\.codex\sessions\**\rollout-*.jsonl`

Possible additional sources if needed:

- `C:\Users\dktho\.codex\session_index.jsonl`
- `C:\Users\dktho\.codex\state_5.sqlite`

### Important rule

Do not assume field names. Inspect several real rollout files and determine their structure before coding the parser.

Prefer rollout JSONL parsing over SQLite for the MVP because it avoids native SQLite dependencies and packaging complexity.

Use SQLite only if the rollout files do not provide enough metadata for reliable session listing.

### Desired metadata per session

Best effort:

- conversation/session/thread ID
- title or first user-message preview
- working directory / project path
- created timestamp
- updated timestamp if available
- source file path

If there is no explicit title, derive a short display label from the first meaningful user prompt.

Do not write to, delete, rename, or modify any Codex session/state files.

---

## Codex Editor Bridge

This is the one intentionally private/undocumented integration point.

Known behavior from the installed Codex extension indicates that existing conversations can be routed to an editor resource conceptually equivalent to:

```text
/local/<conversationId>
```

The Codex custom editor/view is believed to be associated with a view type similar to:

```text
chatgpt.conversationEditor
```

and an internal custom URI scheme used by Codex.

### Do not blindly hard-code those identifiers first.

Before implementing `openSession`, inspect the active installed extension:

1. `package.json`
2. `out/extension.js`

Specifically determine:

- the actual registered custom editor `viewType`
- the actual URI scheme used for Codex conversation resources
- the command IDs contributed by Codex
- how its own history UI constructs/open routes for existing conversations

Search for strings such as:

- `conversationEditor`
- `/local/`
- `newCodex`
- `navigate-in-new-editor-tab`
- `customEditors`
- `registerCustomEditorProvider`
- `Uri.file`
- URI `scheme`

The implementation should then use the smallest supported VS Code API call possible, likely one of:

```ts
vscode.commands.executeCommand('vscode.openWith', uri, codexViewType)
```

or the exact internal command/resource invocation used by Codex itself.

### Desired open behavior

When a user clicks a session:

- If that exact conversation is already open in an editor tab, reveal/reuse it if practical.
- Otherwise open it as a new Codex editor tab.
- Do not create a new empty conversation when opening history.
- Preserve multiple simultaneously open Codex sessions.

Do not build a second chat renderer.

---

## New Session Command

Inspect the active Codex extension's contributed commands and identify the command behind:

`Codex: New Codex Agent`

Invoke that existing command from the companion extension.

Do not simulate button clicks or reproduce Codex's new-session initialization.

The locally patched `26.715.61943` build now renders a new Codex editor tab successfully.

---

## MVP UI

Create one Activity Bar container:

**Codex Sessions**

Inside it, create one tree view.

Toolbar actions:

- `+` New Codex Session
- Refresh

Tree organization:

```text
CURRENT WORKSPACE
  Session title A
  Session title B

RECENT / OTHER
  Session title C
  Session title D
```

If workspace matching is easy, group sessions whose recorded working directory matches one of the currently open workspace folders under **Current Workspace**.

If matching becomes fragile, omit grouping in v1 and simply sort all sessions by most recent first.

Tree item tooltip can include:

- full title/preview
- working directory
- timestamp
- conversation ID

No search UI, rename, archive, pinning, settings page, or context menus are required for MVP.

---

## Suggested Project Structure

Prefer TypeScript with no runtime dependencies.

```text
codex-sessions-navigator/
  package.json
  tsconfig.json
  src/
    extension.ts
    sessionStore.ts
    codexBridge.ts
    treeProvider.ts
  media/
    codex-sessions.svg
  README.md
```

Possible responsibilities:

### `sessionStore.ts`

- Locate Codex home directory (`%USERPROFILE%\.codex` on this machine).
- Enumerate rollout files.
- Parse metadata safely.
- Return normalized `CodexSession[]`.
- Read-only.

### `codexBridge.ts`

- Detect the installed `openai.chatgpt` extension.
- Verify it is active or activate it.
- Determine/invoke New Codex Agent command.
- Construct/open a Codex editor resource for a selected conversation.
- Keep all private Codex integration code isolated here.

### `treeProvider.ts`

- Render groups and sessions.
- Sort by recent activity.
- Session click invokes `codexSessions.openSession`.

### `extension.ts`

- Register tree provider.
- Register commands.
- Wire refresh/new/open actions.

---

## Packaging / Installation

This is a local utility. Do not publish it.

Create a `.vsix` that can be installed into Cursor via:

`Extensions -> ... -> Install from VSIX...`

Use the smallest practical packaging toolchain.

Avoid native dependencies.

The extension should be removable without affecting Codex itself or any Codex sessions.

---

## Acceptance Criteria

The MVP is successful if all of the following are true:

1. Cursor starts normally with Codex `26.715.61943` active.
2. A **Codex Sessions** icon appears in the Activity Bar.
3. Opening the view shows existing local Codex sessions.
4. The list contains enough identifying information to choose the right session.
5. Clicking an existing session opens that **same existing conversation** in the main editor using the real Codex UI.
6. The opened conversation is interactive and retains its existing history.
7. Opening a second session leaves the first available as another editor tab.
8. Clicking a session that is already open does not unnecessarily create duplicate identical tabs if reuse is feasible.
9. The New button invokes the existing **Codex: New Codex Agent** behavior.
10. Refresh updates the tree when new Codex sessions have been created.
11. No Codex database/session files are modified.
12. No additional patch is made to the official Codex bundle unless required to overcome a clearly identified blocker.
13. Uninstalling the companion extension leaves Codex fully functional.

---

## Non-Goals

Do not spend time on any of the following unless the MVP is already working:

- Marketplace publishing
- sign-in/authentication
- model selection
- tool execution
- chat/composer UI
- rich session previews
- session rename/archive/delete
- drag-and-drop
- custom databases
- telemetry
- settings UI
- cross-platform support beyond what naturally falls out of the implementation
- reproducing Claude's UI pixel-for-pixel
- modifying Cursor workbench layout

The goal is functional session navigation, not product polish.

---

## Constraints / Guardrails

- Target the known-working active Codex build: `26.715.61943`.
- Do not switch to `26.721.30844` during development.
- Preserve the existing Windows `fsPath -> path` patch in `26.715.61943`.
- Do not remove the `.backup` file.
- Do not change Cursor's global configuration unless required.
- Do not depend on these VS Code Agent Host settings for the solution:

```json
"chat.agentHost.codexAgent.enabled": true,
"chat.editor.codex.preferAgentHost": true
```

They are not the architecture this utility should rely on.

- Prefer a local extension that drives Codex's existing editor implementation.
- Keep all undocumented/private Codex integration isolated so it can be adjusted later if OpenAI changes its route/view identifiers.

---

## Recommended Implementation Sequence

1. Inspect active Codex `package.json` and bundle to identify exact command IDs, URI scheme, custom editor view type, and history-to-editor routing.
2. Inspect 3-5 real rollout JSONL files under `.codex\sessions` and determine the minimum reliable parser.
3. Scaffold the companion extension.
4. Implement session discovery and render the tree.
5. Implement `openSession` using Codex's existing internal route/editor mechanism.
6. Implement New and Refresh commands.
7. Run locally in Cursor / Extension Development Host if practical.
8. Package as VSIX and install into the normal Cursor profile.
9. Test against the Acceptance Criteria.
10. If successful, stop. Do not add polish unless explicitly requested.

---

## Debugging Priorities

If session listing works but opening a session fails:

1. Verify the exact URI scheme and custom editor view type from the installed Codex build.
2. Compare the resource URI generated by the companion extension with the URI Codex itself generates when opening a history item.
3. Check Cursor Developer Tools and Codex Output.
4. Confirm the `fsPath -> path` patch is still present in the active Codex bundle.
5. Check whether the Codex extension exposes an internal command that is safer than calling `vscode.openWith` directly.

If the only way to proceed would be to build a replacement chat UI, stop and report the blocker instead.

If private routing changes require another tiny targeted compatibility shim, isolate it and document it rather than broadly patching the Codex bundle.

---

## Stop Condition

This is intended to be a quick local utility.

If the MVP cannot be made to work with one straightforward implementation plus one focused compatibility/debugging pass, stop and report:

- exactly what works
- exactly what fails
- the private Codex API/route that blocks progress
- the smallest remaining workaround

Do not turn this into a prolonged extension-development effort.

---

## Final Deliverable

Produce:

1. Source folder for the companion extension.
2. Installable `.vsix`.
3. Short README containing:
   - installation
   - uninstall
   - known dependency on Codex `26.715.61943`
   - note about the existing `fsPath -> path` patch
   - any private Codex identifiers relied on by the extension
4. A short test report against the Acceptance Criteria.

The ideal end state is simple:

**Left sidebar = persistent Codex session navigator.**

**Editor area = real Codex conversations, each in its own tab.**
