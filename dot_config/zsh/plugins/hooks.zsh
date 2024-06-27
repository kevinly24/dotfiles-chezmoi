# zellij_tab_name_update
chpwd_functions=(zellij_set_pane_name_chpwd)
preexec_functions=(zellij_set_pane_name_preexec)

zellij_set_pane_name_preexec() {
    if [[ -z $ZELLIJ ]]; then
	return
    fi
    IGNORED_CMDS=(ls eza cd)
    emulate -L zsh
    local -a WORDS
    WORDS=(${(z)1})
    local FIRSTWORD=${WORDS[1]}
    local ARGUMENTS=${WORDS:1}
    local -r GREEN=$'\e[32m' RESET_COLORS=$'\e[0m'
    [[ "$(whence -w $FIRSTWORD 2>/dev/null)" == "${FIRSTWORD}: alias" ]] &&
	FIRSTWORD=$(whence $FIRSTWORD)
    [[ "$(whence -w $FIRSTWORD 2>/dev/null)" == "${FIRSTWORD}: function" ]] &&
        FIRSTWORD=""    
    if [[ -z $FIRSTWORD ]]; then
    	return
    fi

    if (( $IGNORED_CMDS[(I)$FIRSTWORD] )); then
    	return
    fi

    # get cwd
    local CWD="$(basename $(dirname "$PWD"))/$(basename "$PWD")"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	CWD="git:"
        CWD+=$(basename "$(git rev-parse --show-toplevel)")/
        CWD+=$(git rev-parse --show-prefix)
        CWD=${CWD%/}
    fi
    if [[ -n $ARGUMENTS ]]; then
    	ARGUMENTS="<${ARGUMENTS}>"
    fi

    local name="(${FIRSTWORD})${ARGUMENTS}::${CWD}"
    command nohup zellij action rename-pane $name >/dev/null 2>&1
}

zellij_set_pane_name_chpwd() {
    if [[ -z $ZELLIJ ]]; then
	return
    fi
    # get cwd
    local CWD="$(basename $(dirname "$PWD"))/$(basename "$PWD")"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	CWD="git:"
        CWD+=$(basename "$(git rev-parse --show-toplevel)")/
        CWD+=$(git rev-parse --show-prefix)
        CWD=${CWD%/}
    fi
    if [[ -n $ARGUMENTS ]]; then
    	ARGUMENTS="<${ARGUMENTS}>"
    fi

    local name="${CWD}"
    command nohup zellij action rename-pane $name >/dev/null 2>&1
}

