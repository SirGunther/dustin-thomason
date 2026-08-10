# RabbitMQ Configuration Request Template

Use this template when requesting new queues, exchanges, bindings, or cross-vhost permissions for RabbitMQ topology.

**Where topology lives depends on the environment:**

| Env | Broker | Topology file |
|-----|--------|---------------|
| **sb** | Local to each landscape | `{repo}/{landscape}-sb/us-east-1/rabbitmq/rabbitmq-topology/terragrunt.hcl` |
| **dev/tst/prod** | Centralized in pd-helios | `pd-helios/pd-helios-{env}/us-east-1/rabbitmq/rabbitmq-topology/terragrunt.hcl` |

**Sandbox:** each application landscape has its **own** RabbitMQ in its `*-sb` account (e.g. `pdpd-saturn-sb`, `pdpd-nebula-sb`, `pdpd-neptune-sb`). No VPC Lattice; apps use the direct broker endpoint.

**Dev/tst/prod:** all landscapes share the **centralized** broker in **pd-helios**. Consumer landscapes connect via VPC Lattice (see [AWS-VPC_Lattice.md](./AWS-VPC_Lattice.md)).

When promoting config from sb to shared envs, apply the same topology change in both the landscape sb stack **and** the matching pd-helios env.

---

## Copy-paste request block (standard pattern)

**How to use:** Fill in the block below, then copy the **entire block** and paste it into your request.

- For **sb**: say *"Apply this RabbitMQ config request to `rabbitmq-topology/terragrunt.hcl` in `{landscape}-sb`."*
- For **dev/tst/prod**: say *"Apply this RabbitMQ config request to `rabbitmq-topology/terragrunt.hcl` in pd-helios-{env}."*

```
--- BEGIN RABBITMQ CONFIG REQUEST ---
# Required: sb | dev | tst | prod
target_env: 

# Required when target_env is sb (e.g. pdpd-saturn-sb, pdpd-nebula-sb, pdpd-neptune-sb)
# Omit when target_env is dev, tst, or prod
landscape_account: 

# Required (standard event queues: main + retry + DLQ per action)
entity: 
consumer: 
publisher_vhost: 
actions: 

# Required if consumer reads from another vhost (e.g. dione reading from callisto)
update_cross_vhost_pattern: 

# Optional: only if adding a new application/vhost
# new_application: 

# Optional: retry delay in ms (default 60000 = 1 minute)
# retry_ttl_ms: 60000

# Optional: short note for the change
# note: 
--- END RABBITMQ CONFIG REQUEST ---
```

**Field rules:**

| Field | Example | Notes |
|-------|--------|--------|
| `target_env` | `sb` or `dev` | `sb` = local landscape broker; `dev`/`tst`/`prod` = centralized pd-helios broker |
| `landscape_account` | `pdpd-saturn-sb` | Required for `target_env: sb`. The `*-sb` folder/account where topology is applied |
| `entity` | `document` | Lowercase, singular. Used in queue names: `{consumer}.{entity}.{action}.v1` |
| `consumer` | `dione` | App that consumes (must exist: callisto, dione, triton, europa, nova, mercury) |
| `publisher_vhost` | `callisto` | Vhost where events are published (callisto.events lives here) |
| `actions` | `created, updated` or `created, updated, deleted` | Comma-separated; one of created, updated, deleted (or same pattern for custom) |
| `update_cross_vhost_pattern` | `yes` or `no` | Use `yes` if consumer is in a different vhost and must read these queues |

**Filled example (sb):**

```
--- BEGIN RABBITMQ CONFIG REQUEST ---
target_env: sb
landscape_account: pdpd-saturn-sb
entity: document
consumer: dione
publisher_vhost: callisto
actions: created, updated
update_cross_vhost_pattern: yes
--- END RABBITMQ CONFIG REQUEST ---
```

**Filled example (dev — centralized):**

```
--- BEGIN RABBITMQ CONFIG REQUEST ---
target_env: dev
entity: document
consumer: dione
publisher_vhost: callisto
actions: created, updated
update_cross_vhost_pattern: yes
--- END RABBITMQ CONFIG REQUEST ---
```

---

## 1. Request summary

