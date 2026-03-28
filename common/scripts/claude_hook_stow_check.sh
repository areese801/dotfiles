#!/usr/bin/env bash
################################################################################
# Claude Code PostToolUse Hook: Stow Validation
#
# Runs after Edit/Write tool calls. If the modified file is inside a stow
# package directory within ~/.dotfiles, runs `stow -n <package>` (dry run)
# to detect symlink conflicts early.
#
# USAGE:
#   Called automatically by Claude Code PostToolUse hook (Edit/Write matcher).
#   Receives JSON on stdin with tool_input.file_path and cwd fields.
#
# EXIT CODES:
#   0 - Always (advisory only, never blocks edits)
#
# DEPENDENCIES:
#   - jq
#   - stow
#
# NOTES:
#   - Only activates when cwd is the dotfiles repo
#   - Stow packages are top-level directories (common, macos, fedora, etc.)
#   - Skips non-stow directories (agent_skills, docs, etc.)
################################################################################

set -euo pipefail

readonly DOTFILES_DIR="${HOME}/.dotfiles"

# Read hook JSON from stdin
_stdin=$(cat)

# Extract the file path that was edited
_file_path=$(echo "${_stdin}" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || true
if [ -z "${_file_path}" ]; then
    exit 0
fi

# Only run if the file is inside the dotfiles repo
case "${_file_path}" in
    "${DOTFILES_DIR}/"*)
        ;;
    *)
        exit 0
        ;;
esac

# Extract the stow package name (first directory component after dotfiles root)
_relative="${_file_path#${DOTFILES_DIR}/}"
_package="${_relative%%/*}"

# Skip non-stow directories (submodules, docs, etc.)
readonly STOW_PACKAGES="common macos fedora"
_is_stow_package=false
for _pkg in ${STOW_PACKAGES}; do
    if [ "${_package}" = "${_pkg}" ]; then
        _is_stow_package=true
        break
    fi
done

if [ "${_is_stow_package}" = false ]; then
    exit 0
fi

# Run stow dry run to check for conflicts
# Filter out the standard simulation mode notice — only real conflicts matter
_stow_output=$(stow -n -d "${DOTFILES_DIR}" -t "${HOME}" "${_package}" 2>&1 \
    | grep -v "^WARNING: in simulation mode" \
    | grep -v "^$") || true

if [ -n "${_stow_output}" ]; then
    echo "STOW WARNING: Potential symlink conflicts in '${_package}' package:" >&2
    echo "${_stow_output}" >&2
    echo "" >&2
    echo "Run 'stow -n ${_package}' in ~/.dotfiles to inspect, or 'stow -R ${_package}' to restow." >&2
fi

exit 0
