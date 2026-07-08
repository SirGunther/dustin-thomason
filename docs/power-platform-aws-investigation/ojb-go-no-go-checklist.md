# OJB Reconnection Go/No-Go Checklist

Status: Draft  
Prepared: 2026-07-06

Use this checklist before turning OJB flows back on against RB9 or a new gateway target.

## 1. Scope Lock

- [ ] Restoration goal is forward-looking OJB operation, not full historical backfill.
- [ ] Backlog period is explicitly recorded: starts 2026-05-21 and ends at the approved restoration timestamp.
- [ ] Ops has accepted that high-water mark advancement creates a temporary historical gap.
- [ ] Backfill is owned as a separate work item with timing, rate limits, and rollback criteria.

## 2. Pre-Prod Readiness

- [ ] Production SharePoint list schemas are cloned into a pre-prod workspace.
- [ ] OJB working and archive list schema differences are documented.
- [ ] Required indexed/filter columns are present in pre-prod.
- [ ] Production flows are cloned with production writes disabled.
- [ ] All connector credentials in pre-prod are non-production or explicitly approved for testing.

## 3. Gateway And Connection Readiness

- [ ] New gateway hostname/data source is configured.
- [ ] Gateway version is supported and current enough for Microsoft support policy.
- [ ] Gateway network ports test has passed from the actual gateway host.
- [ ] Gateway admins, backup admins, and monitoring contacts are named.
- [ ] Credential rotation or validation is complete before cutover.
- [ ] Connection sharing is restricted to required technical owners only.

## 4. Query Safety

- [ ] High-water mark location is identified in each flow/config.
- [ ] Approved restoration timestamp is written down before any change.
- [ ] CDC "changed IDs" query is tested independently.
- [ ] Batch update/query size is fixed at the approved value, initially 15 to 20 items.
- [ ] Each query segment completes in 45 seconds or less in pre-prod testing.
- [ ] No pre-prod test query reaches or exceeds 55 seconds.
- [ ] Query result payloads are below gateway and connector limits.
- [ ] Pagination and retry behavior are known and counted against flow request limits.

## 5. Flow Cutover Order

- [ ] Disable or pause all OJB flows before changing connection references.
- [ ] Update one flow at a time to the new gateway/hostname target.
- [ ] Start with the lowest-risk read-only or narrowest-scope flow.
- [ ] Observe at least one successful run before enabling the next flow.
- [ ] Keep reconciliation/full-board flows disabled until narrow delta flows are stable.
- [ ] Confirm archive-list writes only after working-list writes are stable.

## 6. Monitoring During Cutover

- [ ] Flow run history is visible to the cutover owner.
- [ ] Gateway logs/status are visible to IT owner.
- [ ] OMTI/RB9 error feedback path is live.
- [ ] SharePoint list write errors and throttling are watched.
- [ ] Ops has a validation checklist for visible board state.
- [ ] Time of each flow enablement is recorded.

## 7. No-Go And Rollback Triggers

Stop cutover and roll back if any of the following occurs:

- [ ] Any query hits the OMTI 60-second timeout.
- [ ] Any query runtime reaches 55 seconds or greater in production.
- [ ] Same query shape fails twice in a row.
- [ ] Gateway errors indicate connection instability or payload-size failures.
- [ ] OMTI reports database load or rejection signals.
- [ ] SharePoint writes create duplicate, corrupt, or misrouted records.
- [ ] Ops reports board state is materially misleading after a run.

Rollback actions:

- [ ] Disable the most recently enabled flow.
- [ ] Restore prior connection reference if it is safe to do so.
- [ ] Preserve run history and error payloads.
- [ ] Notify Ops that board state is frozen or partially restored.
- [ ] Decide whether to retry with smaller batches or trigger Plan B review.

## 8. Post-Cutover Checks

- [ ] High-water mark value is recorded after successful restoration.
- [ ] Known data gap is logged for backfill.
- [ ] First stable production run time and duration are recorded.
- [ ] Flow owners and alert recipients are verified.
- [ ] Backfill plan is scheduled or explicitly deferred.
- [ ] Decision memo is updated with actual cutover results.
