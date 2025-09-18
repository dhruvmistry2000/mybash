#!/bin/sh -e

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

# Define the repository path and configuration file
REPO_DIR="$HOME/Github/mybash"
REPO_URL="https://github.com/dhruvmistry2000/mybash"

# Check if the repository directory exists, create it if it doesn't
if [ -d "$REPO_DIR" ]; then
    printf "${YELLOW}Pulling mybash repository at: $REPO_DIR${RC}\n"
    cd "$REPO_DIR"
    git pull
    if [ $? -eq 0 ]; then
        printf "${GREEN}Successfully pulled mybash repository${RC}\n"
    else
        printf "${RED}Failed to pull mybash repository${RC}\n"
    fi
else
    printf "${YELLOW}Cloning mybash repository into: $REPO_DIR${RC}\n"
    git clone "$REPO_URL" "$REPO_DIR"
    if [ $? -eq 0 ]; then
        printf "${GREEN}Successfully cloned mybash repository${RC}\n"
    else
        printf "${RED}Failed to clone mybash repository${RC}\n"
    fi
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
            printf "${RED}To run me, you need: $REQUIREMENTS${RC}\n"
        fi
    done

    ## Check Package Handler
    PACKAGEMANAGER='apt dnf pacman'
    for pgm in $PACKAGEMANAGER; do
        if command_exists "$pgm"; then
            PACKAGER="$pgm"
            printf "Using $pgm\n"
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        printf "${RED}Can't find a supported package manager${RC}\n"
    fi

    if command_exists sudo; then
        SUDO_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi

    printf "Using $SUDO_CMD as privilege escalation software\n"

    ## Check if the current directory is writable.
    GITPATH=$(dirname "$(realpath "$0")")
    if [ ! -w "$GITPATH" ]; then
        printf "${RED}Can't write to $GITPATH${RC}\n"
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in $SUPERUSERGROUP; do
        if groups | grep -q "$sug"; then
            SUGROUP="$sug"
            printf "Super user group $SUGROUP\n"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q "$SUGROUP"; then
        printf "${RED}You need to be a member of the sudo group to run me!${RC}\n"
    fi
}

installDepend() {
    ## Check for dependencies.
    DEPENDENCIES='bash bash-completion lsd tar bat xsel tree wget unzip fontconfig'
    if ! command_exists nvim; then
        DEPENDENCIES="${DEPENDENCIES} neovim"
    fi

    printf "${YELLOW}Installing dependencies...${RC}\n"
    if [ "$PACKAGER" = "pacman" ]; then
        if ! command_exists yay && ! command_exists paru; then
            printf "Installing yay as AUR helper...\n"
            ${SUDO_CMD} ${PACKAGER} --noconfirm -S base-devel
            cd /opt && ${SUDO_CMD} git clone https://aur.archlinux.org/yay-git.git && ${SUDO_CMD} chown -R "${USER}:${USER}" ./yay-git
            cd yay-git && makepkg --noconfirm -si
        else
            printf "AUR helper already installed\n"
        fi
        if command_exists yay; then
            AUR_HELPER="yay"
        elif command_exists paru; then
            AUR_HELPER="paru"
        else
            printf "No AUR helper found. Please install yay or paru.\n"
        fi
        ${AUR_HELPER} --noconfirm -S ${DEPENDENCIES}
    elif [ "$PACKAGER" = "dnf" ]; then
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    else
        ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
    fi

    # Check to see if the FiraCode Nerd Font is installed (Change this to whatever font you would like)
    FONT_NAME="Hack"
    if fc-list :family | grep -iq "$FONT_NAME"; then
        printf "Font '$FONT_NAME' is installed.\n"
    else
        printf "Installing font '$FONT_NAME'\n"
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
        printf "'$FONT_NAME' installed successfully.\n"
    fi
}

installStarshipAndFzf() {
    if command_exists starship; then
        printf "Starship already installed\n"
        return
    fi

    if ! curl -sS https://starship.rs/install.sh | sh; then
        printf "${RED}Something went wrong during starship install!${RC}\n"
    fi
    if command_exists fzf; then
        printf "Fzf already installed\n"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        printf "Zoxide already installed\n"
        return
    fi

    if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        printf "${RED}Something went wrong during zoxide install!${RC}\n"
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
            printf "No supported package manager found. Please install neovim manually.\n"
        ;;
    esac
}

create_fastfetch_config() {

    FASTFETCH_SCRIPT="$GITPATH/execution_scripts/fastfetch.sh"
    if [ -f "$FASTFETCH_SCRIPT" ]; then
        chmod +x "$FASTFETCH_SCRIPT"
        printf "${YELLOW}Running fastfetch.sh...${RC}\n"
        "$FASTFETCH_SCRIPT"
        if [ $? -eq 0 ]; then
            printf "${GREEN}fastfetch.sh executed successfully${RC}\n"
        else
            printf "${RED}fastfetch.sh execution failed${RC}\n"
        fi
    else
        printf "${RED}fastfetch.sh not found at $YAY_SCRIPT${RC}\n"
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
        printf "${RED}Failed to create symbolic link for fastfetch config${RC}\n"
    }
}

