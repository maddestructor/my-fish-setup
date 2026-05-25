#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
FISH_CONFIG="$HOME/.config/fish"
BACKUP_DIR="$HOME/.config/fish.bak.$(date +%Y%m%d%H%M%S)"

# ── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }
step()    { echo -e "\n${GREEN}▶${NC} $*"; }

# ── OS detection ────────────────────────────────────────────────────────────
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

# ── Package installation ─────────────────────────────────────────────────────
install_curl_tool() {
    local name="$1" url="$2"
    info "Installing $name via curl..."
    curl -fsSL "$url" | bash
}

install_eza_deb() {
    local version
    version=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    local deb_url="https://github.com/eza-community/eza/releases/latest/download/eza_${version}_amd64.deb"
    local tmp="/tmp/eza.deb"
    curl -fsSL "$deb_url" -o "$tmp" && sudo dpkg -i "$tmp" && rm "$tmp"
}

install_packages() {
    local os="$1"
    step "Installing packages for: $os"

    case "$os" in
        arch|manjaro|endeavouros)
            sudo pacman -S --needed --noconfirm \
                fish starship zoxide fzf fd ripgrep eza bat neovim git openssh
            ;;

        ubuntu|debian|linuxmint|pop)
            sudo apt-get update -qq
            sudo apt-get install -y \
                fish neovim git openssh-client ripgrep fzf \
                fd-find bat curl build-essential

            # fd: Ubuntu names it fd-find
            mkdir -p "$LOCAL_BIN"
            if ! command -v fd &>/dev/null; then
                ln -sf "$(which fdfind)" "$LOCAL_BIN/fd"
                info "Created fd → fdfind symlink"
            fi

            # bat: Ubuntu names it batcat
            if ! command -v bat &>/dev/null; then
                ln -sf "$(which batcat)" "$LOCAL_BIN/bat"
                info "Created bat → batcat symlink"
            fi

            # starship
            if ! command -v starship &>/dev/null; then
                install_curl_tool "starship" "https://starship.rs/install.sh"
            fi

            # zoxide
            if ! command -v zoxide &>/dev/null; then
                install_curl_tool "zoxide" "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
            fi

            # eza
            if ! command -v eza &>/dev/null; then
                install_eza_deb || warn "eza install failed — try: cargo install eza"
            fi
            ;;

        fedora)
            sudo dnf install -y \
                fish neovim git openssh ripgrep fzf fd-find bat curl

            if ! command -v starship &>/dev/null; then
                install_curl_tool "starship" "https://starship.rs/install.sh"
            fi
            if ! command -v zoxide &>/dev/null; then
                install_curl_tool "zoxide" "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
            fi
            if ! command -v eza &>/dev/null; then
                warn "eza not in fedora repos — install via: cargo install eza"
            fi
            ;;

        rhel|centos|almalinux|rocky)
            sudo dnf install -y epel-release
            sudo dnf install -y \
                fish neovim git openssh ripgrep fzf bat curl

            if ! command -v starship &>/dev/null; then
                install_curl_tool "starship" "https://starship.rs/install.sh"
            fi
            if ! command -v zoxide &>/dev/null; then
                install_curl_tool "zoxide" "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
            fi
            warn "fd + eza may not be in repos — install via: cargo install fd-find eza"
            ;;

        *)
            warn "Unknown OS '$os' — skipping package install. Install manually:"
            warn "  fish starship zoxide fzf fd ripgrep eza bat neovim git openssh"
            ;;
    esac
}

# ── Fish configs ─────────────────────────────────────────────────────────────
install_fish_configs() {
    step "Installing fish configs"

    # Backup existing config
    if [ -d "$FISH_CONFIG" ]; then
        cp -r "$FISH_CONFIG" "$BACKUP_DIR"
        info "Backed up existing fish config → $BACKUP_DIR"
    fi

    mkdir -p "$FISH_CONFIG/conf.d"

    # Remove old static fzf.fish (replaced by fzf --fish | source in config.fish)
    rm -f "$FISH_CONFIG/conf.d/fzf.fish"

    cp "$REPO_DIR/fish/config.fish" "$FISH_CONFIG/config.fish"
    cp "$REPO_DIR/fish/conf.d/ssh-agent.fish" "$FISH_CONFIG/conf.d/ssh-agent.fish"
    cp "$REPO_DIR/fish/conf.d/uv.fish" "$FISH_CONFIG/conf.d/uv.fish"
    info "Fish configs installed"
}

# ── Starship ─────────────────────────────────────────────────────────────────
install_starship_config() {
    step "Installing starship config"
    mkdir -p "$HOME/.config"
    if [ -f "$HOME/.config/starship.toml" ]; then
        warn "~/.config/starship.toml already exists — skipping (delete it to use the dotfiles version)"
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
        read -rp "  Overwrite with dotfiles template? [y/N] " ans
        [[ "${ans,,}" == "y" ]] || { info "Skipping git config"; return; }
    fi
    cp "$REPO_DIR/git/.gitconfig.template" "$HOME/.gitconfig"
    info "Git config installed (name: maddestructor, email: mathieubelanger14@gmail.com)"
}

# ── SSH ───────────────────────────────────────────────────────────────────────
setup_ssh() {
    step "Setting up SSH"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    local has_key=false
    for key in id_ed25519 id_rsa id_archwsl; do
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
    local fish_path
    fish_path="$(which fish 2>/dev/null)" || { warn "fish not found in PATH"; return; }

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
    echo "║        my-fish-setup installer       ║"
    echo "╚══════════════════════════════════════╝"
    echo ""

    local os
    os=$(detect_os)

    install_packages "$os"
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
