# SaySlate Private LM Studio Endpoint — Setup Agent Prompt

Paste everything below the line into an agent session running **on the machine that hosts LM Studio**.
The agent's Part A report is what SAYAI-06 needs. Part B stays with you: you type those values
directly into SaySlate yourself.

---

## Your task

Expose this machine's LM Studio server to my private Tailscale network as an HTTPS endpoint that a
Chrome extension (SaySlate) can call with a Bearer token. Verify it end to end, then report back in
the exact format at the bottom. Work in order, and stop and ask me whenever a step needs my hands
or my decision.

## Hard boundaries

1. **Private only.** Use Tailscale **Serve**. Never enable Tailscale **Funnel**, never open a
   router or firewall port, and never expose LM Studio on the LAN. Leave LM Studio's "serve on
   local network" setting off: Serve proxies from this machine to `localhost`.
2. **Never handle the token in the open.** Do not ask me to paste the LM Studio API token into
   chat. Do not print, log, echo, or write it to any file, and do not include it in your report.
   Read it only from the `LM_API_TOKEN` environment variable (see step 4).
3. **Do not overwrite existing configuration.** If `tailscale serve status` already shows a
   configuration on HTTPS port 443, or LM Studio is already serving on a port something else
   depends on, stop and tell me what you found before you change anything.
4. **Change only what this task needs.** Do not touch SaySlate, other Tailscale settings, ACLs,
   or LM Studio models beyond what the steps say. For every change you make, record it with the
   exact command that reverses it.
5. On Windows PowerShell, use `curl.exe` rather than `curl`, which is an alias for
   `Invoke-WebRequest`. Put JSON request bodies in a temporary file and send them with
   `--data @file`. Delete the file afterwards.

## What SaySlate will do with this endpoint (design the setup for this)

- It stores a base URL of the form `https://<device>.<tailnet>.ts.net/v1`. The URL must be HTTPS,
  with no query string, no fragment, and no credentials in it.
- **Test Connection** sends `GET <base>/models`, with `Authorization: Bearer <token>`, and has a
  **15-second** limit. It passes only if the **exact model ID** appears in the returned `data[].id`
  list.
- **Each AI pass** sends `POST <base>/chat/completions` with `Authorization: Bearer <token>` and has
  a **90-second** limit. The request carries
  `response_format: { type: "json_schema", json_schema: { name: "sayslate_result", strict: true, schema: {...} } }`
  and expects `choices[0].message.content` to be JSON of the form `{"text": "<result>"}`. If the
  server rejects the schema with HTTP 400 or 422, SaySlate retries once without it.
- The extension is granted host permission for exactly this origin, so **LM Studio CORS settings
  are not needed**.
- The browser runs on a different machine that is also in the tailnet.

## Steps

1. **Inventory (read-only).** Record the OS, `tailscale version` (1.52 or newer is required for
   the Serve syntax below), and `tailscale status`: logged in, this device's name, whether MagicDNS
   is working. Also record the LM Studio version (0.4.0 or newer is required for API tokens),
   `lms server status`, `lms ls`, `lms ps`, and the current `tailscale serve status`.
2. **Choose the model.** Show me the downloaded models and ask which one SaySlate should use. For
   structured output, recommend 7B parameters or larger; LM Studio notes smaller models may not
   support it. Load it with `lms load <model>` and record its **model ID exactly as
   `GET /v1/models` reports it**. That is the ID SaySlate must use.
3. **Keep the model ready.** The 15-second Test Connection limit fails if the model has to load
   first. Keep the chosen model loaded: check LM Studio's server settings for just-in-time loading
   and idle auto-unload, and report what they are set to. Make sure the LM Studio server is running
   on `localhost`, on the default port 1234 unless I tell you otherwise.
4. **Require an API token (my step).** Ask me to open **Developers → Server Settings** in LM Studio,
   turn on API-token authentication, and create a token under **Manage Tokens**. The token is shown
   only once; I'll store it in my password manager. For your verification, I'll make it available
   as the `LM_API_TOKEN` environment variable in your shell. If you cannot read that variable, give
   me the exact verification commands to run myself, and I'll report back only the HTTP status
   lines.
