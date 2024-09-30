#!/bin/sh -e

# Define color variables
RC='\033[0m'        # Reset
RED='\033[31m'      # Red
GREEN='\033[32m'    # Green
YELLOW='\033[33m'   # Yellow

# Define variables for the repository URL and the installation directory
FASTFETCH_REPO_URL="https://github.com/LinusDierheimer/fastfetch"
INSTALL_DIR="$HOME/fastfetch"

# Check if the installation directory exists, create it if it doesn't
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Cloning fastfetch repository into: $INSTALL_DIR${RC}"
    git clone "$FASTFETCH_REPO_URL" "$INSTALL_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully cloned fastfetch repository${RC}"
    else
        echo -e "${RED}Failed to clone fastfetch repository${RC}"
        exit 1
    fi
else
    echo -e "${GREEN}Repository already exists at: $INSTALL_DIR${RC}"
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

echo -e "${GREEN}fastfetch has been successfully installed${RC}"
