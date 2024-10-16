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
    printf "${YELLOW}Cloning fastfetch repository into: $INSTALL_DIR${RC}\n"
    if git clone "$FASTFETCH_REPO_URL" "$INSTALL_DIR"; then
        printf "${GREEN}Successfully cloned fastfetch repository${RC}\n"
    else
        printf "${RED}Failed to clone fastfetch repository${RC}\n"
        exit 1
    fi
else
    printf "${GREEN}Repository already exists at: $INSTALL_DIR${RC}\n"
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
make -j"$(nproc)"

# Install fastfetch
sudo make install

printf "${GREEN}fastfetch has been successfully installed${RC}\n"
