# ~/.bash_logout: executed by bash(1) when login shell exits.

# echo '.bash_logout enter'

# when leaving the console clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
	if [ -x /usr/bin/clear_console ]; then 
		/usr/bin/clear_console -q
	elif command -v clear 1>/dev/null 2>&1; then
		clear
		# wipe scrollback on macOS/other systems
    printf '\033[3J'
	fi
fi

# echo '.bash_logout exit'
