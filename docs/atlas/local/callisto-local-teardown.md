# Callisto Local — Teardown (shut it all down)

**Purpose:** the exact inverse of [callisto-local-quickstart.md](./callisto-local-quickstart.md). Copy one block in **Git Bash** to bring everything down cleanly, then rebuild from the quickstart. Two tiers depending on how far down you want to go. Verified in **Git Bash** on 2026-07-16 (the **soft** tier was run end-to-end; the **full** tier's `docker rm` is documented but not executed here — it destroys the containers).

---

## Tier 1 — Soft shutdown (stop everything, keep containers + data)

Use this for a normal stop/restart. Containers and DB data survive; rebuild is fast.

```bash
# ============================================================
#  Callisto local — soft shutdown (Git Bash)
# ============================================================
cd /c/Users/dustin.thomason/callisto-back-end
PORT=$(grep -E '^APP_PORT=' .env | cut -d= -f2 | tr -d '[:space:]')

# stop the API (on APP_PORT) and Atlas (9000) — port-scoped kill, reliable on Windows
for p in "$PORT" 9000; do
  netstat -ano | grep -E ":$p .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
done

# stop the shared containers (data + RabbitMQ vhosts persist)
docker stop callisto-postgres callisto-rabbitmq
```

**Rebuild after Tier 1:** quickstart **§2 — Daily start** (containers just need `docker start`; no reinstall, no DB reset).

---

## Tier 2 — Full teardown (remove containers, wipe local DB + broker)

Use this to prove you can rebuild from nothing. Deletes the Postgres and RabbitMQ containers and everything in them.

```bash
# ============================================================
#  Callisto local — FULL teardown  ⚠ DESTROYS containers + all local data
# ============================================================
cd /c/Users/dustin.thomason/callisto-back-end
PORT=$(grep -E '^APP_PORT=' .env | cut -d= -f2 | tr -d '[:space:]')

# stop API + Atlas
for p in "$PORT" 9000; do
  netstat -ano | grep -E ":$p .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
done

# remove the containers entirely (‑f stops then deletes)
docker rm -f callisto-postgres callisto-rabbitmq

# (optional, deepest clean) also wipe installed deps:
# rm -rf node_modules
```

**Rebuild after Tier 2:** quickstart **§1 — Full setup**, and because the containers no longer exist you must run the **first-ever machine** `docker run` lines (create Postgres + RabbitMQ, then recreate the `nova` + `callisto` vhosts in the RabbitMQ UI). §1's DB-reset step then rebuilds the schema via migrations.

---

## Verify everything is down (run after either tier)

```bash
PORT=$(grep -E '^APP_PORT=' /c/Users/dustin.thomason/callisto-back-end/.env | cut -d= -f2 | tr -d '[:space:]')
echo "=== ports (all should say 'free') ==="
for p in "$PORT" 9000 5432 5672 15672; do
  c=$(netstat -ano | grep -E ":$p .*LISTENING")
  echo "port $p: $([ -z "$c" ] && echo free || echo IN-USE)"
done
echo "=== containers ==="
docker ps --filter "name=callisto-postgres" --filter "name=callisto-rabbitmq" --format "{{.Names}} {{.Status}}"
echo "(Tier 1: 'Exited'. Tier 2: nothing listed. empty port list = clean.)"
```

---

## What persists at each tier

| Tier | API/Atlas processes | Containers | Local DB data | node_modules |
| ---- | ------------------- | ---------- | ------------- | ------------ |
| **1 — Soft** | stopped | kept (`Exited`) | kept | kept |
| **2 — Full** | stopped | **removed** | **wiped** | kept (unless you `rm -rf node_modules`) |

## The full cycle you're practicing

```
Tear down (this doc)  →  Rebuild (quickstart §1 or §2)  →  health OK  →  repeat until trusted
```

Related: [callisto-local-quickstart.md](./callisto-local-quickstart.md) · [callisto-local.mdc](./callisto-local.mdc)
