# NEXT.md

> 휘발성 후속 — 다음에 할 한 걸음. 영속 baseline 은 [AGENTS.md](./AGENTS.md), 공개 정체성은 [README.md](./README.md).

## 지금 상태 (2026-05-27 KST)

### Server half — Forgejo 배포 + OpenClaw webhook 연동 클로즈

- ✅ Forge 인프라 박힘: `forge/docker-compose.yml`, `.env.example`, `.gitignore`, `README.md`
- ✅ Caddy 라우팅: `/forge/*` handle_path (Caddyfile + template 양쪽)
- ✅ Authelia bypass: `/forge` → `bypass` 룰
- ✅ Deploy 가동 + Wizard 통과 + 봇 계정 + 토큰 + 라벨 protocol + mirror migration + `bin/forge` round-trip
- ✅ **OpenClaw Forgejo webhook bypass** (2166fe0): `/openclaw/hooks/forgejo` exact path만 Authelia 우회. wildcard `/openclaw/hooks/*` 금지 — `/hooks/agent` direct-agent endpoint 노출 차단. `header_up X-OpenClaw-Idempotency-Key {http.request.header.X-Forgejo-Delivery}` 로 source-agnostic idempotency contract.
- ✅ **Forgejo webhook allow-list 수정** (b5186d9): `[webhook] ALLOWED_HOST_LIST=private,loopback,${DOMAIN}`. 기본값 `private,loopback` 가 `${DOMAIN}/openclaw/hooks/...` 외부 IP 해석으로 차단하던 함정. `forge/README.md` Troubleshooting + Security posture 박제.
- ✅ **공개 `.env.example` 누락 자리 채움** (34fcbd5): `metabase/`, `postgres/` 신규 생성, `forge/.env.example` 에 `DOMAIN`/`DATA_DIR` 키 명시. 포커가 cp `.env.example` `.env` 후 빈손 안 됨.

### Home half — Step 2 진입 (모듈 + feature flags)

- ✅ **modular home-manager**: `home/modules/minimal.nix` baseline 유지 + 8개 opt-in 모듈 추가. `settings.features.*` 토글 (모두 default `false`).
  - `shell`, `git`, `cli`, `tmux`, `emacs`, `gpg`, `syncthing`, `languages`
  - 각 모듈 `lib.mkIf` 로 self-gate, identity 는 `settings.user.*` 에서 받음
  - Nix evaluate 검증: defaults 시 minimal 만 / 모든 flag on 시 모든 모듈 enable 확인
- 참고: 운영 머신은 별도의 (private) NixOS host config 에서 home-manager 를 관리한다. openglg-config 측 `home/` 은 **다른 호스트 (Oracle ARM / VPS / 우분투 laptop)** 가 쓰는 공개 template 자리.

## 발견된 함정 — 본 repo 안 박힌 자리

- **`bin/forge` 의 `FORGE_BOT_FOOTER` default 가 단일 호스트/모델 하드코딩**. 다른 host/model 에서 도는 봇이 자동으로 본인 footer 박지 못함. 단기 우회: 각 호스트의 `~/.env.local` 에 `FORGE_BOT_FOOTER` override. 장기 fix: forge-config 본 repo 에서 `bin/forge` 가 `~/.current-device` + 호출 시 model 인자를 자동 감지. **forge-config issue 자리**.
- **토큰 채팅 노출 위험**: 채팅 평문 노출 시 즉시 revoke + 재발급 — forge-config AGENTS.md 의 시크릿 규약 자리.
- **homer/.env 잘못 들어간 시스템 변수**: `HOME=` 등 export 캡처 흔적. homer compose 가 env 변수 자체를 안 쓰니까 비워도 되는 자리. GLG 운영면 정리 거리.

## 다음 한 걸음

### Server half — operator follow-ups

- **운영면 `caddy/Caddyfile` 검증**: 이번 사이클에 박힌 webhook bypass + header_up 이 운영면 응답으로 GREEN 확인됨 (`/openclaw/hooks/forgejo` → 401 OpenClaw 직접, `/agent` → 303 Authelia). retry 트리거 시 OpenClaw forge agent 까지 도착 검증은 OpenClaw 운영 분신 자리.

#### OpenClaw Forgejo webhook 라이브 적용 — 검증 시퀀스 (cold pickup 가능)

GLG 가 Forgejo UI 에서 webhook 을 박을 때 곁에서 돌릴 우리(openglg-config) 측 인프라 검증. **OpenClaw 끝단** (mapping path → agent throw → transform 효과 → queueBehind) **은 OpenClaw 분신 자리** — 우리는 외곽 응답만 본다.

