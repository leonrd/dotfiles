#!/usr/bin/env bash

brews=(
  # Install GNU core utilities (those that come with macOS are outdated).
  # Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
  coreutils
  # Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
  findutils
  # Install GNU `sed`, overwriting the built-in `sed`.
  'gnu-sed --with-default-names'
  # Install a modern version of Bash.
  bash
  bash-completion2
  # Install a modern shell.
  zsh
  zsh-completions
  # Install `wget` with IRI support.
  'wget --with-iri'
  # Install GnuPG to enable PGP-signing commits.
  gnupg
  # Install more recent versions of some macOS tools.
  git
  grep
  gmp
  openssh
  screen
  python
  'vim --with-override-system-vi'
  neovim
  # ruby <- install via rbenv
  # Install font tools.
  woff2
  # Install monitoring tools
  dfc
  htop
  # Install other useful binaries.
  git-lfs
  git-flow
  'imagemagick --with-webp'
  imagemagick@6
  libimobiledevice
  # lua
  # luajit
  p7zip
  pkg-config
  readline
  rlwrap
  ssh-copy-id
  tree
  # Install programming related tools
  maven
  nvm
  postgresql
  rbenv
  sqlite
  typescript
  watchman
  yarn
  # switchjdk
  # Install Brew Cask for GUI apps
  caskroom/cask/brew-cask
)

pips=(
  # Glances
)

gems=(
  cocoapods
  # travis
  rails
)

npms=(
)

casks=(
  android-studio
  bettertouchtool
  brave
  # cakebrew
  # ccleaner
  # crashlytics
  # filezilla
  # genymotion
  google-chrome
  iterm2
  java
  java6
  # kodi
  launchrocket
  ngrok
  # openemu
  pgadmin3
  # processing
  # racket
  sketch
  skitch
  # skype
  sourcetree
  # spectacle
  # sqlitestudio
  sublime-text3
  # teamviewer
  the-unarchiver
  # transmission
  virtualbox
  visual-studio-code
  vlc
  # xquartz
)

######################################## End of app list ########################################
set +e

# Install XCode command-line tools.
echo "Installing Xcode Command Line Tools..."
xcode-select --install

# Install command-line tools using Homebrew.

 # Make sure we’re using the latest Homebrew.
if test ! $(which brew); then
  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
fi

brew doctor

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

fails=()

function error {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  msg="${red}Failed to execute: $1 $2${NC}"
  fails+=($2)
  echo -e $msg
}

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      echo "Installed $pkg"
    else
      error $cmd $pkg
    fi
  done
}

install 'brew install' ${brews[@]}

# # Requires user password!
# echo "Setting brew-installed bash as default shell"
# if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
#   echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
#   chsh -s "${BREW_PREFIX}/bin/bash";
# fi;

install 'rbenv install'
install 'nvm install --lts'

install 'pip install' ${pips[@]}
install 'gem install' ${gems[@]}
install 'npm install -g' ${npms[@]}
install "brew cask install --appdir='$HOME'/Applications" ${casks[@]}

echo "Upgrading ..."
pip install --upgrade setuptools
pip install --upgrade pip
gem update --system

echo "Cleaning up ..."
brew cleanup -s
brew cask cleanup
brew linkapps

# # Requires user password!
# echo "Setting zsh as default shell"
# if ! fgrep -q "${BREW_PREFIX}/bin/zsh" /etc/shells; then
#   echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells;
#   chsh -s "${BREW_PREFIX}/bin/zsh";
# fi;

if which brew &> /dev/null && [ -x $(brew --prefix)/bin/zsh ]; then
  case $- in
    *i*) SHELL=$(brew --prefix)/bin/zsh; export SHELL; exec $SHELL -l;;
  esac
fi

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done
