# Callisto Local — Quickstart (drop-in, one shot)

**Purpose:** copy one block, run it in **Git Bash**, and Callisto is up. No port-chasing, no guessing. Every command here was verified end-to-end on 2026-07-16.

> **The port truth (read once, never chase again):** `src/main.ts` binds `process.env.APP_PORT || 3001`. `process.env.APP_PORT` is populated from **`.env`** (not `.env.local`). The repo ships `.env.sample` with `APP_PORT=3004`, so **the out-of-box canonical port is `3004`.** If `.env` and `.env.local` disagree, `.env` wins for the listen port — that mismatch is the #1 source of "why is it on a different port" confusion. The block below writes the port into **both** files **and** Atlas so they can never drift.

---

## 1. Full setup — after a fresh `git pull` / new branch (copy ALL, run in Git Bash)

```bash
# ============================================================
#  Callisto local — full setup (Git Bash)
#  Set two things at the top, then run the whole block.
# ============================================================
export GITHUB_TOKEN=<your-PAT>     # must be SSO-authorized for the planetdepos org
PORT=3004                          # the ONE port knob — everything below follows it

cd /c/Users/dustin.thomason/callisto-back-end

# --- deps (needed after a fresh pull or if node_modules is broken) ---
npm ci

# --- infra: start the shared local containers (they persist data + RabbitMQ vhosts) ---
docker start callisto-postgres callisto-rabbitmq
#   First-ever machine only (containers don't exist yet) — run these once instead:
#   docker run -d --name callisto-postgres -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=callisto -p 5432:5432 postgres:16
#   docker run -d --name callisto-rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
#   (then create the nova + callisto vhosts in the RabbitMQ UI at http://localhost:15672, guest/guest)

# --- pin the port in BOTH callisto env files AND Atlas (kills all drift) ---
for f in .env .env.local; do
  if grep -qE '^APP_PORT=' "$f"; then sed -i "s/^APP_PORT=.*/APP_PORT=$PORT/" "$f"; else echo "APP_PORT=$PORT" >> "$f"; fi
done
ATLAS=/c/Users/dustin.thomason/atlas-front-end/.env.local
sed -i '/CALLISTO_API_URL/d' "$ATLAS"
echo "CALLISTO_API_URL=http://localhost:$PORT" >> "$ATLAS"

# --- reset the local DB clean  ⚠ DESTRUCTIVE: wipes local Callisto data ---
#     (fixes "migration says applied but table missing/empty" inconsistencies)
docker exec callisto-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS callisto WITH (FORCE);"
docker exec callisto-postgres psql -U postgres -d postgres -c "CREATE DATABASE callisto;"
docker exec callisto-postgres psql -U postgres -d callisto  -c "CREATE SCHEMA IF NOT EXISTS callisto;"

# --- free the port (reliable on Windows Git Bash; pkill -f does NOT work here) ---
netstat -ano | grep -E ":$PORT .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
sleep 1

# --- start the API (migrations run automatically on boot) ---
NODE_ENV=local nohup npm run start:dev > /tmp/callisto.log 2>&1 &

# --- wait for boot, then health-check the SAME port ---
sleep 50 && curl.exe http://localhost:$PORT/callisto/health
```

Expected final line: `{"status":"ok",...}`.

---

## 2. Daily start — already set up, just bring it up

```bash
cd /c/Users/dustin.thomason/callisto-back-end
PORT=$(grep -E '^APP_PORT=' .env | cut -d= -f2 | tr -d '[:space:]')   # read the real port from .env
docker start callisto-postgres callisto-rabbitmq
netstat -ano | grep -E ":$PORT .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
sleep 1
NODE_ENV=local nohup npm run start:dev > /tmp/callisto.log 2>&1 &
sleep 50 && curl.exe http://localhost:$PORT/callisto/health
```

## 3. Watch logs / stop the server

```bash
tail -f /tmp/callisto.log     # watch (Ctrl+C stops watching, not the server)
# stop the server (port-scoped):
PORT=$(grep -E '^APP_PORT=' .env | cut -d= -f2 | tr -d '[:space:]')
netstat -ano | grep -E ":$PORT .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F; done
```

## 4. Start Atlas (front-end)

```bash
cd /c/Users/dustin.thomason/atlas-front-end
npm run dev:local     # UI on http://localhost:9000, proxies to Callisto on the port set above
```

---

## Verify URLs (replace 3004 if you changed `PORT`)

| Check   | URL                                          |
| ------- | -------------------------------------------- |
| Health  | `http://localhost:3004/callisto/health`      |
| Swagger | `http://localhost:3004/callisto/swagger`     |
| Atlas   | `http://localhost:9000`                      |
| RabbitMQ UI | `http://localhost:15672` (guest/guest)   |

## DBeaver (local Postgres)

| Field | Value |
| ----- | ----- |
| Host / Port | `localhost` / `5432` |
| Database | `callisto` |
| Username / Password | `postgres` / `postgres` |
| Default schema | `callisto` (else run `SET search_path TO callisto, public;`) |

---

## Troubleshooting (every failure hit while writing this doc)

| Symptom | Cause / Fix |
| ------- | ----------- |
| App runs on a port you didn't expect | `APP_PORT` in **`.env`** drives it (not `.env.local`). Run the pin step in §1, or `grep ^APP_PORT= .env`. |
| `401 Unauthorized` on `npm ci` | `GITHUB_TOKEN` not set in the shell — `export GITHUB_TOKEN=<PAT>` in the same Git Bash session. |
| `403 ... SAML enforcement` on install | PAT works but isn't SSO-authorized: GitHub → Settings → Developer settings → PAT → **Configure SSO → authorize `planetdepos`**. |
| `could not determine executable to run` / `nest` not found | Dev deps missing — rerun `npm ci` (do **not** pass `--omit=dev`). |
| `'rm' is not recognized` | You ran `npm run start:dev` in **PowerShell/cmd**. Use **Git Bash** (the script uses `rm -rf dist`). |
| `EADDRINUSE ... :PORT` | A previous server is still bound. Run the port-scoped kill in §3 (`pkill -f "nest start"` does **not** work on Windows). |
| `Cannot seed ... "MP4 Video" ... not found` / migration crash on boot | Inconsistent local DB (history says applied, tables missing). Run the DB reset in §1. |
| Atlas can't reach Callisto | `CALLISTO_API_URL` in `atlas-front-end/.env.local` must equal `http://localhost:<APP_PORT>`. The §1 block sets this automatically. |
| RabbitMQ `broker (nova)/(callisto)` connection failed | Start `callisto-rabbitmq` and confirm `nova`+`callisto` vhosts exist (`docker exec callisto-rabbitmq rabbitmqctl list_vhosts`). They persist across `docker start`. |

## Related

- [callisto-local.mdc](./callisto-local.mdc) — longer-form runbook (migrations CLI, seed data, per-repo notes)
