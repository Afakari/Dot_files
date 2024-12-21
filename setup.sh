#!/bin/bash


set -e

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
    sudo apt update -y && sudo apt upgrade -y
}

install_package() {
    echo "Installing $1..."
    if ! dpkg -l | grep -qw "$1"; then
        sudo apt install -y $1 > /dev/null
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
    sudo dpkg -i /tmp/$deb_file || sudo apt install -f -y
    rm /tmp/$deb_file
}

echo "Setting up your environment..."

check_prerequisites
set_iranian_repos
update_system

packages=(apt-transport-https  ca-certificates lsb-release  xclip python3 python3-pip vim zsh tmux kitty tor git wget fzf autojump )
for package in "${packages[@]}"; do
    install_package $package
done




if ! command -v code &> /dev/null; then
    install_deb_package "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
else
    echo "Visual Studio Code is already installed. Skipping installation."
fi

if ! command -v google-chrome &> /dev/null; then
    install_deb_package "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
else
    echo "Google Chrome is already installed. Skipping installation."
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" || {
        echo "Oh My Zsh installation failed. Please check logs.";
    }
else
    echo "Oh My Zsh is already installed. Skipping installation."
fi


# echo "Installing Go..."
# wget -c https://go.dev/dl/go1.23.4.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
# export PATH=$PATH:/usr/local/go/bin
# source ~/.profile
# go version || {
#     echo "Go installation failed. Please check logs.";
# }


# echo "Installing Docker..."
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt update -y
# sudo apt-get install -y docker-ce docker-ce-cli containerd.io
# docker --version || {
#     echo "Docker installation failed. Please check logs.";
# }


echo "Downloading configuration files..."
config_repo="https://github.com/afakari/dotfiles.git"
config_dir="$HOME/configs_repo"

if [ -d "$config_dir" ]; then
    echo "Configuration directory already exists. Updating..."
    git -C $config_dir pull
else
    git clone $config_repo $config_dir
fi

echo "Copying configuration files..."
cp -r $config_dir/dotfiles/zshrc ~/.zshrc
cp -r $config_dir/dotfiles/tmux.conf ~/.tmux.conf
cp -r $config_dir/dotfiles/kitty.conf ~/.local/kitty/kitty.conf

echo "Environment setup complete! You may need to log out and log back in for changes to take effect."
