# Prevents /etc/zsh/zshrc calling compinit, since we are doing it in ~/.zshrc.
# See /etc/zsh/zshrc on Ubuntu
skip_global_compinit=1

# prevents .zsh_session creation on macos
export SHELL_SESSIONS_DISABLE=1
