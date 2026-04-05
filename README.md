# seedbed-config

A seedbed for your digital garden — self-hosted on **Oracle Cloud Free Tier** with Docker Compose.

Publish, comment, analyze, and run your own AI agent. **5 compose files** and you own everything.

## What this gives you

| Service | What it does | You get |
|---------|-------------|---------|
| **Caddy** | Reverse proxy + auto HTTPS | Zero-config TLS for all services |
| **Quartz** | Obsidian vault → static site | Your notes, published |
| **Remark42** | Self-hosted comments | Readers can talk back |
| **Umami** | Privacy-friendly analytics | Know your audience, own the data |
| **OpenClaw** | AI agent gateway | Your own AI, on your own machine |

All of this runs on a single ARM instance. Monthly cost: **$0**.

## Architecture

```
┌─── Oracle Cloud Free Tier (ARM Ampere A1) ──────────────┐
│  Ubuntu 22.04 / Docker + Docker Compose                  │
│                                                          │
│  Caddy (automatic HTTPS)  ← :80/:443                    │
│    ├─ garden.example.com    → Quartz (digital garden)    │
│    ├─ comments.example.com  → Remark42 (comments)        │
│    ├─ analytics.example.com → Umami (web analytics)      │
│    └─ (SSH tunnel only)     → OpenClaw (AI agent)        │
│                                                          │
│  Docker network: proxy (Caddy ↔ all services)            │
└──────────────────────────────────────────────────────────┘
```

## Requirements

- **Oracle Cloud account** — [Free Tier](https://www.oracle.com/cloud/free/) (credit card required, no charge)
- **1 domain** — any registrar works (Porkbun, Cloudflare, Namecheap, Google Domains, GoDaddy, etc.)
- **SSH key pair**

## Quick start

```bash
# 1. SSH into your Oracle instance
ssh ubuntu@<instance-ip>

# 2. Clone
git clone https://github.com/junghanacs/seedbed-config.git
cd seedbed-config

# 3. Initial setup (Docker, firewall, directories)
./scripts/init.sh

# 4. Configure
cp .env.example .env
cp caddy/Caddyfile.template caddy/Caddyfile   # ← edit your domains
cp remark42/.env.example remark42/.env
cp umami/.env.example umami/.env

# 5. Start
./scripts/up.sh
```

## Step by step

### 1. Create Oracle instance

- **Shape**: `VM.Standard.A1.Flex` (ARM Ampere)
- **Spec**: 2 OCPU / 12GB RAM (free tier allows up to 4/24)
- **OS**: Ubuntu 22.04 (Canonical)
- **Storage**: 100GB boot + optional 100GB block volume
- **Security List**: open TCP **80** and **443** ingress
- Register your SSH public key (+ admin's key if someone manages it for you)

### 2. Run init script

```bash
./scripts/init.sh
```

Installs Docker, Node.js, creates directories, opens firewall ports, creates the `proxy` Docker network.

### 3. DNS records

Point subdomains to your Oracle instance public IP. Any registrar works — just add A records.

```
A    garden.example.com      → <Oracle IP>
A    comments.example.com    → <Oracle IP>
A    analytics.example.com   → <Oracle IP>
```

> Already on GitHub Pages or Netlify? Keep your main site there.
> Just add subdomains for comments / analytics / agent on Oracle.

### 4. Caddy (reverse proxy + HTTPS)

Edit `caddy/Caddyfile` with your actual domains. Caddy obtains Let's Encrypt certificates automatically.

```bash
cd caddy && docker compose up -d
```

### 5. Quartz (Obsidian → digital garden)

```bash
# Install Quartz
git clone https://github.com/jackyzha0/quartz.git ~/quartz
cd ~/quartz && npm i

# Link your Obsidian vault
ln -s ~/vault ~/quartz/content

# Build
npx quartz build --output ~/docker-data/quartz/public
```

Add volume to `caddy/docker-compose.yml`:

```yaml
volumes:
  - ~/docker-data/quartz/public:/srv/quartz:ro
```

Rebuild Caddy: `cd caddy && docker compose up -d`

> **Keeping vault in sync**: push from your local machine via git, then `git pull && npx quartz build` on the server. A cron job or a simple `watch-and-build.sh` works fine.

### 6. Remark42 (comments)

```bash
cp remark42/.env.example remark42/.env
# Fill in: SECRET, OAuth credentials (GitHub / Google)
cd remark42 && docker compose up -d
```

Embed in Quartz (add to custom layout):

```html
<div id="remark42"></div>
<script>
  var remark_config = {
    host: 'https://comments.example.com',
    site_id: 'garden',
  }
</script>
<script>
  !function(e,n){for(var o=0;o<e.length;o++){
    var r=n.createElement("script");
    r.src=remark_config.host+"/web/"+e[o]+".js";
    r.defer=!0;(n.head||n.body).appendChild(r)
  }}(remark_config.components||["embed"],document);
</script>
```

### 7. Umami (analytics)

```bash
cp umami/.env.example umami/.env
cd umami && docker compose up -d
```

- Open `https://analytics.example.com`
- Default: `admin` / `umami` → **change password immediately**
- Add website → copy tracking script → paste into Quartz layout

### 8. OpenClaw (AI agent)

```bash
cp openclaw/.env.example openclaw/.env
cp openclaw/config/openclaw.json.example openclaw/config/openclaw.json
# Edit: API keys, Telegram bot token
cd openclaw && docker compose up -d --build
```

OpenClaw binds to localhost only. Access via SSH tunnel:

```bash
ssh -L 18789:localhost:18789 ubuntu@<instance-ip>
# Open http://localhost:18789
```

Your Obsidian vault is mounted read-only — the AI can reference your notes.

## Operations

```bash
./scripts/status.sh       # Service status + disk usage
./scripts/restart.sh      # Restart all services
./scripts/backup.sh       # Backup Remark42 + Umami + Caddy certs
./scripts/logs.sh         # All logs (summary)
./scripts/logs.sh caddy   # Follow one service
```

## Disk layout

Oracle Free Tier: up to 200GB total.

```
/home/ubuntu/
  ├── seedbed-config/     (this repo — compose files + scripts)
  ├── docker-data/        (persistent service data)
  │   ├── caddy/          (TLS certs)
  │   ├── remark42/       (comments DB)
  │   ├── umami/          (PostgreSQL)
  │   └── quartz/         (built static site)
  ├── vault/              (Obsidian vault, synced via git)
  └── backup/             (daily backups, 30-day retention)
```

## Future plans

- Emacs/Org-mode publishing support (ox-hugo, org-publish)
- More generator examples beyond Quartz

## References

- [Quartz](https://quartz.jzhao.xyz) — Obsidian → digital garden
- [Remark42](https://remark42.com) — Self-hosted comments
- [Umami](https://umami.is) — Privacy web analytics
- [OpenClaw](https://openclaw.org) — AI agent platform
- [Caddy](https://caddyserver.com) — Automatic HTTPS server
- [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)

## License

MIT