linkConfig() {
    ## Get the correct user home directory.
    USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
    ## Check if a bashrc file is already there.
    OLD_BASHRC="$USER_HOME/.bashrc"
    if [ -e "$OLD_BASHRC" ]; then
        printf "${YELLOW}Moving old bash config file to $USER_HOME/.bashrc.bak${RC}\n"
        if ! mv "$OLD_BASHRC" "$USER_HOME/.bashrc.bak"; then
            printf "${RED}Can't move the old bash config file!${RC}\n"
        fi
    fi

    printf "${YELLOW}Linking new bash config file...${RC}\n"
    ln -svf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" || {
        printf "${RED}Failed to create symbolic link for .bashrc${RC}\n"
    }
    ln -svf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" || {
        printf "${RED}Failed to create symbolic link for starship.toml${RC}\n"
    }
}

imp_scripts() {
    COMPILE_SCRIPT="$GITPATH/execution_scripts/compile_setup.sh"
    if [ -f "$COMPILE_SCRIPT" ]; then
        chmod +x "$COMPILE_SCRIPT"
        printf "${YELLOW}Running compile.sh...${RC}\n"
        "$COMPILE_SCRIPT"
        if [ $? -eq 0 ]; then
            printf "${GREEN}compile.sh executed successfully${RC}\n"
        else
            printf "${RED}compile.sh execution failed${RC}\n"
        fi
    else
        printf"${RED}compile.sh not found at $COMPILE_SCRIPT${RC}\n"
    fi
    
    NUMLOCK_SCRIPT="$GITPATH/execution_scripts/numlock.sh"
    if [ -f "$NUMLOCK_SCRIPT" ]; then
        chmod +x "$NUMLOCK_SCRIPT"
        printf "${YELLOW}Running numlock.sh...${RC}\n"
        "$NUMLOCK_SCRIPT"
        if [ $? -eq 0 ]; then
            printf "${GREEN}numlock.sh executed successfully${RC}\n"
        else
            printf "${RED}numlock.sh execution failed${RC}\n"
        fi
    else
        printf"${RED}numlock.sh not found at $NUMLOCK_SCRIPT${RC}\n"
    fi
    
    YAY_SCRIPT="$GITPATH/execution_scripts/yay_setup.sh"
    if [ -f "$YAY_SCRIPT" ]; then
        chmod +x "$YAY_SCRIPT"
        printf "${YELLOW}Running yay_setup.sh...${RC}\n"
        "$YAY_SCRIPT"
        if [ $? -eq 0 ]; then
            printf "${GREEN}yay_setup.sh executed successfully${RC}\n"
        else
            printf "${RED}yay_setup.sh execution failed${RC}\n"
        fi
    else
        printf"${RED}yay_setup.sh not found at $YAY_SCRIPT${RC}\n"
    fi

    ROFINM_SCRIPT="$GITPATH/execution_scripts/rofi_nm.sh"
    if [ -f "$ROFINM_SCRIPT" ]; then
        chmod +x "$ROFINM_SCRIPT"
        printf "${YELLOW}Running rofi_nm.sh...${RC}\n"
        "$ROFINM_SCRIPT"
        if [ $? -eq 0 ]; then
            printf "${GREEN}rofi_nm.sh executed successfully${RC}\n"
        else
            printf "${RED}rofi_nm.sh execution failed${RC}\n"
        fi
    else
        printf"${RED}rofi_nm.sh not found at $ROFINM_SCRIPT${RC}\n"
    fi
}

copyVimrc() {
    if [ -f "$REPO_DIR/.vimrc" ]; then
        cp "$REPO_DIR/.vimrc" "$HOME/.vimrc"
        printf "${GREEN}.vimrc copied to $HOME successfully!${RC}\n"
    else
        printf "${RED}.vimrc not found in $REPO_DIR${RC}\n"
    fi
}
dockerinstall(){
    printf "${YELLOW}Installing Docker...${RC}\n"
    curl -fsSL https://get.docker.com | bash
    ${SUDO_CMD} usermod -aG docker $USER
    printf "${GREEN}Docker installed successfully! Please log out and log back in to apply group
}

checkEnv
installDepend
installStarshipAndFzf
installZoxide
install_additional_dependencies
create_fastfetch_config
copyVimrc
imp_scripts
dockerinstall

if linkConfig; then
    printf "${GREEN}Done! Restart your shell to see the changes.${RC}\n"
else
    printf "${RED}Something went wrong!${RC}\n"
fi
