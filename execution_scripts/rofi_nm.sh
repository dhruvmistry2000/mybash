#!/bin/bash
set -e

REPO_URL="https://github.com/yourusername/rofi-network-manager.git"
DIR_NAME="$HOME/Github/rofi-network-manager"

if [ ! -d "$DIR_NAME" ]; then
    echo -e "\e[32mCloning repository...\e[0m"
    git clone "$REPO_URL" "$DIR_NAME"
fi

cd "$DIR_NAME"
if [ -f "setup.sh" ]; then
    echo -e "\e[34mRunning setup script...\e[0m"
    chmod +x setup.sh
    ./setup.sh install
else
    echo -e "\e[31msetup.sh not found in $DIR_NAME\e[0m"
fi

CONFIG_FILE="$DIR_NAME/src/ronema.conf"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "\e[33mUpdating configuration file...\e[0m"
    sed -i 's/^THEME=.*/THEME="nord.rasi"/' "$CONFIG_FILE"
else
    echo -e "\e[31m$CONFIG_FILE not found.\e[0m"
fi
