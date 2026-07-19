#!/usr/bin/env bash
#
# bootstrap.sh - Bootstrap a new machine from this dotfiles repo.
#
# Purpose:
#   Idempotently set up a freshly-cloned dotfiles checkout on a new machine:
#   init submodules, install packages, install Oh My Zsh, stow the configs,
#   and (optionally) switch the login shell to zsh.
#
# Usage:
#   bootstrap/bootstrap.sh [options]
#
# Options:
#   -n, --dry-run       Print what would happen without making changes
#       --skip-packages Skip OS package installation (submodule/stow/omz only)
#       --no-chsh        Do not change the default login shell to zsh
#   -h, --help          Show this help message
#
# Supported platforms:
#   - Fedora (dnf)          fully supported
#   - macOS (Homebrew)      supported
#   - Other Linux           submodule/stow/omz run; package step is skipped
#
# Dependencies:
#   git, stow, curl. On Fedora: dnf + sudo. On macOS: brew.
#
# Exit codes: 0=success, 1=error, 2=invalid arguments

set -euo pipefail

###
## Constants & environment
###

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
readonly REPO_ROOT

DRY_RUN=false
SKIP_PACKAGES=false
DO_CHSH=true

# Detected below
_IS_MACOS=false
_IS_LINUX=false
_DISTRO="unknown"

###
## Logging helpers (color-coded)
###

if [[ -t 1 ]]; then
  _C_RESET=$'\033[0m'; _C_RED=$'\033[31m'; _C_GREEN=$'\033[32m'
  _C_YELLOW=$'\033[33m'; _C_BLUE=$'\033[34m'; _C_BOLD=$'\033[1m'
else
  _C_RESET=""; _C_RED=""; _C_GREEN=""; _C_YELLOW=""; _C_BLUE=""; _C_BOLD=""
fi

log_info()    { printf '%s[info]%s %s\n'  "${_C_BLUE}"   "${_C_RESET}" "$*"; }
log_success() { printf '%s[ ok ]%s %s\n'  "${_C_GREEN}"  "${_C_RESET}" "$*"; }
log_warn()    { printf '%s[warn]%s %s\n'  "${_C_YELLOW}" "${_C_RESET}" "$*" >&2; }
log_error()   { printf '%s[fail]%s %s\n'  "${_C_RED}"    "${_C_RESET}" "$*" >&2; }

log_header() {
  local _title="$1"
  printf '\n%s┌─%s\n' "${_C_BOLD}" "${_C_RESET}"
  printf '%s│ %s%s\n'  "${_C_BOLD}" "${_title}" "${_C_RESET}"
  printf '%s└─%s\n'    "${_C_BOLD}" "${_C_RESET}"
}

# Run a command, or just echo it in dry-run mode.
run() {
  if $DRY_RUN; then
    printf '  %s(dry-run)%s %s\n' "${_C_YELLOW}" "${_C_RESET}" "$*"
  else
    "$@"
  fi
}

###
## Platform detection
###

detect_platform() {
  if [[ "${OSTYPE:-}" == darwin* ]]; then
    _IS_MACOS=true
    _DISTRO="macos"
    return
  fi

  _IS_LINUX=true
  if command -v dnf &>/dev/null; then
    _DISTRO="fedora"
  elif command -v pacman &>/dev/null; then
    _DISTRO="arch"
  elif command -v apt &>/dev/null; then
    _DISTRO="debian"
  else
    _DISTRO="linux"
  fi
}

###
## Steps
###

init_submodules() {
  log_header "Git submodules (agent_skills)"
  if [[ ! -f "${REPO_ROOT}/agent_skills/.git" && ! -d "${REPO_ROOT}/agent_skills/.git" ]] \
     || [[ -z "$(ls -A "${REPO_ROOT}/agent_skills" 2>/dev/null)" ]]; then
    run git -C "${REPO_ROOT}" submodule update --init --recursive
    log_success "Submodules initialized"
  else
    log_info "Submodules already initialized; syncing to pinned commit"
    run git -C "${REPO_ROOT}" submodule update --init --recursive
    log_success "Submodules up to date"
  fi
}

# ---- Fedora packages -------------------------------------------------------

# Packages available in Fedora's default repositories.
_FEDORA_DNF_PACKAGES=(
  zsh
  util-linux-user   # provides chsh
  git-core
  neovim
  tmux
  stow
  gh
  ripgrep
  fd-find           # binary: fd
  bat
  eza
  fzf
  zoxide
  git-delta
  cloc
  tree
  jq
  wl-clipboard      # wl-copy / wl-paste
  xclip             # X11 clipboard fallback
)

# Packages that require a COPR repo: "copr/repo:package"
_FEDORA_COPR_PACKAGES=(
  "atim/lazygit:lazygit"
  "lihaohong/yazi:yazi"
)

