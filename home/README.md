# home/ — modular home-manager for Debian/Ubuntu

Reproduce the operator's shell and dev tools on any Debian/Ubuntu host
(Oracle ARM, VPS, laptop, ...) with the smallest possible apt footprint and
**zero security keys** at start. Public HTTPS only.

> **AVF Debian VM (phone) — parked (2026-05-06)**:
> home-manager builds OOM in the S26 AVF VM, and the apt fallback in
> [`../mobile/`](../mobile/) boots cleanly but Android tears the VM down
> whenever the Terminal app drops to background. **The phone is not a viable
> everyday environment.** This `home/` flow targets RAM-comfortable hosts
> (Oracle ARM, x86 VPS, laptop) for now.

## What gets installed

### Baseline — `modules/minimal.nix` (always on)

Loaded regardless of feature flags so a freshly bootstrapped machine has a
working shell even with everything else turned off:

- `bash` with completion
- `git` with `user.name` / `user.email` from `settings.nix`
- `gh` (GitHub CLI — for later `gh auth login` device flow)
- `ripgrep`, `fd`, `bat`

### Optional modules — `settings.features.*`

Toggle in `settings.nix`. Everything defaults to **off**.

| Flag | Module | What it adds |
|------|--------|--------------|
| `shell` | `modules/shell.nix` | bash aliases, prompt, FZF + atuin + zoxide + direnv, `e()`/`v()`/`ec()` emacsclient wrappers with 24-bit color autodetect |
| `git` | `modules/git.nix` | git aliases (co/ci/st/br/prettylog), `delta` diff viewer, LFS, `init.defaultBranch=main`, `pull.rebase`, `merge.conflictstyle=zdiff3` |
| `cli` | `modules/cli.nix` | neovim + eza, jq, yq, lazygit, tokei, ncdu, duf, htop/btop, procs, miller, htmlq, mtr/nmap/iftop, yt-dlp/ffmpeg, ... |
| `tmux` | `modules/tmux.nix` | tmux (256-color, OSC-52 clipboard, vi keys, vim-style pane nav) + zellij with dracula theme |
| `emacs` | `modules/emacs.nix` | `emacs-nox` + vterm + spell (aspell, hunspell w/ Korean), grammar (languagetool), mail (mu, isync, notmuch, afew), pandoc + imagemagick + TeX Live scheme-medium |
| `gpg` | `modules/gpg.nix` | `gpg` + `gpg-agent` (curses pinentry), `pass` with pass-otp, optional `~/.authinfo.gpg` symlink (see `settings.authInfoSource`) |
| `syncthing` | `modules/syncthing.nix` | per-user `services.syncthing` bound to 127.0.0.1:8384, plus `stc-cli` and an `stc` alias |
| `languages` | `modules/languages.nix` | Node.js 22 + pnpm + bun, Python 3.12 (jupyter/pandas), Go + gopls, Zig + zls, Clojure + clojure-lsp, Nix LSPs, gitleaks, C/C++ toolchain |

Modules use `lib.mkIf` internally, so leaving a flag off keeps the module
inert — it costs only a dictionary lookup at eval time.

## Bootstrap flow

No git, no SSH keys. Anonymous HTTPS tarball.

```bash
# 1. Download repo (public, anonymous)
curl -L https://github.com/junghan0611/openglg-config/archive/main.tar.gz | tar xz
cd openglg-config-main/home

# 2. Personalize settings
cp settings.nix.example settings.nix
# edit: user.username, user.email, system, and any features.* you want on

# 3. Run bootstrap
./bootstrap.sh
```

`bootstrap.sh` installs apt minimum, runs the Determinate Nix installer, and
applies `home-manager switch --flake .`. First `switch` on aarch64 takes a
while (lower binary-cache hit rate); turning on `features.languages` or
`features.emacs` adds significant build time on first run.

### Targets

| Target | `system` | Notes |
|--------|----------|-------|
| Ubuntu x86_64 VPS / laptop | `x86_64-linux` | primary 1st-class target |
| Oracle A1 ARM / other cloud ARM | `aarch64-linux` | works, slower first switch |
| Galaxy S26 AVF Debian VM | `aarch64-linux` | **parked**, see header note |

## Fork-and-modify pattern

Anyone using this as a template:

1. Fork `openglg-config` on the GitHub web UI (no keys needed).
2. `curl -L https://github.com/<you>/openglg-config/archive/main.tar.gz | tar xz`
3. Edit `home/settings.nix` — set identity, system, and which features to enable.
4. Run `./bootstrap.sh`.
5. To push back, authenticate after bootstrap:

   ```bash
   gh auth login                              # device flow — no SSH key needed
   gh repo clone <you>/openglg-config         # now over authenticated HTTPS
   ```

No SSH keypair is required at any point. `gh` stores a token.

## Verification checklist

After `./bootstrap.sh` completes, in a fresh shell:

- [ ] `nix --version` prints a version
- [ ] `git --version`, `gh --version`, `rg --version`, `fd --version`, `bat --version` all work
- [ ] `git config --global user.email` matches `settings.nix`
- [ ] If `features.cli = true`: `eza --version`, `jq --version`, `lazygit --version` work
- [ ] If `features.tmux = true`: `tmux -V` shows 256-color + true-color in `:show-options -g`
- [ ] If `features.emacs = true`: `emacs --version` shows `emacs-nox`, `mu --version` works
- [ ] If `features.syncthing = true`: `systemctl --user status syncthing.service` is active
- [ ] `dpkg -l | wc -l` did not balloon — apt footprint stays minimal

Record anything that fails — that is the test pipeline talking.

## Files

| File | Purpose |
|------|---------|
| `flake.nix` | home-manager flake — reads `settings.nix`, loads all modules |
| `settings.nix.example` | template; `settings.nix` is gitignored |
| `bootstrap.sh` | apt minimum → Nix install → `home-manager switch` |
| `modules/minimal.nix` | baseline (always on): bash + git identity + gh + rg/fd/bat |
| `modules/shell.nix` | feature: extra bash + FZF/atuin/zoxide/direnv |
| `modules/git.nix` | feature: aliases + delta + LFS + sane defaults |
| `modules/cli.nix` | feature: modern CLI drawer + neovim |
| `modules/tmux.nix` | feature: tmux + zellij |
| `modules/emacs.nix` | feature: emacs-nox + spell + mail + LaTeX |
| `modules/gpg.nix` | feature: gpg + pass + authinfo symlink |
| `modules/syncthing.nix` | feature: services.syncthing + stc |
| `modules/languages.nix` | feature: nodejs/python/go/zig/clojure + LSPs |

## Adding a host-local module

Modules read from `settings` via `extraSpecialArgs` — they never hardcode an
identity. If you need something this template doesn't ship (e.g. a host-only
service), drop a `modules/<name>.nix` next to the others, add it to the
`modules = [ ... ]` list in `flake.nix`, and gate it on a new flag in
`settings.features`. Keep host-specific values out of the module file —
read them from `settings`.

## Out of scope (still parked)

- Profile split (server / vps / workstation) — single profile via feature flags is enough today
- `run.sh home:*` subcommands — `home-manager switch --flake home` is short enough
- Server ↔ home `.env` sharing
- A GUI/Wayland module — this template targets headless / TTY operators

If you need any of these, open a PR or fork.
