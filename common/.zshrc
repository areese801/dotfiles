# ~/.zshrc - Bootstrap loader for modular zsh configuration
#
# This file detects the OS and sources the appropriate config files:
#   ~/.config/zsh/core.zsh   - Shared configuration (oh-my-zsh, aliases, functions)
#   ~/.config/zsh/macos.zsh  - macOS-specific (Homebrew, Go PATH, pbcopy, etc.)
#   ~/.config/zsh/linux.zsh  - Linux-specific (Wayland clipboard, xdg-open, etc.)
#   ~/.config/zsh/machine.zsh - Optional machine-specific overrides (not in repo)

###
## OS Detection
###
if [[ "$OSTYPE" == "darwin"* ]]; then
  export _IS_MACOS=true
  export _IS_LINUX=false
else
  export _IS_MACOS=false
  export _IS_LINUX=true
fi

###
## Source Configuration Files
###

# Core configuration (shared across all platforms)
# Aliases are in this file
[[ -f ~/.config/zsh/core.zsh ]] && source ~/.config/zsh/core.zsh

# OS-specific configuration
[[ $_IS_MACOS == true ]] && [[ -f ~/.config/zsh/macos.zsh ]] && source ~/.config/zsh/macos.zsh
[[ $_IS_LINUX == true ]] && [[ -f ~/.config/zsh/linux.zsh ]] && source ~/.config/zsh/linux.zsh

# Private/sensitive configuration (work aliases, credentials, etc.)
# Not tracked in git - create ~/.config/zsh/private.zsh for sensitive content
[[ -f ~/.config/zsh/private.zsh ]] && source ~/.config/zsh/private.zsh

# Optional machine-specific overrides (not tracked in git)
# Create ~/.config/zsh/machine.zsh for local customizations like:
#   export _MACHINE_TYPE="work"
#   export AWS_PROFILE="work-profile"
#   alias proj="cd ~/work/projects"
[[ -f ~/.config/zsh/machine.zsh ]] && source ~/.config/zsh/machine.zsh

# Google Cloud SDK
[[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"
[[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"
