#!/usr/bin/env bash
################################################################################
# Multi-Project tmux Dev Sessions
#
# Creates a tmux session with 1-4 side-by-side project columns. Each column
# has claude on top, nvim in the middle, and a small shell at the bottom.
# Supports hot-swapping any column's project and switching two columns.
#
# USAGE:
#   tmux_multi_dev_session.sh <1|2|3|4> [--force|-f] <path1> [path2] [path3] [path4]
#   tmux_multi_dev_session.sh <1|2|3|4> --swap|-a <slot> <new_path>
#   tmux_multi_dev_session.sh <1|2|3|4> --switch|-i <slot_a> <slot_b>
#
# EXAMPLES:
#   tmux_multi_dev_session.sh 1 ~/proj/a                      # 1-column session
#   tmux_multi_dev_session.sh 3 ~/proj/a ~/proj/b ~/proj/c   # 3-column session
#   tmux_multi_dev_session.sh 2 ~/proj/a ~/proj/b             # 2-column session
#   tmux_multi_dev_session.sh 3 --force ~/proj/a ~/proj/b     # kill & recreate
#   tmux_multi_dev_session.sh 3 --swap 2 ~/proj/new           # replace slot 2
#   tmux_multi_dev_session.sh 3 --switch 1 3                  # swap slots 1 and 3
#
# LAYOUT (3-column):
#   ┌──────────┬──────────┬──────────┐
#   │ claude A │ claude B │ claude C │  ~30%
#   ├──────────┼──────────┼──────────┤
#   │  nvim A  │  nvim B  │  nvim C  │  ~60%
#   ├──────────┼──────────┼──────────┤
#   │ shell A  │ shell B  │ shell C  │  ~10%
#   └──────────┴──────────┴──────────┘
#
# DEPENDENCIES:
#   - tmux
#   - nvim (with LazyVim + Neo-tree)
#   - claude (Claude Code CLI)
#
# NOTES:
#   - Session names are fixed: dev1 / dev2 / dev3 / dev4
#   - Slot metadata stored as tmux session environment variables
#   - --swap uses respawn-pane to preserve layout geometry
#   - --switch uses swap-pane to physically move panes (no process killing)
################################################################################

set -euo pipefail

################################################################################
# Colors and Logging
################################################################################

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info()    { echo -e "${BLUE}[multi-dev]${NC} $*"; }
log_success() { echo -e "${GREEN}[multi-dev]${NC} $*"; }
log_error()   { echo -e "${RED}[multi-dev]${NC} $*" >&2; }
log_warn()    { echo -e "${YELLOW}[multi-dev]${NC} $*"; }

################################################################################
# Helper Functions
################################################################################

_show_usage() {
    cat <<'EOF'
Usage:
  tmux_multi_dev_session.sh <1|2|3|4> [--force|-f] <path1> [path2] [path3] [path4]
  tmux_multi_dev_session.sh <1|2|3|4> --swap|-a [<slot>] <new_path>
  tmux_multi_dev_session.sh <1|2|3|4> --switch|-i <slot_a> <slot_b>
  tmux_multi_dev_session.sh <1|2|3|4> --kill|-k

Aliases:
  dev1, dev2, dev3, dev4  - shorthand for tmux_multi_dev_session.sh <N>
  d1, d2, d3, d4          - shorthand for devN
  devn                    - auto-detects column count from current tmux session

Examples:
  dev1 ~/proj/a                         # 1-column session
  dev3 ~/proj/a ~/proj/b ~/proj/c       # create 3-column session
  dev3 -f ~/proj/a ~/proj/b             # kill & recreate, pad last path
  dev3 -a 2 ~/proj/new                  # replace slot 2's project
  dev3 -i 1 3                           # swap slots 1 and 3
  devn -i 1 3                           # same, auto-detects dev1/dev2/dev3/dev4
  devn -k                               # kill current multi-dev session
  devn                                  # show which devN this resolves to
EOF
}

