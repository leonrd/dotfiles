#!/bin/bash

DOTFILES_HOME_DIR=${DOTFILES_HOME_DIR:-$HOME}

git clone --separate-git-dir=$DOTFILES_HOME_DIR/.dotfiles.git . $DOTFILES_HOME_DIR/.dotfiles-tmp
rm -r $DOTFILES_HOME_DIR/.dotfiles-tmp
function dotfiles {
  git --git-dir=$DOTFILES_HOME_DIR/.dotfiles.git/ --work-tree=$DOTFILES_HOME_DIR $@
}
dotfiles checkout
if [ $? = 1 ]; then
  echo "Checked out dotfiles.";
else
  echo "Stashing up pre-existing dot files.";
  dotfiles stash save
fi;
dotfiles checkout $DOTFILES_HOME_DIR/
dotfiles config status.showUntrackedFiles no