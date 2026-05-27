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
