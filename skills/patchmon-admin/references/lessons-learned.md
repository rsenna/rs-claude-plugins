# PatchMon API - lessons learned

From a real session automating patch policies + failure notifications for a
13-host / 7-group homelab fleet. PatchMon's public docs
(`patchmon-api-integrations-guide.md`, `patchmon-admin-guide.md`) cover the
agent-facing and read-heavy endpoints reasonably well, but several admin
endpoints actually used here are either wrong in the docs or missing
entirely - confirmed by cloning `github.com/patchmon/patchmon` and reading
`server-source-code/internal/handler/*.go` and
`server-source-code/internal/server/router.go` directly. Do that whenever an
endpoint doesn't behave as (or isn't) documented - it's faster than
guessing-and-checking against a live server, and safer, since some guesses
(e.g. a malformed `/patching/trigger` body) can actually kick off unwanted
work.

## Two unrelated auth schemes - don't mix them up

- **JWT (Bearer)**: `POST /api/v1/auth/login` with `{"username", "password"}`
  returns `{token, refresh_token, expires_at, expires_in, user, message}`.
  Use `Authorization: Bearer <token>` for everything admin-facing: host
  groups, patch policies, patching trigger/runs, notifications. No
  documented long-lived equivalent for this surface - login fresh each time
  or handle refresh yourself.
- **Basic Auth (API-ID/API-KEY)**: per-host agent traffic
  (`/api/v1/hosts/update`, etc.) and the read-only "Integration API"
  (`GET /api/v1/api/hosts`, `GET /api/v1/api/hosts/{id}/packages`) use
  `curl -u "$API_ID:$API_KEY"` - a completely different credential type
  (created under Settings -> Integrations, or via the
  `/api/v1/auto-enrollment/tokens` JWT-authenticated endpoint for
  provisioning new host tokens). A JWT will NOT authenticate these, and vice
  versa - `{"error":"Missing or invalid authorization header"}` on
  `/api/v1/api/hosts` with a Bearer token is this mismatch, not a broken
  token.

## Endpoints confirmed working (some undocumented)

All under `/api/v1`, all JWT Bearer auth unless noted. Doc status: **public**
(in patchmon docs) vs **undocumented** (found only by reading source).

| Method | Path | Doc status | Notes |
|---|---|---|---|
| POST | `/auth/login` | undocumented (docs only say "returned in the login response", no request shape) | `{"username","password"}` -> `{token, refresh_token, ...}` |
| GET | `/host-groups` | undocumented | list, includes `_count.hosts` per group |
| GET | `/hosts` | undocumented, **different from** `/api/hosts` | JWT-auth'd, full host detail (PascalCase fields: `ID`, `FriendlyName`, `IP`, `OSType`, ...). Confusingly similar-looking `/api/v1/api/hosts` (double `api`) is the *Basic-Auth* Integration API with different (snake/camel) field names - these are two separate handlers, not a typo. |
| GET / POST | `/patching/policies` | public (docs describe the concept, not the exact route) | list / create |
| GET | `/patching/policies/{id}` | undocumented | detail incl. `assignments[]` (`target_type`: `host_group`\|`host`, `target_id`) and `exclusions[]` |
| POST | `/patching/policies/{id}/assignments` | undocumented | `{"target_type":"host_group","target_id":"<uuid>"}` -> 201 |
| POST | `/patching/trigger` | **undocumented, not in public API docs at all** | see below - the actual "do the patching" call |
| GET | `/patching/runs/{id}` | public | run status/`shell_output`/`error_message` |
| GET | `/notifications/destinations` | undocumented | list (config redacted - `has_secret` only) |
| POST | `/notifications/destinations` | undocumented | **does not validate `config` contents at creation** - `{"channel_type":"email","display_name":"...","config":{}}` returns 201 happily and will just fail silently later. See below for real config shapes. |
| PUT | `/notifications/destinations/{id}` | undocumented | same body shape as POST; this is how you actually set/fix `config` after creation (`GET`/`PATCH` on the `{id}` path both returned 405 - `PUT` is the only way to update, despite `OPTIONS` advertising `PATCH` too) |
| POST | `/notifications/test` | undocumented | `{"destination_id":"..."}` -> `{"status":"enqueued"}`, fires a synthetic `test` event through the real delivery pipeline. **The only reliable way to know if a destination's config is actually correct** - check `/notifications/delivery-log` a few seconds after. |
| GET | `/notifications/routes` | undocumented | routing rules: destination + event_types + min_severity + optional host/group scoping |
| POST | `/notifications/routes` | undocumented | `{"destination_id","event_types":[...],"min_severity"}` (`event_types` defaults to `["*"]`, `min_severity` defaults to `"informational"` if omitted) |
| GET | `/notifications/delivery-log?limit=N` | undocumented | `status: sent\|failed`, `error_message` - the actual ground truth for "did it work" |

