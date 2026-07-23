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
# Sets globals OS_ID and OS_ID_LIKE. Must run in the current shell (not a
# subshell/command substitution) so both values survive past this call —
# ID_LIKE is what lets subdistros (e.g. cachyos, nobara) fall back to their
# upstream family's package install logic below.
detect_os() {
    OS_ID="unknown"
    OS_ID_LIKE=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_ID_LIKE="${ID_LIKE:-}"
    fi
}

# ── Package installation ─────────────────────────────────────────────────────
install_curl_tool() {
    local name="$1" url="$2"; shift 2
    info "Installing $name via curl..."
    # Pipe to `sh`, not `bash` — starship's installer warns non-POSIX bash may error.
    # Extra args ("$@") are forwarded to the installer (e.g. --yes for starship).
    curl -fsSL "$url" | sh -s -- "$@"
}

# eza: no correctly-named .deb on GitHub releases (old URL 404s).
# Use the official gierens apt repo instead.
install_eza_apt() {
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update -qq
    sudo apt-get install -y eza
}

# gh: not in default Ubuntu repos — add official GitHub CLI apt repo.
install_gh_apt() {
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y gh
}

# Nerd Font — required for starship powerline glyphs () + dev icons to render.
# Without it the prompt looks like broken boxes.
install_nerd_font() {
    if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
        info "JetBrainsMono Nerd Font already installed"
        return
    fi
    local font_dir="$HOME/.local/share/fonts"
    local tmp="/tmp/JetBrainsMono.zip"
    mkdir -p "$font_dir"
    if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$tmp"; then
        unzip -oq "$tmp" -d "$font_dir" && rm -f "$tmp"
        fc-cache -f "$font_dir" > /dev/null 2>&1 || true
        info "JetBrainsMono Nerd Font installed → set it as your terminal font"
    else
        warn "Nerd Font download failed — install a Nerd Font manually for correct prompt glyphs"
    fi
}

install_arch_packages() {
    sudo pacman -S --needed --noconfirm \
        fish starship zoxide fzf fd ripgrep eza bat neovim git openssh github-cli
}

install_fedora_packages() {
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
}

install_rhel_packages() {
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
}

install_debian_packages() {
    sudo apt-get update -qq
    sudo apt-get install -y \
        fish neovim git openssh-client ripgrep fzf \
        fd-find bat curl build-essential \
        unzip fontconfig gpg wget

    # Ensure ~/.local/bin exists AND is on PATH for the rest of this run,
    # so the command -v checks below (and curl-installed tools) resolve.
    mkdir -p "$LOCAL_BIN"
    export PATH="$LOCAL_BIN:$PATH"

    # fd: Debian/Ubuntu name it fd-find
    if ! command -v fd &>/dev/null; then
        ln -sf "$(which fdfind)" "$LOCAL_BIN/fd"
        info "Created fd → fdfind symlink"
    fi

    # bat: Debian/Ubuntu name it batcat
    if ! command -v bat &>/dev/null; then
        ln -sf "$(which batcat)" "$LOCAL_BIN/bat"
        info "Created bat → batcat symlink"
    fi

    # starship (pass --yes so the installer doesn't prompt when piped)
    if ! command -v starship &>/dev/null; then
        install_curl_tool "starship" "https://starship.rs/install.sh" --yes
    fi

    # zoxide
    if ! command -v zoxide &>/dev/null; then
        install_curl_tool "zoxide" "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
    fi

    # eza (official gierens apt repo — the old .deb URL 404s)
    if ! command -v eza &>/dev/null; then
        install_eza_apt || warn "eza install failed — try: cargo install eza"
    fi

    # gh (GitHub CLI — not in default repos)
    if ! command -v gh &>/dev/null; then
        install_gh_apt || warn "gh install failed — see https://github.com/cli/cli#installation"
    fi

    # Nerd Font (fixes broken prompt glyphs)
    install_nerd_font
}

install_packages() {
    local os="$1" os_like="$2"
    step "Installing packages for: $os"

    case "$os" in
        # Arch and its popular derivatives/spins
        arch|manjaro|endeavouros|cachyos|garuda|arcolinux|artix)
            install_arch_packages
            ;;

        # Debian/Ubuntu and its popular derivatives/spins
        ubuntu|debian|linuxmint|pop|elementary|zorin|neon|kali|kubuntu|xubuntu|lubuntu)
            install_debian_packages
            ;;

        # Fedora and its popular derivatives/spins
        fedora|nobara)
            install_fedora_packages
            ;;

        rhel|centos|almalinux|rocky)
            install_rhel_packages
            ;;

        *)
            # Fall back to the upstream family via ID_LIKE (from /etc/os-release)
            # so subdistros we haven't explicitly listed above still work.
            case "$os_like" in
                *arch*)
                    warn "Unrecognized OS '$os' but ID_LIKE='$os_like' looks Arch-based — using Arch packages"
                    install_arch_packages
                    ;;
                *debian*|*ubuntu*)
                    warn "Unrecognized OS '$os' but ID_LIKE='$os_like' looks Debian-based — using Debian/Ubuntu packages"
                    install_debian_packages
                    ;;
                *fedora*)
                    warn "Unrecognized OS '$os' but ID_LIKE='$os_like' looks Fedora-based — using Fedora packages"
                    install_fedora_packages
                    ;;
                *rhel*)
                    warn "Unrecognized OS '$os' but ID_LIKE='$os_like' looks RHEL-based — using RHEL packages"
                    install_rhel_packages
                    ;;
                *)
                    # Last resort: neither ID nor ID_LIKE told us the family —
                    # just check which package manager binary is actually on PATH.
                    if command -v pacman &>/dev/null; then
                        warn "Unrecognized OS '$os' — found pacman, using Arch packages"
                        install_arch_packages
                    elif command -v apt-get &>/dev/null; then
                        warn "Unrecognized OS '$os' — found apt-get, using Debian/Ubuntu packages"
                        install_debian_packages
                    elif command -v dnf &>/dev/null; then
                        warn "Unrecognized OS '$os' — found dnf, using Fedora packages"
                        install_fedora_packages
                    else
                        warn "Unknown OS '$os' — skipping package install. Install manually:"
                        warn "  fish starship zoxide fzf fd ripgrep eza bat neovim git openssh"
                    fi
                    ;;
            esac
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

    detect_os

    install_packages "$OS_ID" "$OS_ID_LIKE"
    install_fish_configs
    install_starship_config
    configure_git
    setup_ssh
    set_default_shell

    echo ""
    info "Done!"
    echo ""
    echo "  Reload now (no need to open a new terminal):"
    echo -e "    ${GREEN}exec fish${NC}      # switch into fish + load starship this session"
    echo ""
    echo "  Next steps:"
    echo "  • Set your terminal font to 'JetBrainsMono Nerd Font' (fixes prompt glyphs)"
    echo "  • Run 'gh auth login' to authenticate GitHub CLI"
    echo "  • Add ~/.ssh/id_ed25519.pub to GitHub if using SSH"
    echo ""
}

main "$@"
