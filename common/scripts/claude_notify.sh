#!/usr/bin/env bash
################################################################################
# Claude Code Desktop Notification
#
# Sends a desktop notification when Claude Code needs attention. Designed to be
# called by the Claude Code Notification hook. Cross-platform: supports macOS
# (terminal-notifier with click-to-focus, osascript fallback) and Linux
# (notify-send).
#
# USAGE:
#   ./claude_notify.sh [--message "Custom message"] [--title "Custom title"]
#
#   When called by a Claude Code hook, JSON is piped via stdin with a "cwd"
#   field. The script extracts the repo/project name and includes it in the
#   notification message automatically.
#
# OPTIONS:
#   --message   Notification body text (default: "Claude Code needs your attention in <repo>")
#   --title     Notification title (default: "Claude Code")
#
# DEPENDENCIES:
#   macOS:  terminal-notifier (preferred, enables click-to-focus) or osascript
#   Linux:  notify-send (libnotify)
#
# NOTES:
#   - On macOS with terminal-notifier, clicking the notification focuses the
#     terminal application that spawned the tmux/shell session
#   - Falls back gracefully: terminal-notifier → osascript (macOS),
#     notify-send (Linux)
################################################################################

set -euo pipefail

readonly DEFAULT_TITLE="Claude Code"
readonly DEFAULT_MESSAGE="Claude Code needs your attention"

################################################################################
# Parse repo context from hook stdin (JSON with "cwd" field)
################################################################################
_repo_name=""
if [ ! -t 0 ]; then
    # stdin is not a terminal — we're being called by a hook with JSON input
    _stdin=$(cat)
    if [ -n "${_stdin}" ] && command -v jq >/dev/null 2>&1; then
        _cwd=$(echo "${_stdin}" | jq -r '.cwd // empty' 2>/dev/null) || true
        if [ -n "${_cwd}" ]; then
            # Try git repo root name first, fall back to directory basename
            _repo_root=$(git -C "${_cwd}" rev-parse --show-toplevel 2>/dev/null) || true
            if [ -n "${_repo_root}" ]; then
                _repo_name=$(basename "${_repo_root}")
            else
                _repo_name=$(basename "${_cwd}")
            fi
        fi
    fi
fi

_title="${DEFAULT_TITLE}"
if [ -n "${_repo_name}" ]; then
    _message="${DEFAULT_MESSAGE} in ${_repo_name}"
else
    _message="${DEFAULT_MESSAGE}"
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --message)
            _message="$2"
            shift 2
            ;;
        --title)
            _title="$2"
            shift 2
            ;;
        -h|--help)
            head -30 "$0" | tail -25
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

################################################################################
# macOS: Detect the terminal emulator for click-to-focus
################################################################################
_get_macos_terminal_bundle_id() {
    local _bundle_id=""

    # Try common terminal emulators in order of likelihood
    for _app in "Ghostty" "iTerm2" "Alacritty" "kitty" "WezTerm" "Terminal"; do
        _bundle_id=$(osascript -e "id of app \"${_app}\"" 2>/dev/null) && break
    done

    # Fallback: whatever terminal is currently running
    if [ -z "${_bundle_id}" ]; then
        local _frontmost
        _frontmost=$(osascript -e 'tell application "System Events" to get bundle identifier of first application process whose frontmost is true' 2>/dev/null) || true
        _bundle_id="${_frontmost}"
    fi

    echo "${_bundle_id}"
}

################################################################################
# Send notification (platform-specific)
################################################################################
_os="$(uname -s)"

case "${_os}" in
    Darwin)
        if command -v terminal-notifier >/dev/null 2>&1; then
            _bundle_id=$(_get_macos_terminal_bundle_id)
            _activate_flag=()
            if [ -n "${_bundle_id}" ]; then
                _activate_flag=(-activate "${_bundle_id}")
            fi
            terminal-notifier \
                -title "${_title}" \
                -message "${_message}" \
                -sound default \
                "${_activate_flag[@]}"
        else
            osascript -e "display notification \"${_message}\" with title \"${_title}\""
        fi
        ;;
    Linux)
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "${_title}" "${_message}"
        else
            echo "[${_title}] ${_message}" >&2
        fi
        ;;
    *)
        echo "[${_title}] ${_message}" >&2
        ;;
esac
