# linux.zsh - Linux-specific configuration
# This file is only sourced on Linux systems (e.g., Omarchy with Hyprland)

###
## Cross-platform clipboard functions
###
# Wayland (Omarchy uses Hyprland)
alias clip='wl-copy'
alias paste='wl-paste'

###
## Linux-Specific Aliases
###

alias about='stat --format="File: %n%nModified: %y%nAccessed: %x%nChanged: %z"'
alias gurl='u=$(git remote get-url origin | sed "s|git@\(.*\):\(.*\)\.git|https://\1/\2|;s|\.git$||"); echo "${u}" && echo "${u}" | clip && google-chrome "${u}"'
alias purl='p=$(grep "^name" pyproject.toml 2>/dev/null | head -1 | sed "s/.*= *\"//;s/\"//"); if [ -n "$p" ]; then u="https://pypi.org/project/${p}/"; echo "${u}" && echo "${u}" | clip && google-chrome "${u}"; else echo "No pyproject.toml with name found"; fi'
