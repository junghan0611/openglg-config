#!/usr/bin/env bash
# apt route bootstrap — for AVF Debian VM where home-manager OOMs.
# Run inside the VM after vm-bootstrap.sh (sshd + keys) has set up SSH.
#
# Why this exists: see ./README.md.

set -euo pipefail

GIT_EMAIL="${GIT_EMAIL:-junghanacs@gmail.com}"
GIT_NAME="${GIT_NAME:-Junghan Kim}"

echo "=== 1. apt 기본 도구 ==="
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  git ripgrep fd-find bat jq \
  emacs-nox gh \
  curl xz-utils ca-certificates \
  unzip

echo
echo "=== 2. fnm + node 24 (사용자 단, 시스템 깡통 유지) ==="
# 시스템에 nodejs를 깔지 않는다. Debian 13의 nodejs는 20.19 (pi-shell-acp가
# require하는 >=22.6 미달), NodeSource node_24.x는 deb 저장소 없음 (404).
# 사용자 단 fnm으로 node 24를 운영하면 시스템 깡통 + 사용자 도구 분리.
if ! command -v fnm >/dev/null 2>&1; then
  curl -fsSL https://fnm.vercel.app/install | bash
fi
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --shell bash)"
fnm install 24
fnm default 24

echo
echo "=== 3. pnpm via corepack (스토리지 절약 — hard link 공유) ==="
corepack enable pnpm
corepack prepare pnpm@latest --activate

# pnpm 글로벌 디렉토리(PNPM_HOME) 등록 — ~/.bashrc에 자동 추가
# (없으면 'pnpm add -g'가 ERR_PNPM_NO_GLOBAL_BIN_DIR 로 실패)
pnpm setup >/dev/null 2>&1 || true
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

echo
echo "=== 4. git config ==="
git config --global user.email "$GIT_EMAIL"
git config --global user.name  "$GIT_NAME"
git config --global init.defaultBranch main

echo
echo "=== 5. fd / bat alias (Debian 이름이 fdfind / batcat) ==="
grep -q 'alias fd=fdfind'  ~/.bashrc || echo 'alias fd=fdfind'  >> ~/.bashrc
grep -q 'alias bat=batcat' ~/.bashrc || echo 'alias bat=batcat' >> ~/.bashrc

echo
echo "=== verify ==="
echo "git:    $(git --version)"
echo "rg:     $(rg --version | head -1)"
echo "fdfind: $(fdfind --version)"
echo "batcat: $(batcat --version)"
echo "jq:     $(jq --version)"
echo "emacs:  $(emacs --version | head -1)"
echo "gh:     $(gh --version | head -1)"
echo "node:   $(node --version)"
echo "npm:    $(npm --version)"
echo "pnpm:   $(pnpm --version)"
echo "email:  $(git config --global user.email)"
echo
echo "Done."
echo
echo "다음:"
echo "  - 글로벌 agent 도구: pnpm add -g @openai/codex 등 (README 참조)"
echo "  - 자기 리포: git clone <oracle 또는 github>:~/repos/gh/<리포>"
