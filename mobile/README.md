# mobile/ — AVF Debian VM (폰) apt 라우트 (현재 보류)

> ## 상태: 폰 라우트 자체 보류 (2026-05-06)
>
> AVF Debian VM은 home-manager로도 apt 우회로도 **현재 상시 사용 가능한 수준이 아니다**:
>
> - **home-manager 라우트**: nix flake eval/build 메모리 peak이 OOM → VM 다운 (S26에서 검증)
> - **apt 라우트(이 폴더)**: 깡통 부트스트랩은 성공하지만, Terminal 앱이 백그라운드로 가면
>   Android가 VM을 정리해서 sshd/세션이 끊긴다. 즉 화면을 켜둬야만 살아있다.
>
> 결론: **폰을 상시 작업 환경으로 쓰는 것은 현 시점 비현실적.** 이 폴더는 향후
> AVF / 폰 OS가 백그라운드 보존을 보장할 때 다시 손볼 케이브로 남겨둔다.
> 지금 모바일 작업이 필요하면 노트북/태블릿 + SSH(Oracle/VPS)를 쓴다.

`home/` 의 home-manager 흐름이 메모리 한계로 동작하지 않는 환경(Galaxy S26 등의 AVF Debian VM)을 위한 apt 직접 설치 우회 패턴 — **개념적 보존용**.

## 왜 별도 라우트로 시도했었나

폰의 AVF Debian VM은 RAM ~3.8GB이지만:

- nix flake eval / build 메모리 peak이 OOM 킬 → VM 다운
- Terminal 앱이 백그라운드로 가면 Android system이 VM 정리 → SSH 끊김
- `dd if=/dev/zero of=/swapfile bs=1M count=2048` 같은 단순 IO도 다운 (S26에서 검증)
- nix-store 쪽 정책(Determinate Nix `require-sigs=true`)이 사용자 nix.conf 설정을 무시
- ssh-ng protocol mismatch 등 부수 문제 누적

apt 라우트로 메모리 peak은 우회되지만, **백그라운드 정리 문제는 OS 정책이라
사용자 단에서 못 푼다.** 그래서 라우트가 살아있어도 라우트 위에서 일하기가 어렵다.

`home/` 라우트는 **다른 디바이스 (Oracle ARM, VPS, 노트북)** 에서만 의미가 있다.

## 흐름

1. **`~/sync/org/setup/openglg-bridge/vm-bootstrap.sh`** (private bridge)
   - openssh-server 설치 + authorized_keys + sshd 활성화
2. **노트북 → 폰 scp** — `~/.ssh/`, `~/.env.local`, `~/openglg-config` 통째
3. **`./apt-bootstrap.sh`** (이 폴더) — 깡통 위에 필요한 도구 한 번에

## 패키지 카탈로그

`apt-bootstrap.sh` 가 깔아주는 것:

| 패키지 | 버전 (Debian 13 trixie 기준) | 비고 |
|--------|------|------|
| `git` | 2.47 | |
| `gh` | 2.46 | apt 직접 (별도 repo 불필요) |
| `ripgrep` | 14 | |
| `fd-find` | 10 | binary 이름 `fdfind` (alias `fd`) |
| `bat` | 0.25 | binary 이름 `batcat` (alias `bat`) |
| `jq` | 1.7 | |
| `emacs-nox` | 30.1 | 콘솔 emacs (Doom 호환) |
| `unzip` | 6.0 | fnm install이 zip 풀어내려고 의존 |

사용자 단 (시스템 nodejs 안 깔고 fnm으로):

| 도구 | 버전 | 비고 |
|------|------|------|
| `fnm` | latest | Rust binary ~8MB, `~/.local/share/fnm/` |
| `node` | 24.x | fnm 통해 (`fnm install 24 && fnm default 24`) |
| `pnpm` (corepack) | latest | hard-link 공유로 디스크 절약 |

> **왜 시스템 nodejs 안 깔까?**
> Debian 13의 apt `nodejs`는 20.19 — `pi-shell-acp`의 `engines.node >=22.6` 미달.
> NodeSource `node_24.x` deb 저장소는 trixie/bookworm 둘 다 404 (지원 안 함).
> fnm으로 사용자 단만 운영하면 시스템 깡통 + 사용자 도구 깔끔히 분리.

## 스토리지 절약 — pnpm 글로벌

폰 디스크는 충분(207G)하지만 패키지 중복은 피한다. **pnpm은 hard link로 글로벌 store 공유**해서 같은 의존성을 여러 도구가 다른 버전으로 써도 디스크 한 번만 차지.

자주 쓰는 글로벌 도구:

```bash
pnpm add -g @openai/codex
pnpm add -g @google/gemini-cli
pnpm add -g @mariozechner/pi-coding-agent
pnpm add -g @zed-industries/codex-acp@0.12.0
pnpm add -g @agentclientprotocol/claude-agent-acp@0.31.4
```

(Claude Code 본체는 별도 native installer)

## 다음 디바이스로 옮길 때

이 라우트가 의도한 건 **저메모리/제약된 모바일 환경 한정**이다.
Oracle ARM, Ubuntu VPS, 노트북 등 RAM 충분한 머신은 `home/` 의 home-manager 라우트로 가야 일관성·재현성·롤백이 모두 살아난다.

## 재시도 조건 (체크리스트)

향후 이 폴더 다시 손댈 때 먼저 확인할 것:

- [ ] AVF Terminal 앱이 백그라운드 유지(foreground service / persistent)를 지원하는지
- [ ] 또는 Samsung One UI에 Terminal 앱 "배터리 무제한" + "프로세스 보존" 옵션이 들어왔는지
- [ ] VM에 Swap 또는 zram을 안전하게 붙일 방법이 생겼는지 (`/dev/zero` IO로 다운되지 않는지)
- [ ] Determinate Nix `require-sigs=true` 우회 또는 사용자 nix.conf 존중 변경이 있는지

위 중 둘 이상 해소되기 전에는 폰 라우트를 다시 살리지 않는다.
