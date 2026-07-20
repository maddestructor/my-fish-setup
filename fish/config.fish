if status is-interactive
    fish_add_path "$HOME/.local/bin"

    # Prompt
    starship init fish | source

    # Smarter cd (use: z <dir>, zi for interactive)
    zoxide init fish | source

    # fzf key bindings + completions (Ctrl+R, Ctrl+T, Alt+C)
    fzf --fish | source

    # --- eza (modern ls) ---
    alias ls='eza --icons=always'
    alias ll='eza -la --icons=always --git'
    alias la='eza -a --icons=always'
    alias lt='eza --tree --icons=always'
    alias l='eza -l --icons=always'

    # --- bat (better cat) ---
    # `cat` = pretty view (line numbers + grid).
    # `catp` = plain (no numbers/grid/paging) so copy-pasted output stays clean.
    alias cat='bat --paging=never'
    alias catp='bat --style=plain --paging=never'

    # --- editors ---
    alias v='nvim'
    alias vi='nvim'

    # --- git ---
    alias g='git'
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gpl='git pull'
    alias gco='git checkout'
    alias gb='git branch'
    alias glog='git log --oneline --graph --decorate'
    alias gd='git diff'

    # --- ripgrep / fd ---
    alias ff='fd --type f'
    alias search='rg'

    # --- navigation ---
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'

    # --- misc ---
    alias reload='exec fish'
    alias mkdir='mkdir -p'
end
