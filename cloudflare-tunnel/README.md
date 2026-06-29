# Cloudflare Tunnel

Outbound-only gateway. An alternative to exposing services through Caddy on a
public IP: `cloudflared` connects out to Cloudflare's edge, and Cloudflare routes
named hostnames back through the tunnel. No inbound ports, no public IP, and
**Cloudflare Access** (Zero Trust) provides auth instead of Authelia.

Use this for services that can't do path-based routing under the main Caddy
domain (e.g. n8n, whose login breaks on a sub-path) but should still be
authenticated and reachable.

## Setup

1. **Create a tunnel** — Cloudflare dashboard → Zero Trust → Networks → Tunnels →
   *Create a tunnel* (cloudflared type). Copy the token.
2. **Token** — put it in the root `.env` as `TUNNEL_TOKEN=...` (gitignored), then
   `ln -sf ../.env .env` in this directory.
3. **Public Hostname** — in the tunnel's *Public Hostnames* tab, add:
   - Subdomain/Domain: your hostname, e.g. `n8n.example.com`
   - Service: `http://n8n:5678`
   cloudflared joins the `proxy` network, so it resolves the container name — do
   not use a container IP.
4. **Access policy** — Zero Trust → Access → Applications → add the hostname and a
   policy (e.g. allow a Google Workspace group). This is the login gate.
5. **Run** — `docker compose up -d` (the `proxy` network must already exist; it is
   created by `caddy`).

## Migrating a hostname between hosts

A hostname maps to exactly one tunnel. To move `n8n.example.com` from an old host
to this one:

1. Create a new tunnel here and run it (steps above).
2. Remove the hostname from the **old** tunnel's Public Hostnames.
3. Add it to the **new** tunnel pointing at this host's service.
4. Stop the old service. The old tunnel keeps serving its other hostnames.

## Operations

```bash
docker compose up -d
docker compose logs -f        # look for "Registered tunnel connection" / "Tunnel ready"
docker compose down
```
