#!/bin/sh -e

# Define color variables for output
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
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
installDepend() {
    DEPENDENCIES='tar tree multitail tldr trash-cli unzip cmake make jq'
    echo "${YELLOW}Installing dependencies...${RC}"

    case $PACKAGER in
        pacman)
            if ! grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
                echo "${BLUE}Enabling multilib repository...${RC}"
                echo "[multilib]" | $ESCALATION_TOOL tee -a /etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" | $ESCALATION_TOOL tee -a /etc/pacman.conf
                $ESCALATION_TOOL "$PACKAGER" -Syu
            else
                echo "${GREEN}Multilib is already enabled.${RC}"
            fi
            echo "${BLUE}Installing dependencies using AUR helper...${RC}"
            $AUR_HELPER -S --needed --noconfirm "$DEPENDENCIES"
            ;;
        apt-get)
            COMPILEDEPS='build-essential'
            echo "${BLUE}Updating package lists...${RC}"
            $ESCALATION_TOOL "$PACKAGER" update
            echo "${BLUE}Adding i386 architecture and installing dependencies...${RC}"
            $ESCALATION_TOOL dpkg --add-architecture i386
            $ESCALATION_TOOL "$PACKAGER" update
            if ! $ESCALATION_TOOL "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS; then
                echo "${RED}Unable to locate packages. Please check your sources list and try again.${RC}"
                exit 1
            fi
            ;;
        nala)
            COMPILEDEPS='build-essential'
            echo "${BLUE}Updating package lists...${RC}"
            $ESCALATION_TOOL "$PACKAGER" update
            echo "${BLUE}Adding i386 architecture and installing dependencies...${RC}"
            $ESCALATION_TOOL dpkg --add-architecture i386
            $ESCALATION_TOOL "$PACKAGER" update
            if ! $ESCALATION_TOOL "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS; then
                echo "${RED}Unable to locate packages. Please check your sources list and try again.${RC}"
                exit 1
            fi
            ;;
        dnf)
            COMPILEDEPS='@development-tools'
            echo "${BLUE}Updating package lists...${RC}"
            $ESCALATION_TOOL "$PACKAGER" update
            echo "${BLUE}Enabling powertools and installing dependencies...${RC}"
            $ESCALATION_TOOL "$PACKAGER" config-manager --set-enabled powertools
            $ESCALATION_TOOL "$PACKAGER" install -y $DEPENDENCIES $COMPILEDEPS
            $ESCALATION_TOOL "$PACKAGER" install -y glibc-devel.i686 libgcc.i686
            ;;
        zypper)
            COMPILEDEPS='patterns-devel-base-devel_basis'
            echo "${BLUE}Refreshing repositories and installing dependencies...${RC}"
            $ESCALATION_TOOL "$PACKAGER" refresh
            $ESCALATION_TOOL "$PACKAGER" --non-interactive install $DEPENDENCIES $COMPILEDEPS
            $ESCALATION_TOOL "$PACKAGER" --non-interactive install libgcc_s1-gcc7-32bit glibc-devel-32bit
            ;;
        *)
            echo "${BLUE}Installing dependencies using $PACKAGER...${RC}"
            $ESCALATION_TOOL "$PACKAGER" install -y $DEPENDENCIES
            ;;
    esac
}

# Execute functions
checkEnv
checkAURHelper
installDepend
