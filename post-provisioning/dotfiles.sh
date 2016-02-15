#!/bin/bash

su vagrant

DOTFILES_DOWNLOAD=https://github.com/generoi/dotfiles/archive/master.tar.gz
DOTFILES_DOWNLOAD_DIR=~/dotfiles

# Check to see if we've already performed this setup.
if [ ! -d "$DOTFILES_DOWNLOAD_DIR/bootstrap.sh" ]; then
  # Download and expand the dotfiles
  mkdir -p $DOTFILES_DOWNLOAD_DIR
  wget -qO- $DOTFILES_DOWNLOAD | tar xvz --strip 1 -C $DOTFILES_DOWNLOAD_DIR

  # Install the dotfiles.
  cd $DOTFILES_DOWNLOAD_DIR
  ./bootstrap.sh
else
  exit 0
fi
