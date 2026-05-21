# Public OpenClaw service image for openglg-config.
# Runtime baseline follows the validated 2026.5.18 OpenClaw generation used by
# the companion nixos-config deployment, without copying private config/secrets.
FROM ghcr.io/openclaw/openclaw:2026.5.18

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    ffmpeg \
    git \
    jq \
    python3-minimal \
    python3-pip \
    ripgrep \
    tree \
    fd-find \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Media/content helpers used by common OpenClaw skills.
RUN pip install --no-cache-dir --break-system-packages yt-dlp

# ACP route runtime:
# - pi: child process host for pi-shell-acp
# - pi-shell-acp: root bridge package; operators still run `pi install ...`
#   inside the mounted runtime volume so pi settings survive container recreate.
# - claude/codex/gemini CLIs: official login surfaces used inside the container.
# - codex-acp: PATH fallback; pi-shell-acp also carries its pinned dependency.
# - gemini: Gemini's ACP server is the CLI itself.
RUN npm install -g \
      @earendil-works/pi-coding-agent \
      @junghanacs/pi-shell-acp \
      @anthropic-ai/claude-code \
      @openai/codex \
      @zed-industries/codex-acp \
      @google/gemini-cli \
      @steipete/summarize \
    && npm cache clean --force

USER node

RUN mkdir -p /home/node/.summarize \
    && printf '%s\n' '{"model":{"id":"openrouter/google/gemini-3-flash-preview"}}' > /home/node/.summarize/config.json
