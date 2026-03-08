#!/usr/bin/env bash

__dir="$(cd "$(dirname "$0")" && pwd)"

set -euo pipefail
set -E
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
	trap - SIGINT SIGTERM ERR EXIT

  "${__dir}"/pkg-cleanup.sh
}

# Ask for the administrator password upfront
sudo -v

# Keep-alive sudo until script has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

echo "Installing Xcode Command Line Tools"
xcode-select --install

 # Make sure we’re using the latest Homebrew.
if test ! $(which brew); then
  echo "Installing Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew"
  brew update
fi

echo "Running brew doctor"
brew doctor

echo "Upgrading outdated formulae"
brew upgrade --greedy

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

echo "Installing packages from Brewfile"
brew bundle install

if which brew &> /dev/null && [ -x $(brew --prefix)/bin/zsh ]; then
  case $- in
    *i*)
      echo "Setting brew provided zsh as SHELL"
      SHELL=$(brew --prefix)/bin/zsh; export SHELL; exec $SHELL -l
      ;;
  esac
fi

echo "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mv "${HOME}/.zshrc" "${HOME}/.zshrc.post-oh-my-zsh"
mv "${HOME}/.zshrc.pre-oh-my-zsh" "${HOME}/.zshrc"

echo "Installing ohmyzsh plugins"
git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM:-${ZSH:-${HOME}/.oh-my-zsh}/custom}/plugins/zsh-completions"
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/fzf-tab"

if ! fgrep -q "${BREW_PREFIX}/bin/zsh" /etc/shells; then
  echo "Setting brew provided zsh as default shell"
  echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/zsh";
fi;

# Fix oh-my-zsh warnings
compaudit | xargs chmod g-w

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

echo "Installing node lts via n script"
curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | bash -s install lts

echo "Setting npm prefix"
npm config set prefix "${NPM_PREFIX}"

echo "Installing n"
npm install -g n

echo "Installing node lts via n"
n lts

echo "Installing yarn"
npm install -g yarn

echo "Installing kitty"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
# Create a symbolic link to add kitty to PATH (assuming ${HOME}/.local/bin is in
# your system-wide PATH)
ln -s "${HOME}/.local/kitty.app/bin/kitty ${HOME}/.local/bin/"
# Place the kitty.desktop file somewhere it can be found by the OS
cp "${HOME}/.local/kitty.app/share/applications/kitty.desktop ${HOME}/.local/share/applications/"
# If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file
cp "${HOME}/.local/kitty.app/share/applications/kitty-open.desktop ${HOME}/.local/share/applications/"
# Update the paths to the kitty and its icon in the kitty.desktop file(s)
sed -i "s|Icon=kitty|Icon=/home/${USER}/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png"|g "${HOME}/.local/share/applications"/kitty*.desktop
sed -i "s|Exec=kitty|Exec=/home/${USER}/.local/kitty.app/bin/kitty"|g "${HOME}/.local/share/applications"/kitty*.desktop

cleanup
