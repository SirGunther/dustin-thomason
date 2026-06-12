# Accessing Atlas Features by Environment

Reference for reaching Atlas (atlas-front-end) UI surfaces in each environment, the
route map, and the role/infra gotchas that make a feature appear "missing" when it is
really just gated or deep-link-blocked.

> Scope: focused on the **Callisto** area of Atlas (jobs, proceedings, AJSF). Europa and
> Triton surfaces exist under their own route prefixes but are out of scope here.

---

## 1. Environments and how to run / build

From `atlas-front-end/README.md`:

- Run locally against a given environment's APIs:
  - `npm run dev:local`
  - `npm run dev:sb`
  - `npm run dev:dev`
  - `npm run dev:tst`
  - `npm run dev:prod`
- Build for an environment: `npm run build:sb | build:dev | build:tst | build:prod`
- Stage: `npm run stage:dev | stage:tst | stage:prod`

Each environment needs its matching `.env.*` file (`.env.local`, `.env.sb`, `.env.dev`,
`.env.tst`, `.env.prod`). Copy `.sample.env` to create `.env.local` for first-time setup.

### Hosts per environment

Fill in the confirmed CloudFront host for each env as you verify it (the README documents
the S3/CloudFront deploy targets but not the public hostnames):

- local: `http://localhost:9000` (Quasar dev server default; proxies `/callisto`, `/triton`, `/europa` to backends)
- sb: `<fill-in>`
- dev: `<fill-in>`
- tst: `<fill-in>` (confirmed reachable at `/callisto-stuff/my-jobs` on 2026-06-12)
- prod: `<fill-in>`

---

## 2. Callisto route map

The Callisto app is mounted under the `/callisto-stuff` layout prefix
(`src/globalRouter/routes.ts`). Key routes:

- `/callisto-stuff` - Callisto home (`HomePage`)
- `/callisto-stuff/my-jobs` - My Jobs list (`MyJobsPage`) **[role-gated, see section 3]**
- `/callisto-stuff/pending-job-submission-form/:jobTaskId` - **AJSF** (editable job submission form, `PendingJobSubmissionPage`)
- `/callisto-stuff/submitted-job-submission-form/:jobTaskId` - submitted (read-only) job submission form
- `/callisto-stuff/job/:id` - Job Detail (`JobDetailPage`)
- `/callisto-stuff/job/:id/proceeding/:proceedingId` - Proceeding Detail
- `/callisto-stuff/jobs/search` - Search jobs
- `/callisto-stuff/case/:id` - Case Detail
- `/callisto-stuff/case-merge` - Case merge (permission-gated)

---

## 3. Role / entitlement gating

Access to features is driven by the signed-in account's roles (Cognito groups), which
**differ per environment and per user**. This is why a feature can be reachable in tst
but appear missing in dev with a different account.

- **My Jobs / AJSF** require the `NEPTUNE_LITTECH_MEMBERS` role
  (`src/callisto/auth/composables/entitlements/useEntitlements.ts` -> `hasMyJobsEntitlement`).
- The sidebar "My Jobs" (Tasks) nav item is **disabled** with a "coming soon" tooltip when
  the account lacks the entitlement (`src/globalLayouts/MainLayout/NavItems/TasksNavItem.vue`).

If the nav item is greyed out / "coming soon", your account in that env is not in the
LitTech group.

---

## 4. Deep-link and 404 behavior (history-mode SPA)

Atlas is a Quasar/Vue 3 SPA in **history mode**. Client-side routes are not real files.

- DEV/TST/PROD CloudFront currently rewrites **403/404 -> `/index.html` (200)** so deep-links
  and refreshes boot the SPA and let `vue-router` resolve the route client-side.
- Therefore a **404 you see is usually the app's own branded 404**
  (`ErrorNotFoundPage.vue`, via the `/:catchAll(.*)*` route) - meaning the SPA loaded but the
  path did not match - not a raw S3/CloudFront 404.
- Practical rule: prefer in-app navigation (sidebar -> My Jobs -> click a pending job) over
  typing deep links, and double-check the `/callisto-stuff` prefix.

Full infra analysis: see `larry-adams/discovery/atlas-cloudfront-403-404-analysis.md`
(do not duplicate it here).

---

## 5. Reaching the AJSF proceedings surface (relevant to PRDV-15619)

1. Run/visit the target env (e.g. `npm run dev:tst` locally) signed in with a
   `NEPTUNE_LITTECH_MEMBERS` account.
2. Sidebar -> **My Jobs** -> click a **pending** job
   (-> `/callisto-stuff/pending-job-submission-form/:jobTaskId`).
   - A direct deep-link to a known `jobTaskId` also works once the SPA is loaded
     (verified with a dummy job, e.g. `.../pending-job-submission-form/111111`).
3. In the left "Steps to submit job" sidebar, open **step 5 "File upload"**.
4. That panel shows the **proceedings list** (each proceeding renders as a
   `ProceedingUploadArea` card) plus the **"+ Add Proceeding"** form.
   - On a job with no proceedings yet, the list is empty and only "+ Add Proceeding" and
     "Done" are visible.

### Testing the refresh/discrepancy scenario

The 15619 need (see newly-created proceedings by other LTRs without losing form data)
requires:

- a LitTech-entitled account in the env,
- a job in **pending** submission state, and
- a way to add a proceeding from a **second** session/account for the same job while the
  first session's form stays open, so the new proceeding can appear on refresh.
