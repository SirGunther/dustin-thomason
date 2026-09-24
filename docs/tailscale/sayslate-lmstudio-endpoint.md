# Tailscale: private LM Studio endpoint for SaySlate

The LM Studio server on the LM Studio host is reachable over HTTPS from other devices on my
tailnet, including the Chrome machine that runs SaySlate, and from nowhere else. Set up
2026-09-23 for the SaySlate AI provider ticket
(`docs/SaySlate/tickets/sayslate-ai-provider-tailscale/`).

Real hostnames and the tailnet name are **not** in this repo (it is public). They are kept in the
password manager next to the LM Studio token. Everywhere below, `<device>.<tailnet>.ts.net` is a
placeholder.

## How it fits together

```
Chrome machine (SaySlate)                 LM Studio host
  |                                         |
  |  HTTPS, tailnet only                    |
  +--> https://<device>.<tailnet>.ts.net ---+--> Tailscale Serve (:443)
         Authorization: Bearer <token>              |
                                                    +--> http://localhost:1234 (LM Studio, loopback only)
```

- **Tailscale Serve** terminates HTTPS with a tailnet certificate and proxies to `localhost:1234`.
- **Tailscale Funnel is off.** Funnel would publish the endpoint to the public internet.
- **LM Studio** listens on `127.0.0.1:1234` only. "Serve on local network" is off, so nothing is
  exposed on the LAN, and no router or firewall ports are open.
- **LM Studio API-token authentication is on.** Every request needs `Authorization: Bearer <token>`,
  including requests from localhost.
- LM Studio CORS is off and isn't needed: the SaySlate extension has host permission for the
  endpoint origin.

## Values SaySlate uses

| Setting | Value |
| --- | --- |
| Base URL | `https://<device>.<tailnet>.ts.net/v1` |
| Model ID | `google/gemma-4-12b-qat` |
| Token | LM Studio API token (password manager; shown once at creation) |

SaySlate calls:

| Call | Request | Time limit |
| --- | --- | --- |
| Test Connection | `GET <base>/models` (model ID must appear in `data[].id`) | 15 s |
| AI pass | `POST <base>/chat/completions` with `response_format: json_schema` (`sayslate_result`, strict) | 90 s |

## Host inventory at setup

| Item | Value |
| --- | --- |
| OS | Windows 10 Pro 22H2 (10.0.19045) |
| Tailscale | 1.102.4 (installed with winget) |
| LM Studio | 0.4.25+1 |
| Model | `google/gemma-4-12b-qat`: 12B QAT, GGUF, 7.15 GB, 262144 context |
| LM Studio server | port 1234, `networkInterface: 127.0.0.1`, `autoStartOnLaunch: true`, JIT loading on |

## Setup steps (what was done, in order)

1. **Install Tailscale** with winget:
   ```powershell
   winget install --id Tailscale.Tailscale -e --source winget
   ```
   The command actually run (non-interactive) was the same plus
   `--accept-package-agreements --accept-source-agreements --silent`. It installed the official
   `tailscale-setup-1.102.4-amd64.msi` from `pkgs.tailscale.com`, and winget verified the hash.
   - The ID is case-sensitive with `-e`: `tailscale.tailscale` returns "No package found".
   - `--source winget` keeps winget from also querying the Microsoft Store source, which stops and
     asks you to accept the Store's terms first.
2. **Join the host to the tailnet.** Run `tailscale up`, open the printed
   `login.tailscale.com/a/...` link, and click **Connect**. A browser that is already signed in to
   Tailscale does not mean the machine has joined; `tailscale status` must stop saying
   "Logged out".
3. **Load the model with no idle unload**, so Test Connection doesn't wait on a model load:
   ```powershell
   lms load google/gemma-4-12b-qat -y
   ```
   `lms load` creates an extra instance (`...:2`) if the model is already loaded. Check with
   `lms ps` and unload the duplicate with `lms unload "google/gemma-4-12b-qat:2"`.
4. **Turn on API-token auth.** In LM Studio, go to **Developer** (the `>_` icon) → **Server Settings**
   and turn on **Require API token**. Then use **Manage Tokens** → **Create new token**. The token
   is shown once; store it in the password manager.
5. **Start Serve**:
   ```powershell
   tailscale serve --bg --https=443 localhost:1234
   ```
   The first time, it prints "Serve is not enabled on your tailnet" with a
   `login.tailscale.com/f/serve?node=...` link. Open it and enable Serve/HTTPS; **leave Funnel
   unchecked**. The command then finishes by itself.
6. **Confirm it's private.** `tailscale serve status` and `tailscale funnel status` should both show
   `(tailnet only)`.

The first HTTPS request after Serve starts takes about 20 s while the certificate is issued. After
that, requests take about 0.02 s.

## Verification

[`sayslate-verify.ps1`](sayslate-verify.ps1) runs V1–V5. It asks for the token with hidden input
(or reads `$env:LM_API_TOKEN`), finds the tailnet hostname from `tailscale status --json`, and
prints status lines only. It never prints or writes the token.

| Check | Request | Expected | Result 2026-09-23 |
| --- | --- | --- | --- |
| V1 | local `GET /v1/models` + token | 200, model listed | 200, listed |
| V2 | local, no token | 401/403 | 401 |
| V3 | tailnet `GET /v1/models` + token | 200, model listed | 200, listed, <1 s |
| V4 | tailnet, no token | 401/403 | 401 |
| V5 | tailnet structured chat + token | 200, `content` parses to `{text}` | 200, parsed, 6.7 s |
| V6 | `tailscale funnel status` + listeners | Funnel off, loopback only | tailnet only; `127.0.0.1:1234` |
| V7 | V4 run from the Chrome machine | 401 means reachable and auth enforced | pending |

V7 command (run on the Chrome machine; no token needed):

```powershell
curl.exe -s -o NUL -w "%{http_code}`n" https://<device>.<tailnet>.ts.net/v1/models
```

A timeout or connection error there means that machine isn't on the tailnet.

## After a reboot

| Piece | Comes back? | Why |
| --- | --- | --- |
| Tailscale + Serve config | Yes | Tailscale service is Automatic; `--bg` Serve config persists |
| LM Studio server | Yes, after user login | App is in HKCU `Run`; server `autoStartOnLaunch: true` |
| Loaded model | No | JIT loads it on the first chat request (~14 s). Test Connection still passes, because with JIT on, `/v1/models` lists downloaded models |

## Side effects

- Token auth covers the whole LM Studio server. **Argus's local LM Studio provider**
  (`http://127.0.0.1:1234`, which by design stores no credentials) now gets 401. That's out of
  scope for SaySlate; Argus needs token support before it can use LM Studio on this host again.

## Rollback

| Change | Undo |
| --- | --- |
| Serve on :443 | `tailscale serve --https=443 off` (or `tailscale serve reset`) |
| Serve/HTTPS enabled for the tailnet | Tailscale admin console |
| Host joined to the tailnet | `tailscale logout` |
| Tailscale installed | `winget uninstall --id Tailscale.Tailscale -e` |
| Model kept loaded | `lms unload google/gemma-4-12b-qat` |
| API-token auth / token | LM Studio → Developer → Server Settings (toggle off; revoke under Manage Tokens) |
