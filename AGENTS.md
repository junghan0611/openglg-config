# AGENTS.md

## Project

seedbed-config — a seedbed for self-hosted digital gardens.
Oracle Cloud Free Tier + Docker Compose: Caddy + Quartz + Remark42 + Umami + OpenClaw.

## Structure

```
caddy/          Reverse proxy + auto HTTPS
quartz/         Obsidian → static site build
remark42/       Self-hosted comments
umami/          Web analytics (PostgreSQL)
openclaw/       AI agent gateway
scripts/        init, up, status, restart, backup, logs
```

## Rules

- Keep it simple. Target audience: non-NixOS, non-expert users.
- Ubuntu 22.04 on ARM (aarch64). All services run in Docker.
- No flake.nix, no Nix, no complex IaC.
- `.env.example` files are templates — never commit real secrets.
- `docker-compose.yml` files should be self-contained per service.
- All persistent data goes under `~/docker-data/<service>/`.
- Caddy creates the `proxy` network. Other services join it as `external: true`.
- OpenClaw binds to `127.0.0.1` only (SSH tunnel access).
- Scripts in `scripts/` must be idempotent and safe to re-run.

## Conventions

- README in English.
- Compose files use `${HOME}` for paths (no hardcoded usernames).
- One `docker-compose.yml` per service directory.
- Each service has its own `.env.example` with inline comments.

## Testing

```bash
# Validate compose files
for d in caddy remark42 umami openclaw; do
  cd $d && docker compose config --quiet && echo "$d: OK" && cd ..
done
```
