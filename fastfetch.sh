#!/bin/sh -e

# Define variables for the repository URL and the installation directory
FASTFETCH_REPO_URL="https://github.com/LinusDierheimer/fastfetch"
INSTALL_DIR="$HOME/fastfetch"

# Check if the installation directory exists, create it if it doesn't
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Cloning fastfetch repository into: $INSTALL_DIR"
    git clone "$FASTFETCH_REPO_URL" "$INSTALL_DIR"
    if [ $? -eq 0 ]; then
        echo "Successfully cloned fastfetch repository"
    else
        echo "Failed to clone fastfetch repository"
        exit 1
    fi
else
    echo "Repository already exists at: $INSTALL_DIR"
fi

# Navigate to the installation directory
cd "$INSTALL_DIR"

# Pull the latest changes from the repository
git pull

# Create a build directory and navigate into it
mkdir -p build
cd build

# Run cmake and make to compile fastfetch
cmake ..
make -j$(nproc)

# Install fastfetch
sudo make install

echo "fastfetch has been successfully installed"
