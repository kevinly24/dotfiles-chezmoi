# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Print tree structure in the preview window
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'eza {} -T -L 4 --color=always --icons=always --hyperlink'"

export FZF_CTRL_T_OPTS="
  --walker file,follow,hidden
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
