#!/bin/bash
# 전체 서비스 시작
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== 서비스 시작 ==="

echo "--- Caddy ---"
cd "$DIR/caddy" && docker compose up -d

echo "--- Remark42 ---"
cd "$DIR/remark42" && docker compose up -d

echo "--- Umami ---"
cd "$DIR/umami" && docker compose up -d

# OpenClaw은 선택 (설정 완료 후)
if [ -f "$DIR/openclaw/.env" ]; then
    echo "--- OpenClaw ---"
    cd "$DIR/openclaw" && docker compose up -d --build
else
    echo "--- OpenClaw: .env 없음, 건너뜀 ---"
fi

echo ""
echo "=== 상태 ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
