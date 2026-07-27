#!/bin/bash
# Thin wrapper around OPNsense's REST API.
#
# Usage:
#   OPN_HOST=192.168.0.1 OPN_PORT=8443 OPN_KEY=... OPN_SECRET=... \
#     ./opn-api.sh /api/core/firmware/status
#   ./opn-api.sh /api/crowdsec/general/set -X POST -H "Content-Type: application/json" -d '{"general":{"agent_enabled":"1"}}'
#
# Env vars:
#   OPN_HOST   - firewall hostname/IP (required)
#   OPN_PORT   - API port (default 443; use 8443 or whatever the GUI actually
#                listens on if something else - HAProxy, Caddy, etc. - owns 443)
#   OPN_KEY    - API key   (System > Access > Users > <user> > API keys > +)
#   OPN_SECRET - API secret (shown once at generation time, save it)
#
# The API key/secret pair authenticates via HTTP Basic Auth. Scope the user
# down to the minimum privileges the task needs - this is a live firewall.

set -euo pipefail

OPN_HOST="${OPN_HOST:?set OPN_HOST}"
OPN_PORT="${OPN_PORT:-443}"
OPN_KEY="${OPN_KEY:?set OPN_KEY}"
OPN_SECRET="${OPN_SECRET:?set OPN_SECRET}"

path="$1"
shift

curl -sk -m 20 -u "${OPN_KEY}:${OPN_SECRET}" "https://${OPN_HOST}:${OPN_PORT}${path}" "$@"
