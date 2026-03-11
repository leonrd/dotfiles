# ~/.zshenv: called on every shell session by zsh(1)

# ubuntu: prevents /etc/zsh/zshrc calling compinit, since we are doing it in ~/.zshrc. See /etc/zsh/zshrc
export skip_global_compinit=1

# macos: prevents .zsh_session creation for Apple_Terminal. See /etc/zshrc_Apple_Terminal
export SHELL_SESSIONS_DISABLE=1
