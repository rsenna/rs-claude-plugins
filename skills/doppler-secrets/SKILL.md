---
name: doppler-secrets
description: Use the Doppler CLI to configure local access to a user's Doppler project/config via a service token, and to inject secrets into commands without ever writing them to disk or echoing them back. Use whenever the user mentions Doppler, gives you a service token (starts with dp.st.), asks you to read/set secrets, or asks you to run a command "with the creds from Doppler"/"using Doppler". Also use when scoping automation (a cron job, a script on a remote host) to only the secrets it actually needs, rather than a token for an entire project.
---

# Doppler CLI - local access + secret injection

Doppler stores secrets per **project** and **config** (environment); a
**service token** is scoped to exactly one project+config and doesn't need
an explicit `--project`/`--config` flag once set - the CLI resolves both
from the token itself.

## Setting up local access from a token the user gives you

A `dp.st....` string is a live secret the moment you see it - treat it like
any other credential: don't echo it back, don't write it into a repo file,
don't paste it into a memory/notes system. Configure it directly into
Doppler's own local config store, scoped to the directory you're working in
(so it doesn't leak into unrelated projects on the same machine):

```bash
doppler configure set token "dp.st.xxx" --scope /path/to/repo
```

After that, plain `doppler <command>` run from (or under) that path picks the
token up automatically - no env var, no flag, and nothing written to the
repo itself (`doppler configure` stores it under Doppler's own config, not
project-local).

Verify it actually works and see what project/config it resolves to before
relying on it:

```bash
doppler me                     # confirms the token identity
doppler projects               # shows which project it's scoped to
doppler secrets --only-names   # lists secret NAMES ONLY - safe to run/paste, never shows values
```

## Reading secrets into a command

Prefer `doppler run --` over `doppler secrets get` + manual export - it
injects everything as env vars for the duration of one command and nothing
leaks into shell history or a `.env` file:

```bash
doppler run -- bash -c 'curl -H "Authorization: Bearer $SOME_TOKEN" https://example.com'
```

Never `echo`/`print` a secret value to confirm it's "there" - use
`--only-names` (above) or check the *effect* of using it (e.g. the API call
suceeding) instead.

## Read-only vs read/write tokens

A service token's scope (read-only vs read/write) is set when it's created
in the Doppler dashboard, and there's no CLI-visible signal that a token is
read-only until you actually try to write and get:

```
Doppler Error: You do not have write access to this config's secrets.
```

If you need to write secrets (e.g. migrating values in from a local file),
ask the user to mint a **read/write** token specifically - don't assume the
first token they hand you covers it.

## Scoping automation to less than "the whole project"

If a script/cron/systemd-timer on some other host only needs 2 of your 20
secrets (e.g. just `PATCHMON_USERNAME`/`PATCHMON_PASSWORD` out of a project
that also holds SSH private keys and other infra creds), don't hand that
host a token for the whole project. Doppler supports multiple **configs**
(environments) per project - create a dedicated config holding only the
secrets that automation needs, and mint its service token from that config
instead. This keeps a compromised/leaked remote host from also exposing
unrelated secrets it never needed.

## Nested-shell quoting gotcha

When a command needs both `doppler run -- bash -c '...'` AND an embedded
JSON payload (e.g. `curl -d '{"key":"value"}'`), don't string-concatenate
the payload into the single-quoted inner script - once the payload itself
contains quotes, concatenation silently mangles it. Two ways around it that
both actually work:

1. **Positional args**: pass the dynamic bits (paths, small values) as real
   positional parameters to the inner `bash -c`, not interpolated into the
   quoted string - `bash -c '... "$1" ...' _ "$path"` - and keep the JSON
   payload itself as a literal double-quoted string *inside* the
   single-quoted script, with its own internal quotes backslash-escaped
   (`-d "{\"host_id\":\"${host_id}\"}"`) - this works because the inner
   `bash -c`'s content is parsed fresh by a new shell, where double-quote
   escaping rules apply normally.
2. **For anything larger/multi-line** (e.g. a Python one-liner building a
   JSON body from several secrets), skip inline JSON entirely and pipe a
   heredoc into `python3 -`, passing secrets as script arguments
   (`python3 - "$SECRET_A" "$SECRET_B" <<'PYEOF' ... PYEOF`) rather than
   interpolating them into a quoted shell string at all.

See `opnsense-admin`'s and `patchmon-admin`'s `scripts/*.sh` for working,
copy-adaptable examples of pattern 1.
