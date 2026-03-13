# ~/.profile: executed by the command interpreter for login shells.
# This file is not normally read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# This file is not normally read by zsh(1)

# These dotfiles are setup so that .zprofile and .bash_profile load .profile

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
. "${HOME}"/.config/shell/path

# * ~/.config/shell/path can be used to extend `${PATH}`.
. "${HOME}"/.config/shell/exports

# Other

if command -v rbenv 1>/dev/null 2>&1; then
	eval "$(rbenv init - --no-rehash sh)"
fi

if command -v pyenv 1>/dev/null 2>&1; then
	eval "$(pyenv init - sh)"
fi
