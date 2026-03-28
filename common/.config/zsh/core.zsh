# core.zsh - Shared configuration for all platforms
# This file is sourced by ~/.zshrc after OS detection

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,z
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"
ZSH_THEME="xiong-chiamiov-plus"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Commands prefixed with a space won't be saved to history.
# Used by dev/devn scripts to keep send-keys commands out of shell history.
setopt HIST_IGNORE_SPACE

# User configuration

# CREDENTIALS_DIR — set in private.zsh

# Add ~/scripts to PATH for custom scripts
PATH="$HOME/scripts:$PATH"

# Add snippets repo to PATH (browse, get, search, notes, snippets)
PATH="$HOME/projects/snippets:$PATH"

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi
export EDITOR='vim'

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Source mise/rtx environment if it exists
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

###
## FZF Configuration
###

# Source fzf shell integration (key bindings + completion)
# Provides: Ctrl+T (file search), Ctrl+R (history), Alt+C (cd to directory)
if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
elif [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
  # Intel Mac fallback
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  # Linux (Arch/Fedora)
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# Use fd for faster file finding (respects .gitignore)
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# Default options with live preview
export FZF_DEFAULT_OPTS="
  --height 60%
  --layout=reverse
  --border
  --info=inline
  --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} 2>/dev/null || cat {})) || ([[ -d {} ]] && tree -C {} | head -100) || echo {}'
  --preview-window=right:50%:wrap
  --bind 'ctrl-/:toggle-preview'
"

# Ctrl+T options (file search with preview)
export FZF_CTRL_T_OPTS="
  --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} 2>/dev/null || cat {})) || ([[ -d {} ]] && tree -C {} | head -50) || echo {}'
  --bind 'ctrl-y:execute-silent(echo -n {} | pbcopy)+abort'
"

# Ctrl+R options (history search)
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window=down:3:wrap
"

# Alt+C options (cd to directory with tree preview)
export FZF_ALT_C_OPTS="
  --preview 'tree -C {} | head -100'
"

###
## Custom Functions
###

# takes alist of (fieldnames) in camelCase and converts those to lower_snke_case
snake() {
  # Check if there's input from pipe
  if [ -p /dev/stdin ]; then
    # Read from stdin (pipe)
    input=$(cat)
  else
    # Try to read from clipboard if no pipe input
    input=$(paste)
  fi

  # Process each line and store result
  result=$(echo "$input" | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]')

  # Print result to stdout
  echo "$result"

  # Copy result to clipboard
  echo "$result" | clip

  # Optional message indicating clipboard was updated
  echo "✓ Result copied to clipboard" >&2
}

# takes a list of field names and wraps them in a json stub like this: ', "entity_data.valueInCamelCase" : {"key": "value_in_lower_snake_case", "type": "record"}'
entity_data() {
  # Check if there's input from pipe
  if [ -p /dev/stdin ]; then
    # Read from stdin (pipe)
    input=$(cat)
  else
    # Try to read from clipboard if no pipe input
    input=$(paste)
  fi

  # Process each line
  result=$(echo "$input" | while read line; do
    # Skip empty lines
    if [ -z "$line" ]; then
      continue
    fi

    # Convert to snake_case for entity_data part
    snake_case=$(echo "$line" | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]')

    # Format as JSON stub (snake_case in path, original camelCase in key)
    echo ", \"entity_data.${snake_case}\" : {\"key\": \"${line}\", \"type\": \"record\"}"
  done)

  # Print result to stdout
  echo "$result"

  # Copy result to clipboard
  echo "$result" | clip

  # Optional message indicating clipboard was updated
  echo "✓ Result copied to clipboard" >&2
}

# Singer ETL functions (link_tap, tap_out, tap_transform, tap_target, tap_etl)
# live in ~/.config/zsh/private.zsh


###
## Aliases
###

