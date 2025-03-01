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
  kubectl
  zoxide
  git
  curl
  net-tools
  zip
  unzip
  ca-certificates
  gnupg
  stow
)

# Detect OS and set package manager
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
  arch | manjaro)
    PACKAGE_MANAGER="sudo pacman -S --noconfirm"
    PACKAGES+=(alacritty atuin yay fd lazygit docker docker-compose)
    UPDATE_CMD="sudo pacman -Syu --noconfirm"
    ;;
  ubuntu | debian)
    PACKAGE_MANAGER="sudo apt install -y"
    PACKAGES+=(fd-find fonts-jetbrains-mono)
    UPDATE_CMD="sudo apt update && sudo apt upgrade -y"
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
  sudo apt update
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
  sudo apt update
  sudo apt install -y build-essential

  echo "Setting up Docker repository..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  echo "Installing Docker and Docker Compose..."
  sudo apt update
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

fi

# Install Oh My Zsh if not already installed
echo "Checking if Oh My Zsh is installed..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
fi

# Set Zsh as the default shell
echo "Setting Zsh as the default shell..."
chsh -s $(which zsh)

# Install Powerlevel10k if not already installed
P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# Install atuin if not already installed
if [ ! -f "$HOME/.atuin/bin/env" ]; then
  echo "Installing Atuin..."
  bash <(curl https://raw.githubusercontent.com/ellie/atuin/main/install.sh)
fi

# Install Zsh plugins
echo "Installing Zsh plugins..."
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git $ZSH_CUSTOM/plugins/fast-syntax-highlighting

# Check and configure JetBrainsMono Nerd Font
FONT_NAME="JetBrainsMono Nerd Font"
echo "Checking if $FONT_NAME is installed..."
if ! fc-list | grep -qi "$FONT_NAME"; then
  echo "$FONT_NAME not found, installing..."
  $PACKAGE_MANAGER ttf-nerd-fonts
else
  echo "$FONT_NAME is already installed."
fi

echo "Setup complete! Restart your terminal or run 'exec zsh' to apply changes."
