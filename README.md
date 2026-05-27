# openglg-config

A reproducible, self-hosted, single-fork work surface — **server and shell, together**.

Publish a digital garden, analyze data, and run AI agents (server half).
Reproduce your entire development shell on any Ubuntu/Debian with zero security keys at start (home half).
One fork, one domain, no vendor lock-in.

## Two halves

This repo ships two cooperating stacks. Each half can be used independently.

| Half | Lives in | Stack | Entry point | Used for |
|------|----------|-------|-------------|----------|
| **Server** | `caddy/`, `authelia/`, `postgres/`, `homer/`, `metabase/`, `openclaw/`, `remark42/`, `umami/`, `quartz/`, `mattermost/`, `forge/` | Docker Compose | `./run.sh up` | Hosting services behind an authenticated gateway |
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
| **AI** | [OpenClaw](https://openclaw.org) | AI agent gateway (Telegram, web) with a public-safe pi-shell-acp Docker template |
| **Chat** | [Mattermost](https://mattermost.com) | Team messaging |
| **Code** | [Forgejo](https://forgejo.org) | Self-hosted git forge — issues, PRs, labels, webhooks. Operator companion: [`forge-config`](https://github.com/junghan0611/forge-config) |
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
| `/openclaw/` | OpenClaw AI | required; `/openclaw/hooks/forgejo` bypasses Authelia for Forgejo webhooks |
| `/remark42/` | Remark42 comments | public |
| `/umami/` | Umami analytics | public |
| `/mattermost/` | Mattermost (web UI) | required; API/git surface bypasses Authelia |
| `/forge/` | Forgejo | Forgejo self-auth (Authelia bypass) |

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

A **Nix + home-manager** flake that reproduces your shell and dev tools on any Debian or Ubuntu (Oracle ARM / VPS / laptop).

> **Phone / Galaxy S26 AVF Debian VM — currently parked.** home-manager OOMs in the VM,
> and the apt-only fallback in [`mobile/`](mobile/) does bootstrap, but Android tears down
> the VM whenever the Terminal app drops to background, so the VM is not a usable everyday
> environment yet. Phone route is on hold until AVF guarantees background persistence.
> Use a real machine (Oracle ARM, VPS, laptop) for now.

**Design pillars:**

- **Apt minimum.** Exactly three apt packages: `curl`, `xz-utils`, `ca-certificates`. Everything else (git, gh, ripgrep, your editor, languages) comes through Nix.
- **Zero security keys at start.** Public HTTPS tarball clone, no SSH key required. GitHub auth via `gh auth login` device flow only when you want to push.
- **No hardcoded identity.** All personal values live in a single `home/settings.nix` file (gitignored). Fork the repo, edit one file, run one script.
- **One bootstrap for VPS / laptop / cloud ARM.** Same flake, different `system` and profile.

See [`home/README.md`](home/README.md) for the full walkthrough, and [`mobile/README.md`](mobile/README.md) for the parked phone-route notes.

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
├── openclaw/              # server — OpenClaw AI agent template
├── quartz/                # server — digital garden builder
├── remark42/              # server — comments
├── umami/                 # server — web analytics
├── mattermost/            # server — team chat
├── forge/                 # server — Forgejo (operator companion: forge-config)
├── scripts/               # server — init, up, status, backup
├── run.sh                 # server — service manager
├── home/                  # home — Nix + home-manager (Oracle ARM / VPS / laptop)
│   ├── flake.nix
│   ├── settings.nix.example   # copy to settings.nix (gitignored)
│   ├── modules/minimal.nix
│   ├── bootstrap.sh
│   └── README.md
├── mobile/                # parked — apt-only fallback for AVF Debian VM (phone)
│   ├── apt-bootstrap.sh
│   └── README.md          # see for current status (route on hold)
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
| Forgejo | `codeberg.org/forgejo/forgejo:15` | 15.x LTS |

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

## Companion repos

`openglg-config` is the **service + shell surface** that sits on top of a host. The host itself is owned by a separate repo:

| Repo | Role | Path |
|------|------|------|
| [`junghan0611/nixos-config`](https://github.com/junghan0611/nixos-config) | **Mother repo** — declarative NixOS host configuration (Oracle ARM, NUC, laptops). Owns the OS, kernel, system services, system-level home-manager. Backup of OpenClaw runtime / Docker definitions. | `~/repos/gh/nixos-config/` |
| `openglg-config` (this repo) | **Companion** — portable service stack (Docker Compose) + portable home-manager (`home/`) that can land on any Debian/Ubuntu host, including non-NixOS VPS. | `~/repos/gh/openglg-config/` |
| [`junghan0611/forge-config`](https://github.com/junghan0611/forge-config) | **Operator companion for `forge/`** — the agent / bot surface that drives the Forgejo instance this repo provisions. Holds the `bin/forge` CLI, the label protocol, the bot footer convention, and the policies an operator (or sibling agent) follows when working on issues/PRs inside Forgejo. Infra lives here; operator workflow lives there. | `~/repos/gh/forge-config/` |

Use the mother repo when the host is yours and reproducibility starts at the OS. Use this repo when the host already exists (cloud VPS, somebody else's box, AVF VM) and you only get to bring your shell + services.

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

### v0.5.0 (2026-05-27)

- **`home/` Step 2 — modular feature flags**: `home/modules/minimal.nix` stays
  the baseline (always loaded: bash + git identity + gh + rg/fd/bat). Eight new
  opt-in modules ship next to it, each gated by `settings.features.<name>`:
  `shell`, `git`, `cli`, `tmux`, `emacs`, `gpg`, `syncthing`, `languages`.
  Default for every flag is `false`, so a fresh `cp settings.nix.example
  settings.nix` still produces the minimal smoke-test environment. Turn on
  what you need per host — `features.emacs = true;` pulls emacs-nox plus
  spell/mail/LaTeX deps, `features.languages = true;` pulls nodejs/python/go/
  zig/clojure + LSPs, and so on. Module bodies use `lib.mkIf`, so leaving a
  flag off is essentially free at eval time. Identity (`username`, `email`,
  `authInfoSource`) stays in `settings.nix`; modules never hardcode it.

### v0.4.1 (2026-05-27)

- **OpenClaw Forgejo webhook bypass**: `/openclaw/hooks/forgejo` now bypasses
  Authelia so Forgejo can deliver webhooks without an Authelia session. OpenClaw
  verifies its own `hooks.token`. The bypass is an **exact path**, not a wildcard
  — broader `/openclaw/hooks/*` remains behind Authelia to avoid exposing
  `/openclaw/hooks/agent` (direct-agent endpoint). Applied to both
  `caddy/Caddyfile` and `caddy/Caddyfile.template`.
- **Idempotency header translation**: Caddy rewrites Forgejo's `X-Forgejo-Delivery`
  into a source-agnostic `X-OpenClaw-Idempotency-Key` header on its way to
  OpenClaw, so the same idempotency contract works for future webhook sources
  (GitHub `X-GitHub-Delivery`, GitLab `X-Gitlab-Event-UUID`) without OpenClaw
  needing to know each provider's header name.
- **Forgejo webhook allow-list**: `forge/docker-compose.yml` now sets
  `FORGEJO__webhook__ALLOWED_HOST_LIST=private,loopback,${DOMAIN}`. The default
  `private,loopback` blocked outbound delivery to `${DOMAIN}/openclaw/hooks/...`
  (Forgejo resolves the operator's own hostname to a public IP and refuses).
  Adding the exact hostname keeps the allow-list as narrow as possible. See
  `forge/README.md` Troubleshooting for the symptom signature.

### v0.4.0 (2026-05-27)

- **Forge service added**: `forge/` ships a Forgejo 15 + PostgreSQL 16 stack on
  the same Caddy gateway, routed at `${DOMAIN}/forge/` with path-based prefix
  stripping. Forgejo runs self-authenticated (its own user / team / token
  model), so Authelia is **bypassed** for `/forge/*`; the policy is identical
  to Mattermost's API surface and keeps git, mobile clients, webhooks, and bot
  tokens reachable. Closed instance — `DISABLE_REGISTRATION=true`, SSH off.
- **Companion repo**: operator-facing skill + bot CLI lives in
  [`junghan0611/forge-config`](https://github.com/junghan0611/forge-config).
- **Gotchas captured** (in `forge/README.md`): never set `INSTALL_LOCK` via env
  (causes crash loop after wizard); Forgejo tokens require `write:user` where
  GitHub would not; Caddy's bind-mounted `Caddyfile` is inode-sensitive — fall
  back to `docker compose restart caddy` if `caddy reload` looks stuck.

### v0.3.1 (2026-05-06)

- **Phone route parked**: AVF Debian VM on Galaxy S26 verified unusable as everyday environment — `home/` route OOMs in the VM, `mobile/` apt fallback boots fine but Android tears the VM down on Terminal-app background. Documented in `mobile/README.md` + `home/README.md` + `MEMORY.md`. Route stays in tree for retry once AVF guarantees background persistence.
- **Companion relationship documented**: explicit pairing with [`nixos-config`](https://github.com/junghan0611/nixos-config) (mother repo, owns the host) ↔ this repo (companion, owns the portable service + shell surface).
- **`mobile/`**: new directory holding the apt-only fallback and its retry checklist. Targets: Oracle ARM, VPS, laptop (no phone).

### v0.3.0 (2026-04-19)

- **Scope expansion**: repo now ships two halves — server (Docker Compose) **and** home (Nix + home-manager)
- **`home/`**: Step 1 minimal PoC — `flake.nix`, `settings.nix.example`, `modules/minimal.nix`, `bootstrap.sh`
- **Bootstrap**: apt minimum (curl, xz-utils, ca-certificates) → Determinate Nix installer → `home-manager switch`
- **Targets at the time**: Galaxy S26 AVF Debian VM (aarch64-linux), Ubuntu VPS (x86_64-linux), any Debian-family laptop. *S26 target later parked — see v0.3.1.*
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
