# Future-development concerns — Jaimie/shareplane-modularize-availability

Surfaced during investigation (Phase 2). Each is a risk to carry forward, not a blocker for this ticket unless promoted.

## FDC-1 — Bulk availability vs SharePoint throttling / delegation limits
- **Concern:** The OJB lists hit a 5,000-item list-view threshold and ~300 calls/60s (prior coverage, `docs/power-platform-aws-investigation/`). A naive "one `_api` call per pasted title" in bulk mode will throttle (429) and can hit `$filter` delegation limits on large lists.
- **Why it matters:** silent partial results would make availability badges lie.
- **Mitigation direction:** batch titles into a single `$filter` (`Title eq 'a' or Title eq 'b' ...`) with a bounded `$top`; cap titles per check; degrade **visibly** at the limit. → decision D5.

## FDC-2 — Delivery model depends on tenant permissions (SharePoint-page option)
- **Concern:** If D2 = SharePoint-hosted page, modern SharePoint blocks custom script by default; hosting likely means SPFx (a build/deploy pipeline) or a tenant admin enabling custom scripts. This is a slow-feedback, admin-gated dependency (F5).
- **Mitigation direction:** prefer the browser-extension path (no tenant admin needed); only pursue the page option if the extension path is rejected.

## FDC-3 — Session-cookie fetch is a maintenance/security surface
- **Concern:** Reusing the 365 session via `credentials:"include"` from an extension means the tool acts with the user's full SharePoint read permissions; a broad `host_permissions` grant is powerful. Cookie/session changes (SameSite, conditional-access, WAM) could break it without warning.
- **Mitigation direction:** scope `host_permissions` to `https://planetdepos.sharepoint.com/*` only; read-only queries only; surface auth failures loudly (NP-2). Revisit if the tenant tightens session policy.

## FDC-4 — Filter-field assumption spans existing behavior
- **Concern:** Both the new availability query and the *existing* deep-links assume the record number is the internal `Title` field (F3). If wrong, existing links have been quietly imperfect too.
- **Mitigation direction:** confirm in the spike; if wrong, correct `FILTER_FIELD`/`config.js` for both features in the same change. **Update 2026-07-23:** spike CONFIRMED `Title` is the field (real values zero-padded 6-char, e.g. `"000001"`); exact-match `$filter`. Residual: input may need padding/normalization so a typed `1` matches `000001`.

## FDC-5 — F2 (extension cookie-attach) proven only at build time
- **Concern:** LD-002 accepts that the browser attaches the 365 session cookie to the extension-origin `_api` fetch without a pre-build spike proving it (the Stage-2 pre-build test did not load). If, when built, MV3 storage-partitioning / SameSite / tenant conditional-access blocks the cookie, the extension delivery model fails late.
- **Why it matters:** it is the load-bearing assumption of the whole delivery model (LD-001).
- **Mitigation direction:** prove F2 as the **first executable step of Phase 5** (build the real extension, load it correctly with no stale Chrome on the profile, confirm a `621571` read returns OJB:1/Archive:2). If it fails, fall back to the SharePoint-hosted page (F1 already proven) — the modular structure supports either with only `sharepoint.js`'s context differing. Residual risk is low given F1 + established MV3 behavior, but it is real until observed in the built extension.
