# ~/.zprofile - Login shell initialization
# Sourced by login shells before .zshrc

# Homebrew (macOS only)
if [[ "$OSTYPE" == "darwin"* ]] && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Added by Toolbox App
export PATH="$PATH:/Users/areese/Library/Application Support/JetBrains/Toolbox/scripts"

# Created by `pipx` on 2026-04-09 20:46:41
export PATH="$PATH:/Users/areese/.local/bin"
