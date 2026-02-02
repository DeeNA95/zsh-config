#!/bin/bash

# Target directory for the repo
REPO_DIR="$HOME/zsh-config"
ZSHRC="$HOME/.zshrc"
STARSHIP_CONFIG="$HOME/.config/starship.toml"

echo "Setting up Zsh configuration..."

# 1. Clone if not already there (for the VM use case)
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository..."
    git clone https://github.com/DeeNA95/zsh-config.git "$REPO_DIR"
fi

# 2. Install dependencies
echo "Installing dependencies..."

# Install Zap (Zsh Plugin Manager)
if [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]; then
    echo "Installing Zap..."
    zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep
fi

# Install Homebrew packages if brew is present
if command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew packages..."
    brew install starship zoxide eza bat fzf fastfetch
else
    echo "Homebrew not found. skipping package installation. Please install starship, zoxide, eza, bat, fzf, and fastfetch manually."
fi

# 3. Symlink configuration
echo "Symlinking configuration..."

# .zshrc
if [ -f "$ZSHRC" ] && [ ! -L "$ZSHRC" ]; then
    echo "Backing up existing .zshrc..."
    mv "$ZSHRC" "${ZSHRC}.bak"
fi
ln -sf "$REPO_DIR/.zshrc" "$ZSHRC"

# starship.toml
mkdir -p "$(dirname "$STARSHIP_CONFIG")"
if [ -f "$STARSHIP_CONFIG" ] && [ ! -L "$STARSHIP_CONFIG" ]; then
    echo "Backing up existing starship.toml..."
    mv "$STARSHIP_CONFIG" "${STARSHIP_CONFIG}.bak"
fi
ln -sf "$REPO_DIR/starship.toml" "$STARSHIP_CONFIG"

echo "Setup complete! Please restart your terminal."
