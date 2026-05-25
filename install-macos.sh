#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
FISH_CONFIG="$HOME/.config/fish"
BACKUP_DIR="$HOME/.config/fish.bak.$(date +%Y%m%d%H%M%S)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
step() { echo -e "\n${GREEN}▶${NC} $*"; }

# ── Homebrew ──────────────────────────────────────────────────────────────────
install_homebrew() {
    if command -v brew &>/dev/null; then
        info "Homebrew already installed"
    else
        step "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to current shell session (Apple Silicon)
        if [ -f /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

# ── Packages ──────────────────────────────────────────────────────────────────
install_packages() {
    step "Installing packages via Homebrew"
    brew install fish starship zoxide fzf fd ripgrep eza bat neovim git openssh
}

# ── Fish configs ──────────────────────────────────────────────────────────────
install_fish_configs() {
    step "Installing fish configs"

    if [ -d "$FISH_CONFIG" ]; then
        cp -r "$FISH_CONFIG" "$BACKUP_DIR"
        info "Backed up existing fish config → $BACKUP_DIR"
    fi

    mkdir -p "$FISH_CONFIG/conf.d"
    rm -f "$FISH_CONFIG/conf.d/fzf.fish"

    cp "$REPO_DIR/fish/config.fish" "$FISH_CONFIG/config.fish"
    cp "$REPO_DIR/fish/conf.d/ssh-agent.fish" "$FISH_CONFIG/conf.d/ssh-agent.fish"
    cp "$REPO_DIR/fish/conf.d/uv.fish" "$FISH_CONFIG/conf.d/uv.fish"
    info "Fish configs installed"
}

# ── Starship ──────────────────────────────────────────────────────────────────
install_starship_config() {
    step "Installing starship config"
    if [ -f "$HOME/.config/starship.toml" ]; then
        warn "~/.config/starship.toml already exists — skipping"
    else
        cp "$REPO_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
        info "Starship config installed"
    fi
}

# ── Git ───────────────────────────────────────────────────────────────────────
configure_git() {
    step "Configuring git"
    if [ -f "$HOME/.gitconfig" ]; then
        warn "~/.gitconfig already exists"
        read -rp "  Reconfigure? [y/N] " ans
        [[ "${ans,,}" == "y" ]] || { info "Skipping git config"; return; }
    fi

    read -rp "  Git name [maddestructor]: " git_name
    git_name="${git_name:-maddestructor}"

    read -rp "  Git email [mathieubelanger14@gmail.com]: " git_email
    git_email="${git_email:-mathieubelanger14@gmail.com}"

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.editor nvim

    info "Git configured (name: $git_name, email: $git_email)"
}

# ── SSH ───────────────────────────────────────────────────────────────────────
setup_ssh() {
    step "Setting up SSH"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    local has_key=false
    for key in id_ed25519 id_rsa; do
        if [ -f "$HOME/.ssh/$key" ]; then
            info "SSH key found: ~/.ssh/$key"
            has_key=true
            break
        fi
    done

    if [ "$has_key" = false ]; then
        info "No SSH key found — generating ed25519 key"
        ssh-keygen -t ed25519 -C "mathieubelanger14@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""
        info "Key generated: ~/.ssh/id_ed25519"
        echo ""
        warn "Add this public key to GitHub: https://github.com/settings/keys"
        echo "────────────────────────────────────────────────────"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo "────────────────────────────────────────────────────"
    fi
}

# ── Default shell ─────────────────────────────────────────────────────────────
set_default_shell() {
    step "Setting fish as default shell"

    # Homebrew fish paths
    local fish_path=""
    for p in /opt/homebrew/bin/fish /usr/local/bin/fish; do
        if [ -x "$p" ]; then
            fish_path="$p"
            break
        fi
    done

    if [ -z "$fish_path" ]; then
        warn "fish not found — skipping shell change"
        return
    fi

    if ! grep -qF "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
        info "Added $fish_path to /etc/shells"
    fi

    if [ "$SHELL" = "$fish_path" ]; then
        info "fish is already the default shell"
    else
        chsh -s "$fish_path"
        info "Default shell set to fish — restart your terminal"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "╔══════════════════════════════════════╗"
    echo "║    my-fish-setup installer (macOS)   ║"
    echo "╚══════════════════════════════════════╝"
    echo ""

    install_homebrew
    install_packages
    install_fish_configs
    install_starship_config
    configure_git
    setup_ssh
    set_default_shell

    echo ""
    info "Done! Start a new terminal session to use fish."
    echo ""
    echo "  Next steps:"
    echo "  • Run 'gh auth login' to authenticate GitHub CLI"
    echo "  • Add ~/.ssh/id_ed25519.pub to GitHub if using SSH"
    echo ""
}

main "$@"
