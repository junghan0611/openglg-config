# AGENTS.md

## Project

openglg-config — a reproducible single-fork work surface, **companion to** [`junghan0611/nixos-config`](https://github.com/junghan0611/nixos-config) (mother repo: NixOS host config, OS-level reproducibility). This repo carries what doesn't depend on NixOS — the portable service stack and the portable shell layer.

Two cooperating halves:

1. **Server half** (top-level dirs) — an authenticated self-hosted platform.
   Caddy (gateway) + Authelia (auth) + Docker Compose: Homer, Metabase, OpenClaw,
   Quartz, Remark42, Umami, Mattermost, Forge (Forgejo), n8n, PostgreSQL.
2. **Home half** (`home/` + parked `mobile/`) — a Nix + home-manager flake that reproduces the operator's
   shell and dev tools on any Debian/Ubuntu (Oracle ARM / VPS / laptop), starting from an
   absolute-minimum apt footprint and zero security keys. `mobile/` is an apt-only fallback
   left in the tree for the AVF / phone case (currently parked — see Status below).

The two halves are intentionally loosely coupled. Either can be used alone. They
coexist in one repo so a solo operator (or a template-forker) has **one clone,
one set of docs, one bootstrap story** covering "my server + my shell".

## Status — Phone route parked (2026-05-06)

- `home/` — works on Oracle ARM, x86_64 VPS, laptops. **Does not** work in the Galaxy S26 AVF Debian VM (OOM during nix eval/build).
- `mobile/` — apt-only fallback bootstraps cleanly, but Android tears the VM down whenever the Terminal app drops to background, so the VM is not usable as a stable everyday environment.
- Until AVF (or vendor OS policy) guarantees VM background persistence, **the phone route is on hold**. Both directories stay in tree as documented retry surfaces. See `mobile/README.md`'s retry checklist.

## Mother repo (`nixos-config`)

When the host itself is owned (not a rented VPS), the source of truth is the mother repo:

- Host OS, kernel, system services, system-level home-manager, hardware specifics → `nixos-config`.
- This repo's `home/` is intentionally a **subset** of what nixos-config does — it must work without NixOS, with three apt packages and Determinate Nix.
- Backup of OpenClaw runtime (`~/openclaw/`) Docker definitions also lives in `nixos-config/docker/openclaw/`. This repo's `openclaw/` is the public template for Docker Compose deployment, decoupled from the Oracle SSOT.

Operating principle: **don't duplicate state**. If a value belongs in the host OS, it belongs in `nixos-config`, not here.

## Structure

```
caddy/          Reverse proxy + auto HTTPS (gateway)           [server]
authelia/       Authentication portal (forward_auth)           [server]
cloudflare-tunnel/ Outbound tunnel gateway (Cloudflare Access)  [server]
homer/          Service dashboard                              [server]
postgres/       Shared PostgreSQL (pgvector)                   [server]
metabase/       Business intelligence                          [server]
n8n/            Workflow automation (Cloudflare Tunnel, dedicated DB) [server]
openclaw/       OpenClaw AI gateway template (+ pi-shell-acp)   [server]
quartz/         Obsidian → static site                         [server]
remark42/       Self-hosted comments                           [server]
umami/          Web analytics (own PostgreSQL)                 [server]
mattermost/     Team chat                                      [server]
forge/          Forgejo — self-hosted git forge (Authelia bypass) [server]
pomerium/       Alternative OAuth gateway (optional)           [server]
scripts/        init, up, status, restart, backup, logs        [server]
run.sh          Service manager                                [server]

home/           Nix flake + home-manager scaffold              [home]
home/flake.nix              Reads settings.nix, one config per user
home/settings.nix.example   Template; settings.nix is gitignored
home/modules/               home-manager modules (no hardcoded identity)
home/bootstrap.sh           apt minimum → Nix install → switch
home/README.md              Usage and Step 1 status

mobile/         apt-only fallback for AVF Debian VM (parked)   [home/parked]
mobile/apt-bootstrap.sh     Bootstraps apt deps + fnm/node/pnpm
mobile/README.md            Why it exists, why it's parked, retry checklist

MEMORY.md       Operator notes (tracked) — companion to nixos-config/MEMORY.md
```

## Rules — repo-wide

- Keep it simple. Target: anyone with a VPS and Docker (server) or a Debian/Ubuntu machine (home).
- Works on any Linux (x86_64 or aarch64). Not tied to any cloud vendor.
- No Kubernetes, no Terraform, no company names, no internal IPs, no personal identifiers
  in committed files. Use `DOMAIN`, `ALLOWED_DOMAIN`, `example.com`, `alice` as placeholders.
- `.template` / `.example` files are templates — never commit real secrets.

## Rules — server half

- No Nix on the server side. Plain Docker Compose only.
- Real config files (`Caddyfile`, `configuration.yml`, `users.yml`, `config.yml`) are gitignored.
- `docker-compose.yml` files are self-contained per service.
- All persistent data lives under `~/docker-data/<service>/`.
- Caddy creates the `proxy` network. Other services join it as `external: true`.
- Scripts in `scripts/` must be idempotent and safe to re-run.

## Rules — home half

- No hardcoded identity. All personal values (`username`, `fullName`, `email`, `system`
  arch, feature toggles) live **only** in `home/settings.nix`. Modules and profiles must
  read from `settings` via `extraSpecialArgs`; no literal usernames or paths elsewhere.
- `home/settings.nix` is gitignored. Only `home/settings.nix.example` ships in the repo.
- `home/bootstrap.sh` is the Layer 1 surface. It may only install these apt packages:
  `curl`, `xz-utils`, `ca-certificates`. Anything else goes through Nix.
- No SSH keys required to start. Public repo → anonymous HTTPS tarball clone. For push,
  users run `gh auth login` (device flow) **after** bootstrap.
- `home/` targets aarch64-linux (Oracle A1 ARM and other cloud ARM) **and** x86_64-linux
  (Ubuntu VPS, laptops). The flake's `system` is driven by `settings.system`.
  **Not** the S26 AVF VM — that target is parked under `mobile/`, see Status above.
- `mobile/` is intentionally **not** a home-manager profile. It's the documented apt route
  for the AVF/phone case. Don't try to merge it back into `home/` until the underlying
  AVF/OS issues are resolved — the value of keeping it separate is that the boundary
  is visible.
- Module layout: `home/modules/minimal.nix` is the **baseline** (always loaded —
  bash + git identity + gh + rg/fd/bat). Everything else (`shell`, `git`, `cli`,
  `tmux`, `emacs`, `gpg`, `syncthing`, `languages`) lives in its own
  `home/modules/<name>.nix` and is gated by `settings.features.<name>` via
  `lib.mkIf`. Default for every flag is `false` — a fresh `cp settings.nix.example
  settings.nix` produces the minimal baseline and nothing more.
- New modules must follow the same pattern: gate with `settings.features.<name> or
  false`, read identity from `settings.user.*`, never hardcode a username or path.
- Profile split (server / vps / workstation) and `run.sh home:*` subcommands stay
  out of scope — one profile + feature flags has been enough so far.

## Gateway — two options: Caddy + Authelia, or Cloudflare Tunnel

Two gateways ship in this repo; use either, or mix per service:

- **A. Caddy + Authelia** — path-based routing on one domain, Authelia for auth.
  The templates default to this; the rules below describe it.
- **B. Cloudflare Tunnel + Access (free)** — outbound-only, one hostname per
  service, Cloudflare Access for auth. No public IP, no Caddy/Authelia for those
  services. See `cloudflare-tunnel/`. metabase and n8n run on B in this deployment.

### Caddy + Authelia (option A)

- **Path-based routing** — single domain, no wildcard DNS needed. (Exception:
  n8n has no working sub-path mode — even under option A it needs its own
  `n8n.DOMAIN` subdomain, not a `/n8n` path. Or use option B's tunnel.)
- **Caddy `forward_auth`** — delegates authentication to Authelia.
- **`route` directive** — ensures forward_auth runs before `uri strip_prefix`.
- **Authelia path prefix** — served at `/authelia/`, server address includes path
  (`tcp://:9091/authelia`).
- Public services (homer, remark42, umami): no auth.
- Protected services (openclaw): `one_factor` auth via Authelia.
- **metabase / n8n — gateway is the operator's choice (two options shipped).**
  - **Option A — Caddy + Authelia.** metabase at `/metabase` (path); n8n needs a
    `n8n.DOMAIN` subdomain block (it has no working sub-path mode). Templates
    (`Caddyfile.template`, `configuration.yml.template`) ship this option.
  - **Option B — Cloudflare Tunnel + Access (free).** Each on a dedicated hostname
    via cloudflared (`cloudflare-tunnel/`); no Caddy/Authelia involved.
  Pick one per service — never both for the same hostname. This deployment runs B;
  the committed templates default to showing A so a forker starts with the
  Caddy-only stack.
- **Self-authenticated services (mattermost API, forge)**: Authelia bypass. The
  service runs its own login/token system, so git, mobile apps, webhooks, and
  external API clients can reach it without an Authelia cookie. Bypass is scoped
  to a single path prefix; never widen it to `/`.

Notes for the Cloudflare-Tunnel path (option B): cloudflared joins the `proxy`
network and the dashboard maps each hostname to the container (`http://n8n:5678`,
`http://metabase:3333`) — never a container IP. A hostname maps to exactly one
tunnel, so moving it between hosts means re-pointing it in the dashboard (see
cloudflare-tunnel/README.md). n8n keeps its own login + JWT and uses a dedicated
`n8n-db` (forge pattern) regardless of which gateway fronts it.
- **External webhook receivers**: bypass Authelia only on the **exact path** the
  external service posts to, not on a wildcard. Example:
  `handle /openclaw/hooks/forgejo` is OK; `handle /openclaw/hooks/*` is **not** —
  the wildcard would also expose `/openclaw/hooks/agent` (a direct-agent endpoint
  that can fall back to a default agent if `agentId` is omitted), widening the
  blast radius on token leak. One exact path per webhook source.
- **Interactive-button / approval-gate callbacks: keep them internal, gate at the
  network.** When the gateway attaches action buttons to a chat message (the
  approval gate for a delegated agent-in-charge — a click *is* an authorization),
  the chat **server** POSTs to a callback URL when a button is clicked. For a
  host-native gateway, point that callback at the **bridge gateway**
  (`http://172.18.0.1:18789/mattermost`, the channel's `callbackBaseUrl`), **not**
  the public hostname. The callback then never leaves the host: no Caddy, no
  Authelia, no `X-Forwarded-For`/`trustedProxies` in play. Security is the chain
  already in place — the user must be logged into the chat service to click, and
  the **host firewall** already controls who can reach `:18789` (only the
  bridge/Caddy today; an arbitrary container is refused). Do **not** add an
  app-layer source-IP allowlist on top: on a shared bridge it cannot tell peers
  apart without static pins, it collides with the global `trustedProxies` (a
  *direct* source that is also inside `trustedProxies` is mistaken for a proxy →
  its missing XFF → rejected), and it stops no attacker the firewall doesn't
  already stop. One requirement on the chat-service side: its own SSRF guard
  (Mattermost `AllowedUntrustedInternalConnections`) must list the gateway
  address, or it blocks its own outbound callback to that private IP.

## Container addressing — never hardcode a container IP

Docker bridge IPs (`172.18.0.x`) are **not stable**. They are assigned in
container start order, so a recreate (image bump, `up -d`, restart) can hand a
container a different `.x` than it had before. A literal like `172.18.0.7` that
meant "mattermost" yesterday can resolve to "postgres" today. Hardcoding one
breaks silently — the config still parses, the target is just wrong.

Rules:

- **Container → container:** use the service **DNS name**, never an IP. Caddy
  already does this (`reverse_proxy mattermost:8065`, `reverse_proxy
  homer:8080`). Docker's embedded DNS resolves the name to the current IP on
  every connect, so churn is invisible.
- **Host-native → container:** a service running on the host outside Docker
  (e.g. the host-native OpenClaw gateway reaching dockerized Mattermost) cannot
  use Docker DNS. Reach it through the **Caddy public hostname** instead —
  `https://<DOMAIN>/mattermost` on the Authelia-free `/mattermost/api|hooks|
  oauth|plugins` prefixes. Stable, TLS-terminated, and already routed.
- **Trusting a bridge vs authenticating a peer.** To trust "traffic from the
  bridge" (e.g. `trustedProxies` so the gateway reads XFF behind Caddy) the
  **subnet** `172.18.0.0/16` is right and churn-immune. But a subnet **cannot
  authenticate a specific peer** — it trusts every container on the bridge as
  one. The moment a config must tell two same-bridge services apart (trust Caddy
  as a proxy but treat the chat server as an origin), a subnet collapses them and
  an IP allowlist becomes theater. Then either pin the peers to static IPs and
  match exact IPs, or — simpler — drop the app-layer IP check and gate at the
  network (firewall). A subnet grants trust; it does not prove identity.
- **The one stable single IP is `172.18.0.1`** — the bridge *gateway*, not a
  container. That is how Caddy reaches a host-native service
  (`reverse_proxy 172.18.0.1:18789`). It is fixed for the life of the network,
  so it is the only literal IP that belongs in committed/runtime config.

History: 2026-06-04 Mattermost `fetch failed` from the host-native OpenClaw
gateway. Root cause = a stale hardcoded `baseUrl: 172.18.0.7` (had drifted to
postgres) plus `trustedProxies: ["172.18.0.2"]` (had drifted to homer). Fixed by
switching to the Caddy hostname + the `172.18.0.0/16` subnet. The runtime config
lives in the private host runbook; this rule is the portable lesson.

## Conventions

- README and AGENTS.md in English.
- Commit messages in English, `feat: ...` / `fix: ...` / `docs: ...` style. No `Co-Authored-By`.
- Server compose files use `${HOME}` and `${DOMAIN}` (no hardcoded values).
- One `docker-compose.yml` per server service directory.
- Each server service has its own `.env.example` or `.template` with inline comments.
- Server startup order: caddy → authelia → postgres → homer → everything else.
- Home module files never contain the maintainer's username or email — those come
  from `settings`.

## Operations — server

```bash
./run.sh up         # start all (core → apps)
./run.sh down       # stop all
./run.sh restart    # full restart
./run.sh status     # container status + disk
./run.sh logs       # summary or: ./run.sh logs <container>
```

## Operations — home

```bash
# Fresh Debian/Ubuntu machine (S26 AVF, VPS, laptop):
curl -L https://github.com/junghan0611/openglg-config/archive/main.tar.gz | tar xz
cd openglg-config-main/home
cp settings.nix.example settings.nix     # edit user + system
./bootstrap.sh

# Re-run after editing settings.nix or modules:
cd home && nix run home-manager/release-25.11 -- switch --flake . -b backup
```

## Testing

### Server

```bash
# Config validation
for d in caddy authelia homer postgres metabase openclaw remark42 umami mattermost forge n8n cloudflare-tunnel; do
  (cd $d && docker compose config --quiet && echo "$d: OK") || echo "$d: FAIL"
done

# Endpoint check
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/           # 200 (homer)
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/authelia/  # 200 (login)
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/metabase/  # 302 (auth redirect; option A only)
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/forge/     # 200 (Forgejo, self-auth)
curl -s https://DOMAIN/forge/api/v1/version                      # {"version":"15.0.x"}
docker exec n8n wget -qO- http://localhost:5678/healthz         # {"status":"ok"} (n8n; reached via Cloudflare Tunnel, not Caddy)
docker logs cloudflared 2>&1 | grep -i "Registered tunnel"      # tunnel connector is up
```

### Home (Step 1 smoke test)

After `./bootstrap.sh`, in a fresh shell:

```bash
nix --version
git --version && gh --version
rg --version && fd --version && bat --version
git config --global user.email     # matches settings.nix
dpkg -l | awk '/^ii/ {print $2}' | wc -l   # track apt package creep
```

If all five commands succeed and `dpkg` count hasn't ballooned, the home pipe works.
