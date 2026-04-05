#!/bin/bash
# oracle-selfhost 초기 설정 스크립트
# Ubuntu 22.04 (Oracle Cloud Free Tier) 대상
set -euo pipefail

echo "=== oracle-selfhost 초기 설정 ==="

# 1. 시스템 업데이트
echo "--- 시스템 업데이트 ---"
sudo apt update && sudo apt upgrade -y

# 2. Docker 설치
if ! command -v docker &> /dev/null; then
    echo "--- Docker 설치 ---"
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    echo "⚠️  Docker 그룹 적용을 위해 재로그인 필요: exit 후 다시 SSH"
else
    echo "--- Docker 이미 설치됨: $(docker --version) ---"
fi

# 3. Docker Compose 확인
echo "--- Docker Compose: $(docker compose version 2>/dev/null || echo '미설치') ---"

# 4. Node.js 설치 (Quartz 빌드용)
if ! command -v node &> /dev/null; then
    echo "--- Node.js 20 LTS 설치 ---"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "--- Node.js 이미 설치됨: $(node --version) ---"
fi

# 5. 디렉토리 구조 생성
echo "--- 디렉토리 생성 ---"
mkdir -p ~/docker-data/{caddy/data,caddy/config,remark42/var,umami/db,quartz/public}
mkdir -p ~/vault
mkdir -p ~/backup

# 6. Docker 네트워크 생성
if ! docker network inspect proxy &> /dev/null 2>&1; then
    echo "--- Docker 네트워크 'proxy' 생성 ---"
    docker network create proxy
else
    echo "--- Docker 네트워크 'proxy' 이미 존재 ---"
fi

# 7. 방화벽 (Oracle Ubuntu iptables)
echo "--- 방화벽: 80/443 포트 확인 ---"
if ! sudo iptables -L INPUT -n | grep -q "dpt:80"; then
    sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
    sudo iptables -I INPUT 7 -m state --state NEW -p tcp --dport 443 -j ACCEPT
    sudo netfilter-persistent save
    echo "  80/443 포트 열림"
else
    echo "  이미 열려있음"
fi

echo ""
echo "=== 초기 설정 완료 ==="
echo ""
echo "다음 단계:"
echo "  1. .env.example → .env 복사 후 값 채우기"
echo "  2. caddy/Caddyfile.template → caddy/Caddyfile 복사 후 도메인 수정"
echo "  3. remark42/.env.example → remark42/.env"
echo "  4. umami/.env.example → umami/.env"
echo "  5. ./scripts/up.sh 실행"
echo ""
echo "⚠️  Oracle Cloud 콘솔에서 보안 규칙도 열어야 합니다:"
echo "   VCN → Subnet → Security List → Ingress: 80, 443 TCP"
