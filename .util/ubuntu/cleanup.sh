#!/usr/bin/env bash

set -e
set -o pipefail
set -E
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
	trap - SIGINT SIGTERM ERR EXIT
}

usage() {
	cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-d] [--dry-run] [--no-color]

An Ubuntu Cleaning up Utility based on
https://github.com/fwartner/mac-cleanup

Available options:

-h, --help       Print this help and exit
-v, --verbose    Print script debug info
-d, --dry-run    Dry run
--no-color    	 Disable colors
EOF
	exit
}

# shellcheck disable=SC2034  # Unused variables left for readability
setup_colors() {
	if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
		NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
	else
		NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
	fi
}

msg() {
	if [ -z "$dry_run" ]; then
	  echo >&2 -e "${1-}"
	fi
}

die() {
	local msg=$1
	local code=${2-1} # default exit status 1
	msg "$msg"
	exit "$code"
}

parse_params() {
	while :; do
		case "${1-}" in
		-h | --help) usage ;;
		-v | --verbose) set -x ;;
		-d | --dry-run) dry_run=true ;;
		--no-color) NO_COLOR=1 ;;
		-?*) die "Unknown option: $1" ;;
		*) break ;;
		esac
		shift
	done

	return 0
}

parse_params "$@"
setup_colors

deleteCaches() {
	local cacheName=$1
	shift
	local paths=("$@")
	echo "Initiating cleanup ${cacheName} cache..."
	for folderPath in "${paths[@]}"; do
		if [[ -d ${folderPath} ]]; then
			dirSize=$(du -hs "${folderPath}" | awk '{print $1}')
			echo "Deleting ${folderPath} to free up ${dirSize}..."
			rm -rfv "${folderPath}"
		fi
	done
}

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
	if [ -z "$dry_results" ]; then
    msg "$b$d ${S[$s]} of space was cleaned up"
  else
    msg "Approx $b$d ${S[$s]} of space will be cleaned up"
  fi
}

count_dry() {
  for path in "${path_list[@]}"; do
    if [ -d "$path" ] || [ -f "$path" ]; then
      temp_dry_results=$(sudo du -ck "$path" | tail -1 | awk '{ print $1 }')
      dry_results="$((dry_results+temp_dry_results))"
    fi
  done
}

remove_paths() {
  if [ -z "$dry_run" ]; then
    for path in "${path_list[@]}"; do
      rm -rfv "$path" &>/dev/null
    done
    unset path_list
  fi
}

collect_paths() {
  path_list+=("$@")
}

# Ask for the administrator password upfront
sudo -v

HOST=$(whoami)

# Keep-alive sudo until script has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

# Enable extended regex
shopt -s extglob

oldAvailable=$(df / | tail -1 | awk '{print $4}')

