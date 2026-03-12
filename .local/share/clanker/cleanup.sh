#!/usr/bin/env bash

set -eo pipefail

usage() {
	cat <<EOF
Usage: $(basename "$0") [-h] [-v] [-d] [--dry-run]

An Ubuntu Cleaning up Utility based on
https://github.com/fwartner/mac-cleanup

Available options:

-h, --help       Print this help and exit
-v, --verbose    Print script debug info
-d, --dry-run    Dry run
EOF
	exit
}

msg() {
	if [ -z "${dry_run}" ]; then
	  echo >&2 -e "${1-}"
	fi
}

die() {
	local msg=$1
	local code=${2-1} # default exit status 1
	msg "${msg}"
	exit "${code}"
}

parse_params() {
	while :; do
		case "${1-}" in
		-h | --help) usage ;;
		-v | --verbose) set -x ;;
		-d | --dry-run) dry_run=true ;;
		-?*) die "Unknown option: $1" ;;
		*) break ;;
		esac
		shift
	done

	return 0
}

parse_params "$@"

bytesToHuman() {
	b=${1:-0}
	d=''
	s=1
	S=(Bytes {K,M,G,T,E,P,Y,Z}iB)
	while ((b > 1024)); do
		d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
		b=$((b / 1024))
		((s++))
	done
	if [ -z "${dry_results}" ]; then
    msg "$b$d ${S[$s]} of space was cleaned up"
  else
    msg "Approx $b$d ${S[$s]} of space will be cleaned up"
  fi
}

count_dry() {
  for path in "${path_list[@]}"; do
    if [ -d "${path}" ] || [ -f "${path}" ]; then
      temp_dry_results=$(du -ck "${path}" | tail -1 | awk '{ print $1 }')
      dry_results="$((dry_results+temp_dry_results))"
    fi
  done
}

remove_paths() {
  if [ -z "${dry_run}" ]; then
    for path in "${path_list[@]}"; do
      rm -rfv "${path}" &>/dev/null || true
    done
    unset path_list
  fi
}

collect_paths() {
  path_list+=("$@")
}

HOST=$(whoami)

# Enable extended regex
shopt -s extglob

oldAvailable=$(df / | tail -1 | awk '{print $4}')

