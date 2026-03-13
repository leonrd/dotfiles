# ~/.zlogout: executed by zsh(1) when login shell exits.

# echo '.zlogout enter'
# zmodload zsh/zprof

# when leaving the console clear the screen to increase privacy
if [ "$SHLVL" = 1 ]; then
	if command -v clear 1>/dev/null 2>&1; then
		clear
		# wipe scrollback on macOS/other systems
    printf '\033[3J'
	elif [ -x /usr/bin/clear_console ]; then 
		/usr/bin/clear_console -q
	fi
fi

# zprof; zmodload -u zsh/zprof
# echo '.zlogout exit'
