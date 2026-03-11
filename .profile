# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

if command -v brew 1>/dev/null 2>&1; then
	eval "$(brew shellenv)"
	# some brew vars for 3rdparty scripts
	export BREW_PREFIX="${HOMEBREW_PREFIX}"
	export BREW_CELLAR="${HOMEBREW_CELLAR}"
	export BREW_REPOSITORY="${HOMEBREW_REPOSITORY}"
fi

# * ~/.config/shell/path can be used to extend `${PATH}`.
if [ -f "${HOME}/.config/shell/path" ]; then
    . "${HOME}/.config/shell/path"
else
	export PATH="${HOME}/bin:${HOME}/.local/bin:${PATH}"
fi

# * ~/.config/shell/extra can be used for other settings you don’t want to commit.
for file in "${HOME}/.config/shell/exports" "${HOME}/.config/shell/aliases" "${HOME}/.config/shell/functions" "${HOME}/.config/shell/extra"; do
	[ -r "${file}" ] && [ -f "${file}" ] && . "${file}"
done
unset file

# Other

f [ $(uname -s) = 'Darwin' ]; then
	[ -f "${HOME}/.iterm2_shell_integration.sh" ] && source "${HOME}/.iterm2_shell_integration.sh"

	alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

	# Homebrew OCLP patch - auto-reapply after brew update
	brew() {
	    command brew "$@"
	    local ret=$?
	    if [[ "$1" == "update" ]]; then
	        curl -sL "https://raw.githubusercontent.com/ajorpheus/homebrew-oclp-patches/master/homebrew-oclp.patch" | git -C /usr/local/Homebrew apply 2>/dev/null && echo "OCLP patches restored"
	    fi
	    return "${ret}"
	}
fi

if command -v rbenv 1>/dev/null 2>&1; then
	eval "$(rbenv init - --no-rehash sh)"
fi

if command -v pyenv 1>/dev/null 2>&1; then
	eval "$(pyenv init - sh)"
fi
