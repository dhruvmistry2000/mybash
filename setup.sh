#!/bin/sh -e

# Define color codes
RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

setup_environment() {
    # Define the repository path and URL
    REPO_DIR="$HOME/mybash"
    REPO_URL="https://github.com/dhruvmistry2000/mybash"

    # Define variables for commands and paths
    PACKAGER=""
    SUDO_CMD=""
    SUGROUP=""
    GITPATH="$REPO_DIR"

    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }

    is_arch_linux() {
        [ -f /etc/arch-release ]
    }

    check_env() {
        REQUIREMENTS='curl groups sudo'
        for req in $REQUIREMENTS; do
            if ! command_exists "$req"; then
                echo "${RED}To run this script, you need: $REQUIREMENTS${RC}"
                exit 1
            fi
        done

        PACKAGEMANAGER='nala apt dnf yum pacman zypper emerge xbps-install nix-env'
        for pgm in $PACKAGEMANAGER; do
            if command_exists "$pgm"; then
                PACKAGER="$pgm"
                echo "Using $pgm as package manager"
                break
            fi
        done

        if [ -z "$PACKAGER" ]; then
            echo "${RED}Can't find a supported package manager${RC}"
            exit 1
        fi

        if command_exists sudo; then
            SUDO_CMD="sudo"
        elif command_exists doas && [ -f "/etc/doas.conf" ]; then
            SUDO_CMD="doas"
        else
            SUDO_CMD="su -c"
        fi

        echo "Using $SUDO_CMD for privilege escalation"

        GITPATH=$(dirname "$(realpath "$0")")
        if [ ! -w "$GITPATH" ]; then
            echo "${RED}Can't write to $GITPATH${RC}"
            exit 1
        fi

        SUPERUSERGROUP='wheel sudo root'
        for sug in $SUPERUSERGROUP; do
            if groups | grep -q "$sug"; then
                SUGROUP="$sug"
                echo "Super user group $SUGROUP"
                break
            fi
        done

        if ! groups | grep -q "$SUGROUP"; then
            echo "${RED}You need to be a member of the sudo group to run this script!${RC}"
            exit 1
        fi
    }

    install_depend() {
        DEPENDENCIES='bash bash-completion tar bat tree multitail fastfetch wget unzip fontconfig'
        if ! command_exists nvim; then
            DEPENDENCIES="${DEPENDENCIES} neovim"
        fi

        echo "${YELLOW}Installing dependencies...${RC}"
        case "$PACKAGER" in
            pacman)
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
                ;;
            nala)
                ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
                ;;
            emerge)
                ${SUDO_CMD} ${PACKAGER} -v app-shells/bash app-shells/bash-completion app-arch/tar app-editors/neovim sys-apps/bat app-text/tree app-text/multitail app-misc/fastfetch
                ;;
            xbps-install)
                ${SUDO_CMD} ${PACKAGER} -v ${DEPENDENCIES}
                ;;
            nix-env)
                ${SUDO_CMD} ${PACKAGER} -iA nixos.bash nixos.bash-completion nixos.gnutar nixos.neovim nixos.bat nixos.tree nixos.multitail nixos.fastfetch nixos.pkgs.starship
                ;;
            dnf)
                ${SUDO_CMD} ${PACKAGER} install -y ${DEPENDENCIES}
                ;;
            zypper)
                ${SUDO_CMD} zypper refresh
                ${SUDO_CMD} zypper -n install ${DEPENDENCIES}
                ;;
            *)
                ${SUDO_CMD} ${PACKAGER} install -yq ${DEPENDENCIES}
                ;;
        esac

        FONT_NAME="Hack"
        if fc-list :family | grep -iq "$FONT_NAME"; then
            echo "Font '$FONT_NAME' is installed."
        else
            echo "Installing font '$FONT_NAME'"
            FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip"
            FONT_DIR="$HOME/.local/share/fonts"
            wget $FONT_URL -O ${FONT_NAME}.zip
            unzip ${FONT_NAME}.zip -d $FONT_NAME
            mkdir -p $FONT_DIR
            mv ${FONT_NAME}/*.ttf $FONT_DIR/
            fc-cache -fv
            rm -rf ${FONT_NAME} ${FONT_NAME}.zip
            echo "'$FONT_NAME' installed successfully."
        fi
    }

    install_starship_and_fzf() {
        if command_exists starship; then
            echo "Starship already installed"
        else
            if ! curl -sS https://starship.rs/install.sh | sh; then
                echo "${RED}Something went wrong during Starship install!${RC}"
                exit 1
            fi
        fi

        if ! command_exists fzf; then
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install
        else
            echo "Fzf already installed"
        fi
    }

    install_zoxide() {
        if command_exists zoxide; then
            echo "Zoxide already installed"
        else
            if ! curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
                echo "${RED}Something went wrong during Zoxide install!${RC}"
                exit 1
            fi
        fi
    }

    install_additional_dependencies() {
        case "$PACKAGER" in
            apt)
                if [ ! -d "/opt/neovim" ]; then
                    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                    chmod u+x nvim.appimage
                    ./nvim.appimage --appimage-extract
                    ${SUDO_CMD} mv squashfs-root /opt/neovim
                    ${SUDO_CMD} ln -s /opt/neovim/AppRun /usr/bin/nvim
                fi
                ;;
            zypper)
                ${SUDO_CMD} zypper refresh
                ${SUDO_CMD} zypper -n install neovim
                ;;
            dnf)
                ${SUDO_CMD} dnf check-update
                ${SUDO_CMD} dnf install -y neovim
                ;;
            pacman)
                ${SUDO_CMD} pacman -Syu
                ${SUDO_CMD} pacman -S --noconfirm neovim
                ;;
            *)
                echo "No supported package manager found. Please install Neovim manually."
                exit 1
                ;;
        esac
    }

    create_fastfetch_config() {
        USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
        
        if [ ! -d "$USER_HOME/.config/fastfetch" ]; then
            mkdir -p "$USER_HOME/.config/fastfetch"
        fi

        if [ -e "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
            rm -f "$USER_HOME/.config/fastfetch/config.jsonc"
        fi

        ln -svf "$GITPATH/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc" || {
            echo "${RED}Failed to create symbolic link for Fastfetch config${RC}"
            exit 1
        }
    }

    link_config() {
        USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
        OLD_BASHRC="$USER_HOME/.bashrc"
        
        if [ -e "$OLD_BASHRC" ]; then
            echo "${YELLOW}Moving old bash config file to $USER_HOME/.bashrc.bak${RC}"
            if ! mv "$OLD_BASHRC" "$USER_HOME/.bashrc.bak"; then
                echo "${RED}Can't move the old bash config file!${RC}"
                exit 1
            fi
        fi

        echo "${YELLOW}Linking new bash config file...${RC}"
        ln -svf "$GITPATH/.bashrc" "$USER_HOME/.bashrc" || {
            echo "${RED}Failed to create symbolic link for .bashrc${RC}"
            exit 1
        }
        ln -svf "$GITPATH/starship.toml" "$USER_HOME/.config/starship.toml" || {
            echo "${RED}Failed to create symbolic link for starship.toml${RC}"
            exit 1
        }
    }

    copy_scripts() {
        SCRIPTS_SRC_DIR="$GITPATH/scripts"
        SCRIPTS_DEST_DIR="$HOME/.scripts"

        mkdir -p "$SCRIPTS_DEST_DIR"

        for script in "$SCRIPTS_SRC_DIR"/*; do
            if [ -f "$script" ]; then
                cp "$script" "$SCRIPTS_DEST_DIR/"
                chmod +x "$SCRIPTS_DEST_DIR/$(basename "$script")"
                echo "Copied and set execution permission for $(basename "$script")"
            fi
        done
    }

    # Start script execution
    check_env
    install_depend
    install_starship_and_fzf
    install_zoxide
    install_additional_dependencies
    create_fastfetch_config
    copy_scripts

    if is_arch_linux; then
        if ! command_exists yay; then
            echo "${YELLOW}Running yay-setup.sh${RC}"
            curl -sSL https://raw.githubusercontent.com/dhruvmistry2000/mybash/main/yay_setup.sh | bash
        else
            echo "yay is already installed."
        fi

        echo "${YELLOW}Running numlock.sh${RC}"
        curl -sSL https://raw.githubusercontent.com/dhruvmistry2000/mybash/main/numlock.sh | bash
    else
        echo "${RED}This script is intended for Arch Linux only.${RC}"
    fi

    if link_config; then
        echo "${GREEN}Done! Restart your shell to see the changes.${RC}"
    else
        echo "${RED}Something went wrong!${RC}"
    fi
}

setup_environment
