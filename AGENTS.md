# AGENTS.md

## Project

openglg-config — a reproducible single-fork work surface with two cooperating halves:

1. **Server half** (top-level dirs) — an authenticated self-hosted platform.
   Caddy (gateway) + Authelia (auth) + Docker Compose: Homer, Metabase, OpenClaw,
   Quartz, Remark42, Umami, Mattermost, PostgreSQL.
2. **Home half** (`home/`) — a Nix + home-manager flake that reproduces the operator's
   shell and dev tools on any Debian/Ubuntu (including Android AVF Debian on S26),
   starting from an absolute-minimum apt footprint and zero security keys.

The two halves are intentionally loosely coupled. Either can be used alone. They
coexist in one repo so a solo operator (or a template-forker) has **one clone,
one set of docs, one bootstrap story** covering "my server + my shell".

## Structure

```
caddy/          Reverse proxy + auto HTTPS (gateway)           [server]
authelia/       Authentication portal (forward_auth)           [server]
homer/          Service dashboard                              [server]
postgres/       Shared PostgreSQL (pgvector)                   [server]
metabase/       Business intelligence                          [server]
openclaw/       AI agent gateway                               [server]
quartz/         Obsidian → static site                         [server]
remark42/       Self-hosted comments                           [server]
umami/          Web analytics (own PostgreSQL)                 [server]
mattermost/     Team chat                                      [server]
pomerium/       Alternative OAuth gateway (optional)           [server]
scripts/        init, up, status, restart, backup, logs        [server]
run.sh          Service manager                                [server]

home/           Nix flake + home-manager scaffold              [home]
home/flake.nix              Reads settings.nix, one config per user
home/settings.nix.example   Template; settings.nix is gitignored
home/modules/               home-manager modules (no hardcoded identity)
home/bootstrap.sh           apt minimum → Nix install → switch
home/README.md              Usage and Step 1 status
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
- `home/` targets aarch64-linux (S26 AVF Debian, Oracle A1 ARM) **and** x86_64-linux
  (Ubuntu VPS, laptops). The flake's `system` is driven by `settings.system`.
- Step 1 (current): one `homeConfigurations.<settings.user.username>` with a minimal
  module (bash + git + gh + rg/fd/bat). Step 2+ (parked in linked llmlog note):
  profile split (`mobile` / `vps` / `workstation`), feature flags, language modules,
  pass/gpg/authinfo wiring, `run.sh home:*` subcommands.

## Gateway: Caddy + Authelia

- **Path-based routing** — single domain, no wildcard DNS needed.
- **Caddy `forward_auth`** — delegates authentication to Authelia.
- **`route` directive** — ensures forward_auth runs before `uri strip_prefix`.
- **Authelia path prefix** — served at `/authelia/`, server address includes path
  (`tcp://:9091/authelia`).
- Public services (homer, remark42, umami): no auth.
- Protected services (metabase, openclaw): `one_factor` auth via Authelia.

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
for d in caddy authelia homer postgres metabase openclaw remark42 umami mattermost; do
  (cd $d && docker compose config --quiet && echo "$d: OK") || echo "$d: FAIL"
done

# Endpoint check
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/           # 200 (homer)
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/authelia/  # 200 (login)
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/metabase/  # 302 (auth redirect)
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
