#!/bin/bash
# 전체 서비스 재시작
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== 서비스 재시작 ==="

for svc in caddy remark42 umami openclaw; do
    if [ -f "$DIR/$svc/docker-compose.yml" ] && docker ps -q --filter "name=$svc" | grep -q .; then
        echo "--- $svc ---"
        cd "$DIR/$svc" && docker compose restart
    fi
done

echo ""
docker ps --format "table {{.Names}}\t{{.Status}}"
