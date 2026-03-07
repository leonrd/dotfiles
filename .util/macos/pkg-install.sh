#!/usr/bin/env bash

set -x
set -e
set -o pipefail
set -E
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
	trap - SIGINT SIGTERM ERR EXIT

  ./pkg-cleanup.sh
}

# Ask for the administrator password upfront
sudo -v

# Keep-alive sudo until script has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

# Install XCode command-line tools.
echo "Installing Xcode Command Line Tools..."
xcode-select --install

# Install command-line tools using Homebrew.

 # Make sure we’re using the latest Homebrew.
if test ! $(which brew); then
  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
fi

brew doctor

echo "Upgrading outdated formulae..."
brew upgrade --greedy

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

brew bundle install

if which brew &> /dev/null && [ -x $(brew --prefix)/bin/zsh ]; then
  case $- in
    *i*) SHELL=$(brew --prefix)/bin/zsh; export SHELL; exec $SHELL -l;;
  esac
fi

# Install ohmyzsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mv ~/.zshrc ~/.zshrc.post-oh-my-zsh
mv ~/.zshrc.pre-oh-my-zsh ~/.zshrc

# Install zsh plugins
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab

echo "Setting brew zsh as default shell"
if ! fgrep -q "${BREW_PREFIX}/bin/zsh" /etc/shells; then
  echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/zsh";
fi;

# Fix oh-my-zsh warnings
compaudit | xargs chmod g-w

curl -fsSL https://astral.sh/uv/install.sh | sh
uv self update

NPM_PREFIX=${NPM_PREFIX:-"$HOME/.npm-global"} \
N_PREFIX=${NPM_PREFIX:-"$HOME/.n"} \
	mkdir -p $NPM_PREFIX \
	&& npm config set prefix "$NPM_PREFIX" \
	&& npm install -g n \
	&& n lts \
	&& npm install -g yarn

# Install Kitty
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

cleanup
