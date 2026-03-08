#!/usr/bin/env bash

set -euo pipefail

__dir="$(cd "$(dirname "$0")" && pwd)"

DOTFILES_HOME_DIR="${DOTFILES_HOME_DIR:-${HOME}}"
DOTFILES_REPO_DIR="$(cd "${__dir}/../../../" && pwd)"

git clone --separate-git-dir="${DOTFILES_HOME_DIR}/.dotfiles.git" "${DOTFILES_REPO_DIR}" "${DOTFILES_HOME_DIR}/dotfiles-clone-tmp"
rm -r "${DOTFILES_HOME_DIR}/dotfiles-clone-tmp"
function dotfiles {
  git --git-dir="${DOTFILES_HOME_DIR}/.dotfiles.git/" --work-tree="${DOTFILES_HOME_DIR}" $@
}
dotfiles checkout
if [ $? = 1 ]; then
  echo "Checked out dotfiles.";
else
  echo "Stashing up pre-existing dot files.";
  dotfiles stash save
fi;
dotfiles checkout "${DOTFILES_HOME_DIR}/"
dotfiles config status.showUntrackedFiles no

if [ $(uname -s) = 'Darwin' ]; then
  "${DOTFILES_HOME_DIR}/.config/dotfiles/macos"/symlink-configs.sh
fi
