# macos.zsh - macOS-specific configuration
# This file is only sourced on macOS systems

###
## PATH Additions
###

# Add Homebrew to path
# 2026-02-15: Changed to prepend so Homebrew Python takes priority over system Python.
# If something gets weird, switch back to the old line below.
# PATH=$PATH:/opt/homebrew/bin
PATH=/opt/homebrew/bin:$PATH

# Add Antigravity to path
PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Add Go binaries to path
PATH="$HOME/go/bin:$PATH"

# Add libpq stuff to path. This lets us use the psql cli
PATH=$PATH:/opt/homebrew/opt/libpq/bin

# Add wezterm binary to PATH: https://wezterm.org/install/macos.html
PATH=$PATH:/Applications/WezTerm.app/Contents/MacOS

###
## Cross-platform clipboard functions
###
alias clip='pbcopy'
alias paste='pbpaste'

###
## Boilerplate stuff to make the Mac App 'ShellHistory' work correctly (macOS only)
###

# adding shhist to PATH, so we can use it from Terminal
PATH="${PATH}:/Applications/ShellHistory.app/Contents/Helpers"

# creating an unique session id for each terminal session
__shhist_session="${RANDOM}"

# prompt function to record the history
__shhist_prompt() {
  local __exit_code="${?:-1}"
  \history -D -t "%s" -1 | sudo --preserve-env --user ${SUDO_USER:-${LOGNAME}} shhist insert --session ${TERM_SESSION_ID:-${__shhist_session}} --username ${LOGNAME} --hostname $(hostname) --exit-code ${__exit_code} --shell zsh
  return ${__exit_code}
}

# integrating prompt function in prompt
precmd_functions=(__shhist_prompt $precmd_functions)

# pdi() function lives in ~/.config/zsh/private.zsh

###
## macOS-Specific Aliases
###

alias about='stat -f "File: %N%nCreated: %SB%nModified: %Sm%nAccessed: %Sa"'
alias browser='defaultbrowser'
alias chrome='defaultbrowser chrome'
alias csv='easy_csv_editor'
alias edge='defaultbrowser edgemac'
alias gitkraken="open -a Gitkraken"
alias k='open -a Gitkraken .'
alias gurl='u=$(git remote get-url origin | sed "s|git@\(.*\):\(.*\)\.git|https://\1/\2|;s|\.git$||"); echo "${u}" && echo "${u}" | clip && open -a "Google Chrome" "${u}"'
alias purl='p=$(grep "^name" pyproject.toml 2>/dev/null | head -1 | sed "s/.*= *\"//;s/\"//"); if [ -n "$p" ]; then u="https://pypi.org/project/${p}/"; echo "${u}" && echo "${u}" | clip && open -a "Google Chrome" "${u}"; else echo "No pyproject.toml with name found"; fi'
