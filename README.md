# openglg-config

An authenticated self-hosted work surface — your services, your data, your rules.

Publish a digital garden, analyze data, and run AI agents.
All behind Caddy + Authelia with path-based routing. One server, one domain, Docker Compose, zero vendor lock-in.

## What this gives you

| Layer | Service | What it does |
|-------|---------|-------------|
| **Gateway** | [Caddy](https://caddyserver.com) + [Authelia](https://authelia.com) | Reverse proxy + auto HTTPS + authentication |
| **Dashboard** | [Homer](https://github.com/bastienwirtz/homer) | Service index page |
| **Knowledge** | [Quartz](https://quartz.jzhao.xyz) | Obsidian vault → digital garden |
| | [Remark42](https://remark42.com) | Self-hosted comments |
| | [Umami](https://umami.is) | Privacy-friendly web analytics |
| **Work** | [Metabase](https://metabase.com) | Business intelligence / SQL dashboards |
| **AI** | [OpenClaw](https://openclaw.org) | AI agent gateway (Telegram, web) |
| **Data** | [PostgreSQL](https://postgresql.org) | Shared database (pgvector enabled) |

Enable what you need. Disable what you don't. Each service is one `docker compose up -d`.

## Architecture

```
                        Internet
                           │
                    ┌──────▼──────┐
                    │    Caddy    │  ← :443 (auto HTTPS)
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Authelia   │  ← forward_auth (login portal)
                    └──────┬──────┘
                           │ proxy network (path-based routing)
          ┌────────┬───────┼───────┬─────────┐
          ▼        ▼       ▼       ▼         ▼
       Homer   Metabase  Remark42  Umami   OpenClaw
       (/)     (/metabase) (/remark42) (/umami) (/openclaw)
                  │
                  └──────── PostgreSQL ──────┘
```

**Path-based routing** — no wildcard DNS needed. Single A record for your domain.

| Path | Service | Auth |
|------|---------|------|
| `/` | Homer dashboard | public |
| `/authelia/` | Login portal | — |
| `/metabase/` | Metabase BI | required |
| `/openclaw/` | OpenClaw AI | required |
| `/remark42/` | Remark42 comments | public |
| `/umami/` | Umami analytics | public |

## Requirements

- **A server** — any VPS, cloud VM, or bare metal with a public IP
- **1 domain** — single A record pointing to your server
- **Docker + Docker Compose** — that's it

No Kubernetes. No Terraform. No Nix. Just Docker Compose.

## Quick start

```bash
# 1. Clone
git clone https://github.com/junghan0611/openglg-config.git
cd openglg-config

# 2. Initial setup
./scripts/init.sh

# 3. Configure
cp .env.example .env                                     # fill in secrets
cp caddy/Caddyfile.template caddy/Caddyfile              # replace DOMAIN
cp authelia/configuration.yml.template authelia/configuration.yml  # fill in secrets + domain
cp authelia/users.yml.template authelia/users.yml         # set user + password hash
cp homer/config.yml.template homer/config.yml             # customize dashboard

# 4. Start everything
./run.sh up
```

## DNS records

Single A record is enough:

```
A    example.com → <server IP>
```

All services are accessed via path prefix (e.g., `example.com/metabase/`).

## Directory layout

```
openglg-config/            (this repo — compose files + config templates)
├── caddy/                 reverse proxy + auto HTTPS
├── authelia/              authentication portal
├── homer/                 service dashboard
├── postgres/              shared database
├── metabase/              BI dashboards
├── openclaw/              AI agent
├── quartz/                digital garden builder
├── remark42/              comments
├── umami/                 web analytics
├── scripts/               init, up, status, backup
└── run.sh                 service manager

~/docker-data/             (persistent data, not in repo)
├── authelia/
├── caddy/
├── metabase/
├── postgres/
├── remark42/
└── umami/
```

## Operations

```bash
./run.sh up         # start all (core first, then apps)
./run.sh down       # stop all
./run.sh restart    # stop + start
./run.sh status     # container status + disk
./run.sh logs       # all logs (summary)
./run.sh logs metabase  # follow one service
```

Startup order: caddy → authelia → postgres → homer → apps.

## Docker image versions

Pinned at deployment time. Record current versions for reproducibility.

| Service | Image | Version (2026-04-10) |
|---------|-------|---------------------|
| Caddy | `caddy:2-alpine` | 2.10.0 |
| Authelia | `authelia/authelia:latest` | 4.39.18 |
| Homer | `b4bz/homer:latest` | 24.12.1 |
| PostgreSQL | `pgvector/pgvector:pg16` | pg16 |
| Metabase | `metabase/metabase:latest` | 0.54.5 |
| Umami | `ghcr.io/umami-software/umami:postgresql-latest` | 2.16.0 |

> **Tip**: Pin to specific tags in production to avoid breaking changes on `docker pull`.

## Gateway

This repo uses **Caddy + Authelia** (path-based routing, file-based users).

- Caddy handles HTTPS (auto Let's Encrypt) + reverse proxy
- Authelia handles authentication via `forward_auth`
- No OAuth/OIDC needed — simple username/password

Alternative setups available in the repo:
- `pomerium/` — identity-aware proxy with Google/GitHub OAuth (requires wildcard DNS)
- `caddy/` alone — no authentication (public-only services)

## References

- [Caddy](https://caddyserver.com) — Fast, extensible web server
- [Authelia](https://authelia.com) — Authentication & authorization server
- [Homer](https://github.com/bastienwirtz/homer) — Service dashboard
- [Metabase](https://metabase.com) — Open source BI
- [Quartz](https://quartz.jzhao.xyz) — Obsidian → static site
- [Remark42](https://remark42.com) — Self-hosted comments
- [Umami](https://umami.is) — Privacy web analytics
- [OpenClaw](https://openclaw.org) — AI agent platform

## Changelog

### v0.2.0 (2026-04-10)

- **Gateway**: Pomerium → Caddy + Authelia (path-based routing, no wildcard DNS)
- **Auth**: Authelia file-based user authentication with `forward_auth`
- **Caddy**: `route` directive for correct forward_auth → strip → proxy ordering
- **Metabase**: DB password fix, `MB_SITE_URL` for path prefix support
- **Homer**: Path-based URLs (`/metabase/`, `/openclaw/`, etc.)
- **Umami**: Added with dedicated PostgreSQL
- **run.sh**: Added `authelia` to core services

### v0.1.0 (2026-04-09)

- Initial setup: Caddy, PostgreSQL, Homer, Metabase, OpenClaw
- Docker Compose per-service structure
- `run.sh` service manager

## License

MIT
