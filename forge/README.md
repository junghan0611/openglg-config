# forge — Forgejo on Docker

Self-hosted git forge (issues, PRs, labels, CI hooks) running behind Caddy and
**bypassing Authelia** — Forgejo has its own user/team/token model and git/API
clients cannot carry Authelia cookies.

Companion repo (operator-facing skill + bot CLI):
<https://github.com/junghan0611/forge-config>

| | |
|---|---|
| **Image** | `codeberg.org/forgejo/forgejo:15` (LTS) |
| **Database** | PostgreSQL 16-alpine (private `forge-internal` network) |
| **Routing** | `${DOMAIN}/forge/*` — path-based, no wildcard DNS needed |
| **TLS** | Caddy + Let's Encrypt (auto) |
| **SSH** | disabled (HTTPS git push only) |
| **Signup** | `DISABLE_REGISTRATION=true` — admin creates users |
| **Auth** | Forgejo built-in (Authelia bypass) |
| **Data** | `${DATA_DIR:-~/docker-data}/forge/data` + `forge-db/pgdata` |

## Prerequisites

1. Caddy stack already up (`./run.sh up`); the `proxy` network exists.
2. Root `.env` has `DOMAIN` set (used by `FORGEJO__server__ROOT_URL`).
3. DNS A record for `DOMAIN` resolves to this host. **No new DNS entry** —
   `/forge` is just a path on the existing domain.

## Setup

```bash
cd forge
cp .env.example .env
chmod 600 .env

# DB password
openssl rand -base64 32 | tr -d '/+=' | head -c 32
# → paste into FORGE_DB_PASSWORD= in .env
```

> **Big-disk hosts.** If your home partition is small and a separate data
> volume is mounted elsewhere (a dedicated `/data`, `/var/lib/openglg`,
> attached storage, …), set `DATA_DIR=<path>` in `forge/.env`. Both the
> Forgejo data dir and the Postgres `pgdata` will land under
> `${DATA_DIR}/forge/data` and `${DATA_DIR}/forge-db/pgdata`. Git
> repositories grow over time — keep them off the root partition.

Add the Caddy route (already in `caddy/Caddyfile.template`) and the Authelia
bypass rule (already in `authelia/configuration.yml.template`). If you are
upgrading an existing deployment, sync those template changes into your live
`caddy/Caddyfile` and `authelia/configuration.yml`.

```bash
# Start
docker compose up -d
docker compose logs -f forge       # wait for "Listen: http://0.0.0.0:3000"

# Reload Caddy + Authelia so the new route + bypass take effect
docker compose -f ../caddy/docker-compose.yml restart caddy
docker compose -f ../authelia/docker-compose.yml restart authelia
```

## First-boot wizard

Open `https://${DOMAIN}/forge/` in a browser. Most fields are pre-filled from
the compose env; verify only:

| Field | Value |
|---|---|
| Database type | PostgreSQL (locked by env) |
| Server domain | `${DOMAIN}` (locked by env) |
| Application URL | `https://${DOMAIN}/forge/` (locked by env) |
| Repository path | `/data/git/repositories` (default) |
| Disable self-registration | checked |

Scroll down → **Administrator Account Settings**: create the admin user
(operator, not a bot). Click **Install Forgejo**. The wizard writes
`/data/forgejo/conf/app.ini` and sets `INSTALL_LOCK=true` automatically.

> **Do not** set `INSTALL_LOCK` via env. If env forces `false` after install,
> Forgejo crash-loops with an "installed but unlocked" contradiction.

## Creating the bot account

Log in as admin → **Site Administration → User Accounts → Create User Account**:

- Username: `glg-bot` (or whatever the operator companion uses)
- Email: `glg-bot@<your-mail-domain>` (only used for notifications)
- Strong password (one-time, never reused)
- Mark the account **Activated**

Switch to the bot account → **Settings → Applications → Generate New Token**:

| Field | Value |
|---|---|
| Token name | `agent-bus` |
| Scopes | `write:user`, `write:repository`, `write:issue`, `write:organization`, `read:user` |

> `write:user` is required — Forgejo enforces it where GitHub would not. Missing
> it returns 403 from `/api/v1/user` and label endpoints.

Store the token on the operator host (never in this repo):

```bash
# ~/.env.local on the host
export FORGE_URL="https://${DOMAIN}/forge"
export FORGE_TOKEN="<token from Forgejo>"
export FORGE_USER="glg-bot"
```

The companion CLI ([`forge-config/bin/forge`](https://github.com/junghan0611/forge-config))
reads these three variables.

## Smoke test

```bash
source ~/.env.local
curl -s -H "Authorization: token $FORGE_TOKEN" "$FORGE_URL/api/v1/user" | jq .login
# → "glg-bot"

curl -s "$FORGE_URL/api/v1/version" | jq .
# → {"version": "15.0.x"}
```

## Operations

```bash
docker compose ps
docker compose logs --tail=50 forge
docker compose logs --tail=50 forge-db

docker compose restart forge         # app only
docker compose restart               # app + db
docker compose pull forge && docker compose up -d forge   # patch upgrade

docker compose down                  # data preserved on host
```

## Backup

```bash
# DB
docker compose exec forge-db pg_dump -U forgejo forgejo \
  | gzip > ~/backup/forge-db-$(date +%Y%m%d).sql.gz

# Repositories, attachments, LFS, avatars
tar -czf ~/backup/forge-data-$(date +%Y%m%d).tar.gz \
  -C ~/docker-data/forge data
```

## Troubleshooting

**`forge` container exits immediately**
```bash
docker compose logs forge
# "unable to connect to database" → wait for forge-db healthcheck
# "permission denied /data" → chown the data dir to 1000:100
sudo chown -R 1000:100 ~/docker-data/forge/data
```

**`502 Bad Gateway` from `${DOMAIN}/forge/`**
```bash
# Confirm forge joined the proxy network
docker network inspect proxy | jq '.[0].Containers[].Name'

# Reach Forgejo from inside Caddy
docker compose -f ../caddy/docker-compose.yml exec caddy \
  wget -qO- http://forge:3000/api/v1/version
```

**Wizard skips to login on first visit**
```bash
# INSTALL_LOCK already true in app.ini — flip and restart.
docker compose exec forge sed -i 's/^INSTALL_LOCK = true/INSTALL_LOCK = false/' \
  /data/forgejo/conf/app.ini
docker compose restart forge
```

**Caddy edits look "stuck" after reload**
Caddy bind-mounts `Caddyfile` as a single file, which is sensitive to inode
swaps (e.g. editor atomic-write). If `caddy reload` does not pick up changes,
`docker compose restart caddy` always works.

## Security posture

- Closed instance — only the admin can create users.
- HTTPS only — SSH disabled at the Forgejo layer.
- Authelia bypass is intentional and limited to `/forge/*`. Forgejo enforces
  its own auth on every request; the `/api/v1/*` endpoints require a token.
- Token scopes follow least-privilege; `admin:*` is never granted to bots.
- All secrets stay in `forge/.env` (gitignored) or the host's `~/.env.local`.
  This repo only ships `.env.example` and the compose template.
