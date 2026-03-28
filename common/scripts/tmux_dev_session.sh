#!/bin/bash
# ~/scripts/tmux_dev_session.sh
# Creates a dev session with nvim on left, claude + shell on right
# Usage: tmux_dev_session.sh [session-name] [project-path] [bottom-cmd]

SESSION=${1:-dev}
PROJECT=${2:-$(pwd -P)}  # -P resolves symlinks to actual path
BOTTOM_CMD=${3:-}  # Optional command for bottom-right pane

# Detect Python virtual environment for activation
# Checks venv/ first (per conventions), then .venv/ as fallback
_VENV_ACTIVATE=""
if [ -f "${PROJECT}/venv/bin/activate" ]; then
  _VENV_ACTIVATE="source ${PROJECT}/venv/bin/activate && "
elif [ -f "${PROJECT}/.venv/bin/activate" ]; then
  _VENV_ACTIVATE="source ${PROJECT}/.venv/bin/activate && "
fi

# Sanitize session name: remove leading dots (bash, no newline issues)
while [[ "$SESSION" == .* ]]; do
    SESSION="${SESSION#.}"
done

# Replace problematic chars with underscores
SESSION=$(printf '%s' "$SESSION" | tr -c 'a-zA-Z0-9_-' '_')
SESSION=${SESSION:-dev}

# If session already exists, switch or attach to it
if tmux has-session -t "$SESSION" 2>/dev/null; then
  if [ -n "$TMUX" ]; then
    # Already inside tmux, switch to the session
    tmux switch-client -t "$SESSION"
  else
    # Outside tmux, attach to the session
    tmux attach-session -t "$SESSION"
  fi
  exit 0
fi

# Create new session (starts with one pane)
tmux new-session -d -s "$SESSION" -c "$PROJECT"

# Split horizontally: left pane (nvim) | right pane
tmux split-window -h -t "$SESSION" -c "$PROJECT"

# Split the right pane vertically: top (claude) | bottom (shell)
tmux split-window -v -t "$SESSION" -c "$PROJECT"

# Now we have 3 panes. Get pane base index
PANE_BASE=$(tmux show-options -gw pane-base-index 2>/dev/null | awk '{print $2}')
PANE_BASE=${PANE_BASE:-0}

LEFT_PANE=$PANE_BASE
TOP_RIGHT=$((PANE_BASE + 1))
BOTTOM_RIGHT=$((PANE_BASE + 2))

# Resize left pane to be larger (50% width is default, make it ~60%)
tmux resize-pane -t "$SESSION:.$LEFT_PANE" -x 60%

# Start nvim in left pane (with venv activated if present), then open Neo-tree
tmux send-keys -t "$SESSION:.$LEFT_PANE" " ${_VENV_ACTIVATE}nvim" Enter
sleep 1
tmux send-keys -t "$SESSION:.$LEFT_PANE" " e"  # Space+e opens Neo-tree in LazyVim

# Start claude in top-right pane (try to continue previous session, fall back to fresh)
tmux send-keys -t "$SESSION:.$TOP_RIGHT" " claude --continue || claude" Enter

# Bottom-right shell pane (activate venv if present)
if [ -n "$_VENV_ACTIVATE" ]; then
  tmux send-keys -t "$SESSION:.$BOTTOM_RIGHT" " ${_VENV_ACTIVATE}clear" Enter
fi

# Run optional command in bottom-right pane
if [ -n "$BOTTOM_CMD" ]; then
  sleep 1  # Allow venv activation and shell init to complete
  tmux send-keys -t "$SESSION:.$BOTTOM_RIGHT" "$BOTTOM_CMD" Enter
fi

# Focus on top-right pane (claude)
tmux select-pane -t "$SESSION:.$TOP_RIGHT"

# Attach or switch to session
if [ -n "$TMUX" ]; then
  # Already inside tmux, switch to the new session
  tmux switch-client -t "$SESSION"
else
  # Outside tmux, attach to the session
  tmux attach-session -t "$SESSION"
fi
