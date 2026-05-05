# home/ — Step 1 (minimal PoC)

Verify Nix + home-manager `switch` works on Debian/Ubuntu with the smallest
possible apt footprint and **zero security keys**. Public HTTPS only.

> **AVF Debian VM (폰) 예외 — 라우트 자체 보류 (2026-05-06)**:
> 메모리 한계로 home-manager 빌드/eval이 OOM 킬됨 (S26에서 검증).
> [`../mobile/`](../mobile/) apt 우회는 부트스트랩 자체는 되지만,
> Terminal 앱이 백그라운드로 가면 Android가 VM을 정리해 세션이 끊긴다.
> **폰 자체가 현재 상시 작업 환경으로 못 쓴다.** 이 home/ 흐름은
> Oracle ARM / VPS / 노트북 등 RAM 충분한 머신에서만.

Full design (server + client one-set, profiles, feature flags) lives in the
linked llmlog note — not implemented here yet.

## What installs via apt

Three packages, all `--no-install-recommends`:

- `curl`
- `xz-utils`
- `ca-certificates`

That's it. No `git` via apt — we pull the repo as a tarball, and Nix brings its
own `git` after bootstrap.

## What home-manager installs (smoke test)

- `bash` with completion
- `git` (with `user.name` / `user.email` from `settings.nix`)
- `gh` (GitHub CLI — for later `gh auth login` device flow)
- `ripgrep`, `fd`, `bat`

If these are on `$PATH` after `switch`, the pipe works.

## Prerequisites (one-time, on the phone)

1. **Enable Linux Terminal**: Settings → Developer options → Linux dev environment.
2. **Open Terminal app** → Debian VM initializes (first run takes a few minutes).
3. **Set the `droid` password** (default user is `droid`, password blank/unknown):

   ```bash
   sudo passwd droid
   ```

4. Pick a shell and stay in it. `sudo` may prompt for the password you just set.

## Bootstrap flow — Oracle ARM (aarch64) / 기타 aarch64 서버

> AVF / 폰 라우트는 위 박스 사유로 **현재 보류**. 같은 aarch64라도 RAM 충분한
> 클라우드 ARM VM에서는 그대로 동작한다 (1차 타겟).

No git, no SSH keys. Anonymous HTTPS tarball.

```bash
# 1. Download repo (public, anonymous)
curl -L https://github.com/junghan0611/openglg-config/archive/main.tar.gz | tar xz
cd openglg-config-main/home

# 2. Personalize settings
cp settings.nix.example settings.nix
# edit: user.username, user.email, system = "aarch64-linux"

# 3. Run bootstrap
./bootstrap.sh
```

First `switch` takes a while on aarch64 — binary cache hit rate is lower than
x86_64. Subsequent switches are fast.

## Bootstrap flow — Ubuntu x86_64 VPS

Same, change one line in `settings.nix`:

```nix
system = "x86_64-linux";
```

And set `user.username` to your login name (`whoami`).

## Fork-and-modify pattern (Step 2+)

Anyone using this as a template:

1. Fork `openglg-config` on GitHub web (no keys).
2. `curl -L https://github.com/<you>/openglg-config/archive/main.tar.gz | tar xz`
3. Edit `home/settings.nix`, run `./bootstrap.sh`.
4. After bootstrap, authenticate to push back:

   ```bash
   gh auth login                 # device flow — no SSH key needed
   gh repo clone <you>/openglg-config   # now over authenticated HTTPS
   ```

No SSH keypair required at any point. `gh` stores a token.

## Verification checklist

After `./bootstrap.sh` completes:

- [ ] `nix --version` prints a version
- [ ] `git --version`, `gh --version`, `rg --version`, `fd --version`, `bat --version`
      all work in a fresh shell
- [ ] `git config --global user.email` matches `settings.nix`
- [ ] `dpkg -l | wc -l` shows only the expected apt packages (no creep)

Record anything that fails — that's Step 1 output.

## Files

| File | Purpose |
|------|---------|
| `flake.nix` | home-manager flake, reads `settings.nix` |
| `settings.nix.example` | template — copy to `settings.nix` |
| `modules/minimal.nix` | smoke-test module (bash/git/gh/rg/fd/bat) |
| `bootstrap.sh` | apt minimum → Nix install → `switch` |

## Out of scope (Step 2+)

- Profile split (mobile / vps / workstation)
- Feature flags (emacs / tmux / langs / heavy)
- hejdev6 home.nix port
- Server ↔ home `.env` sharing
- `run.sh home:*` subcommands
- pass / gpg / authinfo wiring

See the llmlog note for the full plan.
