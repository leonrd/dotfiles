#!/usr/bin/env bash

__dir="$(cd "$(dirname "$0")" && pwd)"

set -euo pipefail
set -E
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
	trap - SIGINT SIGTERM ERR EXIT
}

echo "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mv "${HOME}/.zshrc" "${HOME}/.zshrc.post-oh-my-zsh"
mv "${HOME}/.zshrc.pre-oh-my-zsh" "${HOME}/.zshrc"

echo "Installing zsh plugins"
git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM:-${ZSH:-${HOME}/.oh-my-zsh}/custom}/plugins/zsh-completions"
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/fzf-tab"

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

echo "Installing Claude Code"
curl -fsSL https://claude.ai/install.sh | bash -s stable

echo "Installing Codex CLI"
npm install -g @openai/codex

echo "Installing OpenCode"
npm install -g opencode-ai

cleanup
