#!/usr/bin/env bash

set -x
set -euo pipefail

__dir="$(cd "$(dirname "$0")" && pwd)"

# Ask for the administrator password upfront
sudo -v

# Keep-alive sudo until script has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

# Disable the Spotlight /Applications & ~/Applications watcher/indexer
launchctl bootout gui/$(id -u) "${HOME}"/Library/LaunchAgents/com.user.spotlight.applications.plist || true

# Disable indexing
sudo mdutil -i off /System/Volumes/Data

# Disable the Spotlight daemon
sudo launchctl bootout system /System/Library/LaunchDaemons/com.apple.metadata.mds.plist || true

# Delete Spotlight indexes
sudo rm -rf /System/Volumes/Data/.Spotlight-V100
rm -fr "${HOME}"/Library/Metadata/CoreSpotlight

# re-create the index directory and write exclusions before daemon starts
sudo mkdir -p /System/Volumes/Data/.Spotlight-V100

# Disable Spotlight indexing for the current user's files and folders except ~/Applications
sudo defaults write /System/Volumes/Data/.Spotlight-V100/VolumeConfiguration Exclusions -array \
  "${HOME}/Desktop" \
  "${HOME}/dev" \
  "${HOME}/Documents" \
  "${HOME}/Downloads" \
  "${HOME}/Library" \
  "${HOME}/Movies" \
  "${HOME}/Music" \
  "${HOME}/Pictures" \
  "${HOME}/Public" \
  "${HOME}/VirtualBox VMs" \
  "${HOME}/README.md" \

# Disable Spotlight suggestions (user)
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
defaults write com.apple.Siri SuggestionsDisabled -bool true
defaults write com.apple.Siri SiriSuggestionsEnabled -bool false
defaults write com.apple.assistant.support "Assistant Enabled" -bool false

# Disable Spotlight suggestions (system)
sudo defaults write /Library/Preferences/com.apple.Spotlight SuggestionsEnabled -bool false

# Enable the Spotlight daemon
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.metadata.mds.plist

echo 'Waiting for mds to recreate the index directory'
waited_seconds=0
until [ -d /System/Volumes/Data/.Spotlight-V100 ]; do
    sleep 1
    waited_seconds=$((waited_seconds + 1))
    if [ $waited_seconds -ge 30 ]; then
        echo "ERROR: Timed out waiting for Spotlight index directory" >&2
        unset waited_seconds
        exit 1
    fi
done
unset waited_seconds

sleep 3

# Enable indexing
sudo mdutil -i on /System/Volumes/Data

# Index apps manually and enable the Spotlight /Applications & ~/Applications watcher/indexer Launch Agent
"${__dir}"/spotlight-applications-import.sh
if [ -f "${HOME}/Library/LaunchAgents/com.user.spotlight.applications.plist" ]; then
  launchctl bootstrap gui/$(id -u) "${HOME}/Library/LaunchAgents/com.user.spotlight.applications.plist"
fi

# Reindex
sudo mdutil -E /System/Volumes/Data
