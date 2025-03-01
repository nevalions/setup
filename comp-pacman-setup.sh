#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

# Update the system and install base dependencies
echo "Updating system and installing dependencies..."
sudo pacman -Syu --noconfirm

# Install necessary packages
PACKAGES=(
  alacritty
  atuin
  neovim
  tmux
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
  fast-syntax-highlighting
  fzf
  fd
  tree
  exa
  lazygit
  kubectl
  kubectx
  zoxide
  powerlevel10k
  git
  curl
  net-tools
  zip
  unzip
  nerd-fonts-jetbrains-mono
)

echo "Installing packages..."
sudo pacman -S --noconfirm "${PACKAGES[@]}"

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
  sudo pacman -S --noconfirm nerd-fonts-jetbrains-mono
else
  echo "$FONT_NAME is already installed."
fi

echo "Setup complete! Restart your terminal or run 'exec zsh' to apply changes."
