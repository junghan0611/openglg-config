# openglg-config

A reproducible, self-hosted, single-fork work surface — **server and shell, together**.

Publish a digital garden, analyze data, and run AI agents (server half).
Reproduce your entire development shell on any Ubuntu/Debian with zero security keys at start (home half).
One fork, one domain, no vendor lock-in.

## Two halves

This repo ships two cooperating stacks. Each half can be used independently.

| Half | Lives in | Stack | Entry point | Used for |
|------|----------|-------|-------------|----------|
| **Server** | `caddy/`, `authelia/`, `postgres/`, `homer/`, `metabase/`, `openclaw/`, `remark42/`, `umami/`, `quartz/`, `mattermost/` | Docker Compose | `./run.sh up` | Hosting services behind an authenticated gateway |
| **Home** | `home/` | Nix flake + home-manager | `home/bootstrap.sh` | Reproducing your shell / dev tools on any Debian or Ubuntu |

**Why both in one repo.** A solo operator's work surface is rarely just a server, and rarely just a laptop shell. It's "the server at my domain + the shell I use to touch it." Shipping both halves as one fork means: one clone, one set of docs, one bootstrap story. Fork it, edit your config, run two commands.

## Server half

Authenticated self-hosted platform behind **Caddy + Authelia** with path-based routing.

