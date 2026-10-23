typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

pokemon-colorscripts --no-title -s -r | fastfetch -c pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

source "$ZSH_CONFIG_DIR/exports.zsh"
source "$ZSH_CONFIG_DIR/plugins.zsh"
source "$ZSH_CONFIG_DIR/history.zsh"

source "$ZSH/oh-my-zsh.sh"

source "$ZSH_CONFIG_DIR/aliases.zsh"
source "$ZSH_CONFIG_DIR/completion.zsh"
source "$ZSH_CONFIG_DIR/keybinds.zsh"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ ! -f "$ZSH_CONFIG_DIR/local.zsh" ]] || source "$ZSH_CONFIG_DIR/local.zsh"

# Multigravity CLI launcher
alias mgy="/home/kubik/scr/python/miltigravity/scripts/mgy"
