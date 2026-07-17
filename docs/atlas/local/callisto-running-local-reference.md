Created by Dustin Thomason
Created on 07/16/26

## Decisions log

### 2026-07-16 — AWS credential env vars: lowercase names are valid on Windows (leave as-is)

- `callisto-back-end/.env.local` carries AWS creds as `aws_access_key_id` / `aws_secret_access_key` (lowercase), pasted directly from AWS.
- **Decision (Dustin):** leave them lowercase — this works and has been used this way before. On Windows, Node's `process.env` is case-insensitive, so the AWS SDK resolves them regardless of case. Do **not** "fix" the casing.
- One exception already applied: `AWS_SESSION_TOKEN` (line 38) is uppercase because that line was rewritten while repairing an unrelated corruption (an agent append had glued `INBOX_ENABLED=true` onto the token value; the token was restored and the flag moved to its own line). Mixed casing in this file is expected and fine.
- Related caution for agents: **never append to `.env.local` blindly** — the file may lack a trailing newline; a bare `>>` append corrupts the last line. Verify the tail of the file first, and only with explicit permission.