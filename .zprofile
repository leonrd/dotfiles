# ~/.zprofile: executed by zsh(1) for login shells.

# echo '.zprofile enter'
# zmodload zsh/zprof

# just like in arch linux /etc/zprofile
emulate sh -c '. "${HOME}"/.profile'

# zprof; zmodload -u zsh/zprof
# echo '.zprofile exit'