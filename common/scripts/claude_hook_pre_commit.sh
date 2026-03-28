#!/usr/bin/env bash
################################################################################
# Claude Code PreToolUse Hook: Submodule Drift Check
#
# Runs before Bash tool calls. If the command is a git commit, checks whether
# any git submodules have uncommitted pointer changes (dirty submodule). Blocks
# the commit with a descriptive message so Claude can address it first.
#
# USAGE:
#   Called automatically by Claude Code PreToolUse hook (Bash matcher).
#   Receives JSON on stdin with tool_input.command and cwd fields.
#
# EXIT CODES:
#   0 - Allow the action (not a git commit, or no submodule drift)
#   2 - Block the action (submodule drift detected)
#
# DEPENDENCIES:
#   - jq
#   - git
################################################################################

set -euo pipefail

# Read hook JSON from stdin
_stdin=$(cat)

# Extract the command being run
_command=$(echo "${_stdin}" | jq -r '.tool_input.command // empty' 2>/dev/null) || true

# Only check git commit commands
if ! echo "${_command}" | grep -qE '^\s*git\s+commit\b'; then
    exit 0
fi

# Extract working directory
_cwd=$(echo "${_stdin}" | jq -r '.cwd // empty' 2>/dev/null) || true
if [ -z "${_cwd}" ]; then
    exit 0
fi

# Check for submodule drift (+ prefix means submodule is at a different commit)
_dirty_submodules=$(git -C "${_cwd}" submodule status 2>/dev/null | grep '^\+' | awk '{print $2}') || true

if [ -n "${_dirty_submodules}" ]; then
    echo "BLOCKED: Submodule(s) have uncommitted pointer changes:" >&2
    echo "${_dirty_submodules}" | while read -r _sub; do
        echo "  - ${_sub}" >&2
    done
    echo "" >&2
    echo "Either include the submodule update in this commit (git add <submodule>)," >&2
    echo "or reset it (git submodule update <submodule>) before committing." >&2
    echo "Ask the user which approach they prefer." >&2
    exit 2
fi

exit 0
