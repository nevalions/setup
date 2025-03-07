#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

# Define package list
PACKAGES=(
    neovim
    tmux
    zsh
    fzf
    tree
    eza
    zoxide
    git
    curl
    net-tools
    zip
    unzip
    ca-certificates
    gnupg
    stow
    python3
    python3-pip
    python3-venv
    nodejs
    npm
)

# Detect OS and set package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
    arch | manjaro)
        PACKAGE_MANAGER="sudo pacman -S --noconfirm"
        PACKAGES+=(alacritty atuin yay fd lazygit docker docker-compose bat)
        UPDATE_CMD="sudo pacman -Syu --noconfirm"
        ;;
    ubuntu | debian)
        PACKAGE_MANAGER="sudo apt install -y"
        PACKAGES+=(fd-find fonts-jetbrains-mono)
        UPDATE_CMD="sudo apt update -y"
        ;;
    *)
        echo "Unsupported OS"
        exit 1
        ;;
    esac
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

# Update the system
echo "Updating system..."
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
    # Ubuntu/Debian
    sudo apt update -y
    sudo apt upgrade -y
elif [[ "$ID" == "arch" || "$ID" == "manjaro" ]]; then
    # Arch/Manjaro
    sudo pacman -Syu --noconfirm
else
    echo "Unsupported OS"
    exit 1
fi

# Install necessary packages
echo "Installing packages..."
$PACKAGE_MANAGER "${PACKAGES[@]}"

# Install Docker & Docker Compose on Ubuntu/Debian
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
    sudo apt install build-essential -y

    echo "Setting up Docker repository..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    echo "Installing Docker and Docker Compose..."
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Enabling Docker service..."
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    sudo chmod 666 /var/run/docker.sock

    echo "Installing lazygit"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t /usr/local/bin/
    # Clean up the setup files (tarball and extracted binary)
    rm -f lazygit.tar.gz lazygit
    echo "LazyGit installation complete and setup files removed."

    echo "Install Rust and Cargo (if not already installed)"
    if ! command -v cargo &>/dev/null; then
        echo "Installing Rust and Cargo..."
        # Install rust (which includes Cargo)
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # Add Rust to the PATH (if not already done by the rustup installation)
        source $HOME/.cargo/env
    fi

    echo "Install Atuin using Cargo"
    if ! command -v atuin &>/dev/null; then
        echo "Installing Atuin via Cargo..."
        cargo install atuin
    fi

    if ! command -v bat &>/dev/null; then
        echo "Installing bat via Cargo"
        cargo install bat
        bat cache --build
    fi
fi

echo "Removing .tmux.conf if it exists"
if [ -f "$HOME/.tmux.conf" ]; then
    rm "$HOME/.tmux.conf"
fi

echo "Installing TPM if not already installed"
if [ ! -d "$HOME/.tmux/plugins/tpm/" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install Oh My Zsh if not already installed
echo "Checking if Oh My Zsh is installed..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
fi

P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    echo "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# if [ ! -f "$HOME/.atuin/bin/env" ]; then
#   echo "Installing Atuin..."
#   bash <(curl https://raw.githubusercontent.com/ellie/atuin/main/install.sh)
# fi
#

echo "Installing Zsh plugins..."
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# Check and clone plugins only if they are not already installed
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

if [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git $ZSH_CUSTOM/plugins/fast-syntax-highlighting
fi

FONT_NAME="JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"

echo "Checking if $FONT_NAME is installed..."
if ! fc-list | grep -qi "$FONT_NAME"; then
    echo "$FONT_NAME not found, installing..."

    # Download JetBrainsMono Nerd Font (replace the version number if needed)
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip -P /tmp

    # Unzip the font to the font directory
    mkdir -p $FONT_DIR
    unzip /tmp/JetBrainsMono.zip -d $FONT_DIR

    # Clean up the zip file
    rm /tmp/JetBrainsMono.zip

    # Update font cache
    # fc-cache -fv

    echo "$FONT_NAME installed successfully."
else
    echo "$FONT_NAME is already installed."
fi

echo "Setup complete! Restart your terminal or run 'exec zsh' to apply changes."
