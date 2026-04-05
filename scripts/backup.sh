#!/bin/bash
# 서비스 데이터 백업
set -euo pipefail
BACKUP_DIR="${HOME}/backup"
DATE=$(date +%Y%m%d)

mkdir -p "$BACKUP_DIR"

echo "=== 백업 시작: $DATE ==="

# Remark42
echo "--- Remark42 ---"
tar czf "$BACKUP_DIR/remark42-${DATE}.tar.gz" -C ~/docker-data/remark42 var/
echo "  $(du -sh "$BACKUP_DIR/remark42-${DATE}.tar.gz" | cut -f1)"

# Umami DB
echo "--- Umami DB ---"
docker exec umami-db pg_dump -U umami umami > "$BACKUP_DIR/umami-${DATE}.sql"
gzip "$BACKUP_DIR/umami-${DATE}.sql"
echo "  $(du -sh "$BACKUP_DIR/umami-${DATE}.sql.gz" | cut -f1)"

# Caddy 인증서
echo "--- Caddy 인증서 ---"
tar czf "$BACKUP_DIR/caddy-${DATE}.tar.gz" -C ~/docker-data/caddy data/
echo "  $(du -sh "$BACKUP_DIR/caddy-${DATE}.tar.gz" | cut -f1)"

# 오래된 백업 정리 (30일 이상)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete

echo ""
echo "=== 백업 완료 ==="
ls -lh "$BACKUP_DIR"/*-${DATE}*
