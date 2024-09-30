#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

# Define the repository path and configuration file
REPO_DIR="$HOME/Github/mybash"
REPO_URL="https://github.com/dhruvmistry2000/mybash"

# Check if the repository directory exists, create it if it doesn't
if [ ! -d "$REPO_DIR" ]; then
    echo -e "${YELLOW}Cloning mybash repository into: $REPO_DIR${RC}"
    git clone "$REPO_URL" "$REPO_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully cloned mybash repository${RC}"
    else
        echo -e "${RED}Failed to clone mybash repository${RC}"
        exit 1
    fi
else
    echo -e "${GREEN}Repository already exists at: $REPO_DIR${RC}"
fi

# Define variables for commands and paths
PACKAGER=""
SUDO_CMD=""
SUGROUP=""
GITPATH="$REPO_DIR"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    for req in $REQUIREMENTS; do
        if ! command_exists "$req"; then
            echo -e "${RED}To run me, you need: $REQUIREMENTS${RC}"
            exit 1
        fi
    done

    ## Check Package Handler
    PACKAGEMANAGER='apt dnf pacman'
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            PACKAGER="$pgm"
            echo -e "Using $pgm"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        echo -e "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi

    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi

    echo -e "Using $SUDO_CMD as privilege escalation software"

    ## Check if the current directory is writable.
    GITPATH=$(dirname "$(realpath "$0")")
    if [ ! -w "$GITPATH" ]; then
        echo -e "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            echo -e "Super user group $SUGROUP"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q "$SUGROUP"; then
        echo -e "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='bash bash-completion tar bat tree wget unzip fontconfig'
    if ! command_exists nvim; then
        DEPENDENCIES="${DEPENDENCIES} neovim"
    fi

    echo -e "${YELLOW}Installing dependencies...${RC}"
    if [ "$PACKAGER" = "pacman" ]; then
        if ! command_exists yay && ! command_exists paru; then
            echo "Installing yay as AUR helper..."
            ${SUDO_CMD} ${PACKAGER} --noconfirm -S base-devel
            cd /opt && ${SUDO_CMD} git clone https://aur.archlinux.org/yay-git.git && ${SUDO_CMD} chown -R "${USER}:${USER}" ./yay-git
            cd yay-git && makepkg --noconfirm -si
        else
            echo "AUR helper already installed"
        fi
        if command_exists yay; then
            AUR_HELPER="yay"
        elif command_exists paru; then
            AUR_HELPER="paru"
        else
            echo "No AUR helper found. Please install yay or paru."
            exit 1
        fi
        ${AUR_HELPER} --noconfirm -S ${DEPENDENCIES}
    elif [[ "$PACKAGER" == "dnf" ]]; then
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    else
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    fi

    # Check to see if the FiraCode Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="Hack"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        echo "Font '$FONT_NAME' is installed."
    else
        echo "Installing font '$FONT_NAME'"
        # Change this URL to correspond with the correct font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip"
        FONT_DIR="$HOME/.local/share/fonts"
        wget $FONT_URL -O ${FONT_NAME}.zip
        unzip ${FONT_NAME}.zip -d $FONT_NAME
        mkdir -p $FONT_DIR
        mv ${FONT_NAME}/*.ttf $FONT_DIR/
        # Update the font cache
        fc-cache -fv
        # delete the files created from this
        rm -rf ${FONT_NAME} ${FONT_NAME}.zip
        echo "'$FONT_NAME' installed successfully."
    fi
}

installStarshipAndFzf() {
    if command_exists starship; then
        echo "Starship already installed"
        return
    fi

    if ! curl -sS https://starship.rs/install.sh | sh; then
        echo -e "${RED}Something went wrong during starship install!${RC}"
        exit 1
    fi
    if command_exists fzf; then
        echo "Fzf already installed"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        echo "Zoxide already installed"
        return
    fi

    if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        echo -e "${RED}Something went wrong during zoxide install!${RC}"
        exit 1
    fi
}

install_additional_dependencies() {
    # Additional dependencies installation
    return
   case "$PACKAGER" in
        *apt)
            if [ ! -d "/opt/neovim" ]; then
                curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                chmod u+x nvim.appimage
                ./nvim.appimage --appimage-extract
                ${SUDO_CMD} mv squashfs-root /opt/neovim
                ${SUDO_CMD} ln -s /opt/neovim/AppRun /usr/bin/nvim
            fi
            ;;
        *dnf)
            ${SUDO_CMD} dnf check-update
            ${SUDO_CMD} dnf install -y neovim
            ;;
        *pacman)
            ${SUDO_CMD} pacman -Syu
            ${SUDO_CMD} pacman -S --noconfirm neovim
            ;;
        *)
            echo "No supported package manager found. Please install neovim manually."
            exit 1
            ;;
    esac
}

create_fastfetch_config() {

    FASTFETCH_SCRIPT="$GITPATH/fastfetch.sh"
    if [ -f "$FASTFETCH_SCRIPT" ]; then
        chmod +x "$FASTFETCH_SCRIPT"
        echo -e "${YELLOW}Running fastfetch.sh...${RC}"
        "$FASTFETCH_SCRIPT"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}fastfetch.sh executed successfully${RC}"
        else
            echo -e "${RED}fastfetch.sh execution failed${RC}"
            exit 1
        fi
    else
        echo -e "${RED}fastfetch.sh not found at $YAY_SCRIPT${RC}"
        exit 1
    fi
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    
    if [ ! -d "$USER_HOME/.config/fastfetch" ]; then
        mkdir -p "$USER_HOME/.config/fastfetch"
    fi
    # Check if the fastfetch config file exists
    if [ -e "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
        rm -f "$USER_HOME/.config/fastfetch/config.jsonc"
    fi
    ln -svf "$GITPATH/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc" || {
        echo -e "${RED}Failed to create symbolic link for fastfetch config${RC}"
        exit 1
    }
}

linkConfig() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    ## Check if a bashrc file is already there.
    OLD_BASHRC="$USER_HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ]; then
        echo -e "${YELLOW}Moving old bash config file to $USER_HOME/.bashrc.bak${RC}"
        if ! mv "$OLD_BASHRC" "$USER_HOME/.bashrc.bak"; then
            echo -e "${RED}Can't move the old bash config file!${RC}"
            exit 1
        fi
    fi

    echo -e "${YELLOW}Linking new bash config file...${RC}"
    ln -svf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" || {
        echo -e "${RED}Failed to create symbolic link for .bashrc${RC}"
        exit 1
    }
    ln -svf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" || {
        echo -e "${RED}Failed to create symbolic link for starship.toml${RC}"
        exit 1
    }
}

copyScripts() {
    # Define the source and target directories
    SCRIPTS_SRC_DIR="$GITPATH/scripts"
    SCRIPTS_DEST_DIR="$HOME/.scripts"

    # Create the target directory if it doesn't exist
    mkdir -p "$SCRIPTS_DEST_DIR"

    # Copy all files from the source directory to the target directory
    for script in "$SCRIPTS_SRC_DIR"/*; do
        # Check if it's a file
        if [ -f "$script" ]; then
            # Copy the file to the destination directory
            cp "$script" "$SCRIPTS_DEST_DIR/"
            # Make the file executable
            chmod +x "$SCRIPTS_DEST_DIR/$(basename "$script")"
            echo -e "Copied and set execution permission for $(basename "$script")"
        fi
    done
}

imp_scripts() {
    COMPILE_SCRIPT="$GITPATH/compile_setup.sh"
    if [ -f "$COMPILE_SCRIPT" ]; then
        chmod +x "$COMPILE_SCRIPT"
        echo -e "${YELLOW}Running compile.sh...${RC}"
        "$COMPILE_SCRIPT"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}compile.sh executed successfully${RC}"
        else
            echo -e "${RED}compile.sh execution failed${RC}"
            exit 1
        fi
    else
        echo -e "${RED}compile.sh not found at $COMPILE_SCRIPT${RC}"
        exit 1
    fi
    
    NUMLOCK_SCRIPT="$GITPATH/numlock.sh"
    if [ -f "$NUMLOCK_SCRIPT" ]; then
        chmod +x "$NUMLOCK_SCRIPT"
        echo -e "${YELLOW}Running numlock.sh...${RC}"
        "$NUMLOCK_SCRIPT"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}numlock.sh executed successfully${RC}"
        else
            echo -e "${RED}numlock.sh execution failed${RC}"
            exit 1
        fi
    else
        echo -e "${RED}numlock.sh not found at $NUMLOCK_SCRIPT${RC}"
        exit 1
    fi
    
    YAY_SCRIPT="$GITPATH/yay_setup.sh"
    if [ -f "$YAY_SCRIPT" ]; then
        chmod +x "$YAY_SCRIPT"
        echo -e "${YELLOW}Running yay_setup.sh...${RC}"
        "$YAY_SCRIPT"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}yay_setup.sh executed successfully${RC}"
        else
            echo -e "${RED}yay_setup.sh execution failed${RC}"
            exit 1
        fi
    else
        echo -e "${RED}yay_setup.sh not found at $YAY_SCRIPT${RC}"
        exit 1
    fi
}


checkEnv
installDepend
installStarshipAndFzf
installZoxide
install_additional_dependencies
create_fastfetch_config
copyScripts
imp_scripts


if linkConfig; then
    echo -e "${GREEN}Done! Restart your shell to see the changes.${RC}"
else
    echo -e "${RED}Something went wrong!${RC}"
fi
