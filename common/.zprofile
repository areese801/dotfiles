# ~/.zprofile - Login shell initialization
# Sourced by login shells before .zshrc

# Homebrew (macOS only)
if [[ "$OSTYPE" == "darwin"* ]] && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# macOS-only app paths (JetBrains Toolbox, Obsidian) — these directories only
# exist under /Users and /Applications, so skip them entirely on Linux.
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Added by Toolbox App
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

  # Added by Obsidian
  export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
fi

# User-local binaries (pipx, claude, etc.) — $HOME, not a hardcoded /Users path,
# so this resolves correctly on both macOS and Linux.
export PATH="$PATH:$HOME/.local/bin"
