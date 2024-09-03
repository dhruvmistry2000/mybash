#!/bin/bash

# Define the directory name for yay
YAY_DIR="yay"
YAY_REPO="https://aur.archlinux.org/yay.git"

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
