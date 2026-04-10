# AGENTS.md

## Project

openglg-config — an authenticated self-hosted work surface.
Pomerium (gateway) + Docker Compose: Homer, Metabase, OpenClaw, Quartz, Remark42, Umami, PostgreSQL.

## Structure

```
pomerium/       Identity-aware reverse proxy + auto HTTPS (gateway)
homer/          Service dashboard
postgres/       Shared PostgreSQL (pgvector)
metabase/       Business intelligence
openclaw/       AI agent gateway
quartz/         Obsidian → static site
remark42/       Self-hosted comments
umami/          Web analytics
caddy/          Alternative gateway (no auth, simpler)
scripts/        init, up, status, restart, backup, logs
```

## Rules

- Keep it simple. Target: anyone with a VPS and Docker.
- Works on any Linux (x86_64 or ARM). Not tied to any cloud vendor.
- No flake.nix, no Nix, no Kubernetes, no Terraform.
- `.env.example` and `.template` files are templates — never commit real secrets.
- `docker-compose.yml` files are self-contained per service.
- All persistent data goes under `~/docker-data/<service>/`.
- Pomerium creates the `proxy` network. Other services join it as `external: true`.
- Scripts in `scripts/` must be idempotent and safe to re-run.
- No company names, internal IPs, or personal information in committed files.
- Use `DOMAIN`, `ALLOWED_DOMAIN`, `example.com` as placeholders.

## Conventions

- README in English.
- Compose files use `${HOME}` for paths (no hardcoded usernames).
- One `docker-compose.yml` per service directory.
- Each service has its own `.env.example` or `.template` with inline comments.
- Startup order: pomerium → postgres → homer → everything else.

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
for d in caddy homer postgres metabase openclaw remark42 umami; do
  (cd $d && docker compose config --quiet && echo "$d: OK") || echo "$d: FAIL"
done
```
