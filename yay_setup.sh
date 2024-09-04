#!/bin/bash

# Define color variables for output
YELLOW='\033[1;33m'
RC='\033[0m'

# Define the directory name for yay
YAY_DIR="yay"
YAY_REPO="https://aur.archlinux.org/yay.git"

# Function to check if the distro is Arch-based
is_arch_based() {
  if command -v pacman >/dev/null 2>&1; then
    return 0  # Arch-based
  else
    return 1  # Not Arch-based
  fi
}

# Check if the system is Arch-based
if is_arch_based; then
  echo -e "${YELLOW}Starting yay installation${RC}"
  
  # Update system
  echo "Updating system..."
  sudo pacman -Syu --noconfirm

  # Install required packages
  echo "Installing base-devel and git..."
  sudo pacman -S --noconfirm base-devel git

  # Clone yay repository into the current directory
  if [ -d "$YAY_DIR" ]; then
      echo "Directory $YAY_DIR already exists. Skipping cloning."
  else
      echo "Cloning yay repository into $YAY_DIR..."
      git clone $YAY_REPO $YAY_DIR
  fi

  # Build and install yay
  cd $YAY_DIR
  echo "Building and installing yay..."
  makepkg -si --noconfirm

  # Clean up
  cd ..
  rm -rf $YAY_DIR

  echo "yay installation completed successfully!"
else
  echo "This script is intended for Arch-based systems only. Exiting."
fi
