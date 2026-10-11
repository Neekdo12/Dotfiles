zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[ %d ]'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':completion:*' show-ambiguity 1
zstyle ':completion:*' dotglob 1
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

zstyle ':fzf-tab:*' fzf-flags \
  --color="hl:yellow,hl+:yellow,pointer:cyan,marker:green" \
  --pointer='>' \
  --marker='o' \
  --reverse \
  --preview-window="right:60%,border-left"

zstyle ':fzf-tab:complete:*:*' fzf-preview '
  if [[ -d $realpath ]]; then
    eza -1a --icons --color=always $realpath
  else
    bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null
  fi'

zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-):*' fzf-preview 'echo ${(P)word}'

zstyle ':fzf-tab:complete:man:*' fzf-preview 'man $word'

zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags \
  --color="hl:yellow,hl+:yellow,pointer:cyan,marker:green" \
  --pointer='>' \
  --marker='o' \
  --reverse \
  --preview-window='down:3:wrap'

zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff --color=always $word'

zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
