typeset -U path
path+=("$HOME/.cargo/bin")

export EDITOR="nvim"
export VISUAL="nvim"

export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window up:3:hidden:wrap --bind 'ctrl-/:toggle-preview'"
export FZF_CTRL_T_COMMAND="fd --type f --hidden --exclude .git"
export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --icons --color=always --level=2 {}'"

export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

export RUSTFMT=yew-fmt