alias ff='fzf'
# alias penv='bash ~/scripts/make_python_env_fast.sh'
alias a='deactivate 2>/dev/null; . $(find . -type f -name "activate" -exec realpath {} + | awk -v pwd="$(realpath .)" '\''{print length($0), $0}'\'' | sort -n | cut -d " " -f 2- | head -n 1) && which python'
# alias about='bash ~/scripts/dbt_about.sh'
# alias c='bash ~/scripts/dbt_compile_and_link.sh'
# Snippets TUI - launches dev session with TUI in bottom-right pane
alias c='cd ~/projects/snippets && tmux_dev_session.sh snippets "$(pwd -P)" "./snippets"'
# Snippets search - multi-term AND search (e.g., `search select transaction`)
alias search='~/projects/snippets/search'
# Claude Code - try to continue previous session, fall back to fresh
alias cc='claude --continue || claude'
alias ccd='claude --continue --enable-auto-mode || claude --enable-auto-mode'
alias ccvd='claude --continue --dangerously-skip-permissions || claude --enable-auto-mode --dangerously-skip-permissions'
alias cl='claude login'
alias cloc='cloc --exclude-dir=venv,.venv,virtualenv,node_modules,vendor,bower_components,.bundle,Pods,target,build,dist,__pycache__,.egg-info'
clean() {
    local _remote=false
    local _dry_run=false

    while [ $# -gt 0 ]; do
        case "$1" in
            -r|--remote)
                _remote=true
                shift
                ;;
            -n|--dry-run)
                _dry_run=true
                shift
                ;;
            -h|--help)
                echo "Usage: clean [-r|--remote] [-n|--dry-run] [-h|--help]"
                echo ""
                echo "Delete local branches that have been merged into main."
                echo ""
                echo "Options:"
                echo "  -r, --remote   Also delete merged remote branches (GitHub only)"
                echo "  -n, --dry-run  Show what would be deleted without deleting"
                echo "  -h, --help     Show this help message"
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Usage: clean [-r|--remote] [-n|--dry-run] [-h|--help]" >&2
                return 1
                ;;
        esac
    done

    # Ensure we're in a git repo
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Error: not in a git repository" >&2
        return 1
    fi

    # Determine default branch (main or master)
    local _default_branch
    if git show-ref --verify --quiet refs/heads/main; then
        _default_branch="main"
    elif git show-ref --verify --quiet refs/heads/master; then
        _default_branch="master"
    else
        echo "Error: could not find main or master branch" >&2
        return 1
    fi

    git checkout "$_default_branch"
    git pull

    # Delete local merged branches
    local _local_branches
    _local_branches=$(git branch --merged "$_default_branch" | grep -Ev "(^\*|master|main)")

    if [ -n "$_local_branches" ]; then
        if $_dry_run; then
            echo "Would delete local branches:"
            echo "$_local_branches" | sed 's/^/  /'
        else
            echo "$_local_branches" | xargs git branch -d
        fi
    else
        echo "No local merged branches to clean up."
    fi

    # Remote cleanup
    if $_remote; then
        local _remote_url
        _remote_url=$(git remote get-url origin 2>/dev/null)

        if [ -z "$_remote_url" ]; then
            echo "Error: no 'origin' remote found" >&2
            return 1
        fi

        if [[ "$_remote_url" != *github.com* ]]; then
            echo "Skipping remote cleanup: remote is not GitHub" >&2
            echo "  origin: $_remote_url" >&2
            return 1
        fi

        # Fetch and prune stale remote tracking refs first
        git fetch --prune

        local _remote_branches
        _remote_branches=$(git branch -r --merged "$_default_branch" \
            | grep -Ev "(origin/${_default_branch}|origin/HEAD)" \
            | sed 's|origin/||' \
            | xargs)

        if [ -z "$_remote_branches" ]; then
            echo "No remote merged branches to clean up."
            return 0
        fi

        if $_dry_run; then
            echo "Would delete remote branches:"
            for _b in ${(z)_remote_branches}; do
                echo "  origin/$_b"
            done
        else
            echo "Deleting remote merged branches..."
            for _b in ${(z)_remote_branches}; do
                echo "  Deleting origin/$_b"
                git push origin --delete "$_b"
            done
        fi
    fi
}
# Work-specific aliases, database connections, and SSH shortcuts live in
# ~/.config/zsh/private.zsh (not tracked in git)
alias d='deactivate'
alias dotfiles='cd ~/.dotfiles && ls -lahG && git status'
alias DL='cd ~/Downloads && ls -lahG'
alias DT='cd ~/Desktop && ls -lahG'
alias duck='cd ~/projects/duck-data/ && ls -lahG'
alias f='yazi'
# alias g='bash cbgraph.sh'  # Commented out to use snippets get
alias g='~/projects/snippets/get'
alias gb=' git --no-pager branch'
alias gcm='git checkout main'
alias gd='git diff --cached' # --cached arg shows diffs for files that are staged for commit as well as those that aren't
alias gg='lazygit'
alias go='. ./go.sh || echo "There is no go.sh in the pwd: $(pwd)"'
alias gs='git status'
# alias gstreams='cat tap_out.txt | grep -i -E '^\{' | cut -d"{" -f 1-2 | cut -d"," -f 1-2 | sort -u'
# alias gstreams='cat tap_out.txt | grep -i -E "^{" | cut -d"{" -f 1-2 | cut -d"," -f 1-2 | nl | sort -k2 -u | sort -n | cut -f2- | grep "RECORD"'
alias h='harlequin'
alias jp='python3 ~/scripts/get_json_paths.py'
alias jd='bash ~/scripts/json_diff.sh'
alias jt='cd ~/projects/personal/jtool && ls -lahG && git status'
alias resume='cd ~/projects/personal/interactive-resume && ls -lahG && git status'
alias kt='for p in $(ps aux | grep ssh | grep "\-L" | tr -s " " | cut -d " " -f 2); do echo "kill $p" && kill $p; done'
alias lg='lazygit'
alias ll='ls -lahG'
alias m='smerge .'
# alias mbl='cd ~/scripts && bash microbatching_log_check.sh'  # Removed - script deleted
alias myip='ifconfig | grep -o  -E \\d\{1,3\}\\.\\d\{1,3\}\\.\\d\{1,3\}\\.\\d\{1,3\} | sort | uniq'
alias nd='nvim -d'
alias o='cd ~/Obsidian/ && ls -lahG && git status'
alias p='cd ~/projects && ls -lahG'
alias pp='cd ~/projects/personal && ls -lahG'
alias pbj='paste | jq | clip'
alias public-ip='curl https://ipinfo.io/ip'
alias rc='sublime ~/.zshrc'
# alias s='sublime .'  # Commented out to use snippets search
alias s='~/projects/snippets/search'
alias get='~/projects/snippets/get'
alias b='~/projects/snippets/browse'
alias browse='~/projects/snippets/browse'
alias notes='~/projects/snippets/notes'
alias snippets='cd ~/projects/snippets && ./snippets'
alias snip='cd ~/projects/snippets && ./snippets'
alias scripts='cd ~/scripts && ls -lahG'
alias src='source ~/.zprofile && source ~/.zshrc'
alias tcomp='bcomp -fv="Table Compare"'
alias tm='tmux'
alias tml='tmux ls'
alias tmls='tmux ls'
alias tma='tmux attach -t '
alias tmd='tmux kill-session -t '
alias tmk='tmux kill-session -t '
alias tmn='tmux new -s '
# dev - launches tmux dev session with nvim + claude code, session named after current directory
# After detaching (Ctrl-b d), terminal auto-closes due to trailing 'exit'
# alias dev='tmux_dev_session.sh "$(basename $(pwd -P))"; exit'
alias dev='tmux_dev_session.sh "$(basename $(pwd -P))"'
alias dev1='tmux_multi_dev_session.sh 1'
alias dev2='tmux_multi_dev_session.sh 2'
alias dev3='tmux_multi_dev_session.sh 3'
alias dev4='tmux_multi_dev_session.sh 4'
alias d1='dev1'
alias d2='dev2'
alias d3='dev3'
alias d4='dev4'
devn() {
    # -h/--help works from anywhere
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        tmux_multi_dev_session.sh 3 -h
        return 0
    fi
    if [ -z "${TMUX:-}" ]; then
        echo "Not in a tmux session. Use dev1, dev2, dev3, or dev4 instead." >&2
        return 1
    fi
    local _cols
    _cols=$(tmux show-environment SLOT_COUNT 2>/dev/null | cut -d= -f2)
    if [ -z "$_cols" ]; then
        echo "Not in a multi-dev session" >&2
        return 1
    fi
    if [ $# -eq 0 ]; then
        tmux_multi_dev_session.sh "$_cols" -h
        echo ""
        echo "devn resolves to: dev${_cols} (tmux_multi_dev_session.sh ${_cols})"
        return 0
    fi
    tmux_multi_dev_session.sh "$_cols" "$@"
}
devkill() {
    local _current=""
    if [ -n "${TMUX:-}" ]; then
        _current=$(tmux display-message -p '#{session_name}')
    fi

    # If a number is given, kill only that session
    if [ -n "${1:-}" ]; then
        local _target="dev${1}"
        if tmux has-session -t "$_target" 2>/dev/null; then
            tmux kill-session -t "$_target" 2>/dev/null && echo "Killed $_target"
        else
            echo "Session '$_target' does not exist" >&2
        fi
        return
    fi

    # No args: kill all multi-dev sessions
    for _s in dev1 dev2 dev3 dev4; do
        [ "$_s" = "$_current" ] && continue
        tmux kill-session -t "$_s" 2>/dev/null && echo "Killed $_s"
    done
    # Kill current session last (if it's a multi-dev session)
    if [ -n "$_current" ] && [[ "$_current" =~ ^dev[1234]$ ]]; then
        tmux kill-session -t "$_current" 2>/dev/null && echo "Killed $_current"
    fi
}

alias tt='tmux ls'
alias todo="rg -i \"(#|--)\s*todo\" --type py --type sql --type md --glob '!venv/**' -n --no-heading \"\$(pwd)\""
alias tree='tree -I "venv|.env|virtualenv" --matchdirs'
alias uuid='uuidgen | tr "[:upper:]" "[:lower:]"'
alias guid='uuid'
alias randompw='_uuid=$(uuidgen) && _hash=$(echo -n "$_uuid" | shasum -a 256 | cut -d" " -f1) && _chars="!@#$%^&*" && _suffix="" && for i in 1 2 3; do _suffix="${_suffix}${_chars:$((RANDOM % ${#_chars})):1}"; done && echo "${_hash}${_suffix}"'
alias utc='date -u && date -u +%s'
alias v='cd $(pwd -P) && nvim .'
alias va='vi ~/.config/zsh/core.zsh'
alias vc="nvim --cmd 'let g:auto_session_enabled = 0' ."
alias vp="cd ~/projects && nvim ."
alias vi='nvim'
alias vim='nvim'
alias virc='nvim ~/.zshrc'
alias vz='vi ~/.zshrc'
# alias word_crawl='~/projects/personal/word_crawl/venv/bin/python3 ~/projects/personal/word_crawl/word_crawl.py'
alias word_crawl='~/projects/personal/word_crawl/venv/bin/python3 ~/projects/personal/word_crawl/word_crawl.py -c ~/projects/personal/word_crawl/word_crawl.conf -s $(pwd -P)'
alias web='cd ~/projects/duck-data/website/ && ls -lahG'
alias x='cd ~/projects/onXmaps/ && ls -lahG'
alias y='yazi'
alias ya='cd ~/projects/yggdrasil-analytics/template_dagster/ && ls -lahG && git status'
# alias z='zed .'
alias zz='zed ~/.zshrc'
# Helper function for jump.  Allows us to type `j`
# See:  https://github.com/gsamokovarov/jump
if command -v jump &>/dev/null; then
  eval "$(jump shell)"

  # The following lines are autogenerated:
  __jump_chpwd() {
    jump chdir
  }

  jump_completion() {
    reply="'$(jump hint "$@")'"
  }

  j() {
    local dir="$(jump cd $@)"
    test -d "$dir" && cd "$dir"
  }

  typeset -gaU chpwd_functions
  chpwd_functions+=__jump_chpwd

  compctl -U -K jump_completion j
fi

# AWS_PROFILE — set in private.zsh
