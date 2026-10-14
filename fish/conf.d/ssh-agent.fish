# Keys stored in 1Password are only served by its own agent, so a plain ssh-agent would hide them.
set -l onepassword_sock "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

if test -S "$onepassword_sock"
    set -gx SSH_AUTH_SOCK $onepassword_sock
else if status is-interactive
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
