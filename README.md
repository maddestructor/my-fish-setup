# my-fish-setup

A modern terminal stack for people who've had enough of slow prompts, unintuitive navigation, and tools that print walls of text. One command to rule them all.

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

The script will:
- Install all tools
- Copy fish configs and aliases
- Set fish as your default shell
- Configure git (name, email, editor, default branch)
- Set up SSH — generates a new `ed25519` key if none exists
- Back up any existing fish config before overwriting

---

## What's included

| Tool | Purpose |
|------|---------|
| [fish](https://fishshell.com) | Your new shell. Autocomplete that actually works out of the box |
| [starship](https://starship.rs) | Fast, minimal prompt with git status and language info |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` — learns where you go and jumps there instantly |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder wired into history, file search, and directory jumping |
| [fd](https://github.com/sharkdp/fd) | `find` but fast, sane, and respects `.gitignore` |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` on steroids — searches your whole codebase in milliseconds |
| [eza](https://github.com/eza-community/eza) | `ls` with icons, colors, git status, and a tree view |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting and line numbers |
| [neovim](https://neovim.io) | The editor. Aliased to `v` and `vi` |
| [git](https://git-scm.com) | Pre-configured with sane defaults (main branch, nvim editor) |
| [openssh](https://www.openssh.com) | SSH client — key generated on install if you don't have one |

---

## Keyboard shortcuts

These work anywhere in fish, powered by fzf:

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Fuzzy search through command history |
| `Ctrl+T` | Fuzzy file picker — inserts selected path into the current command |
| `Alt+C` | Fuzzy directory picker — `cd`s into the selected directory |
| `Tab` | fzf-powered tab completion on any command |

---

## Tools

### zoxide — frecent directory jumping

zoxide tracks which directories you visit and lets you jump to them by name, no matter where you are.

```bash
z projects          # jump to ~/dev/projects (or wherever "projects" matches)
z fish              # jump to ~/.config/fish
z doc               # jump to ~/Documents — zoxide picks the most visited match
zi                  # open interactive picker with fzf — browse all known dirs
z -                 # jump back to the previous directory
```

The more you use it, the smarter it gets. After a week, you'll never type a full path again.

### ripgrep — blazing fast search

```bash
rg "TODO"                    # search for TODO in every file, recursively
rg "useState" src/           # search only in src/
rg -t ts "interface User"    # search only TypeScript files
rg -l "console.log"          # list files containing the pattern (no line output)
rg -i "error"                # case-insensitive search
search "myFunction"          # alias for rg
```

### fd — fast, friendly find

```bash
fd config                    # find all files/dirs named "config"
ff config                    # alias: find only files named "config"
fd -e toml                   # find all .toml files
fd -H .env                   # include hidden files in search
fd -E node_modules "*.ts"    # exclude node_modules
```

---

## Aliases

### Navigation

| Alias | Does what |
|-------|-----------|
| `..` | Go up one directory |
| `...` | Go up two directories |
| `....` | Go up three directories |
| `mkdir` | Always creates parent dirs (`mkdir -p`) — no more "cannot create directory" errors |
| `reload` | Restart fish shell cleanly (`exec fish`) |

### Listing (eza)

| Alias | Does what |
|-------|-----------|
| `ls` | List with icons |
| `l` | Long format with icons |
| `ll` | Long format, hidden files, git status column |
| `la` | Show hidden files |
| `lt` | Tree view of current directory |

```bash
ll          # see permissions, sizes, git status, and modification dates at a glance
lt          # see folder structure without opening every directory
```

### Editors

| Alias | Does what |
|-------|-----------|
| `v` | Open neovim |
| `vi` | Open neovim |
| `cat` | bat — syntax highlighted file viewer with line numbers |

```bash
cat config.fish      # syntax highlighted, paged, line numbers
v .                  # open current directory in neovim
```

### Git

| Alias | Does what |
|-------|-----------|
| `g` | `git` |
| `gs` | `git status` — see what changed |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gco` | `git checkout` |
| `gb` | `git branch` — list branches |
| `glog` | Pretty graph log — one line per commit with branch visualization |
| `gd` | `git diff` — see unstaged changes |

```bash
gs && ga . && gc -m "fix: typo"    # the usual flow
glog                               # see a visual history of your branches
gd HEAD~1                          # diff against the previous commit
```

### Search

| Alias | Does what |
|-------|-----------|
| `search` | `rg` — ripgrep |
| `ff` | `fd --type f` — find files only (no directories) |

---

## After install

### SSH key → GitHub

The installer generates `~/.ssh/id_ed25519` if no key exists. Copy your public key and add it at **https://github.com/settings/keys**:

```bash
cat ~/.ssh/id_ed25519.pub
```

### GitHub CLI auth

```bash
gh auth login
```

### Restart your terminal

Your default shell is now fish. Open a new terminal window to get the full experience.

---

## Git config

The installer prompts for your name and email. Everything else is set automatically:

```
default branch: main
editor:         nvim
pull strategy:  merge (not rebase)
```
