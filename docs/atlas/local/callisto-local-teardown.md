# Callisto + Atlas Local — Teardown (shut it all down)

**Purpose:** the exact inverse of [callisto-local-quickstart.md](./callisto-local-quickstart.md). Copy one block in **Git Bash** to bring everything down, then rebuild from the matching quickstart Part. Verified 2026-07-16 (the `docker rm` in Part 1 destroys containers, so it's documented, not re-run here).

**Pairing:** Teardown **Part 1** ↔ Quickstart **Part 1** (both "from/to nothing"). Teardown **Part 2** ↔ Quickstart **Part 2** (both keep containers).

---

## Part 1 — Full teardown (remove containers, wipe local DB + broker)

Proves you can rebuild from nothing. Deletes the Postgres and RabbitMQ containers and all their data.

```bash
# ============================================================
#  Callisto + Atlas — FULL teardown  ⚠ DESTROYS containers + local data
# ============================================================
CALLISTO=/c/Users/dustin.thomason/callisto-back-end
PORT=$(grep -E '^APP_PORT=' "$CALLISTO/.env" | cut -d= -f2 | tr -d '[:space:]')

# stop both servers: Callisto (APP_PORT) + Atlas (9000)
for p in "$PORT" 9000; do
  netstat -ano | grep -E ":$p .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
done

# remove the containers entirely
docker rm -f callisto-postgres callisto-rabbitmq

# (optional deepest clean — forces a fresh npm ci on rebuild)
# rm -rf "$CALLISTO/node_modules" /c/Users/dustin.thomason/atlas-front-end/node_modules
```

**Rebuild:** Quickstart **Part 1** (its `docker start || docker run` lines recreate the containers; the DB-reset step rebuilds the schema via migrations).

---

## Part 2 — Soft shutdown (stop everything, keep containers + data)

Normal stop/restart. Containers and DB data survive; rebuild is fast.

```bash
# ============================================================
#  Callisto + Atlas — SOFT shutdown (Git Bash)
# ============================================================
CALLISTO=/c/Users/dustin.thomason/callisto-back-end
PORT=$(grep -E '^APP_PORT=' "$CALLISTO/.env" | cut -d= -f2 | tr -d '[:space:]')

# stop both servers
for p in "$PORT" 9000; do
  netstat -ano | grep -E ":$p .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
done

# stop (not remove) the containers
docker stop callisto-postgres callisto-rabbitmq
```

**Rebuild:** Quickstart **Part 2** (containers just need `docker start`).

---

## Verify everything is down (run after either Part)

```bash
PORT=$(grep -E '^APP_PORT=' /c/Users/dustin.thomason/callisto-back-end/.env | cut -d= -f2 | tr -d '[:space:]')
echo "=== ports (all should say 'free') ==="
for p in "$PORT" 9000 5432 5672 15672; do
  c=$(netstat -ano | grep -E ":$p .*LISTENING")
  echo "port $p: $([ -z "$c" ] && echo free || echo IN-USE)"
done
echo "=== containers ==="
docker ps -a --filter "name=callisto-postgres" --filter "name=callisto-rabbitmq" --format "{{.Names}} {{.Status}}"
echo "(Part 1: nothing listed. Part 2: both 'Exited'.)"
```

## What persists

| Part | Servers | Containers | Local DB data | node_modules |
| ---- | ------- | ---------- | ------------- | ------------ |
| **1 — Full** | stopped | **removed** | **wiped** | kept (unless you `rm -rf`) |
| **2 — Soft** | stopped | kept (`Exited`) | kept | kept |

## The cycle you're practicing

```
Teardown Part 1/2  →  Quickstart Part 1/2  →  Callisto health OK + Atlas 200  →  repeat until trusted
```

Related: [callisto-local-quickstart.md](./callisto-local-quickstart.md) · [callisto-local.mdc](./callisto-local.mdc)