# Wait for a pane's shell to be ready for input after respawn-pane.
# Uses tmux wait-for: we queue a signal command into the pty buffer
# IMMEDIATELY after respawn. The terminal buffers the keystrokes until
# zsh finishes sourcing config, initializes zle, and reads stdin —
# then it executes the signal command, unblocking us.
_wait_for_shell() {
    local _pane_id="$1"
    local _signal="ready_${_pane_id//\%/}"

    # Queue the signal command into the pty input buffer.
    # Space prefix keeps it out of shell history.
    tmux send-keys -t "$_pane_id" " tmux wait-for -S ${_signal}" Enter

    # Block until the shell processes the queued command.
    # Background a fallback that fires the signal after 10s to prevent hangs.
    ( sleep 10 && tmux wait-for -S "$_signal" 2>/dev/null ) &
    local _timeout_pid=$!
    tmux wait-for "$_signal" 2>/dev/null || true
    kill "$_timeout_pid" 2>/dev/null || true
    wait "$_timeout_pid" 2>/dev/null || true
}

# Detect Python venv and return activation prefix string (empty if none)
_detect_venv() {
    local _project_path="$1"
    if [ -f "${_project_path}/venv/bin/activate" ]; then
        echo "source ${_project_path}/venv/bin/activate && "
    elif [ -f "${_project_path}/.venv/bin/activate" ]; then
        echo "source ${_project_path}/.venv/bin/activate && "
    fi
}

# Resolve and validate a project path
_resolve_project_path() {
    local _path="$1"
    _path="${_path/#\~/$HOME}"
    if [ -d "$_path" ]; then
        (cd "$_path" && pwd -P)
    else
        log_error "Directory does not exist: $_path"
        return 1
    fi
}

# Launch nvim in a pane
_launch_nvim() {
    local _pane_id="$1"
    local _project_path="$2"
    local _venv_prefix
    _venv_prefix=$(_detect_venv "$_project_path")
    tmux send-keys -t "$_pane_id" " cd ${_project_path} && ${_venv_prefix}nvim ." Enter
}

# Send Neo-tree open key to a pane (call after sleep)
_open_neotree() {
    local _pane_id="$1"
    tmux send-keys -t "$_pane_id" " e"  # Space+e opens Neo-tree in LazyVim
}

# Launch claude code in a pane
_launch_claude() {
    local _pane_id="$1"
    local _project_path="$2"
    local _venv_prefix
    _venv_prefix=$(_detect_venv "$_project_path")
    tmux send-keys -t "$_pane_id" " cd ${_project_path} && ${_venv_prefix}claude --continue || claude" Enter
}

# Initialize a shell pane (cd + venv activation)
_launch_shell() {
    local _pane_id="$1"
    local _project_path="$2"
    local _venv_prefix
    _venv_prefix=$(_detect_venv "$_project_path")
    if [ -n "$_venv_prefix" ]; then
        tmux send-keys -t "$_pane_id" " cd ${_project_path} && ${_venv_prefix}clear" Enter
    else
        tmux send-keys -t "$_pane_id" " cd ${_project_path} && clear" Enter
    fi
}

# Store slot metadata in tmux session environment
_store_slot_metadata() {
    local _session="$1"
    local _slot="$2"
    local _top_pane="$3"
    local _mid_pane="$4"
    local _bot_pane="$5"
    local _path="$6"
    tmux set-environment -t "$_session" "SLOT_${_slot}_TOP" "$_top_pane"
    tmux set-environment -t "$_session" "SLOT_${_slot}_MID" "$_mid_pane"
    tmux set-environment -t "$_session" "SLOT_${_slot}_BOT" "$_bot_pane"
    tmux set-environment -t "$_session" "SLOT_${_slot}_PATH" "$_path"
}

# Read a tmux session env var value
_get_env() {
    local _session="$1"
    local _var="$2"
    tmux show-environment -t "$_session" "$_var" 2>/dev/null | cut -d= -f2
}

################################################################################
# Swap Mode — replace a slot's project with a new one
################################################################################

