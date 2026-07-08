# Power Platform to AWS Decision Memo

Status: Draft, pending stakeholder validation  
Prepared: 2026-07-06  
Scope: ADB restoration, OJB staged recovery, and Lagrange/AWS/Postgres fallback

## Executive Recommendation

Proceed with a two-speed recovery strategy:

1. Restore ADB through the low-frequency Power BI semantic model path plus a SharePoint override list.
2. Restore OJB through a staged RB9 reconnection in a cloned pre-production environment, using high-water mark advancement and small CDC batches to avoid the OMTI 60-second timeout.
3. Keep Lagrange/AWS/Postgres as Plan B until a connector and network proof of feasibility confirms TLS, DNS/certificate handling, gateway/proxy routing, and security posture.

Do not expose a database directly to public inbound traffic. Any Lagrange path should use a controlled gateway/proxy/private-network design and pass an explicit security review.

## Decision Summary

| Track | Recommended path | Why | Decision gate |
| --- | --- | --- | --- |
| ADB | Use Power BI semantic model refresh plus SharePoint manual overrides. | The workload can tolerate scheduled refresh latency if user-entered scheduling overrides are immediate and persistent. | Schema parity for `VQM jobs` and `VQM jobs tests`; override precedence confirmed; refresh failures monitored. |
| OJB | Use staged RB9 reconnect with high-water mark advancement and segmented CDC batches. | OJB volume and query shape make direct backlog catch-up unsafe and make the ADB semantic-model pattern a poor fit. | Pre-prod clone ready; each flow/query completes under 60 seconds; rollback owner and backfill plan approved. |
| Lagrange | Treat as fallback/modernization path pending PoC. | Vendor docs show the pieces are plausible, but the risky part is connector TLS/DNS behavior across the Power Platform gateway/proxy path. | Successful encrypted PostgreSQL connection through the intended network path with certificate validation and no direct public DB exposure. |

## Confirmed Facts And Vendor Constraints

Internal notes establish that RB9 connectivity was severed, OJB has a backlog beginning May 21, 2026, and OMTI enforces a non-negotiable 60-second query execution limit. OJB uses a CDC-like pattern that first identifies changed records and then updates in small batches, reported as 15 to 20 items. ADB is less real-time and can use a scheduled semantic model if SharePoint overrides carry immediate user changes.

Microsoft's PostgreSQL connector is Premium for Power Apps and Power Automate, uses server/database/basic credential/gateway parameters, has an "Encrypt Connection" option, and documents 300 API calls per connection per 60 seconds. The connector docs also call out order/pagination caveats for deterministic result handling. Source: [PostgreSQL connector](https://learn.microsoft.com/en-us/connectors/postgresql/).

The on-premises data gateway supports Power Apps, Power Automate, and Power BI. Microsoft documents that it initiates outbound cloud connections and does not require inbound ports. Gateway limits relevant to this investigation include a 2-MB request limit, 8-MB compressed read response limit, 2-MB write payload limit, 2048-character GET URL limit, credential caching behavior, and a 1,000-data-source limit per gateway cluster. Sources: [gateway overview](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-onprem), [gateway communication settings](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-communication).

