#!/bin/bash
# 서비스 로그 확인
# 사용법: ./logs.sh [서비스명] [줄수]
# 예: ./logs.sh caddy 100

SERVICE="${1:-all}"
LINES="${2:-50}"

if [ "$SERVICE" = "all" ]; then
    for svc in caddy remark42 umami umami-db openclaw-gateway; do
        if docker ps -q --filter "name=$svc" | grep -q .; then
            echo "=== $svc (최근 ${LINES}줄) ==="
            docker logs "$svc" --tail "$LINES" 2>&1 | tail -10
            echo ""
        fi
    done
else
    docker logs "$SERVICE" --tail "$LINES" -f
fi