_handle_swap() {
    local _session="$1"
    local _slot="$2"
    local _new_path="$3"
    local _slot_count

    if ! tmux has-session -t "$_session" 2>/dev/null; then
        log_error "Session '$_session' does not exist. Create it first."
        exit 1
    fi

    _slot_count=$(_get_env "$_session" "SLOT_COUNT")
    if [ -z "$_slot_count" ]; then
        log_error "Session '$_session' has no SLOT_COUNT metadata. Was it created by this script?"
        exit 1
    fi

    if [ "$_slot" -lt 1 ] || [ "$_slot" -gt "$_slot_count" ]; then
        log_error "Slot $_slot is out of range (1-${_slot_count})"
        exit 1
    fi

    _new_path=$(_resolve_project_path "$_new_path")

    local _top_pane _mid_pane _bot_pane
    _top_pane=$(_get_env "$_session" "SLOT_${_slot}_TOP")
    _mid_pane=$(_get_env "$_session" "SLOT_${_slot}_MID")
    _bot_pane=$(_get_env "$_session" "SLOT_${_slot}_BOT")

    if [ -z "$_top_pane" ] || [ -z "$_mid_pane" ] || [ -z "$_bot_pane" ]; then
        log_error "Could not find pane IDs for slot $_slot"
        exit 1
    fi

    log_info "Swapping slot $_slot to: $_new_path"

    # Respawn all three panes — kills process, restarts shell, preserves geometry
    tmux respawn-pane -k -t "$_top_pane" -c "$_new_path"
    tmux respawn-pane -k -t "$_mid_pane" -c "$_new_path"
    tmux respawn-pane -k -t "$_bot_pane" -c "$_new_path"

    # Wait for all three shells to finish sourcing zshrc and present a prompt.
    # respawn-pane forks a new shell that must load the full zsh config before
    # it can accept send-keys input — 0.5s is not enough with a heavy config.
    _wait_for_shell "$_top_pane"
    _wait_for_shell "$_mid_pane"
    _wait_for_shell "$_bot_pane"

    _launch_claude "$_top_pane" "$_new_path"
    _launch_nvim "$_mid_pane" "$_new_path"
    _launch_shell "$_bot_pane" "$_new_path"

    sleep 1
    _open_neotree "$_mid_pane"

    tmux set-environment -t "$_session" "SLOT_${_slot}_PATH" "$_new_path"

    log_success "Slot $_slot swapped to $(basename "$_new_path")"
}

################################################################################
# Switch Mode — swap two slots' positions with each other
################################################################################

_handle_switch() {
    local _session="$1"
    local _slot_a="$2"
    local _slot_b="$3"
    local _slot_count

    if ! tmux has-session -t "$_session" 2>/dev/null; then
        log_error "Session '$_session' does not exist. Create it first."
        exit 1
    fi

    _slot_count=$(_get_env "$_session" "SLOT_COUNT")
    if [ -z "$_slot_count" ]; then
        log_error "Session '$_session' has no SLOT_COUNT metadata. Was it created by this script?"
        exit 1
    fi

    for _s in "$_slot_a" "$_slot_b"; do
        if [ "$_s" -lt 1 ] || [ "$_s" -gt "$_slot_count" ]; then
            log_error "Slot $_s is out of range (1-${_slot_count})"
            exit 1
        fi
    done

    if [ "$_slot_a" = "$_slot_b" ]; then
        log_warn "Both slots are the same, nothing to do"
        exit 0
    fi

    local _path_a _path_b
    _path_a=$(_get_env "$_session" "SLOT_${_slot_a}_PATH")
    _path_b=$(_get_env "$_session" "SLOT_${_slot_b}_PATH")

    if [ -z "$_path_a" ] || [ -z "$_path_b" ]; then
        log_error "Could not find paths for slots $_slot_a and $_slot_b"
        exit 1
    fi

    local _top_a _mid_a _bot_a _top_b _mid_b _bot_b
    _top_a=$(_get_env "$_session" "SLOT_${_slot_a}_TOP")
    _mid_a=$(_get_env "$_session" "SLOT_${_slot_a}_MID")
    _bot_a=$(_get_env "$_session" "SLOT_${_slot_a}_BOT")
    _top_b=$(_get_env "$_session" "SLOT_${_slot_b}_TOP")
    _mid_b=$(_get_env "$_session" "SLOT_${_slot_b}_MID")
    _bot_b=$(_get_env "$_session" "SLOT_${_slot_b}_BOT")

    log_info "Switching slot $_slot_a ($(basename "$_path_a")) with slot $_slot_b ($(basename "$_path_b"))"

    # Physically swap all three pane pairs — no process killing, everything keeps running
    tmux swap-pane -s "$_top_a" -t "$_top_b"
    tmux swap-pane -s "$_mid_a" -t "$_mid_b"
    tmux swap-pane -s "$_bot_a" -t "$_bot_b"

    # Update metadata — pane IDs follow the pane, so swap them
    _store_slot_metadata "$_session" "$_slot_a" "$_top_b" "$_mid_b" "$_bot_b" "$_path_b"
    _store_slot_metadata "$_session" "$_slot_b" "$_top_a" "$_mid_a" "$_bot_a" "$_path_a"

    log_success "Switched slot $_slot_a <-> slot $_slot_b"
}