| Field | Value |
|-------|--------|
| **Requester** | (your name or team) |
| **Date** | (YYYY-MM-DD) |
| **Environment** | `sb` (local landscape broker) or `dev` / `tst` / `prod` (centralized pd-helios broker) |
| **Landscape account** | Required for sb: e.g. `pdpd-saturn-sb`, `pdpd-nebula-sb`, `pdpd-neptune-sb` |
| **Brief description** | One-line summary of what you need |

---

## 2. Applications (only if adding a new app/vhost)

Existing apps in topology: `callisto`, `dione`, `triton`, `europa`, `nova`, `mercury`.

- [ ] I need a **new application** (new vhost + service account).
- **Application name:** `________________` (lowercase, used as vhost and in queue names).

If you only need new queues/bindings for an existing app, skip this section.

---

## 3. Event / entity and consumer

Describe the **domain entity** and **which app consumes** the events (following the pattern e.g. job, case, proceeding, contact).

| Field | Value |
|-------|--------|
| **Entity name** | e.g. `document`, `assignment`, `contact` (lowercase, singular) |
| **Consumer application** | e.g. `dione` (the app that will consume from the queues) |
| **Publisher / source vhost** | e.g. `callisto` (where events are published; usually where `callisto.events` lives) |

---

## 4. Event actions

Which lifecycle events do you need? For each, we create: **main queue**, **retry queue**, and **DLQ**, plus bindings.

- [ ] **created**
- [ ] **updated**
- [ ] **deleted**
- [ ] **Other:** `________________` (e.g. `published`, `archived`)

**Resulting queue names** (for your reference; infra will create these):

- Main: `{consumer}.{entity}.{action}.v1`
  e.g. `dione.document.created.v1`
- Retry: `{consumer}.{entity}.{action}.retry.1m`
  e.g. `dione.document.created.retry.1m`
- DLQ: `{consumer}.{entity}.{action}.dlq`
  e.g. `dione.document.created.dlq`

---

## 5. Exchanges (only if you need a new exchange)

Existing: `callisto.events` (topic), `callisto.events.dlx` (topic, for retry/DLQ).

- [ ] I need a **new exchange** (if not using `callisto.events` / `callisto.events.dlx`).

| Field | Value |
|-------|--------|
| **Exchange name** | e.g. `callisto.events` or `myapp.commands` |
| **Vhost** | e.g. `callisto` |
| **Type** | `topic` / `direct` / `fanout` |
| **Durable** | `true` / `false` |
| **Auto-delete** | `true` / `false` |

---

## 6. Queues (standard event pattern)

For the **standard pattern** (main + retry + DLQ with 1m retry), we only need the **entity** and **actions** from sections 3–4. The following is for **custom** queue needs (e.g. no retry, different TTL, different name).

- [ ] I need **custom queue settings** (different from the standard main/retry/dlq pattern).

| Queue purpose | Name | Vhost | Durable | Auto-delete | Special arguments (e.g. TTL, DLX) |
|---------------|------|--------|---------|-------------|------------------------------------|
| Main          |      |        |         |             |                                    |
| Retry         |      |        |         |             |                                    |
| DLQ           |      |        |         |             |                                    |

**Retry delay:** Default is **1 minute** (60000 ms). If you need a different delay: `______` ms.

---

## 7. Bindings (routing keys)

For the **standard pattern**, routing keys follow:

- **From main exchange to main queue:**
  `callisto.{entity}.{action}.v1` and `{consumer}.{entity}.{action}.v1`
  e.g. `callisto.document.created.v1`, `dione.document.created.v1`
- **From DLX to retry queue:**
  `{consumer}.{entity}.{action}.retry.1m`
- **From DLX to DLQ:**
  `{consumer}.{entity}.{action}.dlq`

- [ ] I need **different routing keys** or **extra bindings** (e.g. additional keys or another exchange).

| Source exchange | Destination (queue name) | Routing key(s) |
|----------------|---------------------------|----------------|
|                |                           |                |

---

## 8. Cross-vhost permissions

If the **consumer** runs in a different vhost and must **read** from the **publisher’s vhost** (e.g. dione reading from callisto), we need a cross-vhost permission entry.

- [ ] I need **cross-vhost read** (consumer app can consume from another vhost’s queues).

| Field | Value |
|-------|--------|
| **Source app** (consumer) | e.g. `dione` |
| **Target vhost** (where queues live) | e.g. `callisto` |
| **Queue name pattern** (regex) | e.g. `dione\.(job\|case\|document)\..*` |

Current cross-vhost entries in pd-helios-dev include:

