#!/bin/sh -e

# Define color variables for output
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[34m'
RC='\033[0m'  # Reset color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Define package manager and escalation tool
PACKAGER=""
ESCALATION_TOOL=""

# Function to check the environment
checkEnv() {
    echo "${BLUE}Checking environment...${RC}"
    # Check for supported package managers
    if command_exists pacman; then
        PACKAGER="pacman"
    elif command_exists apt-get; then
        PACKAGER="apt-get"
    elif command_exists nala; then
        PACKAGER="nala"
    elif command_exists dnf; then
        PACKAGER="dnf"
    elif command_exists zypper; then
        PACKAGER="zypper"
    else
        echo "${RED}No supported package manager found.${RC}"
        exit 1
    fi

    # Determine the escalation tool
    if command_exists sudo; then
        ESCALATION_TOOL="sudo"
    elif command_exists doas; then
        ESCALATION_TOOL="doas"
    else
        ESCALATION_TOOL="su -c"
    fi

    echo "${GREEN}Using $PACKAGER as package manager and $ESCALATION_TOOL for privilege escalation.${RC}"
}

# Function to check if an AUR helper is available
checkAURHelper() {
    if [ "$PACKAGER" = "pacman" ]; then
        if command_exists yay; then
            AUR_HELPER="yay"
        elif command_exists paru; then
            AUR_HELPER="paru"
        else
            echo "${RED}No AUR helper found. Please install yay or paru.${RC}"
            exit 1
        fi
    else
        AUR_HELPER=""
    fi
}

# Install dependencies based on the package manager
installneovim() {
    DEPENDENCIES='tar tree tldr trash-cli unzip cmake make jq'
    VIM_REPO="https://github.com/neovim/neovim"
    LAZYVIM_REPO="https://github.com/LazyVim/starter"
    NEOVIM_DIR="~/.config/nvim"

    echo "${YELLOW}Compiling Neovim...${RC}"
    git clone --depth=1 $VIM_REPO
    cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd ..
    $ESCALATION_TOOL rm -rf neovim
    cd $HOME
    echo "${YELLOW}Installing LazyVim...${RC}"
    git clone $LAZYVIM_REPO $NEOVIM_DIR
    $ESCALATION_TOOL rm -rf $NEOVIM_DIR/.git

}

# Execute functions
checkEnv
checkAURHelper
installneovim