################################################################################
# Main: Create Session
################################################################################

_create_session() {
    local _col_count="$1"
    local _force="$2"
    shift 2
    local _session="dev${_col_count}"
    local _paths=()

    for _p in "$@"; do
        _paths+=("$(_resolve_project_path "$_p")")
    done

    # If session already exists, kill it (--force) or attach to it
    if tmux has-session -t "$_session" 2>/dev/null; then
        if [ "$_force" = "1" ]; then
            log_info "Killing existing session '$_session'..."
            tmux kill-session -t "$_session"
        else
            log_info "Session '$_session' already exists, attaching..."
            if [ -n "${TMUX:-}" ]; then
                tmux switch-client -t "$_session"
            else
                tmux attach-session -t "$_session"
            fi
            exit 0
        fi
    fi

    log_info "Creating ${_col_count}-column dev session..."

    local _top_panes=()
    local _mid_panes=()
    local _bot_panes=()

    # Create session with first project (this is slot 1's top pane)
    local _first_pane
    _first_pane=$(tmux new-session -d -s "$_session" -c "${_paths[0]}" -P -F '#{pane_id}')
    _top_panes+=("$_first_pane")

    # Create additional columns via horizontal splits
    for (( _i=1; _i<_col_count; _i++ )); do
        local _pane_id
        _pane_id=$(tmux split-window -h -t "$_session" -c "${_paths[$_i]}" -P -F '#{pane_id}')
        _top_panes+=("$_pane_id")
    done

    # Equalize column widths
    tmux select-layout -t "$_session" even-horizontal

    # Split each column vertically into 3 rows: claude (~30%), nvim (~60%), shell (~10%)
    for (( _i=0; _i<_col_count; _i++ )); do
        local _mid_pane _bot_pane

        # Split top pane: top keeps 30% (claude), bottom gets 70% (nvim + shell)
        _mid_pane=$(tmux split-window -v -t "${_top_panes[$_i]}" -c "${_paths[$_i]}" -l 70% -P -F '#{pane_id}')
        _mid_panes+=("$_mid_pane")

        # Split mid pane: top keeps 85% (nvim), bottom gets 15% (shell)
        _bot_pane=$(tmux split-window -v -t "$_mid_pane" -c "${_paths[$_i]}" -l 15% -P -F '#{pane_id}')
        _bot_panes+=("$_bot_pane")
    done

    # Store metadata
    tmux set-environment -t "$_session" "SLOT_COUNT" "$_col_count"
    for (( _i=0; _i<_col_count; _i++ )); do
        local _slot=$(( _i + 1 ))
        _store_slot_metadata "$_session" "$_slot" "${_top_panes[$_i]}" "${_mid_panes[$_i]}" "${_bot_panes[$_i]}" "${_paths[$_i]}"
    done

    # Launch claude in all top panes
    for (( _i=0; _i<_col_count; _i++ )); do
        _launch_claude "${_top_panes[$_i]}" "${_paths[$_i]}"
    done

    # Launch nvim in all mid panes (parallel start)
    for (( _i=0; _i<_col_count; _i++ )); do
        _launch_nvim "${_mid_panes[$_i]}" "${_paths[$_i]}"
    done

    # Single sleep for all nvim instances to initialize
    sleep 1

    # Open Neo-tree in all nvim instances
    for (( _i=0; _i<_col_count; _i++ )); do
        _open_neotree "${_mid_panes[$_i]}"
    done

    # Initialize shell in all bottom panes
    for (( _i=0; _i<_col_count; _i++ )); do
        _launch_shell "${_bot_panes[$_i]}" "${_paths[$_i]}"
    done

    # Focus on slot 1's shell pane (bottom-left)
    tmux select-pane -t "${_bot_panes[0]}"

    log_success "Session '$_session' created with ${_col_count} columns"

    # Attach or switch to session
    if [ -n "${TMUX:-}" ]; then
        tmux switch-client -t "$_session"
    else
        tmux attach-session -t "$_session"
    fi
}

