export EDITOR="nvim"
export WORKSHOP="$HOME/workshop"
source $HOME/.config/zsh/config.zsh
export TERMINAL="ghostty"
export PATH=$PATH:"$HOME/.local/bin/:$HOME/.zvm/bin"

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=niri
    exec dbus-run-session niri --session
fi
