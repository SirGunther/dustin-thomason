# Stakeholder Interview Questions

Status: Draft  
Prepared: 2026-07-06

These questions target facts that cannot be proven from public docs or local notes.

## Gregg / Ops

1. What is the minimum OJB board state Ops needs on day one for work to resume safely?
2. Who can formally accept the historical data gap created by high-water mark advancement?
3. Which jobs, statuses, or date windows must be backfilled first after forward operation is stable?
4. What visible OJB symptoms should trigger immediate rollback from an Ops perspective?
5. For ADB, what manual override fields must be editable immediately, and who is allowed to edit them?
6. When should an ADB manual override expire: source catch-up, job completion, manual resolution, or a fixed age?

## Dustin / Jamie / Justin

1. Which exact ADB PowerApp screens and formulas merge semantic model data with SharePoint overrides?
2. What are the required fields and data types from `VQM jobs` and `VQM jobs tests`?
3. What is the current Power BI semantic model refresh schedule, owner, capacity, and failure history?
4. Which OJB flows currently read RB9, write the working list, write the archive list, or perform reconciliation?
5. Where is the high-water mark stored for each OJB flow?
6. What are the current OJB batch sizes, retry policies, recurrence schedules, and concurrency settings?
7. Which OJB SharePoint columns are indexed and used in filters/views?
8. Which flows use a shared credential or connection that should be rotated?

## Eric / Carl / IT

1. What gateway host or cluster will Power Platform use for the staged RB9 reconnect?
2. Is the gateway version within Microsoft's actively supported release window?
3. Can the gateway host reach RB9 and any AWS/Lagrange endpoint without inbound firewall exposure?
4. Who owns gateway monitoring and who is backup during cutover?
5. Are gateway credentials cached or shared in a way that could delay credential rotation?
6. What network path is acceptable for Lagrange: gateway host routing, NLB, PrivateLink, proxy/security appliance, or another pattern?
7. Is direct public inbound database exposure explicitly prohibited for this workload?
8. What logs can IT watch during cutover: gateway logs, firewall logs, NLB metrics, DB metrics, or all of these?

## Larry / Lagrange

1. Which Lagrange views/tables are intended to replace RB9 reads for ADB and OJB?
2. Are the required TST objects merged and deployed?
3. Is there a least-privilege read role for Power Platform testing?
4. What PostgreSQL engine/version and hosting model are in use: RDS PostgreSQL, Aurora PostgreSQL, or self-managed?
5. What DNS name should clients use, and what certificate name will be presented?
6. Is TLS required with server identity verification, and which CA bundle must clients trust?
7. Are materialized views refreshed frequently enough for OJB, or would OJB require a different incremental sync model?

## OMTI / RB9 Contact

1. Can OMTI confirm the 60-second query execution limit and whether it applies per query, per connection, or per transaction?
2. What reconnect cadence is acceptable during staged restoration?
3. What signals will OMTI provide if Power Automate traffic is causing source instability?
4. Are there preferred indexed columns or query patterns for modified-date CDC reads?
5. Can OMTI provide a safe backfill window or read replica for the skipped period?

## Decision Questions For The Final Memo

1. What exact event triggers Plan B review: repeated timeout count, OMTI rejection, missed cutover window, or Ops impact?
2. Who is authorized to pause production cutover?
3. Who is authorized to accept the high-water mark data gap?
4. Who owns the post-recovery backfill and reconciliation report?
5. What date should the final recommendation be reviewed again if Plan A is stable?
