#!/usr/bin/env bash

# Install the Solarized Dark theme for iTerm
mkdir -p "${HOME}/Library/Application\ Support/iTerm2"
cp -r "${HOME}/.config/macos/Application\ Support/iTerm2/Solarized\ Dark.itermcolors" "${HOME}/Application\ Support/iTerm2/Solarized Dark.itermcolors"
open "${HOME}/Application\ Support/iTerm2/Solarized\ Dark.itermcolors"

# Import iTerm profile
mkdir -p "${HOME}/Library/Application\ Support/iTerm2/DynamicProfiles"
cp -r "${HOME}/.config/macos/Application\ Support/iTerm2/DynamicProfiles/Profiles.json" "${HOME}/Library/Application\ Support/iTerm2/DynamicProfiles" 2> /dev/null

# Install Sublime Text settings
mkdir -p "${HOME}/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/"
cp -r "${HOME}/.config/sublime-text/Packages/User/Preferences.sublime-settings" "${HOME}/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings" 2> /dev/null

# Install Sublime Merge settings
mkdir -p "${HOME}/Library/Application\ Support/Sublime\ Merge/Packages/User/"
cp -r "${HOME}/.config/sublime-merge/Packages/User/Preferences.sublime-settings" "${HOME}/Library/Application\ Support/Sublime\ Merge/Packages/User/Preferences.sublime-settings" 2> /dev/null
cp -r "${HOME}/.config/sublime-merge/Packages/User/Diff.sublime-settings" "${HOME}/Library/Application\ Support/Sublime\ Merge/Packages/User/Diff.sublime-settings" 2> /dev/null

# Install VSCode settings
mkdir -p "${HOME}/Library/Application\ Support/Code/User/"
cp -r "${HOME}/.config/Code/User/settings.json" "${HOME}/Library/Application\ Support/Code/User/settings.json" 2> /dev/null

# Set up my preferred keyboard shortcuts
mkdir -p "${HOME}/Library/Application\ Support/Spectacle"
cp -r "${HOME}/.config/macos/Application\ Support/Spectacle/Shortcuts.json" "${HOME}/Library/Application\ Support/Spectacle/Shortcuts.json" 2> /dev/null

# Install the BTT preset
mkdir -p "${HOME}/Application\ Support/BetterTouchTool/"
cp -r "${HOME}/.config/macos/Application\ Support/BetterTouchTool/Default.bttpreset" "${HOME}/Application\ Support/BetterTouchTool/Default.bttpreset"
open "${HOME}/.config/macos/Application\ Support/BetterTouchTool/Default.bttpreset"