install_packages_fedora() {
  log_header "Installing packages (dnf)"
  run sudo dnf install -y "${_FEDORA_DNF_PACKAGES[@]}"
  log_success "Base packages installed"

  log_header "Installing COPR packages (lazygit, yazi)"
  local _entry _copr _pkg
  for _entry in "${_FEDORA_COPR_PACKAGES[@]}"; do
    _copr="${_entry%%:*}"
    _pkg="${_entry##*:}"
    if rpm -q "${_pkg}" &>/dev/null; then
      log_info "${_pkg} already installed; skipping COPR"
      continue
    fi
    if run sudo dnf copr enable -y "${_copr}" && run sudo dnf install -y "${_pkg}"; then
      log_success "${_pkg} installed (copr: ${_copr})"
    else
      log_warn "Could not install ${_pkg} from copr ${_copr}; install it manually later"
    fi
  done
}

# ---- macOS packages --------------------------------------------------------

_BREW_PACKAGES=(
  stow git neovim tmux yazi ripgrep fd fzf bat eza gh lazygit git-delta cloc tree jq zoxide
)

install_packages_macos() {
  log_header "Installing packages (Homebrew)"
  if ! command -v brew &>/dev/null; then
    log_error "Homebrew not found. Install it first: https://brew.sh"
    return 1
  fi
  run brew install "${_BREW_PACKAGES[@]}"
  run brew install --cask ghostty
  log_success "Packages installed"
}

install_packages() {
  if $SKIP_PACKAGES; then
    log_header "Package installation (skipped via --skip-packages)"
    return
  fi
  case "${_DISTRO}" in
    fedora) install_packages_fedora ;;
    macos)  install_packages_macos ;;
    *)
      log_header "Package installation"
      log_warn "No package recipe for '${_DISTRO}'. Install the tools manually:"
      log_warn "  zsh neovim tmux stow gh ripgrep fd bat eza fzf yazi lazygit git-delta cloc tree jq"
      ;;
  esac
}

# ---- Oh My Zsh -------------------------------------------------------------

install_oh_my_zsh() {
  log_header "Oh My Zsh"
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    log_info "Oh My Zsh already installed; skipping"
    return
  fi
  # --keep-zshrc: don't clobber our stowed ~/.zshrc
  # RUNZSH=no / CHSH=no: don't launch zsh or change the shell here (we do chsh ourselves)
  if $DRY_RUN; then
    printf '  %s(dry-run)%s install oh-my-zsh (unattended, keep-zshrc)\n' "${_C_YELLOW}" "${_C_RESET}"
  else
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      "" --unattended --keep-zshrc
  fi
  log_success "Oh My Zsh installed"
}

# ---- Stow ------------------------------------------------------------------

# Move aside any real (non-symlink) file that would block stow, so a
# re-clone onto a machine that already has installer-created configs works.
_backup_conflict() {
  local _target="$1"
  if [[ -e "${_target}" && ! -L "${_target}" ]]; then
    local _bak="${_target}.pre-stow.bak"
    log_warn "Backing up existing ${_target} -> ${_bak}"
    run mv "${_target}" "${_bak}"
  fi
}

run_stow() {
  log_header "Stow (symlinking configs)"

  # Known files that a fresh install may create as real files before we stow.
  _backup_conflict "${HOME}/.claude/settings.json"

  run stow --dir="${REPO_ROOT}" --target="${HOME}" --restow --verbose common
  log_success "Stowed 'common'"

  if $_IS_MACOS; then
    run stow --dir="${REPO_ROOT}" --target="${HOME}" --restow --verbose macos
    log_success "Stowed 'macos'"
  fi
}

# ---- Default shell ---------------------------------------------------------

set_default_shell() {
  log_header "Default shell"
  if ! $DO_CHSH; then
    log_info "Skipping shell change (--no-chsh)"
    return
  fi
  local _zsh
  _zsh="$(command -v zsh || true)"
  if [[ -z "${_zsh}" ]]; then
    log_warn "zsh not found on PATH; cannot change shell"
    return
  fi
  if [[ "${SHELL:-}" == "${_zsh}" ]]; then
    log_info "Login shell is already zsh (${_zsh})"
    return
  fi
  # Ensure zsh is a valid login shell
  if ! grep -qx "${_zsh}" /etc/shells 2>/dev/null; then
    log_info "Adding ${_zsh} to /etc/shells"
    run sudo sh -c "echo '${_zsh}' >> /etc/shells"
  fi
  log_info "Changing login shell to ${_zsh} (may prompt for your password without passwordless sudo)"
  run sudo chsh -s "${_zsh}" "${USER}"
  log_success "Default shell set to zsh (takes effect on next login)"
}

###
## Argument parsing
###

usage() {
  sed -n '3,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)     DRY_RUN=true; shift ;;
      --skip-packages)  SKIP_PACKAGES=true; shift ;;
      --no-chsh)        DO_CHSH=false; shift ;;
      -h|--help)        usage; exit 0 ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 2
        ;;
    esac
  done
}

###
## Main
###

main() {
  parse_args "$@"
  detect_platform

  log_header "dotfiles bootstrap"
  log_info "Repo:     ${REPO_ROOT}"
  log_info "Platform: ${_DISTRO}"
  $DRY_RUN && log_warn "DRY RUN — no changes will be made"

  init_submodules
  install_packages
  run_stow
  install_oh_my_zsh
  set_default_shell

  log_header "Done"
  log_success "Bootstrap complete."
  log_info "Open a new terminal (or run 'exec zsh') to start using your shell."
}

main "$@"