**자리 분담**

| 단계 | 자리 | 누가 |
|---|---|---|
| Forgejo UI 에서 webhook 박기 (URL/method/secret/events) | OpenClaw 분신 NEXT 의 1~2단계 | GLG (UI) 또는 분신 (API + PATCH 보정) |
| Test Delivery 응답 | OpenClaw 측 시야 | OpenClaw 분신 |
| Caddy/Forgejo/Authelia 인프라 GREEN | **우리 자리** | **이 repo 담당자** |
| 라벨 토글 → agent throw → comment-back | OpenClaw 측 | OpenClaw 분신 |
| queueBehind 검증 (재진입 안 됨, sandbox#6 패턴) | OpenClaw 측 | OpenClaw 분신 |

**우리 측 검증 시퀀스** — host 의 `~/.env.local` 또는 root `.env` 에 `DOMAIN` 정의 가정.

```bash
# 운영자 host 의 DOMAIN 을 source
source ~/.env.local 2>/dev/null || source ./.env

echo "=== 1) Caddy /openclaw/hooks/forgejo 외부 응답 (운영자가 webhook 박기 전 baseline = 401) ==="
curl -s -o /dev/null -w "HTTP %{http_code}  redirect→%{redirect_url}\n" \
  -X POST "https://${DOMAIN}/openclaw/hooks/forgejo" \
  -H "X-Forgejo-Delivery: dryrun-$(date +%s)" \
  -H "Content-Type: application/json" -d '{}' --max-time 5

echo "=== 2) /openclaw/hooks/agent 는 여전히 Authelia 게이트 차단 (= 303 → /authelia/) ==="
curl -s -o /dev/null -w "HTTP %{http_code}  redirect→%{redirect_url}\n" \
  -X POST "https://${DOMAIN}/openclaw/hooks/agent" \
  -H "Content-Type: application/json" -d '{}' --max-time 5

echo "=== 3) Forgejo live app.ini — allow-list 자리 (private,loopback,\${DOMAIN}) ==="
docker exec forge cat /data/gitea/conf/app.ini | grep -A1 '^\[webhook\]'

echo "=== 4) Caddy live config — hooks/forgejo 블록 + header_up X-OpenClaw-Idempotency-Key ==="
docker exec caddy cat /etc/caddy/Caddyfile | grep -A8 'hooks/forgejo'

echo "=== 5) Forgejo logs — webhook delivery 흔적 (deny / unable / delivered) ==="
docker logs forge --tail 200 2>&1 | grep -iE 'webhook|deliver|allowed http|deny' | tail -10

echo "=== 6) Caddy access log — /openclaw/hooks 요청 status (운영자 박은 후 trigger) ==="
docker logs caddy --tail 200 2>&1 | grep -iE 'openclaw/hooks' | tail -10
```

**기대값**

- (1) **401** "Unauthorized" — Caddy 가 bypass 통과시켰고 OpenClaw 가 token 없는 요청 거절. GREEN. Forgejo 가 secret 박은 정상 webhook 보낼 때는 200/204.
- (2) **303** → `https://${DOMAIN}/authelia/?rd=...` — Authelia 게이트 살아있음. `/hooks/agent` 노출 차단 확인. GREEN.
- (3) `ALLOWED_HOST_LIST = private,loopback,<host>` — 운영자 host 가 박혀있음. GREEN.
- (4) `handle /openclaw/hooks/forgejo` 블록 + `header_up X-OpenClaw-Idempotency-Key {http.request.header.X-Forgejo-Delivery}` 라인 보임. GREEN.
- (5) `deny '<host>(...)'` 가 보이면 allow-list 자리 — `${DOMAIN}` 외의 다른 호스트면 `forge/docker-compose.yml` 확장 자리.
- (6) Caddy access log 의 method/path/status 가 외부 응답과 일치.

**함정 패턴 → 우리 측 대응 자리**

| 증상 | 원인 | 대응 |
|---|---|---|
| `/openclaw/hooks/forgejo` → 303 → Authelia | Caddy 운영본이 reverted 됨 (inode cache 함정 재발) | `docker exec caddy cat /etc/caddy/Caddyfile \| grep hooks/forgejo` 확인 → `docker compose -f caddy/docker-compose.yml restart caddy` |
| `/openclaw/hooks/forgejo` → 502/504 | OpenClaw upstream (`172.18.0.1:18789`) 미응답 | OpenClaw process 상태 확인 (운영자 자리), Caddy 자체는 OK |
| Forgejo 로그에 `webhook can only call allowed HTTP servers` | `ALLOWED_HOST_LIST` 에 대상 호스트 없음 | `forge/docker-compose.yml` 의 `FORGEJO__webhook__ALLOWED_HOST_LIST` 확장 → `docker compose up -d forge` (env 변경은 recreate) |
| Test Delivery 가 401 만 반환 | OpenClaw `hooks.token` 과 webhook secret 불일치 | OpenClaw 분신 자리 — 운영자 토큰 동기화 |
| Test Delivery 200 인데 OpenClaw 가 안 받음 | Caddy 가 받았지만 reverse_proxy 가 다른 곳으로 | live Caddyfile 의 `reverse_proxy 172.18.0.1:18789` 자리 확인 |

OpenClaw 운영 분신 NEXT 의 우선순위 A 자리 (운영자 자리 webhook 적용) 와 짝 — A 실행 시점에 위 시퀀스 호출.
- **다른 서비스도 `/disk-A` 로 옮길지** — `mattermost`, `postgres`, `openclaw` 등 root partition. 자라는 서비스부터 `DATA_DIR=/disk-A/docker-data` 패턴으로 이전 가능. compose 들이 이미 `${DATA_DIR:-~/docker-data}` 받게 박혀있어서 stop → mv → up.
- **HMAC signature 검증 (선택)**: webhook hardening — OpenClaw upstream / adapter / Caddy 확장 모듈 셋 중 하나 자리. openglg-config 자리는 아님.

### Home half — Step 2 활용 follow-ups

- **실 호스트에서 검증**: Oracle ARM 또는 우분투 노트북에서 `./bootstrap.sh` → features 점진 토글 → 첫 swirh 시간 / OOM 여부 / 패키지 missing 기록. Step 1 verification checklist 의 features 별 자리 채움.
- **`features.emacs` 빌드 시간**: 첫 switch heavy (LaTeX scheme-medium + hunspell + texlive). 작은 VPS 에서 disable 권고 — `home/README.md` 에 명시했지만 실측 후 가이드 보강.
- **AGENTS.md "Backup of OpenClaw runtime" 자리**: nixos-config 가 owner 인 자리 — 별도 자리.

### 결정 대기 항목 (힣)

- `glg-bot` 외에 회사 작업용 봇 계정 namespace 분리 여부 (운영 메모 자리, 이 repo 에는 X).
- 라벨 protocol 확장 여부 (forge-config 의 5개 라벨 → 회사 워크플로 맞춤).
- GitHub mirror push 방향 (Forgejo → GitHub) 활성화 여부.
- 첫 회사 repo organization 생성.

## 미루지 말 것

- `forge/.env` 는 절대 commit X — 두 겹 .gitignore 가 막아주지만 `git status` 로 매번 확인.
- 운영본 `caddy/Caddyfile` / `authelia/configuration.yml` 은 gitignored — template 만 커밋. 변경할 때 양쪽 동기화 필수.
- 토큰 발급 후 `git log -p | grep -i token` 로 history 오염 검사.
- Forgejo / Caddy / OpenClaw 어느 한 곳을 손볼 때 다른 두 자리의 함정 박제 (`forge/README.md` Troubleshooting, AGENTS.md webhook rule) 도 같이 점검.

## 미루어도 되는 것

- Forgejo Actions (CI/CD) 활성화 — v1 은 issue/label round-trip 만 검증.
- LFS 사용 — 활성화돼있으나 회사 작업 패턴 확정 후 실사용.
- 백업 자동화 — `scripts/backup.sh` 가 forge 까지 커버하도록 확장 (지금은 README 의 수동 명령).
- agent skill 표면 — `forge-config` 가 `.claude/skills/forge/SKILL.md` 박은 후 agent-config 에서 thin pointer.
- `home/` profile split / `run.sh home:*` subcommands — 한 profile + feature flags 로 충분히 진행 가능.

## 영속할 자리

- 라벨 protocol 확정 → `forge-config/AGENTS.md` 의 라벨 섹션 갱신.
- 함정 박제 (INSTALL_LOCK, write:user, inode cache, `[webhook] ALLOWED_HOST_LIST`) → `forge/README.md` 본문 + Changelog.
- AGENTS.md webhook rule (external webhook receivers — exact path only, wildcard 금지) — 다음 webhook source 박을 때 wildcard 유혹 차단.
- 운영 사실 (회사 repo 명, organization 이름) → 절대 이 공개 repo 에 안 들어옴. host `~/.env.local` + 운영 매뉴얼 (private) 자리.
