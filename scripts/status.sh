#!/bin/bash
# 전체 서비스 상태 확인
echo "=== Docker 서비스 ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== 디스크 ==="
df -h / | tail -1

echo ""
echo "=== Docker 디스크 ==="
docker system df 2>/dev/null

echo ""
echo "=== 데이터 디렉토리 ==="
du -sh ~/docker-data/*/ 2>/dev/null
