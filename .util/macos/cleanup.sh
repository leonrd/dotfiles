#!/usr/bin/env bash

set -eo pipefail

usage() {
	cat <<EOF
Usage: $(basename "$0") [-h] [-v] [-d] [--dry-run]

A Mac Cleanup up Utility based on
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

deleteCaches() {
	local cacheName=$1
	shift
	local paths=("$@")
	echo "Initiating cleanup ${cacheName} cache..."
	for folderPath in "${paths[@]}"; do
		if [[ -d "${folderPath}" ]]; then
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
	if [ -z "${dry_results}" ]; then
    msg "$b$d ${S[$s]} of space was cleaned up"
  else
    msg "Approx $b$d ${S[$s]} of space will be cleaned up"
  fi
}

count_dry() {
  for path in "${path_list[@]}"; do
    if [ -d "${path}" ] || [ -f "${path}" ]; then
      temp_dry_results=$(sudo du -ck "${path}" | tail -1 | awk '{ print $1 }')
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

sudo_remove_paths() {
  if [ -z "${dry_run}" ]; then
    for path in "${path_list[@]}"; do
      sudo rm -rfv "${path}" &>/dev/null || true
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

collect_paths /Volumes/*/.Trashes/*
collect_paths "${HOME}/.Trash"/*
msg 'Emptying the Trash 🗑 on all mounted volumes and the main HDD...'
sudo_remove_paths

collect_paths /Library/Caches/*
collect_paths /System/Library/Caches/*
collect_paths "${HOME}/Library/Caches"/*
collect_paths /private/var/folders/bh/*/*/*/*
msg 'Clearing System Cache Files...'
sudo_remove_paths

collect_paths /private/var/log/asl/*.asl
collect_paths /Library/Logs/DiagnosticReports/*
collect_paths /Library/Logs/CreativeCloud/*
collect_paths /Library/Logs/Adobe/*
collect_paths /Library/Logs/adobegc.log
collect_paths "${HOME}/Library/Containers/com.apple.mail/Data/Library/Logs/Mail"/*
collect_paths "${HOME}/Library/Logs/CoreSimulator"/*
msg 'Clearing System Log Files...'
sudo_remove_paths

if [ -d "${HOME}/Library/Logs/JetBrains/" ]; then
  collect_paths "${HOME}/Library/Logs/JetBrains"/*/
  msg 'Clearing all application log files from JetBrains...'
  remove_paths
fi

if [ -d "${HOME}/Library/Application Support/Adobe/" ]; then
  collect_paths "${HOME}/Library/Application Support/Adobe/Common/Media Cache Files"/*
  msg 'Clearing Adobe Cache Files...'
  remove_paths
fi

if [ -d "${HOME}/Library/Application Support/Google/Chrome" ]; then
  collect_paths "${HOME}/Library/Application Support/Google/Chrome/Default/Application Cache"/*
  msg 'Clearing Google Chrome Cache Files...'
  remove_paths
fi

collect_paths "${HOME}/Music/iTunes/iTunes Media/Mobile Applications"/*
msg 'Cleaning up iOS Applications...'
remove_paths

collect_paths "${HOME}/Library/Application Support/MobileSync/Backup"/*
msg 'Removing iOS Device Backups...'
remove_paths

collect_paths "${HOME}/Library/Developer/Xcode/DerivedData"/*
collect_paths "${HOME}/Library/Developer/Xcode/Archives"/*
collect_paths "${HOME}/Library/Developer/Xcode/iOS Device Logs"/*
msg 'Cleaning up XCode Derived Data and Archives...'
remove_paths

if type "xcrun" &>/dev/null; then
  msg 'Cleaning up iOS Simulators...'
  if [ -z "${dry_run}" ]; then
    osascript -e 'tell application "com.apple.CoreSimulator.CoreSimulatorService" to quit' &>/dev/null || true
    osascript -e 'tell application "iOS Simulator" to quit' &>/dev/null || true
    osascript -e 'tell application "Simulator" to quit' &>/dev/null || true
    xcrun simctl shutdown all &>/dev/null || true
    xcrun simctl erase all &>/dev/null || true
  else
    collect_paths "${HOME}/Library/Developer/CoreSimulator/Devices"/*/data/!(Library|var|tmp|Media)
    collect_paths "${HOME}/Library/Developer/CoreSimulator/Devices"/*/data/Library/!(PreferencesCaches|Caches|AddressBook)
    collect_paths "${HOME}/Library/Developer/CoreSimulator/Devices"/*/data/Library/Caches/*
    collect_paths "${HOME}/Library/Developer/CoreSimulator/Devices"/*/data/Library/AddressBook/AddressBook*
		remove_paths
  fi
fi

# support deleting Dropbox Cache if they exist
if [ -d "/Users/${HOST}/Dropbox" ]; then
  collect_paths "${HOME}/Dropbox/.dropbox.cache"/*
  msg 'Clearing Dropbox 📦 Cache Files...'
  remove_paths
fi

if [ -d "${HOME}/Library/Application Support/Google/DriveFS/" ]; then
  collect_paths "${HOME}/Library/Application Support/Google/DriveFS"/[0-9a-zA-Z]*/content_cache
  msg 'Clearing Google Drive File Stream Cache Files...'
  killall "Google Drive File Stream"
  remove_paths
fi

if type "composer" &>/dev/null; then
  msg 'Cleaning up composer...'
  if [ -z "${dry_run}" ]; then
    composer clearcache --no-interaction &>/dev/null || true
  else
    collect_paths "${HOME}/Library/Caches/composer"
		remove_paths
  fi
fi

# Deletes Steam caches, logs, and temp files
# -Astro
if [ -d "${HOME}/Library/Application Support/Steam" ]; then
  collect_paths "${HOME}/Library/Application Support/Steam/appcache"
  collect_paths "${HOME}/Library/Application Support/Steam/depotcache"
  collect_paths "${HOME}/Library/Application Support/Steam/logs"
  collect_paths "${HOME}/Library/Application Support/Steam/steamapps/shadercache"
  collect_paths "${HOME}/Library/Application Support/Steam/steamapps/temp"
  collect_paths "${HOME}/Library/Application Support/Steam/steamapps/download"
  msg 'Clearing Steam Cache, Log, and Temp Files...'
  remove_paths
fi

# Deletes Minecraft logs
# -Astro
if [ -d "${HOME}/Library/Application Support/minecraft" ]; then
  collect_paths "${HOME}/Library/Application Support/minecraft/logs"
  collect_paths "${HOME}/Library/Application Support/minecraft/crash-reports"
  collect_paths "${HOME}/Library/Application Support/minecraft/webcache"
  collect_paths "${HOME}/Library/Application Support/minecraft/webcache2"
  collect_paths "${HOME}/Library/Application Support/minecraft/crash-reports"
  collect_paths "${HOME}/Library/Application Support/minecraft"/*.log
  collect_paths "${HOME}/Library/Application Support/minecraft/launcher_cef_log.txt"
  if [ -d "${HOME}/Library/Application Support/minecraft/.mixin.out" ]; then
    collect_paths "${HOME}/Library/Application Support/minecraft/.mixin.out"
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

if type "brew" &>/dev/null; then
  collect_paths "$(brew --cache)"
  msg 'Cleaning up Homebrew Cache...'
  if [ -z "${dry_run}" ]; then
    brew cleanup -s &>/dev/null || true
    remove_paths
    brew tap --repair &>/dev/null || true
  else
    remove_paths
  fi
fi

if type "gem" &>/dev/null; then  # TODO add count_dry
  msg 'Cleaning up any old versions of gems'
  if [ -z "${dry_run}" ]; then
    gem cleanup &>/dev/null || true
  fi
fi

if type "docker" &>/dev/null; then  # TODO add count_dry
  msg 'Cleaning up Docker'
  if [ -z "${dry_run}" ]; then
    if ! docker ps >/dev/null 2>&1; then
      close_docker=true
      open --background -a Docker || true
    fi
    docker system prune -af &>/dev/null || true
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

if type "npm" &>/dev/null; then
  msg 'Cleaning up npm cache...'
  if [ -z "${dry_run}" ]; then
    npm cache clean --force &>/dev/null || true
  else
    collect_paths "${HOME}/.npm"/*
  	remove_paths
  fi
fi

if type "yarn" &>/dev/null; then
	msg 'Cleaning up Yarn Cache...'
  if [ -z "${dry_run}" ]; then
    yarn cache clean --force &>/dev/null || true
  else
    collect_paths "${HOME}/Library/Caches/yarn"
  	remove_paths
  fi
fi

if type "pnpm" &>/dev/null; then
  msg 'Cleaning up pnpm Cache...'
  if [ -z "${dry_run}" ]; then
    pnpm store prune &>/dev/null || true
  else
    collect_paths "${HOME}/.pnpm-store"/*
  	remove_paths
  fi
fi

if type "pod" &>/dev/null; then
  msg 'Cleaning up Pod Cache...'
  if [ -z "${dry_run}" ]; then
    pod cache clean --all &>/dev/null || true
  else
    collect_paths "${HOME}/Library/Caches/CocoaPods"
  	remove_paths
  fi
fi

if type "go" &>/dev/null; then
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

# Deletes all Microsoft Teams Caches and resets it to default - can fix also some performance issues
# -Astro
if [ -d "${HOME}/Library/Application Support/Microsoft/Teams" ]; then
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/IndexedDB"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/Cache"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/Application Cache"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/Code Cache"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/blob_storage"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/databases"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/gpucache"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/Local Storage"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/tmp"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams"/*logs*.txt
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams/watchdog"
  collect_paths "${HOME}/Library/Application Support/Microsoft/Teams"/*watchdog*.json
  msg 'Deleting Microsoft Teams logs and caches...'
  remove_paths
fi

# Deletes Poetry cache
if [ -d "${HOME}/Library/Caches/pypoetry" ]; then
  collect_paths "${HOME}/Library/Caches/pypoetry"
  msg 'Deleting Poetry cache...'
  remove_paths
fi

# Removes Java heap dumps
collect_paths "${HOME}"/*.hprof
msg 'Deleting Java heap dumps...'
remove_paths

msg 'Cleaning up DNS cache...'
if [ -z "${dry_run}" ]; then
  sudo dscacheutil -flushcache &>/dev/null || true
  sudo killall -HUP mDNSResponder &>/dev/null || true
fi

msg 'Purging inactive memory...'
if [ -z "${dry_run}" ]; then
  sudo purge &>/dev/null || true
fi

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
