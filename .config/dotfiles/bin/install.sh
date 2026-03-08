#!/usr/bin/env sh

__dir="$(cd "$(dirname "$0")" && pwd)"

DOTFILES_REPO="${DOTFILES_REPO:-$(cd "${__dir}/../../../" && pwd)}"

dotfiles() {
  git --git-dir="${HOME}/.dotfiles.git/" --work-tree="${HOME}" "$@"
}

git clone --separate-git-dir="${HOME}/.dotfiles.git" "${DOTFILES_REPO}" "${HOME}/dotfiles-clone-tmp"
rm -rf "${HOME}/dotfiles-clone-tmp"

if dotfiles checkout; then
  echo "Checked out dotfiles."
else
  echo "Stashing pre-existing dotfiles."
  dotfiles stash save
  dotfiles checkout
fi

dotfiles config status.showUntrackedFiles no

if [ "$(uname -s)" = "Darwin" ]; then
  "${HOME}/.config/dotfiles/macos/symlink-configs.sh"
fi
