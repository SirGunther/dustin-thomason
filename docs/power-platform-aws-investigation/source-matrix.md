# Source Matrix

Status: Draft  
Prepared: 2026-07-06

## Source Inventory

| Source | Type | Facts used | Confidence | Follow-up |
| --- | --- | --- | --- | --- |
| Pasted `Power Platform to AWS` meeting note, 2026-06-15 | Internal meeting summary | ADB/OJB/Lagrange framing; OMTI 60-second query limit; OJB high-water mark strategy; ADB semantic model strategy; open questions and action items. | Medium | Validate against Otter transcript and owners. |
| Local WorkLists meeting records, 2026-06-16 through 2026-06-26 | Internal meeting leads | Follow-up sessions exist for RB9 reconnection, OJB/RB connection, OMTI strategy, Chris consult, ADB/OJB issues, and ADB semantic model refresh. | Medium | Pull transcripts or summaries before final memo. |
| Local WorkLists OJB notes | Internal implementation leads | Candidate OJB lists, archive list, RB Dispatcher flow names, reconciliation flow names, and payload reference. | Medium | Verify in Power Automate and SharePoint admin views. |
| Microsoft PostgreSQL connector docs | Vendor docs | Premium connector, gateway/credential/encrypt parameters, 300 calls per connection per 60 seconds, OData query parameters. | High | Test TLS and DNS behavior in tenant. |
| Microsoft on-premises data gateway docs | Vendor docs | Gateway requires outbound cloud connectivity, supports Power Apps/Automate/BI, no inbound ports, request/response limits, credential caching. | High | Confirm installed gateway version, region, admins, and network routes. |
| Microsoft gateway communication docs | Vendor docs | Azure Relay dependency, outbound port/FQDN requirements, diagnostics test, certificate revocation endpoint consideration. | High | Run gateway network ports test with IT. |
| Microsoft Power Platform request limit docs | Vendor docs | Flow actions, failed actions, retries, and pagination count against request limits; Premium and Process/per-flow limits. | High | Get current licenses for actual flow owners. |
| Microsoft Power Automate limits docs | Vendor docs | Flow performance profiles and owner-based behavior; flow definition and execution limits. | High | Confirm whether critical flows are solution-owned and correctly licensed. |
| Microsoft Power BI scheduled refresh docs | Vendor docs | Refresh frequency limits, start-time variability, four-failure disable behavior. | High | Confirm workspace capacity/license and alerting. |
| Microsoft SharePoint list threshold and connector docs | Vendor docs | 5,000-item list view threshold; SharePoint Get items filter/order/top and limit-columns-by-view behavior. | High | Confirm indexed columns, views, and list sizes. |
| AWS NLB listener docs | Vendor docs | TCP/TLS listener behavior, TLS offload, TCP pass-through, mTLS limitation on TLS listeners. | High | Decide whether Power Platform should see DB cert, proxy cert, or NLB cert. |
| AWS PrivateLink docs | Vendor docs | Endpoint service uses NLB, optional private DNS, AZ/resiliency considerations. | High | Validate whether Power Platform/gateway host can consume the endpoint path. |
| AWS RDS/Aurora PostgreSQL TLS docs | Vendor docs | RDS/Aurora support TLS; certificate verification requires CA trust; endpoint DNS identity matters for verify-full. | High | Test actual connector behavior with encrypted connection and certificate identity. |

## Internal Sources Still Needed

| Needed source | Why it matters | Owner candidate |
| --- | --- | --- |
| Power Automate export or screenshots for each ADB/OJB flow | Confirms triggers, recurrence, queries, concurrency, retries, timeout handling, and connection refs. | Dustin/Jamie |
| SharePoint list schema exports for ADB override and OJB working/archive lists | Confirms field types, indexed columns, list sizes, views, and delegation risks. | Dustin/Jamie/Ops |
| Gateway admin configuration | Confirms gateway version, cluster membership, data sources, admins, credentials, network placement, and logs. | Eric/Carl |
| OMTI/RB9 constraint statement | Confirms 60-second limit, acceptable reconnect cadence, and database-side monitoring. | Gregg/OMTI contact |
| Lagrange schema PR and TST deployment status | Confirms fallback target objects and read-only role readiness. | Larry |
| Power BI semantic model metadata | Confirms ADB schema parity, refresh schedule, owner, capacity, and failure history. | Chris/Justin/Dustin |

## Sanitization Notes

- Credential-like values were observed in source material and intentionally omitted.
- Private Power Automate, SharePoint, ClickUp, Otter, and Lucid URLs were used only as local leads and are not reproduced here.
- Before external sharing, review these artifacts for tenant names, internal flow names, and operational details.
