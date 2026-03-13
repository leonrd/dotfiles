#!/usr/bin/env sh

DOTFILES_HOME_DIR="${DOTFILES_HOME_DIR:-${HOME}}"

dotfiles() {
  git \
    --git-dir="${DOTFILES_HOME_DIR}/.dotfiles.git/" \
    --work-tree="${DOTFILES_HOME_DIR}" \
    "$@"
}

__dir="$(cd "$(dirname "$0")" && pwd)"

DOTFILES_REPO="${DOTFILES_REPO:-$(cd "${__dir}/../../../" && pwd)}"

git clone --separate-git-dir="${DOTFILES_HOME_DIR}"/.dotfiles.git "${DOTFILES_REPO}" "${DOTFILES_HOME_DIR}"/dotfiles-clone-tmp || exit 1
rm -rf "${DOTFILES_HOME_DIR}"/dotfiles-clone-tmp

dotfiles checkout
if [ $? = 1 ]; then
  echo 'Checking out dotfiles.'
else
  echo 'Stashing pre-existing dotfiles.'
  dotfiles stash save
fi

dotfiles checkout "${DOTFILES_HOME_DIR}/"
dotfiles config status.showUntrackedFiles no

if [ "$(uname -s)" = 'Darwin' ]; then
  "${__dir}"/macos/symlink-configs.sh
fi
