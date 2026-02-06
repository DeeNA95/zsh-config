#!/bin/bash

# Target directory for the repo
REPO_DIR="$HOME/zsh-config"
ZSHRC="$HOME/.zshrc"
STARSHIP_CONFIG="$HOME/.config/starship.toml"

echo "Setting up Zsh configuration..."

# --- Utility Functions ---

backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup="${target}.${timestamp}.bak"
        echo "Backing up existing $(basename "$target") to $(basename "$backup")..."
        mv "$target" "$backup"
    fi
}

# --- Core Setup ---

# 0. Check and install Zsh if not found
check_and_install_zsh() {
    if ! command -v zsh >/dev/null 2>&1; then
        echo "Zsh not found. Installing..."
        if command -v brew >/dev/null 2>&1; then
            brew install zsh
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y zsh
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y zsh
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm zsh
        else
            echo "Error: No supported package manager found to install Zsh. Please install it manually."
            exit 1
        fi
    else
        echo "Zsh is already installed."
    fi
}

set_default_shell() {
    CURRENT_SHELL=$(basename "$SHELL")
    if [ "$CURRENT_SHELL" != "zsh" ]; then
        echo "Changing default shell to Zsh..."
        if command -v chsh >/dev/null 2>&1; then
            sudo chsh -s "$(which zsh)" "$USER"
        else
            echo "Warning: 'chsh' not found. Please manually set Zsh as your default shell."
        fi
    else
        echo "Zsh is already the default shell."
    fi
}

check_and_install_zsh
set_default_shell

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
    if command -v brew >/dev/null 2>&1; then
        echo "Detected Homebrew. Installing packages..."
        brew install starship zoxide eza bat fzf fastfetch
    elif command -v apt-get >/dev/null 2>&1; then
        echo "Detected apt-get. Installing packages..."
        sudo apt-get update

        # Try to install eza via official repo if not already available
        if ! command -v eza &> /dev/null; then
            echo "Setting up eza community repository..."
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierdot.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierdot.gpg] http://deb.gierdot.net/ stable main" | sudo tee /etc/apt/sources.list.d/gierdot.list
            sudo apt-get update
        fi

        sudo apt-get install -y zoxide fzf bat fastfetch eza 2>/dev/null || sudo apt-get install -y zoxide fzf batcat

        # starship recommendation for linux is script
        if ! command -v starship &> /dev/null; then
             curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi

        # Cargo fallback for eza
        if command -v cargo >/dev/null 2>&1; then
            echo "Installing eza via cargo..."
            rustc_version=$(rustc --version | awk '{print $2}')
            # Need 1.82.0+ for latest eza
            if [[ "$rustc_version" < "1.82.0" ]]; then
                echo "rustc version $rustc_version is older than 1.82.0. Installing eza 0.20.18..."
                cargo install eza --version 0.20.18
            else
                cargo install eza
            fi
        else
            echo "Cargo not found. Skipping eza. Please install manually."
        fi

        # fix bat command name on ubuntu if installed as batcat
        if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
            mkdir -p ~/.local/bin
            ln -sf /usr/bin/batcat ~/.local/bin/bat
        fi

    elif command -v dnf >/dev/null 2>&1; then
        echo "Detected dnf. Installing packages..."
        sudo dnf install -y starship zoxide eza bat fzf fastfetch
    elif command -v pacman >/dev/null 2>&1; then
        echo "Detected pacman. Installing packages..."
        sudo pacman -S --noconfirm starship zoxide eza bat fzf fastfetch
    elif command -v conda >/dev/null 2>&1; then
        echo "Detected Conda. Installing packages..."
        conda install -y -c conda-forge starship zoxide bat fzf eza
    else
        echo "No supported package manager found. Attempting manual installs..."
        # Starship
        if ! command -v starship &> /dev/null; then
             curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
        # Zoxide
        if ! command -v zoxide &> /dev/null; then
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        fi
    fi
}

install_zap
install_packages

# 3. Symlink configuration
echo "Symlinking configuration..."

# .zshrc
backup_if_exists "$ZSHRC"
ln -sf "$REPO_DIR/.zshrc" "$ZSHRC"

# starship.toml
mkdir -p "$(dirname "$STARSHIP_CONFIG")"
backup_if_exists "$STARSHIP_CONFIG"
ln -sf "$REPO_DIR/starship.toml" "$STARSHIP_CONFIG"

echo "Setup complete! Please restart your terminal."
