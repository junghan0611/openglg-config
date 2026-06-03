# OpenClaw service template

Public-safe Docker Compose template for running [OpenClaw](https://openclaw.org) behind the repo's Caddy + Authelia gateway.

This directory is intentionally the OpenClaw surface for `openglg-config`. It is **not** a new generic `agent-web` template. The private/runtime deployments may be richer, but this public template keeps only reusable wiring.

## What is included

- OpenClaw gateway image pinned to the 2026.5.18 generation.
- `pi`, `@junghanacs/pi-shell-acp`, `codex-acp`, `gemini`, and common CLI helpers baked into the image.
- Compose defaults that use Docker named volumes for runtime state and backend auth.
- `openclaw-cli` profile for one-off plugin install, backend login, and smoke commands.
- Caddy/Authelia compatibility: gateway listens on `openclaw-gateway:18789`; `/openclaw/` stays a protected route in the root templates.

## Public-safety boundary

Do not commit real secrets, tokens, private hostnames, internal IPs, or personal runtime config.

Default policy:

- Backend auth is created **inside the container** and persisted in named volumes:
  - `/home/node/.claude`
  - `/home/node/.codex`
  - `/home/node/.gemini`
- pi runtime state is persisted in the named volume mounted at `/home/node/.pi`.
- The optional host workspace mount defaults to `./workspace`; keep any real path in local `.env` only.

Advanced opt-in:

- Host auth passthrough (`~/.claude`, `~/.codex`, `~/.gemini`, `~/.pi/agent`) is acceptable only on a trusted single-user host. Use `docker-compose.override.yml` locally and never commit it.

## Quick start

```bash
cd openclaw
cp .env.example .env
cp config/openclaw.json.example config/openclaw.json
# edit .env and config/openclaw.json; set GATEWAY_TOKEN at minimum
```

Build the image:

```bash
# Needed when testing this directory standalone before the root Caddy stack creates it.
docker network inspect proxy >/dev/null 2>&1 || docker network create proxy

docker compose build openclaw-gateway
```

Install the OpenClaw plugin and pi bridge into the mounted runtime volumes:

```bash
# OpenClaw host adapter plugin.
docker compose run --rm openclaw-cli \
  plugins install npm:@junghan0611/openclaw-pi-shell-acp

# pi-shell-acp bridge visible to child `pi` processes.
docker compose run --rm --entrypoint sh openclaw-cli -lc '
  pi install npm:@junghanacs/pi-shell-acp
  mkdir -p "$HOME/.openclaw/workspace"
  "$(npm root -g)/@junghanacs/pi-shell-acp/run.sh" install "$HOME/.openclaw/workspace"
'
```

Authenticate at least one backend **inside the container**:

```bash
# Pick what you use. These write to named volumes, not the host home.
docker compose run --rm --entrypoint sh openclaw-cli -lc 'claude login'
docker compose run --rm --entrypoint sh openclaw-cli -lc 'codex login'
docker compose run --rm --entrypoint sh openclaw-cli -lc 'gemini'
```

Start the gateway:

```bash
docker compose up -d openclaw-gateway
```

If using the root stack, Caddy proxies `/openclaw/` to `openclaw-gateway:18789` and Authelia protects it.

## Channel base URLs — use the Caddy hostname, not a container IP

When a channel in `config/openclaw.json` points at another service in this stack
(e.g. `channels.mattermost.baseUrl`, `<MATTERMOST_BASE_URL>`), set it to the
**Caddy public hostname**, not a Docker container IP:

```
"baseUrl": "https://<DOMAIN>/mattermost"     # ✅ stable, TLS, Authelia-free API path
"baseUrl": "http://172.18.0.7:8065"          # ✗ container IP churns on recreate
```

Docker bridge IPs (`172.18.0.x`) are reassigned in start order, so a literal IP
silently drifts to the wrong container after any restart. The Mattermost
`/mattermost/api|hooks|oauth|plugins` prefixes bypass Authelia (service runs its
own token auth), so a bot reaches them with just `<MATTERMOST_BOT_TOKEN>`. If the
gateway runs **inside** Docker on the `proxy` network it may instead use the DNS
name (`http://mattermost:8065`); a **host-native** gateway must use the hostname.
See AGENTS.md "Container addressing" for the full rule.

## Smoke checks

Compose wiring:

```bash
docker compose config --quiet
```

Image/runtime basics:

```bash
docker compose run --rm --entrypoint sh openclaw-cli -lc '
  node --version
  pi --version
  claude --version || true
  codex --version || true
  codex-acp --version || true
  gemini --version || true
  node openclaw.mjs plugins list --json
'
```

Bridge smoke after backend login:

```bash
docker compose run --rm --entrypoint sh openclaw-cli -lc '
  "$(npm root -g)/@junghanacs/pi-shell-acp/run.sh" smoke-all "$HOME/.openclaw/workspace"
'
```

This validates deployment wiring. It does not re-test pi-shell-acp/OpenClaw bridge internals; those live in the plugin/bridge repos.

## Advanced: host auth passthrough

For a trusted single-user deployment, create a local `docker-compose.override.yml`:

```yaml
services:
  openclaw-gateway:
    volumes:
      - ~/.claude:/home/node/.claude:rw
      - ~/.codex:/home/node/.codex:rw
      - ~/.gemini:/home/node/.gemini:rw
      - ~/.pi/agent:/home/node/.pi/agent:rw
  openclaw-cli:
    volumes:
      - ~/.claude:/home/node/.claude:rw
      - ~/.codex:/home/node/.codex:rw
      - ~/.gemini:/home/node/.gemini:rw
      - ~/.pi/agent:/home/node/.pi/agent:rw
```

This makes the container part of your host credential trust boundary. The pi-shell-acp plugin does not copy or proxy credentials; it only lets official backend CLIs read the filesystem visible to the container.

## Advanced: emacs skill socket

If child pi sessions should use the `emacs` skill, mount an Emacs server socket and set a full socket path:

```yaml
services:
  openclaw-gateway:
    environment:
      PI_EMACS_AGENT_SOCKET: /run/emacs/server
    volumes:
      - /run/user/1000/emacs:/run/emacs:ro
  openclaw-cli:
    environment:
      PI_EMACS_AGENT_SOCKET: /run/emacs/server
    volumes:
      - /run/user/1000/emacs:/run/emacs:ro
```

Short names like `server` usually do not resolve inside Docker; use `/run/emacs/server`.

## Files

- `Dockerfile` — OpenClaw 2026.5.18 image plus ACP-route runtime tools.
- `docker-compose.yml` — public-safe service and CLI helper.
- `.env.example` — placeholders only.
- `config/openclaw.json.example` — minimal gateway config using `pi-shell-acp/gpt-5.4`.

## References

- Runtime reference: `~/repos/gh/nixos-config/docker/openclaw` (private/operational patterns only; do not copy secrets).
- Plugin boundary docs: `~/repos/gh/pi-shell-acp/plugins/openclaw/README.md`.
