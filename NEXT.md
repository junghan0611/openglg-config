# NEXT.md

> 휘발성 후속 — 다음에 할 한 걸음. 영속 baseline 은 [AGENTS.md](./AGENTS.md), 공개 정체성은 [README.md](./README.md).

## 지금 상태 (2026-05-27 KST)

- ✅ Forge 인프라 박힘: `forge/docker-compose.yml`, `.env.example`, `.gitignore`, `README.md`
- ✅ Caddy 라우팅: `/forge/*` handle_path (Caddyfile + template 양쪽)
- ✅ Authelia bypass: `/forge` → `bypass` 룰 (configuration.yml + template 양쪽)
- ✅ `run.sh APP_SERVICES` 에 forge 추가
- ✅ AGENTS.md / README.md 갱신 + forge-config 담당자 링크 박음
- ❌ 실제 deploy 미실행: `forge/.env` 생성 → `docker compose up -d` → wizard
- ❌ 첫 round-trip 검증 미실시 (`/forge/api/v1/version` 200 확인)
- ❌ 담당자 (`forge-config`) 의 `bin/forge` 가 이 인스턴스에서 동작하는지 확인 안 함

## 다음 한 걸음

### 1. 배포 — `forge/` 띄우기 (operator)

```bash
cd ~/repos/gh/openglg-config/forge
cp .env.example .env
openssl rand -base64 32 | tr -d '/+=' | head -c 32   # → FORGE_DB_PASSWORD
chmod 600 .env

mkdir -p ~/docker-data/forge/data ~/docker-data/forge-db/pgdata
docker compose up -d
docker compose logs -f forge          # "Listen: http://0.0.0.0:3000" 대기

# Caddy + Authelia 리로드
docker compose -f ../caddy/docker-compose.yml restart caddy
docker compose -f ../authelia/docker-compose.yml restart authelia
```

### 2. Wizard 통과 + 봇 계정

브라우저로 `https://${DOMAIN}/forge/` → admin 계정 생성 → 로그인 →
`Site Administration → Create User Account` 로 `glg-bot` 발급 →
`Settings → Applications → Generate New Token` (`agent-bus`,
scopes: `write:user`, `write:repository`, `write:issue`, `write:organization`, `read:user`)
→ `~/.env.local` 에 `FORGE_URL` / `FORGE_TOKEN` / `FORGE_USER` 박기.

### 3. 검증 round-trip

```bash
source ~/.env.local
curl -s "$FORGE_URL/api/v1/version" | jq .
curl -s -H "Authorization: token $FORGE_TOKEN" "$FORGE_URL/api/v1/user" | jq .login   # glg-bot
```

그 다음 `forge-config/bin/forge list-open` 이 `glg-bot/sandbox` 패턴으로 동작하는지 확인 — 단,
이 인스턴스에서는 회사 작업용 repo 이름이 다를 수 있어 `bin/forge` 의 기본 repo 설정 점검 필요.

### 4. 결정 대기 항목 (힣)

- `glg-bot` 외에 회사 작업용 봇 계정 namespace 분리 여부 (계정 이름은 운영 메모에 둠, 이 repo 에는 X).
- 라벨 protocol — `forge-config` 의 5개 라벨 (`agent:ready` 등) 을 그대로 쓸지, 회사 워크플로에 맞춰 확장할지.
- GitHub mirror — Forgejo 의 push mirror 로 GitHub 공개 repo 와 동기화할지 여부. (회사 작업은 mirror 안 함 가능성 높음.)
- 첫 회사 repo 생성 — admin 으로 organization 박고 들어갈 repo 목록.

## 미루지 말 것

- `forge/.env` 는 절대 commit X — 두 겹 .gitignore 가 막아주지만 `git status` 로 매번 확인.
- 운영본 `caddy/Caddyfile` / `authelia/configuration.yml` 은 gitignored — template 만 커밋. 변경할 때 양쪽 동기화 필수 (오늘 작업의 패턴).
- 토큰 발급 후 `git log -p | grep -i token` 로 history 오염 검사.

## 미루어도 되는 것

- Forgejo Actions (CI/CD) 활성화 — v1 은 issue/label round-trip 만 검증.
- LFS 사용 — 활성화돼있으나 회사 작업 패턴 확정 후 실사용.
- 백업 자동화 — `scripts/backup.sh` 가 forge 까지 커버하도록 확장 (지금은 README 의 수동 명령).
- agent skill 표면 — `forge-config` 가 `.claude/skills/forge/SKILL.md` 박은 후 agent-config 에서 thin pointer.

## 영속할 자리

- 라벨 protocol 확정 → `forge-config/AGENTS.md` 의 라벨 섹션 갱신.
- 함정 박제 (INSTALL_LOCK, write:user, inode cache) → 이미 `forge/README.md` 본문 + Changelog 에 박힘.
- 운영 사실 (회사 repo 명, organization 이름) → 절대 이 공개 repo 에 안 들어옴. `forge-config` 도 공개라 동일. 필요하면 host `~/.env.local` + 운영 매뉴얼 (private) 자리.
