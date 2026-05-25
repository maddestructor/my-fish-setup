# my-fish-setup

Fish shell dotfiles for a modern terminal stack. One-command install on Linux and macOS.

---

## Install

**Linux (Arch / Debian / Ubuntu / Fedora / RHEL):**
```bash
git clone git@github.com:maddestructor/my-fish-setup.git ~/.my-fish-setup
bash ~/.my-fish-setup/install.sh
```

**macOS:**
```bash
git clone git@github.com:maddestructor/my-fish-setup.git ~/.my-fish-setup
bash ~/.my-fish-setup/install-macos.sh
```

---

## What's included

| Tool | Purpose |
|------|---------|
| [fish](https://fishshell.com) | Shell |
| [starship](https://starship.rs) | Prompt |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder |
| [fd](https://github.com/sharkdp/fd) | Fast `find` replacement |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast `grep` replacement |
| [eza](https://github.com/eza-community/eza) | Modern `ls` |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting |
| [neovim](https://neovim.io) | Editor |

---

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Fuzzy command history search |
| `Ctrl+T` | Fuzzy file picker (inserts path) |
| `Alt+C` | Fuzzy `cd` picker |
| `Tab` | fzf completion on any command |

### Zoxide

```
z <dir>       # Jump to frecent directory matching <dir>
zi            # Interactive directory picker (fzf)
z -           # Jump to previous directory
```

### ripgrep

```
rg <pattern>              # Search current directory recursively
rg <pattern> <path>       # Search in specific path
rg -t py <pattern>        # Search only Python files
rg -l <pattern>           # List matching files only
search <pattern>          # Alias for rg
```

### fd

```
fd <pattern>              # Find files by name pattern
ff <pattern>              # Alias: fd --type f <pattern>
fd -e py                  # Find by extension
fd -H <pattern>           # Include hidden files
```

---

## Aliases

### Navigation
| Alias | Command |
|-------|---------|
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `reload` | `exec fish` |
| `mkdir` | `mkdir -p` |

### Listing (eza)
| Alias | Command |
|-------|---------|
| `ls` | `eza --icons=always` |
| `l` | `eza -l --icons=always` |
| `ll` | `eza -la --icons=always --git` |
| `la` | `eza -a --icons=always` |
| `lt` | `eza --tree --icons=always` |

### Editors
| Alias | Command |
|-------|---------|
| `v` | `nvim` |
| `vi` | `nvim` |
| `cat` | `bat` |

### Git
| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `glog` | `git log --oneline --graph --decorate` |
| `gd` | `git diff` |

### Search
| Alias | Command |
|-------|---------|
| `search` | `rg` |
| `ff` | `fd --type f` |

---

## Manual steps after install

1. **GitHub SSH key** — copy your public key and add it at https://github.com/settings/keys:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. **GitHub CLI auth:**
   ```bash
   gh auth login
   ```

3. **Restart your terminal** to load fish as default shell.
