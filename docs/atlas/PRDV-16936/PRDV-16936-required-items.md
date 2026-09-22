# PRDV-16936 Requirements and Readiness

## Current Readiness

The required repositories and technical foundation are available locally. No
additional framework setup is required before implementation.

- [x] Proteus dependencies have been installed locally.
- [x] The Proteus worktree is on `prototype-main`.
- [x] The existing Proteus baseline has already been inspected and is considered in
  good standing. A new baseline gate run is not required.
- [x] Lana's in-progress work is not required as a starting point. The
  implementation will build on the Proteus code already supplied by Larry.

## Repositories

- [x] **Proteus frontend:** Available locally at
  `C:\Users\dustin.thomason\proteus-front-end`. This is the target repository
  for the prototype implementation.
- [x] **Current Atlas frontend:** Available locally at
  `C:\Users\dustin.thomason\atlas-front-end`. This is the source of truth for
  the existing Case Details layout, fields, tables, categories, and actions.
- [x] **Calisto/API and database references:** Available locally with the Atlas
  materials. These can be used to reproduce relevant response shapes with fake
  data in Proteus.

No repository or data-source access is currently blocking implementation.

## Branch and Route

- [x] Create and maintain the prototype work on `prototype-main`.
- [x] Existing `/cases` and `/cases/:caseId` routes are available in Proteus.
- [ ] Build the Atlas-parity Case Details prototype at `/cases/:caseId`.
- [x] No deployment branch or CI/CD setup is required.

Proteus already defines the routes `/cases` and `/cases/:caseId`. The existing
Case Detail implementation at `/cases/:caseId` is the scaffold to extend.

## Frameworks and Project Tools

- [x] React 19 and React DOM
- [x] TypeScript
- [x] Vite
- [x] React Router 7
- [x] TanStack Query
- [x] Axios API layer
- [x] shadcn/ui on Base UI
- [x] Tailwind CSS 4 with existing semantic theme tokens
- [x] Existing Proteus mock authentication, Axios mock adapter, routes, and
  generated fixtures
- [x] Existing npm scripts and package lock

All required framework and project tooling is already present. Do not add a
separate backend, mock server, UI library, or replacement framework.

## Existing Proteus Functionality

The following functionality is already available and should be reused:

- [x] Atlas application shell and protected-route flow
- [x] Automatic fake authentication while mock mode is enabled
- [x] Cases list and individual Case Detail routes
- [x] Typed cases API with `GET cases` and `GET cases/:caseId`
- [x] Typed jobs API with `GET jobs/:jobId`
- [x] Upcoming, available, and archived proceeding endpoints
- [x] Proceeding Detail and proceeding-file endpoints
- [x] Generated case, job, proceeding, invoice, and proceeding-file fixtures
- [x] Axios mock routing with simulated latency and no backend dependency
- [x] Existing Case Detail query hooks, loading/error handling, search, and
  grid/list presentation
- [x] Reusable tabs, tables, cards, dropdown menus, drawers, breadcrumbs, badges,
  buttons, tooltips, and file-type components

The current Proteus Case Detail page primarily displays upcoming, past, and
archived proceedings. It does not yet provide Atlas parity for Case Info,
Restricted Access, the Jobs List tab, or the Case Files tab.

## Required Prototype Content

- [x] Case name is represented in the existing Proteus Case Detail data and UI.
- [x] Case ID is available through the route and existing case model.
- [x] Case number is represented in the existing Proteus Case Detail data and UI.
- [ ] Add all current Atlas Case Info fields.
- [ ] Add the Restricted Access panel and information.
- [ ] Add Jobs List and Case Files tabs.
- [ ] Add the Jobs List with all current Atlas columns.
- [ ] Add Case Files with all current Atlas categories.
- [ ] Add all current user-facing actions.
- [ ] Add realistic fake data for all newly represented case, job, and file fields.

The exact Case Info fields, Jobs List columns, Case Files categories, and
available actions must be taken from the local Atlas implementation rather than
invented for the prototype.

## Expected Data Changes

Implementation is expected to require:

- [ ] Expand the Proteus case type and case fixture with the Atlas Case Info and
  Restricted Access fields
- [ ] Enrich the current job model as needed for every Atlas Jobs List column
- [ ] Add typed case-file models and API requests where the current
  proceeding-file model is insufficient
- [ ] Add case-file fixtures and mock routes matching the API layer
- [ ] Keep all fake data in `src/mocks/`; page components must not import or
  embed fixtures

## Interaction Expectations

- [ ] The page is clickable and demonstrates the current Atlas workflow.
- [ ] The page closely reproduces the current Atlas Case Details look and feel, including its
  layout, hierarchy, spacing, density, tabs, tables, category sections, badges, and action placement.
- [ ] Backend-dependent actions return believable simulated results.
- [ ] File actions use fake files or simulated downloads where appropriate.
- [x] No real Calista integration, authentication, permissions system, or Azure resources are required.

Existing interactions and components should be adapted where practical. Mocked
actions should follow the same API-layer pattern as reads when state changes or
response behavior need to be demonstrated.

Atlas is the visual source of truth. Use its Case Details Vue templates and SCSS
modules for side-by-side reference, translating them into Proteus's existing
React/shadcn components, Tailwind utilities, and semantic tokens. The result
should look like the same page implemented in the new stack, not a redesign.

## Local Handoff

- [ ] Shay can pull the branch, install dependencies, and start the prototype through the repository's normal npm workflow.
- [ ] The implementation is simple enough for Shay to modify with Claude Code.
- [ ] The completed prototype favors speed and functional completeness over production architecture, automated test coverage, pixel-perfect design, and exhaustive responsive behavior.

## Implementation Conventions

- [ ] New data flows through typed services in `src/api/**` and TanStack Query hooks.
- [ ] New fake responses and data live only in `src/mocks/routes.ts` and
  `src/mocks/fixtures.ts`.
- [ ] New Case Detail-only components, hooks, types, and utilities remain under
  `src/pages/CaseDetail/`.
- [ ] Reuse existing shadcn, Planet Depos, and shared components before adding new
  ones.
- [ ] Use Tailwind utilities and semantic theme tokens; do not add raw colors,
  inline styles, CSS Modules, or another component library.
- [ ] Favor functional completeness and easy modification over production-level
  abstraction or polish.

## Remaining Discovery

The local Atlas frontend and Callisto backend investigation is complete. The
exact evidence and implementation packets are recorded in
`PRDV-16936-CASE-DETAIL-PROTOTYPE-TODO.md`.

- [x] Case Info fields and display order
- [x] Restricted Access content and actions
- [x] Jobs List columns, sorting, menus, and row actions
- [x] Case Files categories, columns, menus, and file actions
- [x] Empty, loading, and disabled states that stakeholders expect to see

This is implementation discovery using sources already available locally; it
is not an outstanding access prerequisite.
