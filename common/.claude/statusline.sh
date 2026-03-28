#!/usr/bin/env bash
set -euo pipefail

# Read JSON from stdin
JSON=$(cat)


# ── Helpers ──────────────────────────────────────────────────────────────────
RST='\033[0m'
DIM='\033[2m'
BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BRED='\033[1;31m'

_jq() { echo "$JSON" | jq -r "$1 // empty" 2>/dev/null || true; }
_jqn() { echo "$JSON" | jq -r "$1 // 0" 2>/dev/null || echo 0; }

threshold_color() {
  local pct=$1
  if (( pct >= 80 )); then printf '%b' "$RED"
  elif (( pct >= 50 )); then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"
  fi
}

segments=()

# ── 0. Project directory ───────────────────────────────────────────────────
proj_dir=$(basename "$PWD")
if [[ -n "$proj_dir" ]]; then
  segments+=("${BOLD}${GREEN}${proj_dir}${RST}")
fi

# ── 1. Model ─────────────────────────────────────────────────────────────────
model=$(_jq '.model.display_name')
if [[ -n "$model" ]]; then
  # Strip parenthetical suffixes like "(1M context)" — context size shown in Ctx bar
  model_short="${model%% (*}"
  segments+=("${DIM}${model_short}${RST}")
fi

# ── 2. Vim mode ──────────────────────────────────────────────────────────────
vim_mode=$(_jq '.vim.mode')
if [[ -n "$vim_mode" ]]; then
  case "$vim_mode" in
    NORMAL)  segments+=("${BGREEN}NOR${RST}") ;;
    INSERT)  segments+=("${BYELLOW}INS${RST}") ;;
    VISUAL)  segments+=("${BOLD}${CYAN}VIS${RST}") ;;
    *)       segments+=("${DIM}${vim_mode}${RST}") ;;
  esac
fi

# ── 3. (moved to end — after 5h rate) ────────────────────────────────────────
bar_len=10

# ── 4. Git branch + changes ─────────────────────────────────────────────────
if git rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || true)
  staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')

  git_seg="${CYAN}⎇ ${branch:-detached}${RST}"
  if (( staged > 0 )); then git_seg+=" ${GREEN}+${staged}${RST}"; fi
  if (( modified > 0 )); then git_seg+=" ${YELLOW}~${modified}${RST}"; fi
  segments+=("$git_seg")
fi

# ── 5. Lines changed ────────────────────────────────────────────────────────
lines_added=$(_jqn '.cost.total_lines_added')
lines_removed=$(_jqn '.cost.total_lines_removed')

if (( lines_added > 0 || lines_removed > 0 )); then
  segments+=("${GREEN}+${lines_added}${RST}/${RED}-${lines_removed}${RST}")
fi

# ── 6. Session cost ─────────────────────────────────────────────────────────
cost=$(_jq '.cost.total_cost_usd')

if [[ -n "$cost" ]]; then
  cost_fmt=$(printf '$%.2f' "$cost")
  segments+=("${YELLOW}Equiv: ${cost_fmt}${RST}")
fi

# ── 8. Agent name ─────────────────────────────────────────────────────────
agent_name=$(_jq '.agent.name')
if [[ -n "$agent_name" ]]; then
  segments+=("${BOLD}${CYAN}${agent_name}${RST}")
fi

# ── 9. Worktree ───────────────────────────────────────────────────────────
wt_branch=$(_jq '.worktree.branch')
if [[ -n "$wt_branch" ]]; then
  segments+=("${DIM}wt:${RST}${CYAN}${wt_branch}${RST}")
fi

# ── 10. 5-hour rate limit with bar ───────────────────────────────────────────
rate_pct=$(_jqn '.rate_limits.five_hour.used_percentage' | awk '{printf "%d", $1}')

if (( rate_pct > 0 )); then
  rate_color=$(threshold_color "$rate_pct")
  rate_filled=$(( rate_pct * bar_len / 100 ))
  (( rate_filled > bar_len )) && rate_filled=$bar_len
  rate_empty=$(( bar_len - rate_filled ))

  rate_bar="${rate_color}"
  for (( i=0; i<rate_filled; i++ )); do rate_bar+="▓"; done
  for (( i=0; i<rate_empty; i++ )); do rate_bar+="░"; done
  rate_bar+="${RST}"

  rate_seg="5h: ${rate_bar} ${rate_color}${rate_pct}%${RST}"

  resets_at=$(_jq '.rate_limits.five_hour.resets_at')
  if [[ -n "$resets_at" ]]; then
    now=$(date +%s)
    reset_epoch=$(date -jf "%Y-%m-%dT%H:%M:%S" "${resets_at%%.*}" +%s 2>/dev/null || \
                  date -d "${resets_at}" +%s 2>/dev/null || echo 0)
    diff_s=$(( reset_epoch - now ))
    if (( diff_s > 0 )); then
      hours=$(( diff_s / 3600 ))
      mins=$(( (diff_s % 3600) / 60 ))
      if (( hours > 0 )); then
        rate_seg+=" ${DIM}(${hours}h${mins}m)${RST}"
      else
        rate_seg+=" ${DIM}(${mins}m)${RST}"
      fi
    fi
  fi
  segments+=("$rate_seg")
fi

# ── 11. Context bar (last) ───────────────────────────────────────────────────
ctx_pct=$(_jqn '.context_window.used_percentage' | awk '{printf "%d", $1}')
ctx_size=$(_jqn '.context_window.context_window_size')
filled=$(( ctx_pct * bar_len / 100 ))
(( filled > bar_len )) && filled=$bar_len
empty=$(( bar_len - filled ))

color=$(threshold_color "$ctx_pct")
bar="${color}"
for (( i=0; i<filled; i++ )); do bar+="▓"; done
for (( i=0; i<empty; i++ )); do bar+="░"; done
bar+="${RST}"

ctx_label="Ctx"
if (( ctx_size >= 1000000 )); then
  ctx_label="Ctx $(( ctx_size / 1000000 ))M"
elif (( ctx_size >= 1000 )); then
  ctx_label="Ctx $(( ctx_size / 1000 ))k"
fi
segments+=("${ctx_label}: ${bar} ${color}${ctx_pct}%${RST}")

# ── Output ───────────────────────────────────────────────────────────────────
IFS=' │ '
for (( i=0; i<${#segments[@]}; i++ )); do
  printf '%b' "${segments[$i]}"
  if (( i < ${#segments[@]} - 1 )); then
    printf '%b' " ${DIM}│${RST} "
  fi
done
