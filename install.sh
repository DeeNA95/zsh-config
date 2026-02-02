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

install_zap() {
    if [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]; then
        echo "Installing Zap..."
        zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep
    else
        echo "Zap already installed."
    fi
}

install_packages() {
    PACKAGES="starship zoxide fzf bat"
    # Note: 'eza' and 'fastfetch' might need special handling on some distros, trying widely available names
    # mapped names: bat -> batcat (ubuntu), fzf -> fzf, zoxide -> zoxide, starship -> starship

    if command -v brew >/dev/null 2>&1; then
        echo "Detected Homebrew. Installing packages..."
        brew install starship zoxide eza bat fzf fastfetch
    elif command -v apt-get >/dev/null 2>&1; then
        echo "Detected apt-get. Installing packages..."
        sudo apt-get update
        sudo apt-get install -y zoxide fzf bat
        # starship recommendation for linux is script
        if ! command -v starship &> /dev/null; then
             curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
        # eza/fastfetch usually require adding repos on older ubuntu, skipping for basic fallback or using cargo if available
        if command -v cargo >/dev/null 2>&1; then
            echo "Installing eza/fastfetch via cargo..."
            cargo install eza fastfetch
        else
            echo "Cargo not found. Skipping eza/fastfetch. Please install manually."
        fi

        # fix bat command name on ubuntu
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/batcat ~/.local/bin/bat

    elif command -v dnf >/dev/null 2>&1; then
        echo "Detected dnf. Installing packages..."
        sudo dnf install -y starship zoxide eza bat fzf fastfetch
    elif command -v pacman >/dev/null 2>&1; then
        echo "Detected pacman. Installing packages..."
        sudo pacman -S --noconfirm starship zoxide eza bat fzf fastfetch
    elif command -v conda >/dev/null 2>&1; then
        echo "Detected Conda. Installing packages..."
        conda install -y -c conda-forge starship zoxide bat fzf eza
        # Fastfetch might not be in standard conda channels, try to install or skip
        if ! command -v fastfetch &> /dev/null; then
             echo "fastfetch not found in conda, skipping or install manually."
        fi
    else
        echo "No supported package manager found. Attempting manual installs for supported tools..."

        # Starship
        if ! command -v starship &> /dev/null; then
             curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi

        # Zoxide
        if ! command -v zoxide &> /dev/null; then
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        fi

        echo "Please install eza, bat, fzf, and fastfetch manually for your OS."
    fi
}

install_zap
install_packages

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
