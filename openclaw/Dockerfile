FROM ghcr.io/openclaw/openclaw:2026.4.1

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ripgrep \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

USER node
