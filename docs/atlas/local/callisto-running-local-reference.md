Created by Dustin Thomason
Created on 07/16/26

## Decisions log

### 2026-07-16 — AWS credential env vars: lowercase names are valid on Windows (leave as-is)

- `callisto-back-end/.env.local` carries AWS creds as `aws_access_key_id` / `aws_secret_access_key` (lowercase), pasted directly from AWS.
- **Decision (Dustin):** leave them lowercase — this works and has been used this way before. On Windows, Node's `process.env` is case-insensitive, so the AWS SDK resolves them regardless of case. Do **not** "fix" the casing.
- One exception already applied: `AWS_SESSION_TOKEN` (line 38) is uppercase because that line was rewritten while repairing an unrelated corruption (an agent append had glued `INBOX_ENABLED=true` onto the token value; the token was restored and the flag moved to its own line). Mixed casing in this file is expected and fine.
- Related caution for agents: **never append to `.env.local` blindly** — the file may lack a trailing newline; a bare `>>` append corrupts the last line. Verify the tail of the file first, and only with explicit permission.

### 2026-07-16 — "Local" is NOT fully local: S3 is always REAL sandbox AWS

- Local runs use local Postgres + local RabbitMQ, but **every file operation hits real AWS S3** — there is no local S3 emulator in this repo (no localstack/minio).
- Uploads from local Atlas → local Callisto create **real objects in `s3-callisto-sb-ue1-jobs`** (the `S3_JOBS` bucket). Downloads and the video-transcode handler's copy step are equally real.
- Consequence: "failed to upload file" locally is an **AWS credential failure first** — check creds before anything else.
- **Azure tokens ≠ AWS credentials.** The Azure/Entra login (Atlas SSO, ~24 h) has nothing to do with S3. S3 uses the AWS keys in `callisto-back-end/.env.local` (`aws_access_key_id` / `aws_secret_access_key` / `AWS_SESSION_TOKEN` from Planet Portal); those session tokens expire on their own, much shorter schedule.
- Env values load **only at boot** — repairing/refreshing creds in `.env.local` does nothing to an already-running server until it restarts.

### 2026-07-16 — How to find & kill a process on a port (Git Bash, self-serve)

```bash
# 1. What's on the port? (LAST number in the output = the PID; no output = nothing running)
netstat -ano | grep ":3004" | grep LISTENING

# 2. Kill that PID (double slashes required in Git Bash)
taskkill //PID <pid> //F
#    SUCCESS ... terminated  = dead now
#    ERROR ... not found     = was ALREADY dead — fine, just start the server

# 3. Verify (should print nothing)
netstat -ano | grep ":3004" | grep LISTENING
```

- See what a PID is before killing: `tasklist //FI "PID eq <pid>"`
- Server started in a visible terminal? **Ctrl+C there** is the normal stop — PID hunting is only for background servers.
- PIDs change every restart — always re-run step 1; never reuse an old PID.
- PowerShell syntax differs: `taskkill /PID <pid> /F` (single slashes); `Get-NetTCPConnection -LocalPort 3004` instead of netstat/grep.
- Ports: **3004** Callisto · **9000** Atlas · **5432** Postgres · **5672/15672** RabbitMQ. The last three are Docker containers — `docker stop callisto-postgres callisto-rabbitmq`, not taskkill.
- Start Callisto (foreground, logs visible): `cd /c/Users/dustin.thomason/callisto-back-end && NODE_ENV=local npm run start:dev` — healthy when the log prints `Application started`.

### 2026-07-16 — Upload-failure debugging: the full chain, as actually diagnosed

The single UI symptom "Failed to upload file (500)" had **three stacked causes**, each only visible after fixing the previous. Check them in this order:

1. **AWS creds expired** (`ExpiredToken` in server log) — Planet Portal session creds die in hours; Azure/Atlas login (24 h) is unrelated. Refresh from Planet Portal (SB account).
2. **Creds never reach the server.** The S3 clients are `new AWS.S3()` → they read the **AWS SDK default chain (shell env → `~/.aws/credentials`)**, NOT `.env.local`. Fix: export the three vars in the shell that starts the server (pull them from `.env.local` automatically):
   ```bash
   cd /c/Users/dustin.thomason/callisto-back-end
   export AWS_ACCESS_KEY_ID=$(grep -E "^aws_access_key_id=" .env.local | cut -d= -f2)
   export AWS_SECRET_ACCESS_KEY=$(grep -E "^aws_secret_access_key=" .env.local | cut -d= -f2)
   export AWS_SESSION_TOKEN=$(grep -E "^aws_session_token=" .env.local | cut -d= -f2)
   NODE_ENV=local npm run start:dev
   ```
3. **Wrong bucket name** (`NoSuchBucket` in server log) — `.env` shipped with placeholder buckets (`callisto-jobs`); `.env.local` has the real SB ones (`s3-callisto-sb-ue1-jobs`). **`.env` beats `.env.local`** (same precedence as APP_PORT). Fix: put the real SB bucket names in `.env`:
   `S3_CASES=s3-callisto-sb-ue1-cases` · `S3_JOBS=s3-callisto-sb-ue1-jobs`

Verification helpers (read-only, prove creds/bucket outside the app):
- `aws sts get-caller-identity` → whose creds these are + which account
- `aws s3api head-bucket --bucket s3-callisto-sb-ue1-jobs` → creds can reach the bucket
- The server-side truth for any upload failure is the `S3MultiPartUploadRepository` error line in the server terminal — the browser only ever shows the generic 500.