collect_paths ~/.cache/thumbnails/*
msg 'Clearing thumbnail Cache'
remove_paths

msg 'Removing old snaps' # TODO add count_dry
if [ -z "$dry_run" ]; then
	snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
      sudo snap remove "$snapname" --revision="$revision"
    done
fi

collect_paths /var/log/*gz
msg 'Clearing System Log Files...'
remove_paths

if [ -d ~/.cache/google-chrome/ ]; then
  collect_paths ~/.cache/google-chrome/Default/Cache/*
  msg 'Clearing Google Chrome Cache Files...'
	remove_paths
fi

if type "composer" &>/dev/null; then
  msg 'Cleaning up composer...'
  if [ -z "$dry_run" ]; then
    composer clearcache --no-interaction &>/dev/null
  else
    collect_paths ~/Library/Caches/composer
		remove_paths
  fi
fi

# Deletes Steam caches, logs, and temp files
# -Astro
if [ -d ~/.steam/steam ]; then
  collect_paths ~/.steam/steam/appcache
  collect_paths ~/.steam/steam/depotcache
  collect_paths ~/.steam/steam/logs
  collect_paths ~/.steam/steam/steamapps/shadercache
  collect_paths ~/.steam/steam/steamapps/temp
  collect_paths ~/.steam/steam/steamapps/download
  msg 'Clearing Steam Cache, Log, and Temp Files...'
  remove_paths
fi

# Deletes Minecraft logs
# -Astro
if [ -d ~/Library/Application\ Support/minecraft ]; then
  collect_paths ~/Library/Application\ Support/minecraft/logs
  collect_paths ~/Library/Application\ Support/minecraft/crash-reports
  collect_paths ~/Library/Application\ Support/minecraft/webcache
  collect_paths ~/Library/Application\ Support/minecraft/webcache2
  collect_paths ~/Library/Application\ Support/minecraft/crash-reports
  collect_paths ~/Library/Application\ Support/minecraft/*.log
  collect_paths ~/Library/Application\ Support/minecraft/launcher_cef_log.txt
  if [ -d ~/Library/Application\ Support/minecraft/.mixin.out ]; then
    collect_paths ~/Library/Application\ Support/minecraft/.mixin.out
  fi
  msg 'Clearing Minecraft Cache and Log Files...'
  remove_paths
fi

# Deletes Lunar Client logs (Minecraft alternate client)
# -Astro
if [ -d ~/.lunarclient ]; then
  collect_paths ~/.lunarclient/game-cache
  collect_paths ~/.lunarclient/launcher-cache
  collect_paths ~/.lunarclient/logs
  collect_paths ~/.lunarclient/offline/*/logs
  collect_paths ~/.lunarclient/offline/files/*/logs
  msg 'Deleting Lunar Client logs and caches...'
  remove_paths
fi

# Deletes Wget logs
# -Astro
if [ -d ~/wget-log ]; then
  collect_paths ~/wget-log
  collect_paths ~/.wget-hsts
  msg 'Deleting Wget log and hosts file...'
  remove_paths
fi

# Deletes Cacher logs
# I dunno either
# -Astro
if [ -d ~/.cacher ]; then
  collect_paths ~/.cacher/logs
  msg 'Deleting Cacher logs...'
  remove_paths
fi

# Deletes Android (studio?) cache
# -Astro
if [ -d ~/.android ]; then
  collect_paths ~/.android/cache
  msg 'Deleting Android cache...'
  remove_paths
fi

# Clears Gradle caches
# -Astro
# if [ -d ~/.gradle ]; then
#   collect_paths ~/.gradle/caches
#   msg 'Clearing Gradle caches...'
#   remove_paths
# fi

if type "gem" &>/dev/null; then  # TODO add count_dry
	msg 'Cleaning up any old versions of gems'
  if [ -z "$dry_run" ]; then
    gem cleanup &>/dev/null
  fi
fi

# if type "docker" &>/dev/null; then  # TODO add count_dry
#   msg 'Cleaning up Docker'
#   if [ -z "$dry_run" ]; then
#     if ! docker ps >/dev/null 2>&1; then
#       close_docker=true
#       open --background -a Docker
#     fi
#     docker system prune -af &>/dev/null
#     if [ "$close_docker" = true ]; then
#       killall Docker
#     fi
#   fi
# fi

if [ "$PYENV_VIRTUALENV_CACHE_PATH" ]; then
  collect_paths "$PYENV_VIRTUALENV_CACHE_PATH"
  msg 'Removing Pyenv-VirtualEnv Cache...'
  remove_paths
fi

# if type "npm" &>/dev/null; then
#   msg 'Cleaning up npm cache...'
#   if [ -z "$dry_run" ]; then
#     npm cache clean --force &>/dev/null
#   else
#     collect_paths ~/.npm/*
#   	remove_paths
#   fi
# fi

# if type "yarn" &>/dev/null; then
# 	msg 'Cleaning up Yarn Cache...'
#   if [ -z "$dry_run" ]; then
#     yarn cache clean --force &>/dev/null
#   else
#     collect_paths ~/Library/Caches/yarn
#   	remove_paths
#   fi
# fi

# if type "pnpm" &>/dev/null; then
#   msg 'Cleaning up pnpm Cache...'
#   if [ -z "$dry_run" ]; then
#     pnpm store prune &>/dev/null
#   else
#     collect_paths ~/.pnpm-store/*
#   	remove_paths
#   fi
# fi

# if type "pod" &>/dev/null; then
#   msg 'Cleaning up Pod Cache...'
#   if [ -z "$dry_run" ]; then
#     pod cache clean --all &>/dev/null
#   else
#     collect_paths ~/Library/Caches/CocoaPods
#   	remove_paths
#   fi
# fi

if type "go" &>/dev/null; then
	msg 'Clearing Go module cache...'
  if [ -z "$dry_run" ]; then
    go clean -modcache &>/dev/null
  else
    if [ -n "$GOPATH" ]; then
      collect_paths "$GOPATH/pkg/mod"
    else
      collect_paths ~/go/pkg/mod
    fi
		remove_paths
  fi
fi

# Removes Java heap dumps
collect_paths ~/*.hprof
msg 'Deleting Java heap dumps...'
remove_paths

# Disables extended regex
shopt -u extglob

if [ -z "$dry_run" ]; then
  msg "${GREEN}Success!${NOFORMAT}"

  newAvailable=$(df / | tail -1 | awk '{print $4}')
  count=$((newAvailable - oldAvailable))
  bytesToHuman $count
else
  count_dry
  unset dry_run
  bytesToHuman "$dry_results"
  msg "Continue? [enter]"
  read -r -s -n 1 clean_dry_run
  if [[ $clean_dry_run = "" ]]; then
    exec "$0"
  fi
fi

cleanup