collect_paths "${HOME}/.cache/thumbnails"/*
msg 'Clearing thumbnail Cache'
remove_paths

if [ -d "${HOME}/.cache/google-chrome" ]; then
  collect_paths "${HOME}/.cache/google-chrome/Default/Cache"/*
  msg 'Clearing Google Chrome Cache Files...'
	remove_paths
fi

if command -v composer 1>/dev/null 2>&1; then
  msg 'Cleaning up composer...'
  if [ -z "${dry_run}" ]; then
    composer clearcache --no-interaction &>/dev/null || true
  else
    collect_paths "${HOME}/.cache/composer"
		remove_paths
  fi
fi

# Deletes Steam caches, logs, and temp files
# -Astro
if [ -d "${HOME}/.steam/steam" ]; then
  collect_paths "${HOME}/.steam/steam/appcache"
  collect_paths "${HOME}/.steam/steam/depotcache"
  collect_paths "${HOME}/.steam/steam/logs"
  collect_paths "${HOME}/.steam/steam/steamapps/shadercache"
  collect_paths "${HOME}/.steam/steam/steamapps/temp"
  collect_paths "${HOME}/.steam/steam/steamapps/download"
  msg 'Clearing Steam Cache, Log, and Temp Files...'
  remove_paths
fi

# Deletes Minecraft logs
# -Astro
if [ -d "${HOME}/.config/minecraft" ]; then
  collect_paths "${HOME}/.config/minecraft/logs"
  collect_paths "${HOME}/.config/minecraft/crash-reports"
  collect_paths "${HOME}/.config/minecraft/webcache"
  collect_paths "${HOME}/.config/minecraft/webcache2"
  collect_paths "${HOME}/.config/minecraft/crash-reports"
  collect_paths "${HOME}/.config/minecraft"/*.log
  collect_paths "${HOME}/.config/minecraft/launcher_cef_log.txt"
  if [ -d "${HOME}/.config/minecraft/.mixin.out" ]; then
    collect_paths "${HOME}/.config/minecraft/.mixin.out"
  fi
  msg 'Clearing Minecraft Cache and Log Files...'
  remove_paths
fi

# Deletes Lunar Client logs (Minecraft alternate client)
# -Astro
if [ -d "${HOME}/.lunarclient" ]; then
  collect_paths "${HOME}/.lunarclient/game-cache"
  collect_paths "${HOME}/.lunarclient/launcher-cache"
  collect_paths "${HOME}/.lunarclient/logs"
  collect_paths "${HOME}/.lunarclient/offline"/*/logs
  collect_paths "${HOME}/.lunarclient/offline/files"/*/logs
  msg 'Deleting Lunar Client logs and caches...'
  remove_paths
fi

# Deletes Wget logs
# -Astro
if [ -d "${HOME}/wget-log" ]; then
  collect_paths "${HOME}/wget-log"
  collect_paths "${HOME}/.wget-hsts"
  msg 'Deleting Wget log and hosts file...'
  remove_paths
fi

# Deletes Cacher logs
# I dunno either
# -Astro
if [ -d "${HOME}/.cacher" ]; then
  collect_paths "${HOME}/.cacher/logs"
  msg 'Deleting Cacher logs...'
  remove_paths
fi

# Deletes Android (studio?) cache
# -Astro
if [ -d "${HOME}/.android" ]; then
  collect_paths "${HOME}/.android/cache"
  msg 'Deleting Android cache...'
  remove_paths
fi

# Clears Gradle caches
# -Astro
if [ -d "${HOME}/.gradle" ]; then
  collect_paths "${HOME}/.gradle/caches"
  msg 'Clearing Gradle caches...'
  remove_paths
fi

if command -v gem 1>/dev/null 2>&1; then  # TODO add count_dry
  msg 'Cleaning up any old versions of gems'
  if [ -z "${dry_run}" ]; then
    gem cleanup &>/dev/null || true
  fi
fi

if command -v docker 1>/dev/null 2>&1; then  # TODO add count_dry
  msg 'Cleaning up Docker'
  if [ -z "${dry_run}" ]; then
    if ! docker ps >/dev/null 2>&1; then
      close_docker=true
      open --background -a Docker || true
    fi
    docker system prune -af &>/dev/null
    if [ "${close_docker}" = true ]; then
      killall Docker || true
    fi
  fi
fi

if [ "${PYENV_VIRTUALENV_CACHE_PATH}" ]; then
  collect_paths "${PYENV_VIRTUALENV_CACHE_PATH}"
  msg 'Removing Pyenv-VirtualEnv Cache...'
  remove_paths
fi

if command -v npm 1>/dev/null 2>&1; then
  msg 'Cleaning up npm cache...'
  if [ -z "${dry_run}" ]; then
    npm cache clean --force &>/dev/null || true
  else
    collect_paths "${HOME}/.npm"/*
  	remove_paths
  fi
fi

if command -v yarn 1>/dev/null 2>&1; then
	msg 'Cleaning up Yarn Cache...'
  if [ -z "${dry_run}" ]; then
    yarn cache clean --force &>/dev/null || true
  else
    collect_paths "${HOME}/.cache/yarn"
  	remove_paths
  fi
fi

if command -v pnpm 1>/dev/null 2>&1; then
  msg 'Cleaning up pnpm Cache...'
  if [ -z "${dry_run}" ]; then
    pnpm store prune &>/dev/null || true
  else
    collect_paths "${HOME}/.pnpm-store"/*
  	remove_paths
  fi
fi

if command -v pod 1>/dev/null 2>&1; then
  msg 'Cleaning up Pod Cache...'
  if [ -z "${dry_run}" ]; then
    pod cache clean --all &>/dev/null || true
  else
    collect_paths "${HOME}/.cache/CocoaPods"
  	remove_paths
  fi
fi

if command -v go 1>/dev/null 2>&1; then
	msg 'Clearing Go module cache...'
  if [ -z "${dry_run}" ]; then
    go clean -modcache &>/dev/null || true
  else
    if [ -n "${GOPATH}" ]; then
      collect_paths "${GOPATH}/pkg/mod"
    else
      collect_paths "${HOME}/go/pkg/mod"
    fi
		remove_paths
  fi
fi

# Removes Java heap dumps
collect_paths "${HOME}"/*.hprof
msg 'Deleting Java heap dumps...'
remove_paths

# Disables extended regex
shopt -u extglob

if [ -z "${dry_run}" ]; then
  msg "${GREEN}Success!${NOFORMAT}"

  newAvailable=$(df / | tail -1 | awk '{print $4}')
  count=$((newAvailable - oldAvailable))
  bytesToHuman "${count}"
else
  count_dry
  unset dry_run
  bytesToHuman "${dry_results}"
  msg "Continue? [enter]"
  read -r -s -n 1 clean_dry_run
  if [[ ${clean_dry_run} = "" ]]; then
    exec "$0"
  fi
fi