################################################################################
# Argument Parsing
################################################################################

if [ $# -lt 1 ]; then
    _show_usage
    exit 2
fi

_COL_COUNT="$1"
shift

# Validate column count
if [ "$_COL_COUNT" != "1" ] && [ "$_COL_COUNT" != "2" ] && [ "$_COL_COUNT" != "3" ] && [ "$_COL_COUNT" != "4" ]; then
    log_error "Column count must be 1, 2, 3, or 4, got: $_COL_COUNT"
    _show_usage
    exit 2
fi

# If no further args, try to attach to existing session
if [ $# -eq 0 ]; then
    _SESSION="dev${_COL_COUNT}"
    if tmux has-session -t "$_SESSION" 2>/dev/null; then
        if [ -n "${TMUX:-}" ]; then
            tmux switch-client -t "$_SESSION"
        else
            tmux attach-session -t "$_SESSION"
        fi
        exit 0
    else
        log_error "Session '$_SESSION' does not exist. Provide project paths to create it."
        _show_usage
        exit 2
    fi
fi

# Check for help
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    _show_usage
    exit 0
fi

# Check for kill mode
if [ "${1:-}" = "--kill" ] || [ "${1:-}" = "-k" ]; then
    _SESSION="dev${_COL_COUNT}"
    if tmux has-session -t "$_SESSION" 2>/dev/null; then
        log_info "Killing session '$_SESSION'..."
        tmux kill-session -t "$_SESSION"
        log_success "Session '$_SESSION' killed"
    else
        log_warn "Session '$_SESSION' does not exist"
    fi
    exit 0
fi

# Check for swap mode (replace a slot with a new project)
if [ "${1:-}" = "--swap" ] || [ "${1:-}" = "-a" ]; then
    shift
    if [ $# -lt 1 ]; then
        log_error "--swap requires at least <new_path>"
        _show_usage
        exit 2
    fi

    # If first arg is a number, it's the slot; otherwise default to last column
    if [[ "$1" =~ ^[0-9]+$ ]] && [ $# -ge 2 ]; then
        _SWAP_SLOT="$1"
        _SWAP_PATH="$2"
    else
        _SWAP_SLOT="$_COL_COUNT"
        _SWAP_PATH="$1"
    fi

    _handle_swap "dev${_COL_COUNT}" "$_SWAP_SLOT" "$_SWAP_PATH"
    exit 0
fi

# Check for switch mode (swap two slots with each other)
if [ "${1:-}" = "--switch" ] || [ "${1:-}" = "-i" ]; then
    shift
    if [ $# -lt 2 ]; then
        log_error "--switch requires <slot_a> <slot_b>"
        _show_usage
        exit 2
    fi
    _SLOT_A="$1"
    _SLOT_B="$2"

    for _s in "$_SLOT_A" "$_SLOT_B"; do
        if ! [[ "$_s" =~ ^[0-9]+$ ]]; then
            log_error "Slot must be a number, got: $_s"
            exit 2
        fi
    done

    _handle_switch "dev${_COL_COUNT}" "$_SLOT_A" "$_SLOT_B"
    exit 0
fi

# Check for --force flag
_FORCE="0"
if [ "${1:-}" = "--force" ] || [ "${1:-}" = "-f" ]; then
    _FORCE="1"
    shift
fi

# Create mode: validate path count (too many = error, too few = pad with last path)
if [ $# -gt "$_COL_COUNT" ]; then
    log_error "Expected at most $_COL_COUNT project paths, got $#"
    _show_usage
    exit 2
fi

# Pad missing paths: repeat last arg, but use snippets repo for the final spare column
readonly _SNIPPETS_PATH="${HOME}/projects/snippets"
_ARGS=("$@")
_LAST_ARG="${_ARGS[$(( ${#_ARGS[@]} - 1 ))]}"
while [ ${#_ARGS[@]} -lt "$_COL_COUNT" ]; do
    if [ ${#_ARGS[@]} -eq $(( _COL_COUNT - 1 )) ] && [ -d "$_SNIPPETS_PATH" ]; then
        _ARGS+=("$_SNIPPETS_PATH")
    else
        _ARGS+=("$_LAST_ARG")
    fi
done

_create_session "$_COL_COUNT" "$_FORCE" "${_ARGS[@]}"
