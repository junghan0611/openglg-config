#!/usr/bin/env bash
# Step 1 bootstrap — Layer 1 raw, no security keys required.
#
# Target: S26 AVF Debian VM (aarch64). Also works on Ubuntu x86_64 VPS.
# Goal: install Nix and run home-manager switch against this flake.
#
# Absolute apt minimum: curl, xz-utils, ca-certificates.
# No git via apt. Nix brings git after install.

set -euo pipefail

cd "$(dirname "$0")"

# --- 1. Layer 1 apt (absolute minimum) -------------------------------------
need_apt=0
for pkg in curl xz-utils ca-certificates; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    need_apt=1
    break
  fi
done

if [ "$need_apt" = 1 ]; then
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends \
    curl xz-utils ca-certificates
fi

# --- 2. Nix (Determinate installer, multi-user) ----------------------------
if ! command -v nix >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
fi

# Activate nix-daemon profile in this shell
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# --- 3. settings.nix existence check ---------------------------------------
if [ ! -f settings.nix ]; then
  cat >&2 <<EOF

settings.nix not found.

  cp settings.nix.example settings.nix
  \$EDITOR settings.nix   # set user.username / user.email / system

Then re-run: ./bootstrap.sh
EOF
  exit 1
fi

# --- 4. home-manager build & activate (uses flake.lock) -------------------
# flake.lock pins nixpkgs + home-manager. No more branch-alias drift.
# If lock is missing (forked repo without lock), generate it once.
if [ ! -f flake.lock ]; then
  nix --extra-experimental-features 'nix-command flakes' flake lock
fi

# path: scheme — ignore .git tree-tracking. Bootstrap runs before git is on PATH;
# nix would otherwise call `git` (provided by home-manager itself, chicken/egg).
#
# --max-jobs 1 --cores 1 → AVF aarch64 VM은 RAM 압박이 심해서 병렬 빌드 시
# OOM 킬로 VM 자체가 다운된다. 느려도 살아있게 한다.
nix --extra-experimental-features 'nix-command flakes' \
  build "path:.#homeConfigurations.${USER}.activationPackage" \
  --max-jobs 1 --cores 1

# HOME_MANAGER_BACKUP_EXT=backup turns dotfile conflicts into .backup files
# (Debian default ~/.bashrc would otherwise abort activation).
HOME_MANAGER_BACKUP_EXT=backup ./result/activate

echo
echo "Done. Open a new shell; git/gh/rg/fd/bat should be on PATH."
