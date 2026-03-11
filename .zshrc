# zmodload zsh/zprof

export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-${HOME}/.cache/zsh}"
mkdir -p "${ZSH_CACHE_DIR}"
export ZSH_COMPDUMP_DIR="${ZSH_COMPDUMP_DIR:-${ZSH_CACHE_DIR}}"
mkdir -p "${ZSH_COMPDUMP_DIR}"
export ZSH_COMPDUMP="${ZSH_COMPDUMP:-${ZSH_COMPDUMP_DIR}/zcompdump}"

# Path to your Oh My Zsh installation.
export ZSH="${ZSH:-${HOME}/.config/oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME}/.config/oh-my-zsh-custom}"

if [ -d "${ZSH}" ]; then
	# Set name of the theme to load --- if set to "random", it will
	# load a random theme each time Oh My Zsh is loaded, in which case,
	# to know which specific one was loaded, run: echo $RANDOM_THEME
	# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
	ZSH_THEME="robbyrussell"

	# Set list of themes to pick from when loading at random
	# Setting this variable when ZSH_THEME=random will cause zsh to load
	# a theme from this variable instead of looking in $ZSH/themes/
	# If set to an empty array, this variable will have no effect.
	# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

	# Uncomment the following line to use case-sensitive completion.
	# CASE_SENSITIVE="true"

	# Uncomment the following line to use hyphen-insensitive completion.
	# Case-sensitive completion must be off. _ and - will be interchangeable.
	# HYPHEN_INSENSITIVE="true"

	# Uncomment one of the following lines to change the auto-update behavior
	# zstyle ':omz:update' mode disabled  # disable automatic updates
	# zstyle ':omz:update' mode auto      # update automatically without asking
	# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

	# Uncomment the following line to change how often to auto-update (in days).
	zstyle ':omz:update' frequency 7

	# Uncomment the following line if pasting URLs and other text is messed up.
	# DISABLE_MAGIC_FUNCTIONS="true"

	# Uncomment the following line to disable colors in ls.
	# DISABLE_LS_COLORS="true"

	# Uncomment the following line to disable auto-setting terminal title.
	# DISABLE_AUTO_TITLE="true"

	# Uncomment the following line to enable command auto-correction.
	# ENABLE_CORRECTION="true"

	# Uncomment the following line to display red dots whilst waiting for completion.
	# You can also set it to another string to have that shown instead of the default red dots.
	# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
	# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
	COMPLETION_WAITING_DOTS="true"

	# Uncomment the following line if you want to disable marking untracked files
	# under VCS as dirty. This makes repository status check for large repositories
	# much, much faster.
	# DISABLE_UNTRACKED_FILES_DIRTY="true"

	# Uncomment the following line if you want to change the command execution time
	# stamp shown in the history command output.
	# You can set one of the optional three formats:
	# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
	# or set a custom format using the strftime function format specifications,
	# see 'man strftime' for details.
	# HIST_STAMPS="mm/dd/yyyy"

	# Would you like to use another custom folder than $ZSH/custom?
	# ZSH_CUSTOM=/path/to/new-custom-folder

	# Which plugins would you like to load?
	# Standard plugins can be found in $ZSH/plugins/
	# Custom plugins may be added to $ZSH_CUSTOM/plugins/
	# Example format: plugins=(rails git textmate ruby lighthouse)
	# Add wisely, as too many plugins slow down shell startup.
	plugins=(fzf-tab zsh-autosuggestions zsh-navigation-tools)
	fpath+="${ZSH_CUSTOM}/plugins/zsh-completions/src"
	if [ $(uname -s) = 'Darwin' ]; then
		plugins+=(macos )
	fi

	zstyle ':omz:update' zcompdump-file "${ZSH_COMPDUMP}"

	source "${ZSH}/oh-my-zsh.sh"
else
	autoload -Uz promptinit compinit

	zstyle ':completion:*' auto-description 'specify: %d'
	zstyle ':completion:*' completer _expand _complete _correct _approximate
	zstyle ':completion:*' format 'Completing %d'
	zstyle ':completion:*' group-name ''
	zstyle ':completion:*' menu select=2
	if command -v dircolors 1>/dev/null 2>&1; then
		eval "$(dircolors -b)"
	fi
	zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
	zstyle ':completion:*' list-colors ''
	zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
	zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
	zstyle ':completion:*' menu select=long
	zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
	zstyle ':completion:*' use-compctl false
	zstyle ':completion:*' verbose true

	zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
	zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
	promptinit

	# Load only from secure directories
	compinit -i -d "$ZSH_COMPDUMP"
fi

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n "${SSH_CONNECTION}" ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# zsh-autosuggest
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bold,underline"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="vim ${HOME}/.zshrc"
# alias ohmyzsh="vim ${HOME}/.oh-my-zsh"

# Input

# Use the text that has already been typed as the prefix for searching through
# commands (i.e. more intelligent Up/Down behavior)
bindkey "\e[B" history-search-forward
bindkey "\e[A" history-search-backward

# Use Alt/Meta + arrows to navigate between words
# iTerm
bindkey "\e\e[D" backward-word
bindkey "\e\e[C" forward-word
# kitty
bindkey "\e[1;3D" backward-word
bindkey "\e[1;3C" forward-word

# Use Alt/Meta + Delete to delete the preceding word
bindkey "\e[3;3~" kill-word

# Other

if [ $(uname -s) = 'Darwin' ]; then
	[ -f "${HOME}/.config/iterm2/iterm2_shell_integration.zsh" ] && source "${HOME}/.config/iterm2/iterm2_shell_integration.zsh"

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

if command -v uv 1>/dev/null 2>&1; then
 eval "$(uv generate-shell-completion zsh)"
fi

if command -v uvx 1>/dev/null 2>&1; then
 eval "$(uvx --generate-shell-completion zsh)"
fi

# * ~/.config/shell/extra can be used for other settings you don’t want to commit.
for file in "${HOME}/.config/shell"/{aliases,functions,extra}; do
	[ -r "${file}" ] && [ -f "${file}" ] && . "${file}";
done;
unset file;

# zprof
# zmodload -u zsh/zprof
