cp "${HOME}/.zsh_history" "${HOME}/.zsh_history.pre-dedup" \
  && cat -n "${HOME}/.zsh_history" | sort -t ';' -uk2 | sort -nk1 | cut -f2- \
    > "${HOME}/.zsh_history.dedup" \
  && mv "${HOME}/.zsh_history.dedup" "${HOME}/.zsh_history"