| Consumer | Publisher vhost | Read pattern |
|----------|-----------------|--------------|
| `dione` | `callisto` | `dione\\..*` |
| `nova` | `callisto` | `nova\\..*` |
| `mercury` | `callisto` | `mercury\\..*` |
| `callisto` | `nova` | `callisto\\..*` |
| `callisto` | `mercury` | `callisto\\..*` |

If you add a **new consumer vhost** reading from an existing publisher, a new `cross_vhost_permissions` entry is required. If the consumer already has a wildcard pattern (e.g. `dione\\..*`), new entities under that prefix do not need a pattern change.

Legacy example (entity-specific pattern):

`dione\\.(job|case|proceeding|contact|document)\\..*`

---

## 9. Checklist before submitting

- [ ] Target environment is specified (`target_env`: sb, dev, tst, or prod).
- [ ] For sb: `landscape_account` is filled in (e.g. `pdpd-saturn-sb`).
- [ ] For dev/tst/prod: change will be applied to matching `pd-helios-{env}` topology.
- [ ] Entity name is lowercase, singular (e.g. `document`, not `Documents`).
- [ ] Consumer and publisher apps are existing applications (or section 2 is filled for a new app).
- [ ] Actions (created/updated/deleted) are listed in section 4.
- [ ] If using standard pattern: only sections 1–4 and 8 (if cross-vhost) are required; 5–7 only for custom exchanges/queues/bindings.
- [ ] Cross-vhost pattern (section 8) includes the new entity if the consumer is in a different vhost.

---

## 10. Example: “Document created/updated” for Dione

- **Entity:** `document`
- **Consumer:** `dione`
- **Publisher vhost:** `callisto`
- **Actions:** created, updated

**Queues to add:**
`dione.document.created.v1`, `dione.document.created.retry.1m`, `dione.document.created.dlq`,
`dione.document.updated.v1`, `dione.document.updated.retry.1m`, `dione.document.updated.dlq`

**Bindings:**
From `callisto.events` to each main queue with routing keys
`callisto.document.created.v1` / `dione.document.created.v1` and
`callisto.document.updated.v1` / `dione.document.updated.v1`;
from `callisto.events.dlx` to the corresponding retry and DLQ queues.

**Cross-vhost:**
No change needed; read pattern `dione\\..*` already allows all queues whose names start with `dione.`.

---

## 11. Where changes are applied

| What | Sandbox (sb) | Dev/tst/prod |
|------|--------------|--------------|
| **Topology** | `{landscape}-sb/us-east-1/rabbitmq/rabbitmq-topology/terragrunt.hcl` | `pd-helios/pd-helios-{env}/us-east-1/rabbitmq/rabbitmq-topology/terragrunt.hcl` |
| **Broker** | `{landscape}-sb/us-east-1/rabbitmq/rabbitmq-broker/terragrunt.hcl` | `pd-helios/pd-helios-{env}/us-east-1/rabbitmq/rabbitmq-broker/terragrunt.hcl` |
| **Lattice exposure** | N/A (not used in sb) | `pd-helios/pd-helios-{env}/us-east-1/rabbitmq/rabbitmq-lattice/terragrunt.hcl` |
| **MQ endpoint** (SSM) | Direct broker endpoint from local `rabbitmq-broker` | Consumer landscape `ssm_param` (Lattice DNS from pd-helios `rabbitmq-lattice` output) |

Known sb landscapes with local RabbitMQ: **pdpd-saturn-sb**, **pdpd-nebula-sb**, **pdpd-neptune-sb** (same stack pattern in each).

After topology apply, export application credentials if needed:

```bash
# sb example
cd pdpd-saturn/pdpd-saturn-sb/us-east-1/rabbitmq/rabbitmq-topology
./export-credentials.sh

# centralized dev example
cd pd-helios/pd-helios-dev/us-east-1/rabbitmq/rabbitmq-topology
./export-credentials.sh json
```

Broker admin password (required for topology apply):

```bash
export TF_VAR_rabbitmq_admin_password="your-secure-password"
```

---

*References:*
- *Sandbox:* `pdpd-saturn/pdpd-saturn-sb/us-east-1/rabbitmq/rabbitmq-topology/terragrunt.hcl`
- *Centralized dev:* `pd-helios/pd-helios-dev/us-east-1/rabbitmq/rabbitmq-topology/terragrunt.hcl`
