#!/bin/bash

set -e

# Variables
CONFIG_REPO="https://github.com/afakari/dotfiles.git"
CONFIG_DIR="$HOME/configs_repo"
USER_HOME=$(eval echo ~$(logname))
WARP_PLUS_URL="https://github.com/bepass-org/warp-plus/releases/download/v1.2.5/warp-plus_linux-amd64.zip"
WARP_PLUS_ZIP="/tmp/warp-plus.zip"
WARP_PLUS_DIR="/tmp/warp-plus"

# Argument flags
NO_DNS=false
NO_GOLANG=false
NO_DOCKER=false
NO_VSCODE=false
NO_CHROME=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-dns)
            NO_DNS=true
            shift
            ;;
        --no-golang)
            NO_GOLANG=true
            shift
            ;;
        --no-docker)
            NO_DOCKER=true
            shift
            ;;
        --no-vscode)
            NO_VSCODE=true
            shift
            ;;
        --no-chrome)
            NO_CHROME=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

check_prerequisites() {
    echo "Checking prerequisites..."

    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Use sudo to execute the script."
        exit 1
    fi

    if ! ping -c 1 google.com &> /dev/null; then
        echo "Internet connection is required. Please check your connection and try again."
        exit 1
    fi
}

set_iranian_repos() {
    echo "Setting up Iranian repositories..."

    if [ -f /etc/os-release ]; then
        source /etc/os-release

        case $ID in
            ubuntu)
                mirror="http://ir.archive.ubuntu.com/ubuntu/"
                ;;
            debian)
                mirror="http://debian.ir/debian/"
                ;;
            *)
                echo "Unsupported OS: $ID"
                exit 1
                ;;
        esac

        cat > /etc/apt/sources.list <<EOL
deb $mirror ${VERSION_CODENAME} main restricted universe multiverse
deb $mirror ${VERSION_CODENAME}-updates main restricted universe multiverse
deb $mirror ${VERSION_CODENAME}-security main restricted universe multiverse
EOL
        echo "Iranian repositories configured for $ID ($VERSION_CODENAME)."
    else
        echo "Unable to determine OS version. /etc/os-release is missing."
        exit 1
    fi
}

setup_dns() {
    if $NO_DNS; then
        echo "Skipping DNS setup as per --no-dns flag."
        return
    fi

    echo "Setting up DNS..."
    dns_servers=("178.22.122.100" "185.51.200.2")

    if [ -f /etc/resolv.conf ]; then
        echo "Backing up existing /etc/resolv.conf..."
        cp /etc/resolv.conf /etc/resolv.conf.bak

        echo "Updating DNS servers..."
        {
            for dns in "${dns_servers[@]}"; do
                echo "nameserver $dns"
            done
        } > /etc/resolv.conf

        echo "DNS setup complete. Current DNS servers:" \
            && cat /etc/resolv.conf
    else
        echo "DNS setup failed: /etc/resolv.conf not found."
        exit 1
    fi
}

update_system() {
    echo "Updating system..."
    apt update -qq -y && apt upgrade -qq -y
}

install_package() {
    echo "Installing $1..."
    if ! dpkg -l | grep -qw "$1"; then
        apt install -qq -y $1 > /dev/null
        echo "$1 installation completed."
    else
        echo "$1 is already installed. Skipping installation."
    fi
}

install_deb_package() {
    local url=$1
    local deb_file=${url##*/}
    echo "Downloading and installing $deb_file..."
    wget -q $url -O /tmp/$deb_file
    dpkg -i /tmp/$deb_file > /dev/null 2>&1 || apt install -f -y > /dev/null 2>&1
    rm /tmp/$deb_file
}

install_golang() {
    if $NO_GOLANG; then
        echo "Skipping Go installation as per --no-golang flag."
        return
    fi

    echo "Installing Go..."
    wget -c https://go.dev/dl/go1.23.4.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
    export PATH=$PATH:/usr/local/go/bin
    source ~/.profile
    go version || {
        echo "Go installation failed. Please check logs.";
    }
}

install_docker() {
    if $NO_DOCKER; then
        echo "Skipping Docker installation as per --no-docker flag."
        return
    fi

    echo "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update -qq -y
    apt-get install -qq -y docker-ce docker-ce-cli containerd.io > /dev/null
    docker --version || {
        echo "Docker installation failed. Please check logs.";
    }
}

setup_oh_my_zsh() {
    if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" || {
            echo "Oh My Zsh installation failed. Please check logs.";
        }
    else
        echo "Oh My Zsh is already installed. Skipping installation."
    fi
}

copy_config_files() {
    echo "Downloading configuration files..."
    if [ -d "$CONFIG_DIR" ]; then
        echo "Configuration directory already exists. Updating..."
        git -C $CONFIG_DIR pull
    else
        git clone $CONFIG_REPO $CONFIG_DIR
    fi

    echo "Copying configuration files..."
    cp -r $CONFIG_DIR/dotfiles/zshrc $USER_HOME/.zshrc
    cp -r $CONFIG_DIR/dotfiles/tmux.conf $USER_HOME/.tmux.conf
    mkdir -p $USER_HOME/.local/kitty
    cp -r $CONFIG_DIR/dotfiles/kitty.conf $USER_HOME/.local/kitty/kitty.conf

    # Ensure the user owns their home directory files
    chown -R $(logname):$(logname) $USER_HOME
}

install_warp() {
    echo "Setting up Warp..."
    if ! command -v warp &> /dev/null; then
        echo "Downloading Warp Plus..."
        wget -q $WARP_PLUS_URL -O $WARP_PLUS_ZIP

        echo "Extracting Warp Plus..."
        mkdir -p $WARP_PLUS_DIR
        unzip -q $WARP_PLUS_ZIP -d $WARP_PLUS_DIR

        echo "Installing Warp..."
        mv $WARP_PLUS_DIR/warp-plus /usr/local/bin/warp

        echo "Cleaning up..."
        rm -rf $WARP_PLUS_ZIP $WARP_PLUS_DIR

        echo "Warp installed successfully. You can now use the 'warp' command."
    else
        echo "Warp is already installed. Skipping installation."
    fi
}

echo "Setting up your environment..."

check_prerequisites
set_iranian_repos
update_system

packages=(apt-transport-https ca-certificates lsb-release xclip python3 python3-pip vim zsh tmux kitty tor git wget fzf autojump)
for package in "${packages[@]}"; do
    install_package $package
done

if ! $NO_VSCODE && ! command -v code &> /dev/null; then
    install_deb_package "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
else
    echo "Visual Studio Code installation skipped or already installed."
fi

if ! $NO_CHROME && ! command -v google-chrome &> /dev/null; then
    install_deb_package "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
else
    echo "Google Chrome installation skipped or already installed."
fi

setup_oh_my_zsh
install_golang
install_docker
install_warp
copy_config_files

echo "Environment setup complete! You may need to log out and log back in for changes to take effect."