# linux.zsh - Linux-specific configuration
# Sourced by ~/.zshrc on Linux systems (Fedora/GNOME, Arch, etc.).
# Mirrors macos.zsh so the same aliases/functions work cross-platform.

###
## Cross-platform clipboard (clip / paste)
###
# Prefer Wayland (wl-clipboard), fall back to X11 (xclip).
if command -v wl-copy &>/dev/null; then
  alias clip='wl-copy'
  alias paste='wl-paste'
elif command -v xclip &>/dev/null; then
  alias clip='xclip -selection clipboard'
  alias paste='xclip -selection clipboard -o'
fi

###
## Colorized ls
###
# On GNU coreutils, -G means "no group column" (not colorize like macOS).
# Alias ls to add --color so the shared `ls -lahG` aliases (ll, DL, p, ...)
# come out colorized on Linux too.
alias ls='ls --color=auto'

###
## Linux-Specific Aliases
###

# about - file metadata (GNU stat)
alias about='stat --format="File: %n%nModified: %y%nAccessed: %x%nChanged: %z"'

# gurl - open the current repo's remote in the default browser (xdg-open)
alias gurl='u=$(git remote get-url origin | sed "s|git@\(.*\):\(.*\)\.git|https://\1/\2|;s|\.git$||"); echo "${u}" && echo "${u}" | clip && xdg-open "${u}"'

# purl - open the current project's PyPI page in the default browser
alias purl='p=$(grep "^name" pyproject.toml 2>/dev/null | head -1 | sed "s/.*= *\"//;s/\"//"); if [ -n "$p" ]; then u="https://pypi.org/project/${p}/"; echo "${u}" && echo "${u}" | clip && xdg-open "${u}"; else echo "No pyproject.toml with name found"; fi'
