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

echo "Installing zsh plugins"
git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM:-${ZSH:-${HOME}/.oh-my-zsh}/custom}/plugins/zsh-completions"
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/fzf-tab"

echo "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mv "${HOME}/.zshrc" "${HOME}/.zshrc.post-oh-my-zsh"
mv "${HOME}/.zshrc.pre-oh-my-zsh" "${HOME}/.zshrc"

echo "Reloading SHELL"
SHELL=$(which zsh)
export SHELL; exec "${SHELL}" -l

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

echo "Installing Claude Code"
curl -fsSL https://claude.ai/install.sh | bash -s stable

echo "Installing Codex CLI"
npm install -g @openai/codex

echo "Installing OpenCode"
npm install -g opencode-ai

echo "Installing depgraph"
curl -fsSL https://raw.githubusercontent.com/henryhale/depgraph/master/scripts/install.sh | 

echo "Installing ai-grep"
git clone https://github.com/seqis/AI-grep.git "${HOME}/dev/tools/ai-grep/"" \
	&& chmod +x "${HOME}/dev/tools/ai-grep/ai-grep" \
	&& mkdir -p "${HOME}/dev/tools/bin" \
	&& ln -s "${HOME}/dev/tools/ai-grep/ai-grep" "${HOME}/dev/tools/bin/ai-grep"

echo "Done. Final SHELL reload"
export SHELL; exec "${SHELL}" -l
