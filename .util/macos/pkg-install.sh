#!/usr/bin/env bash

set -euo pipefail

__dir="$(cd "$(dirname "$0")" && pwd)"

cleanup() {
  [ -x "${__dir}/pkg-cleanup.sh" ] && ${__dir}/pkg-cleanup.sh
}

on_exit() {
  trap - EXIT SIGINT SIGTERM
  cleanup
}

on_sigint() {
  on_exit
  trap - SIGINT
  kill -SIGINT $$
}

on_sigterm() {
  on_exit
  trap - SIGTERM
  kill -SIGTERM $$
}

trap on_exit EXIT
trap on_sigint SIGINT
trap on_sigterm SIGTERM

echo "Installing Xcode Command Line Tools"
xcode-select --install || true

 # Make sure we’re using the latest Homebrew.
if ! command -v brew 1>/dev/null 2>&1; then
  echo "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Updating Homebrew"
  brew update
fi

echo "Running brew doctor"
brew doctor || true

echo "Upgrading outdated formulae"
brew upgrade --greedy

# Save Homebrew’s installed location.
export BREW_PREFIX=$(brew --prefix)

echo "Installing packages from Brewfile"
brew bundle install --file "${__dir}/Brewfile"

echo "Installing zsh plugins"
ZSH_CUSTOM="${ZSH_CUSTOM:-${ZSH:-${HOME}/.oh-my-zsh}/custom}"
git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM}/plugins/zsh-completions"
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
git clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM}/plugins/fzf-tab"

echo "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mv "${HOME}/.zshrc" "${HOME}/.zshrc.post-oh-my-zsh"
mv "${HOME}/.zshrc.pre-oh-my-zsh" "${HOME}/.zshrc"

echo "Installing rbenv"
git clone https://github.com/rbenv/rbenv.git "${HOME}/.rbenv"
git clone https://github.com/rbenv/ruby-build.git "${HOME}/.rbenv/plugins/ruby-build"
echo "Installing latest ruby via rbenv"
RUBY_VERSION=$(rbenv install -l | grep -v - | tail -1) \
	&& rbenv install "${RUBY_VERSION}" \
	&& rbenv global "${RUBY_VERSION}"

echo "Installing uv"
curl -fsSL https://astral.sh/uv/install.sh | sh
uv self update
echo "Installing latest python via uv"
uv python install --default

echo "Installing n and node lts via n-install"
curl -L https://bit.ly/n-install | bash -s -- -y -n
echo "Installing yarn"
npm install -g yarn

echo "Installing kitty"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
# Create symbolic links to add kitty and kitten to PATH (assuming "${HOME}"/.local/bin is in
# your system-wide PATH)
ln -sf "${HOME}"/.local/kitty.app/bin/kitty "${HOME}"/.local/kitty.app/bin/kitten "${HOME}"/.local/bin/

SHELL=$(which zsh)

if ! fgrep -q "${SHELL}" /etc/shells; then
  echo "Setting new zsh as default shell"
  echo "${SHELL}" | sudo tee -a /etc/shells
  chsh -s "${SHELL}"
fi;

echo "Done. Reloading SHELL"
SHELL=$(which zsh)
export SHELL; exec "${SHELL}" -l
