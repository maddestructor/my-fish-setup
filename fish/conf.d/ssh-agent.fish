if status is-interactive
    if not pgrep -u $USER ssh-agent > /dev/null
        eval (ssh-agent -c) > /dev/null
        set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
        set -Ux SSH_AGENT_PID $SSH_AGENT_PID
    end

    # Auto-add default key if it exists
    if test -f ~/.ssh/id_ed25519
        ssh-add -q ~/.ssh/id_ed25519 2>/dev/null
    else if test -f ~/.ssh/id_rsa
        ssh-add -q ~/.ssh/id_rsa 2>/dev/null
    end
end
