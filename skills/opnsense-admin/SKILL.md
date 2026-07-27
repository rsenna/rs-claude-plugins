---
name: opnsense-admin
description: Manage an OPNsense firewall/router through its REST API - inspecting or changing firewall rules, NAT, interfaces, DHCP/DNS (Unbound), VPN (WireGuard/OpenVPN/IPsec), HAProxy reverse-proxy config, installed plugins (CrowdSec, ACME, etc.), and firmware/upgrade status. Use this whenever the user mentions OPNsense, pfSense-style firewall config, their home router/firewall, or asks to look at/change/harden/audit/upgrade a box that turns out to be running OPNsense - even if they don't say "OPNsense" or "API" explicitly (e.g. "can you check my firewall", "why can't I reach X through my router", "harden my home network"). Also use this if the OPNsense box is stuck after a failed or interrupted major-version upgrade.
---

# OPNsense administration via REST API

OPNsense exposes nearly its entire configuration surface over a REST API
authenticated with a per-user API key/secret pair. This is almost always a
better path than trying to script the web GUI or requesting shell access:
it's scriptable, auditable (every call is attributable to the API user), and
easy to scope down to read-only if that's all a task needs.

This is a **live firewall for someone's network** (often the only thing
between their home and the internet). Move deliberately: read before you
write, confirm before firing anything with a blast radius (VPN setup, firewall
rule changes, HAProxy edits, firmware upgrades), and always leave yourself a
way back — see the config-backup step below before anything nontrivial.

## Getting access

You need a key/secret pair. If you don't have one yet, ask the user to
generate one (or point you to an existing scoped-down user) under
**System → Access → Users → (user) → API keys → +** in the GUI — this
downloads a `.txt` with `key` and `secret` once, non-recoverable after that.
For anything beyond read-only inspection, a dedicated user scoped to what's
actually needed beats reusing a full-admin account.

Don't assume port 443 — if the box also runs a reverse proxy (HAProxy is
common), the GUI/API often lives on 8443 or similar instead. Probe a few
ports if a plain `https://<host>/` doesn't return a login page; see
`references/lessons-learned.md` for the one-liner.

Use `scripts/opn-api.sh` as the base for any calls:

```bash
export OPN_HOST=192.168.0.1 OPN_PORT=8443 OPN_KEY=... OPN_SECRET=...
./scripts/opn-api.sh /api/core/firmware/status
```

## Before changing anything

1. **Pull a fresh config backup**: `GET /api/core/backup/download/this`
   returns the full `config.xml`. Do this before any nontrivial change, and
   consider handing a copy to the user as an off-box safety net — some
   installs have no filesystem-level snapshot rollback available.
2. **Read before you write.** For any resource you're about to modify, call
   its `get<Item>` endpoint first (with no uuid, if it's a new item, to see
   the default template and every valid field/enum) so you know the real
   shape of what you're sending back.
3. If several changes are related (e.g. "hardening pass"), it's fine to do
   them one at a time and confirm each landed rather than batching blindly.

## Discovering the right endpoint

There's no single directory of endpoints. Two things that actually work:

- The config backup's top-level `<OPNsense>` child tags map directly to API
  module names (`<crowdsec>` → `/api/crowdsec/...`, `<wireguard>` →
  `/api/wireguard/...`, `<HAProxy>` → `/api/haproxy/...`).
- Within a module, CRUD resources follow `search<Item>`, `get<Item>[/<uuid>]`,
  `add<Item>`, `set<Item>/<uuid>`, `del<Item>/<uuid>`, `toggle<Item>/<uuid>`,
  with service-level `status`/`start`/`stop`/`reconfigure` (and sometimes
  `configtest`) under a sibling `service` controller.

Full detail, plus the exact gotchas below (multi-select field format, save-
vs-apply, what has no API at all), is in `references/lessons-learned.md` —
read it before doing anything with CrowdSec, WireGuard, HAProxy routing, or
a stuck firmware upgrade specifically; those sections include working,
copy-adaptable request bodies from a real session.

## Quick-reference gotchas (see references/lessons-learned.md for full detail)

- **Multi-select fields** (`linkedAcls`, `tunneladdress`, `dns`, `peers`, ...)
  come back from `GET` as a dict-of-dicts for form-rendering purposes, but go
  back to `POST` as a plain comma-separated string of the selected
  keys/values — not the nested structure.
- **Saving isn't applying.** `add`/`set` persist config; you almost always
  need a separate `service/reconfigure` (or `firewall/filter/apply` for
  filter rules) to make it live. Verify against a real signal after (e.g. a
  bouncer's `last_seen` timestamp), not just the save response.
- **Some legacy settings have no API** (e.g. the SSH root-login/password-auth
  toggle under System → Settings → Administration). Don't force these through
  a full config restore — tell the user to flip it by hand in the GUI.
- **A box stuck mid major-upgrade** (base OS upgraded, package/ABI metadata
  not) breaks pkg resolution everywhere identically and looks like a mirror
  problem but isn't. Recovery is the console's firmware-update menu option,
  typing the target version explicitly — not manual `pkg` surgery. Confirm
  physical/console access exists as a fallback before attempting any
  upgrade-related fix remotely, since you're reaching the box through its own
  network stack.

## Working examples

`references/lessons-learned.md` has full worked request sequences for:
enabling CrowdSec (agent + LAPI + firewall bouncer), standing up a WireGuard
server and client peer (including generating keys locally since there's no
keygen endpoint), and gating a specific HAProxy backend behind a source-IP
ACL without disturbing its existing Host-header routing. Adapt these rather
than reinventing the request shapes from scratch.