5. **Enable HTTPS on the tailnet (possibly my step).** Serve needs MagicDNS and HTTPS certificates
   enabled for the tailnet. If they aren't enabled, tell me exactly what to turn on in the Tailscale
   admin console, then continue.
6. **Start Serve.** Run `tailscale serve --bg --https=443 localhost:1234`, adjusting the port if
   step 3 used a different one. Confirm that `tailscale serve status` shows the HTTPS URL as
   tailnet-only, and that `tailscale funnel status` shows Funnel is not enabled. Rollback:
   `tailscale serve --https=443 off` (or `tailscale serve reset` if nothing else was configured).
7. **Verify.** Run every check below and record the HTTP status and outcome of each. Never show
   the token in commands you display to me; reference `LM_API_TOKEN`.

   | ID | From | Request | Expected |
   | --- | --- | --- | --- |
   | V1 | this machine | `GET http://127.0.0.1:1234/v1/models` with the token | 200, and the chosen model ID is listed |
   | V2 | this machine | the same request **without** the token | 401 or 403 (proves authentication is enforced) |
   | V3 | this machine | `GET https://<device>.<tailnet>.ts.net/v1/models` with the token | 200, and the model ID is listed |
   | V4 | this machine | V3 **without** the token | 401 or 403 |
   | V5 | this machine | `POST https://<device>.<tailnet>.ts.net/v1/chat/completions` with the token and the body below | 200; `choices[0].message.content` parses as JSON with a non-empty string `text`; record the elapsed seconds |
   | V6 | this machine | `tailscale funnel status`, and what LM Studio is listening on (`netstat` or equivalent) | Funnel off; LM Studio bound to loopback only |
   | V7 | **the Chrome machine** | V3, run there | 200. If you can't run on that machine, give me the one command to run there, and I'll report the status |

   V5 request body. It matches what SaySlate sends; keep `strict` as the boolean `true`:

   ```json
   {
     "model": "<MODEL_ID>",
     "messages": [{ "role": "user", "content": "Correct the grammar of this sentence and return only the corrected sentence: this are a simple test sentence." }],
     "response_format": {
       "type": "json_schema",
       "json_schema": {
         "name": "sayslate_result",
         "strict": true,
         "schema": {
           "type": "object",
           "properties": { "text": { "type": "string" } },
           "required": ["text"],
           "additionalProperties": false
         }
       }
     }
   }
   ```

   If V5 returns 400 or 422 or content that isn't valid JSON, rerun it once without
   `response_format` and record both results. SaySlate would fall back to plain text for this
   model, and I need to know that.
8. **Survives a restart (report only).** Tell me whether the Serve configuration and the LM Studio
   server will come back after a reboot, and what would need enabling for that. Don't enable
   anything I haven't approved.

## Report format — return exactly these two parts

### Part A — paste-back report (non-secret; safe to share)

```md
## SaySlate private endpoint readiness
- Date/time (UTC):
- Host OS:
- Tailscale version:            | Serve syntax 1.52+: yes/no
- LM Studio version:            | API tokens (0.4.0+): yes/no
- Base URL shape: https://<redacted>.ts.net/v1   (the real value is in Part B only)
- Model ID (exact, as listed by /v1/models):
- Model size / format (GGUF or MLX) / context length:
- Model kept loaded: yes/no — JIT loading: on/off — idle auto-unload:
- API-token authentication enforced: yes/no
- Funnel: off (confirmed by `tailscale funnel status`)
- LM Studio listening on: loopback only / other:
- Serve survives reboot: yes/no/unknown — LM Studio server survives reboot: yes/no/unknown

| Check | HTTP status | Result |
| --- | --- | --- |
| V1 local models + token | | |
| V2 local models, no token | | |
| V3 tailnet models + token | | |
| V4 tailnet models, no token | | |
| V5 structured chat + token | | parsed {text}: yes/no — elapsed: s |
| V5b plain chat (only if V5 failed) | | |
| V6 exposure | — | |
| V7 from Chrome machine | | |

- Changes made (each with its rollback command):
- Open issues or anything you could not verify:
```

### Part B — private values (for me only; never saved to a file)

- The full base URL to enter in SaySlate: `https://<device>.<tailnet>.ts.net/v1`
- A reminder that the token is the one I created in step 4. Do **not** repeat it.
