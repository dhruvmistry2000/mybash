#!/bin/bash
set -e

# Define color variables
RC='\033[0m'        # Reset
GREEN='\033[32m'    # Green
YELLOW='\033[33m'   # Yellow
BLUE='\033[34m'     # Blue
RED='\033[31m'      # Red

REPO_URL="https://github.com/P3rf/rofi-network-manager.git"
DIR_NAME="$HOME/Github/rofi-network-manager"

if [ ! -d "$DIR_NAME" ]; then
    echo -e "${GREEN}Cloning repository...${RC}"
    git clone "$REPO_URL" "$DIR_NAME"
fi

cd "$DIR_NAME"
if [ -f "setup.sh" ]; then
    echo -e "${BLUE}Running setup script...${RC}"
    chmod +x setup.sh
    ./setup.sh install
else
    echo -e "${RED}setup.sh not found in $DIR_NAME${RC}"
fi

CONFIG_FILE="$DIR_NAME/src/ronema.conf"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Updating configuration file...${RC}"
    sed -i 's/^THEME=.*/THEME="nord.rasi"/' "$CONFIG_FILE"
else
    echo -e "${RED}$CONFIG_FILE not found.${RC}"
fi
