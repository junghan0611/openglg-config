# MEMORY.md

리포 작업용 메모. 다음 세션·다른 도구가 같이 본다.
같은 패턴: `nixos-config/MEMORY.md` — 그 쪽이 mother repo, 여기는 companion.

## 현재 상태 — 폰 라우트 자체 보류 (2026-05-06)

- `home/` (Nix + home-manager): Oracle ARM / VPS / 노트북 — 정상.
- `mobile/` (apt 우회): 부트스트랩은 통과하지만 Terminal 앱이 백그라운드 가면
  Android가 VM 정리 → 세션 끊김. 폰 자체가 상시 환경이 못 됨.
- 즉 아래 SSH 브리지 노하우는 **재시도용 보존 자료**. 지금 굴리는 흐름이 아니다.
- 재시도 트리거: AVF가 백그라운드 보존을 보장하거나, S26 OS 쪽 정책이 바뀔 때.
  자세한 체크리스트는 `mobile/README.md` 하단 참조.

## AVF Terminal SSH 부트스트랩 (Syncthing 브리지 패턴) — 보존용

**목표**: 랩탑 → S26 네이티브 Linux Terminal(AVF/Debian VM) 진입을 폰 키보드 입력 없이. 재현성 확보.

**왜 중요했나**: home half를 폰 VM 위에서도 굴려보려 했다. SSH 채널은 어차피 필수 인프라고 키 입력 없는 부트스트랩이 재현성의 핵심. 다만 위 사유로 라우트 자체가 보류.

### 환경 (검증됨)
- Phone: SM-S942N (S26), Android 16, One UI 8.5
- Terminal app: `com.android.virtualization.terminal` (APEX `/apex/com.android.virt/priv-app/VmTerminalApp@BP4A.251205.006/`)
- 사용자가 Terminal 앱 "포트 제어"에서 **2222 허용 포트 추가**해둠

### Syncthing 경로
- 랩탑: `~/sync/org/` (`~/org` → `~/sync/org` 심볼릭)
- Termux 뷰: `/data/data/com.termux/files/home/storage/shared/Documents/sync/org`
- 실제 Android 공유 스토리지: `/storage/emulated/0/Documents/sync/org`
- Termux storage 플러그인 통해 매핑

### 아키텍처
```
[랩탑] ─Syncthing─▶ [Android 공유 스토리지] ─AVF Shared Folder─▶ [VM /mnt/...]
                                       ▲
                                       └── Termux도 같은 경로 (~/storage/shared/...)
```

### ⚠️ sdcardfs/FUSE 권한 함정
공유 스토리지는 `chmod` 안 통하고 모든 파일이 일관된 권한으로 보임 → SSH는 world-readable `authorized_keys` 거부함.
**공유 폴더에 키 두고 직접 사용 ❌. 반드시 VM의 ext4(`~/.ssh/`)로 `cp` 후 `chmod 600`.**

### 부트스트랩 패턴

**랩탑 (한 번 준비)**:
```bash
mkdir -p ~/sync/org/openglg-bridge
cp ~/.ssh/id_rsa.pub ~/sync/org/openglg-bridge/laptop.pub
# bootstrap.sh 작성 (아래)
```

**bootstrap.sh**:
```bash
#!/usr/bin/env bash
set -euo pipefail
SHARED="${1:-$HOME/storage/sync/org/openglg-bridge}"  # AVF 마운트 경로로 조정
sudo apt update && sudo apt install -y openssh-server
sudo systemctl enable --now ssh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat "$SHARED/laptop.pub" >> ~/.ssh/authorized_keys
sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**VM 안 (한 번만 짧게 타이핑)**:
```bash
bash ~/storage/.../openglg-bridge/bootstrap.sh
```

**호스트 진입**:
```bash
adb forward tcp:2222 tcp:<Terminal_앱이_노출한_포트>
ssh -p 2222 droid@localhost
```

### 잘못된 길 (시간 낭비 방지)
- ❌ `adb shell`로 VM 진입 — 별도 network namespace
- ❌ `adb forward tcp:N tcp:22` 직접 — Android 호스트 22번이지 VM의 22번 아님
- ❌ `adb forward tcp:7681` — ttyd는 VM 내부에만 바인딩, Android 호스트 미노출
- ❌ 공유 폴더 `authorized_keys` 직접 사용 — 권한 거부
- ❌ Termux private(`/data/data/com.termux/...`) 공유 — AVF가 못 봄

### 다음 세션 확인 사항
1. AVF Terminal 앱 Settings의 "Shared folder" 항목 — 위치, 마운트 경로 후보
2. 사용자가 추가한 "허용 포트 2222"의 정확한 매핑 의미 (앱 UI상 22→2222인지 다른 의미인지)
3. VM 기본 사용자명 (`droid` 가정 — 확인 필요)
