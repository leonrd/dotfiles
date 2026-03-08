#!/usr/bin/env bash

set -euo pipefail

__dir="$(cd "$(dirname "$0")" && pwd)"

DOTFILES_HOME_DIR="$(cd "${__dir}/../../../" && pwd)"

function dotfiles {
  git --git-dir="${DOTFILES_HOME_DIR}/.dotfiles.git" --work-tree="${DOTFILES_HOME_DIR}" $@
}

dotfiles fetch