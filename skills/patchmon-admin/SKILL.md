---
name: patchmon-admin
description: Manage a PatchMon patch-management server through its REST API - host groups, patch policies, triggering patch_all/patch_package runs, and the notification system (email/webhook/ntfy destinations, routing rules, delivery log, test-send). Use whenever the user mentions PatchMon, asks to patch/update Linux hosts in bulk, wants alerts when a patch run fails, or asks to automate OS package updates across a fleet. Several endpoints used here (POST /patching/trigger, PUT /notifications/destinations/{id}, POST /notifications/test) are undocumented in PatchMon's public docs and were reverse-engineered by reading its Go source - see references/lessons-learned.md before guessing at a new one.
---

# PatchMon administration via REST API

PatchMon exposes host inventory, patch policies, patch runs, and its
notification pipeline over a REST API. Most of the *admin* surface (host
groups, policies, notifications, triggering runs) is JWT-authenticated via a
regular username/password login - there is no long-lived admin API key for
this part. A separate, unrelated auth scheme (`X-API-ID`/`X-API-KEY` Basic
auth) exists for per-host agent traffic and a narrower "integration" token
type - don't confuse the two, see references/lessons-learned.md.

**Triggering a `patch_all` run is a real, immediate action on a live host** -
it runs `apt-get upgrade` (or the distro equivalent) right now, restarts
services as needed (openssh-server, etc.), and there is no dry-run for
`patch_all` (only `patch_package` supports `dry_run`). Treat every call to
`/patching/trigger` with the same care as SSHing in and running the upgrade
yourself - confirm with the user before the first real trigger against any
given host, and prefer testing against a low-criticality host first.

## Getting access

Ask the user for a dedicated PatchMon account's username/password (least
privilege that still covers host-groups/policies/notifications management -
not necessarily full admin, if PatchMon's role model allows narrower). Store
as `PATCHMON_USERNAME`/`PATCHMON_PASSWORD` in Doppler or your own env - see
`doppler-secrets` skill for the Doppler-side patterns.

Use `scripts/patchmon-api.sh` as the base for any calls - it logs in fresh
every call (JWTs are short-lived, not worth caching) and forwards the rest to
curl:

```bash
export PATCHMON_HOST=patchmon.example.com PATCHMON_USERNAME=... PATCHMON_PASSWORD=...
./scripts/patchmon-api.sh /api/v1/host-groups
./scripts/patchmon-api.sh /api/v1/patching/trigger -X POST -H "Content-Type: application/json" \
  -d '{"host_id":"<uuid>","patch_type":"patch_all"}'
```

## The core model

- **Host groups** (`/api/v1/host-groups`) are just selectors - hosts belong to
  one or more, groups feed policies/notifications/filtering.
- **Patch policies** (`/api/v1/patching/policies`) control *timing/approval*
  of a run once it's triggered (`immediate` / delayed N minutes / fixed
  daily time) - assigned to host groups (or individual hosts) via a separate
  assignments sub-resource. **A policy does NOT create a recurring schedule
  by itself** - something still has to call `/patching/trigger` to actually
  start a run. If the ask is "patch everything automatically every week",
  you need both: a policy assigned to every relevant group/host (so runs
  don't sit in a pending-approval limbo), AND an external
  cron/systemd-timer/etc. that calls trigger on a schedule. See
  references/lessons-learned.md for a working trigger-loop script.
- **Notifications**: destinations (email/SMTP, generic webhook - auto-detects
  Discord/Slack URLs, ntfy, built-in Internal Alerts) + routing rules
  (destination + event_types + min_severity + optional host/group scoping).
  Key events: `patch_run_started/completed/failed/cancelled`, `host_down`,
  `host_recovered`, `server_update`, `agent_update`, `compliance_scan_completed`,
  and a synthetic `test` event for verifying a destination end-to-end.

## Before wiring up anything automated

1. Check existing policy assignments (`GET /patching/policies/{id}`) before
   assuming a policy covers everything - it's easy for it to have been set up
   against only some host groups, silently leaving others on no policy at
   all (i.e. any triggered run for them falls back to "immediate, no policy"
   behavior, or - if pending_approval was requested - stuck waiting forever).
2. Send a `POST /api/v1/notifications/test` to any new destination and check
   `GET /api/v1/notifications/delivery-log` a few seconds later - creating a
   destination does **not** validate its config (a `channel_type` + empty
   `config: {}` is accepted with 201, and will just silently fail to deliver
   later). The delivery log is the only place failures surface
   (`error_message` field).
3. Gmail SMTP for the email destination is a common dead end: PatchMon's
   mailer only does plain SMTP auth (Go `net/smtp.PlainAuth`), no OAuth2/
   XOAUTH2 - and Gmail increasingly won't issue app passwords even with 2FA
   on. A free transactional relay (Brevo, Mailgun, etc.) that hands out a
   plain SMTP login/password is usually less friction than fighting Gmail's
   auth model.

Full endpoint list actually confirmed working (with exact request/response
shapes pulled from the Go source, since the public docs are incomplete/wrong
in places), plus the `patch_all` trigger-loop script pattern, is in
`references/lessons-learned.md`.
