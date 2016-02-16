#!/bin/bash

USERNAME=vagrant
DOTFILES_GIT=https://github.com/generoi/dotfiles.git
DOTFILES_DOWNLOAD_DIR=/home/$USERNAME/dotfiles

# Check to see if we've already performed this setup.
if [ ! -e "$DOTFILES_DOWNLOAD_DIR/bootstrap.sh" ]; then
  # Download and expand the dotfiles
  sudo -u $USERNAME -H git clone $DOTFILES_GIT $DOTFILES_DOWNLOAD_DIR

  # Install the dotfiles.
  sudo -u $USERNAME -H sh -c "cd $DOTFILES_DOWNLOAD_DIR; bash bootstrap.sh"
else
  exit 0
fi
