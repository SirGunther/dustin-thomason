# ============================================================
#  Callisto local — full setup (Git Bash)
#  Set two things at the top, then run the whole block.
# ============================================================
PORT=3004                          # the ONE port knob — everything below follows it

CALLISTO=/c/Users/dustin.thomason/callisto-back-end
ATLAS=/c/Users/dustin.thomason/atlas-front-end

# ---------- CALLISTO ----------
cd "$CALLISTO"
# npm ci                              # needs GITHUB_TOKEN in this shell
npm install

# infra: start if present, else create (this is the fix for "no such container")
docker start callisto-postgres 2>/dev/null || docker run -d --name callisto-postgres \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=callisto -p 5432:5432 postgres:16
docker start callisto-rabbitmq 2>/dev/null || docker run -d --name callisto-rabbitmq \
  -p 5672:5672 -p 15672:15672 rabbitmq:3-management
#   RabbitMQ vhosts (only when the broker starts cleanly — see troubleshooting if it crash-loops):
for i in $(seq 1 20); do docker exec callisto-rabbitmq rabbitmqctl await_startup >/dev/null 2>&1 && break; sleep 3; done
for vh in nova callisto; do
  docker exec callisto-rabbitmq rabbitmqctl add_vhost "$vh" 2>/dev/null
  docker exec callisto-rabbitmq rabbitmqctl set_permissions -p "$vh" guest ".*" ".*" ".*" 2>/dev/null
done
#   Broker topology Callisto EXPECTS to pre-exist (code uses createExchangeIfNotExists /
#   createQueueIfNotExists = false, i.e. passive checks only). Without these the app connects,
#   gets channel `not_found` errors, silently retries forever, and NEVER binds APP_PORT —
#   the log just stops after the "Registered handler ..." lines. rabbitmqadmin ships in the
#   management image, so no extra install:
for vh in nova callisto; do
  docker exec callisto-rabbitmq rabbitmqadmin -u guest -p guest -V "$vh" declare exchange name="$vh.events" type=topic durable=true
  docker exec callisto-rabbitmq rabbitmqadmin -u guest -p guest -V "$vh" declare exchange name="$vh.events.dlx" type=topic durable=true
done
for q in callisto.proceeding.file.video-transcode-completed.v1 callisto.notification.requested.v1; do
  docker exec callisto-rabbitmq rabbitmqadmin -u guest -p guest -V nova declare queue name="$q" durable=true
  docker exec callisto-rabbitmq rabbitmqadmin -u guest -p guest -V nova declare binding source=nova.events destination="$q" routing_key="$q"
done

# pin the port in BOTH callisto env files AND Atlas (kills all drift)
for f in "$CALLISTO/.env" "$CALLISTO/.env.local"; do
  if grep -qE '^APP_PORT=' "$f"; then sed -i "s/^APP_PORT=.*/APP_PORT=$PORT/" "$f"; else echo "APP_PORT=$PORT" >> "$f"; fi
done
sed -i '/CALLISTO_API_URL/d' "$ATLAS/.env.local"
echo "CALLISTO_API_URL=http://localhost:$PORT" >> "$ATLAS/.env.local"

# reset the local DB clean  ⚠ DESTRUCTIVE (wipes local Callisto data; fixes migration/schema inconsistencies)
docker exec callisto-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS callisto WITH (FORCE);"
docker exec callisto-postgres psql -U postgres -d postgres -c "CREATE DATABASE callisto;"
docker exec callisto-postgres psql -U postgres -d callisto  -c "CREATE SCHEMA IF NOT EXISTS callisto;"
docker exec callisto-postgres psql -U postgres -d callisto  -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" 

# free the port (reliable on Windows Git Bash; pkill -f does NOT work here), then start (migrations auto-run)
netstat -ano | grep -E ":$PORT .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
sleep 1

# kill whatever's on 3004
netstat -ano | grep -E ":3004 .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F; done

# start Callisto WITH the creds from .env.local injected into its shell
cd /c/Users/dustin.thomason/callisto-back-end
export AWS_ACCESS_KEY_ID=$(grep -E "^aws_access_key_id=" .env.local | cut -d= -f2)
export AWS_SECRET_ACCESS_KEY=$(grep -E "^aws_secret_access_key=" .env.local | cut -d= -f2)
export AWS_SESSION_TOKEN=$(grep -E "^aws_session_token=" .env.local | cut -d= -f2)
NODE_ENV=local nohup npm run start:dev > /tmp/callisto.log 2>&1 &

netstat -ano | grep -E ":9000 .*LISTENING" | awk '{print $5}' | sort -u \
  | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
tasklist //FI "IMAGENAME eq dart.exe" 2>/dev/null | grep -oE "^dart.exe +[0-9]+" \
  | awk '{print $2}' | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
sleep 2

# ---------- ATLAS ----------
cd "$ATLAS"
npm ci                              # also needs GITHUB_TOKEN (Atlas uses private @planetdepos packages)
nohup npm run dev:local > /tmp/atlas.log 2>&1 &

# ---------- verify both ----------
sleep 55
echo "=== Callisto health ($PORT) ==="; curl.exe -s "http://localhost:$PORT/callisto/health"; echo ""
echo "=== Atlas (9000) ==="; curl.exe -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:9000

# ---------- seed dev dataset (the data Atlas actually displays) ----------
# Migrations (auto-run on app boot) only seed REFERENCE data (roles, permissions, job types).
# Business data (cases, jobs, proceedings, contacts) comes from dev-dataset-reset/*.sql —
# see src/typeorm/dev-dataset-reset/README.md. Must run AFTER Callisto health is OK
# (migrations create the tables on first boot). Scripts are idempotent + schema-qualified.
for f in "$CALLISTO"/src/typeorm/dev-dataset-reset/*.sql; do
  docker exec -i callisto-postgres psql -U postgres -d callisto -v ON_ERROR_STOP=1 < "$f" >/dev/null
done
echo "seeded cases: $(docker exec callisto-postgres psql -U postgres -d callisto -tAc 'SELECT count(*) FROM callisto.cases')"
# optional: layer feature-specific data from src/typeorm/dev-dataset-usecases/ (see its README)

cd ~/callisto-back-end
docker exec callisto-postgres psql -U postgres -d callisto -c "ALTER TABLE callisto.proceedings ALTER COLUMN created_user_identity DROP NOT NULL; ALTER TABLE callisto.proceedings ALTER COLUMN modified_user_identity DROP NOT NULL;"
for f in src/typeorm/dev-dataset-reset/*.sql; do docker exec -i callisto-postgres psql -U postgres -d callisto < "$f"; done
docker exec callisto-postgres psql -U postgres -d callisto -c "UPDATE callisto.proceedings SET created_user_identity='system', modified_user_identity='system' WHERE created_user_identity IS NULL OR modified_user_identity IS NULL; ALTER TABLE callisto.proceedings ALTER COLUMN created_user_identity SET NOT NULL; ALTER TABLE callisto.proceedings ALTER COLUMN modified_user_identity SET NOT NULL;"

netstat -ano | grep ":3004" | awk '{print $5}' | sort -u \
  | while read pid; do taskkill //PID $pid //F; done; sleep 1; netstat -ano | grep ":3004" || echo CLEAR
cd "$CALLISTO"
npm run start:dev
