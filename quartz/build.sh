#!/bin/bash
# Quartz 빌드 스크립트
# Obsidian vault → 정적 사이트 빌드
#
# 사전 조건:
#   - Node.js 20+ 설치
#   - Quartz 클론: git clone https://github.com/jackyzha0/quartz.git ~/quartz
#   - vault 심링크: ln -s ~/vault ~/quartz/content
#
# 사용법:
#   ./build.sh              # 빌드만
#   ./build.sh --deploy     # 빌드 + Caddy 서빙 경로에 복사

set -euo pipefail

QUARTZ_DIR="${QUARTZ_DIR:-$HOME/quartz}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/docker-data/quartz/public}"

echo "=== Quartz 빌드 시작 ==="
echo "Quartz: $QUARTZ_DIR"
echo "Output: $OUTPUT_DIR"

cd "$QUARTZ_DIR"

# vault 동기화 (git pull — 선택)
if [ -d content/.git ]; then
    echo "--- vault git pull ---"
    cd content && git pull && cd ..
fi

# 빌드
npx quartz build --output "$OUTPUT_DIR"

echo "=== 빌드 완료: $(find "$OUTPUT_DIR" -name '*.html' | wc -l) HTML 파일 ==="

if [ "${1:-}" = "--deploy" ]; then
    echo "Caddy가 $OUTPUT_DIR 를 서빙합니다."
    echo "Caddyfile의 root 경로가 /srv/quartz 인 경우,"
    echo "caddy docker-compose.yml 볼륨에 다음을 추가하세요:"
    echo "  - $OUTPUT_DIR:/srv/quartz:ro"
fi
