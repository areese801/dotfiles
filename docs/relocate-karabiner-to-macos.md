# Task: Relocate Karabiner config from `common/` to `macos/`

**Run this on the macOS machine** (Karabiner-Elements is macOS-only, so the live
symlink and the app that reads it only exist there). Hand this file to Claude Code
as the task prompt.

> This repository is **public**. Do not add secrets, internal hostnames, credential
> paths, or machine-specific personal data in any change you make.

---

## Context

This dotfiles repo uses GNU Stow with a package-per-context layout:

- `common/` — configs shared across **all** machines (always stowed)
- `macos/` — **macOS-only** configs (stowed only on Macs)

`~/.config/karabiner/karabiner.json` is [Karabiner-Elements](https://karabiner-elements.pqrs.org/)
configuration — a macOS-only app. It currently lives in `common/.config/karabiner/`,
which is wrong: on Linux machines it stows a useless (dead) symlink. It belongs in
the `macos/` package alongside the Sublime Text settings.

`macos/` currently stows into `~/Library/...`; after this change it will also manage
`~/.config/karabiner/`. Stow handles multiple subtrees in one package fine.

## Goal

Move `common/.config/karabiner/` → `macos/.config/karabiner/` and re-point the live
symlink so Karabiner-Elements keeps reading the same file, with zero behavior change.

## Preconditions

```bash
cd ~/.dotfiles
git switch main && git pull          # start from up-to-date main
git status                           # confirm a clean working tree
```

If the working tree isn't clean, stop and ask the user how to proceed.

## Steps

1. **Create a feature branch** (never commit to main):
   ```bash
   git switch -c chore/move-karabiner-to-macos
   ```

2. **Move the files in the repo** (`git mv` creates `macos/.config/` as needed):
   ```bash
   git mv common/.config/karabiner macos/.config/karabiner
   ```

3. **Preview the stow changes** before touching any live symlink:
   ```bash
   stow -n -v -R common     # should show it UNLINK-ing .config/karabiner
   stow -n -v -R macos      # should show it LINK-ing .config/karabiner
   ```

4. **Re-stow** so the live link moves from `common` to `macos`. Order matters —
   clear the old link first, then create the new one:
   ```bash
   stow -R common           # drops ~/.config/karabiner (no longer in common)
   stow -R macos            # recreates it, now pointing into macos/
   ```
   If `stow -R macos` reports a conflict on `~/.config/karabiner`, the old link
   wasn't cleared — verify it's a symlink and remove it, then retry:
   ```bash
   [ -L ~/.config/karabiner ] && rm ~/.config/karabiner && stow -R macos
   ```

## Verification (must pass before committing)

```bash
# 1. The live symlink now resolves into macos/, not common/
readlink ~/.config/karabiner        # expect: ...../.dotfiles/macos/.config/karabiner

# 2. The config file still resolves and is valid JSON
cat ~/.config/karabiner/karabiner.json | python3 -m json.tool >/dev/null && echo "JSON OK"

# 3. No leftover reference to the old location
[ -e common/.config/karabiner ] && echo "STILL IN COMMON (bad)" || echo "removed from common OK"

# 4. Nothing else in common/ got disturbed
stow -n -v common                   # expect no unexpected relinks/conflicts
```

Then confirm in the GUI: open **Karabiner-Elements → Settings** and check your
profile/complex modifications are intact. Karabiner writes back through the symlink
into the repo file (same as before the move) — that's expected.

## Docs to update in the same commit

- `CLAUDE.md` — under **"What Goes Where"**, add a row noting Karabiner lives in
  `macos/` (it's currently unlisted). Confirm the `macos/` "Current Packages"
  description still reads correctly.
- Grep for any lingering references and fix if present:
  ```bash
  grep -rni karabiner README.md CLAUDE.md
  ```

## Commit & PR (follow repo conventions)

```bash
git add -A
git commit -m "Move Karabiner config from common/ to macos/

Karabiner-Elements is macOS-only; keeping its config in common/ stowed a
dead symlink on Linux machines. Relocate it into the macos/ package.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push -u origin chore/move-karabiner-to-macos
gh pr create --fill
```

## Note for Linux machines (no action needed)

On any Linux machine, the stale `~/.config/karabiner` symlink self-heals on the next
`stow -R common` after pulling this change — stow removes links whose source no longer
exists in the package.

---

## Already handled (context, no action needed)

The macOS-only commands that used to lurk in shared `common/` files were made
cross-platform in the same change that introduced this doc:

- A `common/scripts/clip` helper now copies stdin to the clipboard on any platform
  (pbcopy → wl-copy → xclip → xsel). It complements the interactive `clip` shell alias.
- `common/.config/yazi/keymap.toml` and `common/scripts/sq.sh` call `clip` instead of `pbcopy`.
- `common/scripts/sq.sh` resolves `snowsql` from PATH first, falling back to the macOS app bundle.
- `common/scripts/json_diff.sh` falls back to an nvim diff (then plain `diff`) when Beyond Compare is absent.

Nothing to do here — just don't reintroduce hardcoded `pbcopy`/app-bundle paths.
