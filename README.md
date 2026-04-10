# openglg-config

An authenticated self-hosted work surface — your services, your data, your rules.

Publish a digital garden, analyze data, chat with your team, and run AI agents.
All behind a single identity-aware gateway. One server, Docker Compose, zero vendor lock-in.

## What this gives you

| Layer | Service | What it does |
|-------|---------|-------------|
| **Gateway** | [Pomerium](https://pomerium.com) | Identity-aware reverse proxy + auto HTTPS (Google/GitHub OAuth) |
| **Dashboard** | [Homer](https://github.com/bastienwirtz/homer) | Service index page |
| **Knowledge** | [Quartz](https://quartz.jzhao.xyz) | Obsidian vault → digital garden |
| | [Remark42](https://remark42.com) | Self-hosted comments |
| | [Umami](https://umami.is) | Privacy-friendly web analytics |
| **Work** | [Metabase](https://metabase.com) | Business intelligence / SQL dashboards |
| | [Mattermost](https://mattermost.com) | Team chat (Slack alternative) |
| **AI** | [OpenClaw](https://openclaw.org) | AI agent gateway (Telegram, web) |
| **Data** | [PostgreSQL](https://postgresql.org) | Shared database (pgvector enabled) |

Enable what you need. Disable what you don't. Each service is one `docker compose up -d`.

## Architecture

```
                        Internet
                           │
                    ┌──────▼──────┐
                    │  Pomerium   │  ← :443 (auto HTTPS + OAuth)
                    │  (gateway)  │
                    └──────┬──────┘
                           │ proxy network
          ┌────────┬───────┼───────┬─────────┬──────────┐
          ▼        ▼       ▼       ▼         ▼          ▼
       Homer   Metabase  Quartz  Remark42  OpenClaw  Mattermost
                  │                                     │
                  └──────── PostgreSQL ─────────────────┘
```

Public services (garden, comments, analytics) can bypass authentication.
Internal services (metabase, AI, chat) require Google/GitHub OAuth.

## Requirements

- **A server** — any VPS, cloud VM, or bare metal with a public IP
- **1 domain** — with DNS A records pointing to your server
- **Docker + Docker Compose** — that's it
- **Google Cloud OAuth credentials** (for Pomerium authentication)

No Kubernetes. No Terraform. No Nix. Just Docker Compose.

## Quick start

```bash
# 1. Clone
git clone https://github.com/junghan0611/openglg-config.git
cd openglg-config

# 2. Initial setup (Docker, firewall, directories)
./scripts/init.sh

# 3. Configure
cp .env.example .env                              # ← fill in secrets
cp pomerium/config.yaml.template pomerium/config.yaml  # ← fill in domains + OAuth

# 4. Start core services
cd pomerium && docker compose up -d && cd ..   # gateway (must be first)
cd postgres  && docker compose up -d && cd ..   # database
cd homer     && docker compose up -d && cd ..   # dashboard

# 5. Start what you need
cd metabase  && docker compose up -d && cd ..   # BI dashboards
cd openclaw  && docker compose up -d && cd ..   # AI agent
cd remark42  && docker compose up -d && cd ..   # comments
cd umami     && docker compose up -d && cd ..   # analytics
```

## DNS records

Point your domain and subdomains to your server's public IP:

```
A    example.com           → <server IP>    # Homer dashboard
A    auth.example.com      → <server IP>    # Pomerium auth
A    metabase.example.com  → <server IP>    # Metabase
A    garden.example.com    → <server IP>    # Digital garden
A    comments.example.com  → <server IP>    # Remark42
A    analytics.example.com → <server IP>    # Umami
A    ai.example.com        → <server IP>    # OpenClaw
A    chat.example.com      → <server IP>    # Mattermost
```

Only create records for services you actually enable.

## Directory layout

```
openglg-config/            (this repo — compose files + config templates)
├── pomerium/              gateway + authentication
├── homer/                 service dashboard
├── postgres/              shared database
├── metabase/              BI dashboards
├── openclaw/              AI agent
├── quartz/                digital garden builder
├── remark42/              comments
├── umami/                 web analytics
├── mattermost/            team chat (coming soon)
└── scripts/               init, up, status, backup

~/docker-data/             (persistent data, not in repo)
├── postgres/
├── metabase/
├── caddy/ or pomerium/
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

Startup order is handled automatically: caddy/pomerium → postgres → homer → apps.

## Choosing your gateway

This repo ships with **Pomerium** (identity-aware proxy with OAuth).

If you don't need authentication, the `caddy/` directory has a simpler
Caddy-only setup. Swap `pomerium/` for `caddy/` — everything else stays the same.

| | Pomerium | Caddy |
|---|---------|-------|
| HTTPS | auto (Let's Encrypt) | auto (Let's Encrypt) |
| Authentication | Google/GitHub/OIDC OAuth | none (or basic auth) |
| Use when | internal/team services | public-only services |

## Coming from Oracle Free Tier?

The original version of this repo was Oracle ARM-specific.
It now works on **any server** — x86 or ARM, any cloud or bare metal.
Oracle Free Tier still works, but is no longer required.

## References

- [Pomerium](https://pomerium.com) — Identity-aware access proxy
- [Homer](https://github.com/bastienwirtz/homer) — Service dashboard
- [Metabase](https://metabase.com) — Open source BI
- [Quartz](https://quartz.jzhao.xyz) — Obsidian → static site
- [Remark42](https://remark42.com) — Self-hosted comments
- [Umami](https://umami.is) — Privacy web analytics
- [OpenClaw](https://openclaw.org) — AI agent platform
- [Mattermost](https://mattermost.com) — Self-hosted team chat

## License

MIT
