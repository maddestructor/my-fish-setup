# A fish login shell does not read ~/.zprofile, so put Homebrew on PATH before config.fish needs it.
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end
