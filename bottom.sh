#!/bin/bash

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

installRustAndBottom() {
    # Check if Rust is installed
    if command_exists rustc; then
        echo "${GREEN}Rust is already installed.${RC}"
        return
    fi

    echo "${YELLOW}Installing Rust...${RC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y

    # Source the Rust environment
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    else
        echo "${RED}Failed to source Rust environment. Please ensure Rust is installed correctly.${RC}"
        exit 1
    fi

    # Clone the bottom repository
    echo "${YELLOW}Cloning bottom repository...${RC}"
    BOTTOM_DIR="$HOME/bottom"
    if [ ! -d "$BOTTOM_DIR" ]; then
        git clone https://github.com/ClementTsang/bottom.git "$BOTTOM_DIR"
    else
        echo "Bottom repository already exists at $BOTTOM_DIR"
    fi

    # Build the bottom project
    echo "${YELLOW}Building bottom...${RC}"
    cd "$BOTTOM_DIR" || { echo "${RED}Failed to enter directory $BOTTOM_DIR.${RC}"; exit 1; }
    cargo build --release
    if [ $? -eq 0 ]; then
        echo "${GREEN}Bottom built successfully!${RC}"
    else
        echo "${RED}Failed to build bottom!${RC}"
        exit 1
    fi

    # Cleanup: Remove the bottom directory
    echo "${YELLOW}Cleaning up by removing the bottom directory...${RC}"
    cd ~ || exit 1  # Navigate back to the home directory
    rm -rf "$BOTTOM_DIR"
    echo "${GREEN}Bottom directory removed successfully.${RC}"

    # Ask the user if they want to keep Rust
    read -p "Do you want to keep Rust installed? (y/n): " keep_rust
    if [[ "$keep_rust" =~ ^[Nn]$ ]]; then
        echo "${YELLOW}Removing Rust...${RC}"
        rustup self uninstall -y
        echo "${GREEN}Rust has been removed.${RC}"
    else
        echo "${GREEN}Rust will be kept.${RC}"
    fi
}

# Call the function
installRustAndBottom