## Destination `config` field shapes (from Go source, not docs)

From `server-source-code/internal/queue/notification_worker.go`:

```go
type emailConfig struct {
    SMTPHost string `json:"smtp_host"`
    SMTPPort int    `json:"smtp_port"`   // defaults to 587 if 0
    Username string `json:"username"`
    Password string `json:"password"`
    From     string `json:"from"`
    To       string `json:"to"`          // comma-separated for multiple recipients
    UseTLS   bool   `json:"use_tls"`
}

type ntfyConfig struct {
    ServerURL string `json:"server_url"` // defaults to https://ntfy.sh if empty
    Topic     string `json:"topic"`      // required
    Token     string `json:"token"`      // optional access token
    Username  string `json:"username"`   // optional, alternative to token
    Password  string `json:"password"`   // optional, alternative to token
    Priority  string `json:"priority"`   // optional: min/low/default/high/urgent
}
```

Webhook config is just `{"url": "..."}` - PatchMon auto-detects Discord/Slack
webhook URL shapes and formats accordingly, no channel_type distinction
needed beyond `"webhook"`.

**Gmail SMTP will very likely fail** with
`535 5.7.8 Username and Password not accepted` even with a real app
password, because there is no OAuth2/XOAUTH2 support in `sendEmail()` at all
(confirmed reading the same file) - Gmail's own trend of hiding app passwords
for more personal accounts (even with 2FA on) makes this a common dead end.
A free transactional relay (Brevo's `smtp-relay.brevo.com:587` worked cleanly
in testing, no domain verification needed - just a single sender email) is
usually the path of least resistance.

## `/patching/trigger` request shape (undocumented, from `patching.go`)

```go
var body struct {
    HostID           string   `json:"host_id"`            // required
    PatchType        string   `json:"patch_type"`         // "patch_all" | "patch_package", required
    PackageName      string   `json:"package_name"`       // patch_package only
    PackageNames     []string `json:"package_names"`      // patch_package only, max 100
    DryRun           bool     `json:"dry_run"`             // patch_package ONLY - patch_all cannot dry-run
    PendingApproval  bool     `json:"pending_approval"`    // create in pending_validation, don't enqueue work
    ScheduleOverride string   `json:"schedule_override"`   // "immediate" to bypass the policy's delay
}
```

Response: `{"job_id", "message":"Patch queued", "patch_run_id", "queued":true, "run_at"}`.
Poll `GET /patching/runs/{patch_run_id}` for `status`
(`queued`/`running`/`completed`/`failed`) and `shell_output`.

**This is a real, immediate action** when the resolved policy is `immediate`
(the default if no policy is assigned) - it runs the actual package manager
on the actual host right now. Verified end-to-end once, deliberately against
a low-criticality host, before ever wiring this into anything scheduled.

## Patch policies don't schedule themselves

A policy only governs the delay/approval-gate of a run *once triggered*
(`patch_delay_type`: `immediate`/`delayed`/`fixed_time`, converted to an
asynq job delay server-side). There is no "run this policy every week"
concept in PatchMon - recurring automation needs an external trigger loop:

```bash
# List all hosts, trigger patch_all for each, staggered.
JWT=$(curl -sk -X POST "$BASE/api/v1/auth/login" -H "Content-Type: application/json" \
  -d "{\"username\":\"$USER\",\"password\":\"$PASS\"}" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')

for host_id in $(curl -sk -H "Authorization: Bearer $JWT" "$BASE/api/v1/hosts" \
  | python3 -c 'import json,sys; [print(h["ID"]) for h in json.load(sys.stdin)]'); do
  curl -sk -X POST -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
    -d "{\"host_id\":\"$host_id\",\"patch_type\":\"patch_all\"}" \
    "$BASE/api/v1/patching/trigger"
  sleep 15   # avoid slamming shared storage (e.g. several LXCs on one Proxmox host) at once
done
```

Drive this from cron/systemd-timer wherever it needs to run from (needs
network access to the PatchMon server + the login credentials) - it does not
need to run *on* PatchMon itself.

## Policy assignment coverage is easy to get wrong silently

A policy applied to "some" host groups looks, from the outside (a single
`GET /patching/policies` list call), identical to one that covers
everything - the count of assignments isn't shown in the list view. Always
`GET /patching/policies/{id}` and cross-reference `assignments[].target_id`
against the full `GET /host-groups` list before assuming coverage is
complete. In one real case, a pre-existing policy silently missed the
largest host group (8 of 13 hosts) because it was set up before that group
existed.
