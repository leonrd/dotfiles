#!/usr/bin/env bash

set -euo pipefail

__dir="$(cd "$(dirname "$0")" && pwd)"

cleanup() {
  [ -x "${__dir}/pkg-cleanup.sh" ] && ${__dir}/pkg-cleanup.sh
  rm -f /tmp/git-delta.deb
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

# Ask for the administrator password upfront
sudo -v

# Keep-alive sudo until script has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

sudo apt-get update -y

# Install basic tools
sudo apt-get install -y --no-install-recommends \
	man-db less sed curl wget git vim nano make bash tmux unzip gnupg gnupg2

# Install awesome tools
sudo apt-get install -y --no-install-recommends \
	zsh fzf jq ripgrep bat git-flow htop dfc sqlite3 imagemagick ffmpeg sox \
	screen rename rlwrap tree watchman

# Install some dependencies
# ca-certificates: necessary for git-delta and others
# build-essential, libz-dev, libyaml-dev: necessary for building ruby using rbenv
sudo apt-get install -y --no-install-recommends \
	ca-certificates \
	build-essential libyaml-dev

# Install extra tools
sudo apt-get install -y --no-install-recommends \
	gh

# Install git-delta
GIT_DELTA_VERSION=0.18.2 \
ARCH=$(dpkg --print-architecture) \
	wget -q -O /tmp/git-delta.deb \
		"https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" \
	&& sudo dpkg -i /tmp/git-delta.deb \
	&& rm -f /tmp/git-delta.deb

# Install ssh
sudo apt-get install -y --no-install-recommends \
	ssh \
	&& sudo systemctl start ssh \
	&& sudo systemctl enable ssh

# Install Docker
echo "Installing Docker"
sudo apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl software-properties-common \
	&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
	&& sudo apt-get update \
	&& apt-cache policy docker-ce \
	&& sudo apt-get install -y --no-install-recommends docker-ce \
	&& sudo usermod -aG docker "${USER}"
sudo apt-get install -y --no-install-recommends docker-compose-plugin

echo "Installing zsh plugins"
git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM:-${ZSH:-${HOME}/.oh-my-zsh}/custom}/plugins/zsh-completions"
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/fzf-tab"

echo "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mv "${HOME}/.zshrc" "${HOME}/.zshrc.post-oh-my-zsh"
mv "${HOME}/.zshrc.pre-oh-my-zsh" "${HOME}/.zshrc"

echo "reloading SHELL"
SHELL=$(which zsh)
export SHELL; exec "${SHELL}" -l

if ! fgrep -q "${SHELL}" /etc/shells; then
  echo "Setting new zsh as default shell"
  echo "${SHELL}" | sudo tee -a /etc/shells
  chsh -s "${SHELL}"
fi;

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
# Place the kitty.desktop file somewhere it can be found by the OS
cp "${HOME}"/.local/kitty.app/share/applications/kitty.desktop "${HOME}"/.local/share/applications/
# If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file
cp "${HOME}"/.local/kitty.app/share/applications/kitty-open.desktop "${HOME}"/.local/share/applications/
# Update the paths to the kitty and its icon in the kitty desktop file(s)
sed -i "s|Icon=kitty|Icon=/home/${USER}/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" "${HOME}"/.local/share/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=/home/${USER}/.local/kitty.app/bin/kitty|g" "${HOME}"/.local/share/applications/kitty*.desktop
# Make xdg-terminal-exec (and hence desktop environments that support it use kitty)
echo 'kitty.desktop' > "${HOME}"/.config/xdg-terminals.list

echo "Installing sublime-text and sublime-merge"
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg \
	&& echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list \
	&& sudo apt-get update \
	&& sudo apt-get install -y --no-install-recommends sublime-text sublime-merge

echo "Installing gthumb"
sudo apt-get install -y --no-install-recommends gthumb

echo "Installing Google Chrome"
curl -sLO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo dpkg -i google-chrome-stable_current_amd64.deb && rm -f google-chrome-stable_current_amd64.deb

echo "Installing tailscale"
curl -fsSL https://tailscale.com/install.sh | sh

echo "Installing vscode"
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
sudo apt-get update && sudo apt-get install -y --no-install-recommends code

echo "Installing Spotify"
curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get install -y --no-install-recommends spotify-client

echo "Installing dbeaver"
sudo add-apt-repository ppa:serge-rider/dbeaver-ce
sudo apt-get install -y --no-install-recommends dbeaver-ce

echo "Installing android-studio"
sudo apt-get install -y --no-install-recommends openjdk-11-jdk
sudo add-apt-repository -y ppa:maarten-fonville/android-studio
sudo apt-get update && sudo apt-get install -y --no-install-recommends android-studio

echo "Installing OpenResty"
wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
    | sudo tee /etc/apt/sources.list.d/openresty.list
sudo apt-get update && sudo apt-get install -y --no-install-recommends openresty
