#!/usr/bin/env bash

set -euo pipefail

app_dirs=(/Applications)
[ -d "${HOME}/Applications" ] && app_dirs+=("${HOME}/Applications")
find "${app_dirs[@]}" -name "*.app" -maxdepth 2 | xargs -I{} mdimport -i "{}"
unset app_dirs