Power Automate request limits matter for any high-volume polling or backfill. Microsoft counts connector calls, built-in actions, failed actions, retries, and pagination as requests. Current official limits include 40,000 requests per 24 hours for Power Automate Premium user-owned flows, 250,000 per 24 hours for Process/per-flow licensed flows, and a five-minute limit of 100,000 requests. Source: [Power Platform request limits](https://learn.microsoft.com/en-us/power-platform/admin/api-request-limits-allocations).

Power BI scheduled refresh can support the ADB pattern, but it is not a real-time guarantee. Microsoft documents up to 8 scheduled refreshes per day for Pro and up to 48 per day for PPU/Premium/Fabric capacity. Refresh is targeted to start within 15 minutes of the scheduled slot, but can be delayed up to one hour. Power BI disables scheduled refresh after four consecutive failures or certain unrecoverable configuration errors. Source: [scheduled refresh](https://learn.microsoft.com/en-us/power-bi/connect-data/refresh-scheduled-refresh).

SharePoint remains a scaling constraint for OJB. Microsoft documents a 5,000-item list view threshold and Power Apps delegation limitations for SharePoint. The SharePoint connector's "Get items" action supports OData filter/order/top and can limit columns by view to avoid column threshold issues. Sources: [SharePoint list threshold](https://learn.microsoft.com/en-us/troubleshoot/sharepoint/lists-and-libraries/items-exceeds-list-view-threshold), [Power Apps SharePoint delegation](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/connections/connection-sharepoint-online), [SharePoint connector](https://learn.microsoft.com/en-us/connectors/sharepointonline/).

AWS Network Load Balancer can support TCP or TLS listeners. A TLS listener terminates TLS at the load balancer; a TCP listener can pass encrypted traffic through to the target. AWS documents that NLB TLS listeners do not support mutual TLS. Source: [NLB listeners](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html).

AWS PrivateLink can expose a service through an endpoint service backed by a Network Load Balancer, with optional private DNS for consumers. This is relevant if Power Platform traffic must reach AWS through controlled network paths rather than a public database endpoint. Source: [AWS PrivateLink endpoint services](https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-share-your-services.html).

RDS and Aurora PostgreSQL support TLS. AWS documents that certificate verification requires the RDS CA bundle, and RDS/Aurora PostgreSQL certificates include the DB endpoint or cluster endpoint as the certificate common name when verification is enabled. `sslmode=verify-full` therefore makes DNS name alignment a first-class design constraint. Sources: [RDS TLS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html), [RDS PostgreSQL SSL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.SSL.html), [Aurora PostgreSQL security](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Security.html).

## Track Findings

### ADB

Recommendation: Continue the semantic model approach. The immediate operational gap should be handled through a SharePoint override list that the PowerApp reads with higher precedence than semantic model data.

Acceptance criteria:

- Semantic model fields match the legacy `VQM jobs` and `VQM jobs tests` shapes needed by ADB.
- Refresh cadence is explicitly documented, including owner, schedule, expected delay, and failure alerting.
- Overrides persist across refreshes and take precedence in the UI.
- Cleanup/reconciliation rule is approved so stale overrides do not survive indefinitely.

Main residual risk: ADB will intentionally show stale source data between refreshes. The mitigation is making override behavior visible, auditable, and reconciled.

### OJB

Recommendation: Use Plan A, but only behind an explicit readiness gate. OJB should not run a full historical catch-up against RB9. Advance the high-water mark to the approved restoration timestamp, restore forward-looking delta polling first, and treat the skipped period as a separate controlled backfill.

Default reconnection thresholds to approve or revise:

- Pre-prod query segments must complete in 45 seconds or less to leave buffer below the OMTI 60-second limit.
- Production cutover pauses after any query reaches 55 seconds, any hard timeout occurs, or database-side rejection/error rate exceeds the agreed monitoring threshold.
- Plan B review triggers after two repeated timeout cycles on the same query shape, or after any OMTI/provider signal that the reconnection pattern is harming shared database stability.

Known internal dependency leads to verify:

- SharePoint lists: Operations Job Boards and Operations Job Boards Archive.
- Flow names: `PROTOTYPE - RB Dispatcher V2`, `OJB - Clean Up Cancelled Jobs`, `OJB Full Board Reconciliation RB Dispatcher`, `Full Board Reconciliation Tool`, `GEN - SP List Automate Create Columns`.
- Payload/config reference: `rbPayload.json` in the Orion/RB dispatcher area.

Main residual risk: high-water mark advancement creates a known data gap from May 21, 2026 through the restoration timestamp. This must be accepted by Ops and paired with a backfill plan.

### Lagrange/AWS/Postgres

Recommendation: Keep as Plan B until the team proves the connector path, network path, and certificate story. The likely hard parts are not PostgreSQL itself; they are TLS verification, gateway/proxy routing, DNS identity, and security boundaries.

Minimum PoC:

- Power Platform PostgreSQL connection created through the intended gateway/network route.
- Encryption enabled and server identity validation behavior documented.
- DNS name used by Power Platform matches the database/proxy certificate strategy.
- AWS path avoids direct public database exposure.
- Least-privilege database user can read the required views/tables only.
- Connection observes expected connector/request throttles under representative load.

Open architecture decision: choose one endorsed connection pattern after PoC:

- Gateway host with private line-of-sight to AWS Postgres/proxy.
- TCP pass-through via NLB where the backend certificate identity remains valid.
- TLS termination at an intermediate proxy/security appliance with a certificate identity Power Platform can validate.
- PrivateLink-backed service if both sides can support the required network placement.

## Decisions Needed

| Decision | Owner to confirm | Default recommendation |
| --- | --- | --- |
| OJB skipped-period backfill process | Gregg/Ops/Dustin | Restore forward-only first, then run a separate throttled backfill outside production peak hours. |
| OJB fallback trigger | Gregg/Eric/Dustin | Use the timeout thresholds in this memo unless OMTI supplies stricter limits. |
| ADB override cleanup rule | Jamie/Ops/Gregg | Expire override when source row catches up, job completes/cancels, or owner manually resolves. |
| Gateway capacity and ownership | Eric/Carl | Assign one gateway owner, one backup, and alert routing before production cutover. |
| Lagrange network pattern | Eric/Carl/Larry | Reject direct public database exposure; validate secure proxy/gateway path first. |
| Lagrange schema readiness | Larry | Confirm TST views/tables and least-privilege read role before connector PoC. |

## Security Notes

The source material contained credential-like values. They are not copied here. Treat any credential-like string shared in notes as exposed until proven otherwise, and rotate or invalidate it if it maps to a live system.

## Bottom Line

ADB can proceed as a tactical decoupling fix. OJB can proceed only with a staged, measured reconnection and explicit acceptance of the data gap. Lagrange is the right fallback to investigate, but it should not be used as an emergency pivot until TLS/DNS/gateway behavior is proven end to end.
