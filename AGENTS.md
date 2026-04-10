# AGENTS.md

## Project

openglg-config — an authenticated self-hosted work surface.
Caddy (gateway) + Authelia (auth) + Docker Compose: Homer, Metabase, OpenClaw, Quartz, Remark42, Umami, PostgreSQL.

## Structure

```
caddy/          Reverse proxy + auto HTTPS (gateway)
authelia/       Authentication portal (forward_auth, file-based users)
homer/          Service dashboard
postgres/       Shared PostgreSQL (pgvector)
metabase/       Business intelligence
openclaw/       AI agent gateway
quartz/         Obsidian → static site
remark42/       Self-hosted comments
umami/          Web analytics (own PostgreSQL)
scripts/        init, up, status, restart, backup, logs
```

## Rules

- Keep it simple. Target: anyone with a VPS and Docker.
- Works on any Linux (x86_64 or ARM). Not tied to any cloud vendor.
- No flake.nix, no Nix, no Kubernetes, no Terraform.
- `.template` files are templates — never commit real secrets.
- Real config files (Caddyfile, configuration.yml, users.yml, config.yml) are in `.gitignore`.
- `docker-compose.yml` files are self-contained per service.
- All persistent data goes under `~/docker-data/<service>/`.
- Caddy creates the `proxy` network. Other services join it as `external: true`.
- Scripts in `scripts/` must be idempotent and safe to re-run.
- No company names, internal IPs, or personal information in committed files.
- Use `DOMAIN`, `ALLOWED_DOMAIN`, `example.com` as placeholders.

## Gateway: Caddy + Authelia

- **Path-based routing** — single domain, no wildcard DNS needed.
- **Caddy `forward_auth`** — delegates authentication to Authelia.
- **`route` directive** — ensures forward_auth runs before `uri strip_prefix`.
- **Authelia path prefix** — served at `/authelia/`, server address includes path (`tcp://:9091/authelia`).
- Public services (homer, remark42, umami): no auth.
- Protected services (metabase, openclaw): `one_factor` auth via Authelia.

## Conventions

- README in English.
- Compose files use `${HOME}` and `${DOMAIN}` for paths (no hardcoded values).
- One `docker-compose.yml` per service directory.
- Each service has its own `.env.example` or `.template` with inline comments.
- Startup order: caddy → authelia → postgres → homer → everything else.

## Operations

```bash
./run.sh up         # start all (core → apps)
./run.sh down       # stop all
./run.sh restart    # full restart
./run.sh status     # container status + disk
./run.sh logs       # summary or: ./run.sh logs <container>
```

## Testing

```bash
# Config validation
for d in caddy authelia homer postgres metabase openclaw remark42 umami; do
  (cd $d && docker compose config --quiet && echo "$d: OK") || echo "$d: FAIL"
done

# Endpoint check
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/           # 200 (homer)
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/authelia/  # 200 (login)
curl -s -o /dev/null -w '%{http_code}' https://DOMAIN/metabase/  # 302 (auth redirect)
```