| Layer | Service | What it does |
|-------|---------|-------------|
| **Gateway** | [Caddy](https://caddyserver.com) + [Authelia](https://authelia.com) | Reverse proxy + auto HTTPS + authentication |
| **Dashboard** | [Homer](https://github.com/bastienwirtz/homer) | Service index page |
| **Knowledge** | [Quartz](https://quartz.jzhao.xyz) | Obsidian vault → digital garden |
| | [Remark42](https://remark42.com) | Self-hosted comments |
| | [Umami](https://umami.is) | Privacy-friendly web analytics |
| **Work** | [Metabase](https://metabase.com) | Business intelligence / SQL dashboards |
| **AI** | [OpenClaw](https://openclaw.org) | AI agent gateway (Telegram, web) |
| **Chat** | [Mattermost](https://mattermost.com) | Team messaging |
| **Data** | [PostgreSQL](https://postgresql.org) | Shared database (pgvector enabled) |

Enable what you need. Disable what you don't. Each service is one `docker compose up -d`.

### Server architecture

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

### Server quick start

```bash
# 1. Clone
git clone https://github.com/junghan0611/openglg-config.git
cd openglg-config

# 2. Initial setup
./scripts/init.sh

# 3. Configure
cp .env.example .env                                     # fill in secrets
cp caddy/Caddyfile.template caddy/Caddyfile              # replace DOMAIN
cp authelia/configuration.yml.template authelia/configuration.yml
cp authelia/users.yml.template authelia/users.yml         # user + password hash
cp homer/config.yml.template homer/config.yml             # customize dashboard

# 4. Start everything
./run.sh up
```

### Server requirements

- **A VPS** — 2+ vCPU, 4GB+ RAM, 40GB+ disk (see [Recommended VPS](#recommended-vps))
- **1 domain** — single A record pointing to your server
- **Docker + Docker Compose** — that's it on the server

No Kubernetes. No Terraform. No Nix on the server.

### Server operations

```bash
./run.sh up         # start all (core first, then apps)
./run.sh down       # stop all
./run.sh restart    # stop + start
./run.sh status     # container status + disk
./run.sh logs       # all logs (summary)
./run.sh logs metabase  # follow one service
```

Startup order: caddy → authelia → postgres → homer → apps.

## Home half

A **Nix + home-manager** flake that reproduces your shell and dev tools on any Debian or Ubuntu — including the Android Linux Terminal (AVF Debian) on Galaxy S26.

**Design pillars:**

- **Apt minimum.** Exactly three apt packages: `curl`, `xz-utils`, `ca-certificates`. Everything else (git, gh, ripgrep, your editor, languages) comes through Nix.
- **Zero security keys at start.** Public HTTPS tarball clone, no SSH key required. GitHub auth via `gh auth login` device flow only when you want to push.
- **No hardcoded identity.** All personal values live in a single `home/settings.nix` file (gitignored). Fork the repo, edit one file, run one script.
- **One bootstrap for phone / VPS / laptop.** Same flake, different `system` and profile.

See [`home/README.md`](home/README.md) for the full walkthrough.

### Home quick start

```bash
# 1. Download the repo (anonymous, public HTTPS)
curl -L https://github.com/junghan0611/openglg-config/archive/main.tar.gz | tar xz
cd openglg-config-main/home

# 2. Personalize
cp settings.nix.example settings.nix
# edit: user.username, user.email, system (aarch64-linux for phone/ARM, x86_64-linux for VPS)

# 3. Bootstrap
./bootstrap.sh
```

After bootstrap, `nix`, `git`, `gh`, `ripgrep`, `fd`, `bat` are all on `$PATH`.

### Home status: Step 1 (minimal PoC)

What's in the repo today:

- `home/flake.nix` — reads `settings.nix`, produces one `homeConfigurations.<username>`
- `home/modules/minimal.nix` — bash + git + gh + rg/fd/bat (smoke test)
- `home/bootstrap.sh` — apt minimum → Determinate Nix installer → `home-manager switch`

What's designed but **not yet in this repo**:

- Profile split: `mobile` / `vps` / `workstation`
- Feature flags: `emacs` / `tmux` / `langs` / `heavy` (texlive, languagetool, imagemagick)
- `pass` / `gpg` / `authinfo` wiring
- `run.sh home:bootstrap` / `home:switch` / `home:update` subcommands
- Server ↔ home `.env` sharing

The full design is held in a linked note. Step 1 intentionally lands a working bootstrap on one target (S26 AVF Debian aarch64) before expansion.

## Directory layout

```
openglg-config/
├── caddy/                 # server — reverse proxy + auto HTTPS
├── authelia/              # server — authentication portal
├── postgres/              # server — shared database
├── homer/                 # server — service dashboard
├── metabase/              # server — BI dashboards
├── openclaw/              # server — AI agent
├── quartz/                # server — digital garden builder
├── remark42/              # server — comments
├── umami/                 # server — web analytics
├── mattermost/            # server — team chat
├── scripts/               # server — init, up, status, backup
├── run.sh                 # server — service manager
├── home/                  # home — Nix + home-manager
│   ├── flake.nix
│   ├── settings.nix.example   # copy to settings.nix (gitignored)
│   ├── modules/minimal.nix
│   ├── bootstrap.sh
│   └── README.md
└── README.md / AGENTS.md

~/docker-data/             # server persistent data (not in repo)
```

## DNS records

Single A record is enough:

```
A    example.com → <server IP>
```

All services accessed via path prefix (e.g., `example.com/metabase/`).

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

> Pin to specific tags in production to avoid breaking changes on `docker pull`.

## Recommended VPS

Tested and compared as of April 2026. Prices reflect post-April 2026 adjustments.

### Minimum specs

Running the full stack (Caddy + Authelia + PostgreSQL + Homer + 2–3 apps) requires:

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| vCPU | 2 | 2–4 |
| RAM | 2 GB | 4 GB |
| Disk | 40 GB NVMe | 80 GB NVMe |
| Traffic | 1 TB/mo | 10+ TB/mo |
| OS | Ubuntu 22.04+ | Ubuntu 24.04 LTS |

> With 2 GB RAM you can run the gateway + lightweight apps (Homer, Remark42, Umami).
> OpenClaw + Metabase + PostgreSQL need 4 GB.

### Provider comparison ($10–15/mo range)

Latency measured from South Korea (April 2026).

| Provider | Plan | Spec | Region | Price/mo | Ping (KR) | Notes |
|----------|------|------|--------|----------|-----------|-------|
| **Hetzner** | CPX22 | 2C / 4GB / 80GB NVMe | **Singapore** | ~$14 | **148ms** | Best balance of spec + latency. Full stack OK. 20TB traffic |
| **Vultr** | Regular | 1C / 2GB / 55GB | **Seoul** | $10 | **46ms** | Lowest latency. Light stack only (2GB RAM). 2TB traffic |
| Hetzner | CPX22 | 2C / 4GB / 80GB NVMe | Germany | ~$9 | 461ms | Great spec + price, but too slow from Asia |
| Hetzner | CAX21 | 4C / 8GB / 80GB NVMe (ARM) | Germany | ~$9 | 461ms | Best value on paper. EU-only, high latency from Asia |
| Contabo | VPS 10 | 4C / 8GB / 75GB NVMe | Singapore | ~$7 | untested | Most spec per dollar. Performance stability concerns |
| DigitalOcean | Basic | 1C / 2GB / 50GB | Singapore | $12 | ~180ms | Good docs, expensive for specs |

> **Hetzner EU** (Germany/Finland): 460–1270ms from Korea. Only viable with a CDN like Cloudflare in front.

### Recommendation

**For Asia-based users running OpenClaw**: Hetzner Singapore CPX22 (~$14/mo).
- 2 vCPU / 4 GB RAM / 80 GB NVMe / 20 TB traffic
- 148ms from Korea — pages load in 1–2s, dashboard use is comfortable
- Enough RAM for the full stack including OpenClaw + PostgreSQL

**For budget-strict ($10) with light services**: Vultr Seoul Regular ($10/mo).
- 46ms from Korea — instant response
- 2 GB RAM limits you to gateway + 1–2 lightweight apps
- Skip Metabase and OpenClaw, or run them on-demand

**For non-Asia users or with Cloudflare CDN**: Hetzner EU CAX21 (~$9/mo).
- 4 vCPU / 8 GB RAM (ARM) — most power per dollar anywhere
- Pair with Cloudflare for acceptable global latency

### Quick latency reference

```
From South Korea (measured 2026-04-11):
  Vultr Seoul        46ms   TTFB 0.3s   ← fastest
  Hetzner Singapore  148ms  TTFB 0.6s   ← good enough
  Hetzner Germany    461ms  TTFB 1.1s   ← too slow without CDN
  Hetzner Finland    1271ms TTFB 1.4s   ← unusable
```

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
- [home-manager](https://nix-community.github.io/home-manager/) — Nix-based user environment
- [Determinate Nix Installer](https://install.determinate.systems/) — used in `home/bootstrap.sh`

## Changelog

### v0.3.0 (2026-04-19)

- **Scope expansion**: repo now ships two halves — server (Docker Compose) **and** home (Nix + home-manager)
- **`home/`**: Step 1 minimal PoC — `flake.nix`, `settings.nix.example`, `modules/minimal.nix`, `bootstrap.sh`
- **Bootstrap**: apt minimum (curl, xz-utils, ca-certificates) → Determinate Nix installer → `home-manager switch`
- **Targets**: Galaxy S26 AVF Debian VM (aarch64-linux), Ubuntu VPS (x86_64-linux), any Debian-family laptop
- **Zero-key start**: anonymous HTTPS tarball clone, no SSH key required; `gh auth login` device flow later
- **Identity**: all personal values in single `home/settings.nix` (gitignored); no hardcoded usernames

### v0.2.1 (2026-04-11)

- **VPS Guide**: Added recommended VPS section with provider comparison (Hetzner, Vultr, Contabo, DO)
- **Latency data**: Real ping/TTFB measurements from South Korea to all Hetzner regions + Vultr Seoul
- **Requirements**: Updated minimum specs (2C/4GB for full stack, 2GB for light)

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
