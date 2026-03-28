# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository containing personal development environment configurations.

## Repository Structure

The repository uses GNU Stow for symlink management with a package-per-context pattern:

```
~/.dotfiles/
├── agent_skills/     # Git submodule → areese801/agent_skills (SKILL.md-based skills)
├── common/           # Shared across ALL machines (always stow this)
│   ├── .claude/      # Claude Code config (skills symlink, settings, global CLAUDE.md)
│   ├── .config/      # XDG configs (nvim, ghostty, yazi, zsh)
│   ├── .tmux.conf
│   ├── .zshrc
│   └── scripts/      # Custom scripts (symlinked to ~/scripts)
│
├── macos/            # macOS-specific (future, if needed)
│   └── .config/
│
└── fedora/           # Fedora-specific (future)
    └── .config/      # e.g., hyprland, waybar, dnf configs
```

### What Goes Where

| Config Type | Location | Examples |
|-------------|----------|----------|
| Cross-platform tools | `common/` | nvim, tmux, zsh, ghostty, yazi |
| Window managers | `<os>/` | hyprland, sway, yabai |
| DE-specific | `<os>/` | waybar, polybar, sketchybar |
| Package manager configs | `<os>/` | dnf, brew (if customized) |
| OS-specific scripts | `<os>/scripts/` | systemd services, launchd agents |

### Current Packages

- `common/` - Shared configs for all machines (nvim, ghostty, yazi, tmux, zsh, scripts, Claude Code)
- `agent_skills/` - Git submodule containing SKILL.md-based agent skills (forked from castlenthesky/agent_skills)

## Architecture

### Common Configs (`common/`)

- `common/.config/nvim/` - Complete Neovim configuration based on LazyVim starter template
  - `init.lua` - Entry point that bootstraps lazy.nvim and LazyVim
  - `lua/config/` - Core configuration files for LazyVim
    - `lazy.lua` - Plugin manager setup and configuration
    - `options.lua` - Custom Vim options
    - `keymaps.lua` - Custom key mappings
    - `autocmds.lua` - Auto commands
  - `lua/plugins/` - Custom plugin configurations and overrides
- `common/.config/ghostty/` - Terminal emulator configuration
- `common/.config/yazi/` - File manager configuration
- `common/.tmux.conf` - Tmux configuration
- `common/.zshrc` - Zsh bootstrap loader
- `common/scripts/` - Custom shell scripts (symlinked to ~/scripts)

## ZSH Sourcing Architecture

```
~/.zshrc (bootstrap loader)
    ↓
~/.config/zsh/core.zsh        # Shared config: oh-my-zsh, generic aliases, functions (tracked in git)
    ↓
~/.config/zsh/macos.zsh       # macOS-specific: Homebrew, pbcopy, ShellHistory
OR ~/.config/zsh/linux.zsh    # Linux-specific: Wayland clipboard, xdg-open
    ↓
~/.config/zsh/private.zsh     # Sensitive/work-specific: DB connections, SSH hosts,
                               # credential paths, project aliases (NOT tracked in git)
    ↓
~/.config/zsh/machine.zsh     # Machine-specific overrides (NOT tracked in git)
```

### Public vs Private Split

`core.zsh` is committed to git and contains only generic, reusable content. Anything that references internal hostnames, credentials, company projects, or SSH hosts belongs in `private.zsh`.

**Goes in `core.zsh` (public):**
- Generic utility functions (`clean`, `snake`, `devkill`, etc.)
- Tool aliases (`ff`, `cloc`, `ll`, `vim`, `lazygit`, etc.)
- FZF, tmux, editor, git, and snippets aliases
- Oh-my-zsh setup and PATH configuration

**Goes in `private.zsh` (gitignored):**
- Database connection aliases (hostnames, usernames, credential paths)
- SSH aliases to internal servers
- AWS_PROFILE, CREDENTIALS_DIR exports
- Project navigation aliases (`cd ~/projects/company/...`)
- Credential-reading aliases (API keys, passwords)
- Work-specific ETL/pipeline functions

## Coding Conventions

### Shell Scripts (zshrc)

- **Internal environment variables** should be prefixed with an underscore (e.g., `_IS_MACOS`, `_IS_LINUX`)
- This distinguishes internal/helper variables from user-facing exports like `AWS_PROFILE`

## Tmux Dev Session Scripts

Variants for launching tmux-based development sessions:

| Command | Script | Layout | Use Case |
|---------|--------|--------|----------|
| `dev` | `tmux_dev_session.sh` | nvim (left 60%) \| claude + shell (right) | Single project (legacy) |
| `dev1` / `d1` | `tmux_multi_dev_session.sh 1` | 1 column, 3 rows (claude/nvim/shell) | Single project |
| `dev2` / `d2` | `tmux_multi_dev_session.sh 2` | 2 equal columns, 3 rows each | Two related projects |
| `dev3` / `d3` | `tmux_multi_dev_session.sh 3` | 3 equal columns, 3 rows each | Three related projects |
| `dev4` / `d4` | `tmux_multi_dev_session.sh 4` | 4 equal columns, 3 rows each | Four related projects |

### Multi-Dev Layout (dev1 / dev2 / dev3 / dev4)

Each column has 3 rows: claude (top ~30%), nvim (middle ~60%), shell (bottom ~10%).

**Operations:**
- `dev3 --swap <slot> <new_path>` — replace a column's project (respawn-pane)
- `dev3 --switch <slot_a> <slot_b>` — swap two columns' positions (swap-pane)
- `dev3` (no args) — reattach to existing session

### Keeping Variants in Sync

**IMPORTANT**: When the user requests a change to any dev session variant (e.g., layout percentages, row ordering, launch behavior), ask whether the same change should be applied to the other variants. The `dev` script (`tmux_dev_session.sh`) has a different layout structure, so changes may not apply directly, but should still be offered. The `dev1`/`dev2`/`dev3`/`dev4` variants share a single script (`tmux_multi_dev_session.sh`), so changes there automatically apply to all.

## Git Branch Cleanup (`clean`)

The `clean` function deletes merged branches. Defined in `core.zsh`.

| Usage | Behavior |
|-------|----------|
| `clean` | Checkout main/master, pull, delete local merged branches |
| `clean -r` | Also delete merged remote branches (GitHub only, skips Bitbucket) |
| `clean -n` | Dry run — show what would be deleted |
| `clean -r -n` | Dry run for both local and remote |
| `clean -h` | Show help |

Auto-detects `main` vs `master`. The `-r` flag checks `git remote get-url origin` and only proceeds if the remote is GitHub.

## LazyVim Configuration

This setup uses [LazyVim](https://github.com/LazyVim/LazyVim) as the base configuration. LazyVim automatically:
- Installs and manages plugins via lazy.nvim
- Provides sensible defaults for options, keymaps, and autocmds
- Supports plugin extras for specific languages and features

### Key Configuration Points

- Plugin manager: lazy.nvim with automatic installation (:1-14 in lazy.lua)
- Default colorschemes: tokyonight, habamax (:33)
- Automatic plugin updates enabled (:34-37)
- Performance optimizations with disabled built-in plugins (:38-52)

### Plugin Customization

Plugins are configured in `lua/plugins/` directory. Each file is automatically loaded. The example file shows patterns for:
- Adding new plugins
- Configuring LazyVim settings
- Overriding plugin options
- Enabling/disabling plugins
- Setting up language servers with mason

## Common Development Tasks

Since this is a dotfiles repository, the primary "development" task is configuration management. The LazyVim setup handles most plugin management automatically.

### Neovim Plugin Management

- Plugins are managed via LazyVim's lazy.nvim integration
- New plugins can be added by creating files in `lua/plugins/`
- Plugin updates are checked automatically (configured in lazy.lua)
- Mason automatically installs configured tools like stylua, shellcheck, shfmt, flake8

### Configuration Changes

- Custom options: Edit `lua/config/options.lua`
- Custom keymaps: Edit `lua/config/keymaps.lua` 
- Plugin configurations: Add files to `lua/plugins/` directory
- New plugin installations: Create plugin spec files in `lua/plugins/`

The configuration follows LazyVim patterns where custom configurations extend rather than replace the defaults.

## Database Configuration (vim-dadbod)

This repository includes a sophisticated database access setup using vim-dadbod with custom adaptations for secure credential management and Snowflake RSA key authentication.

### Database Architecture

- `lua/config/databases.lua` - **SECURE** database configuration (safe to version control)
  - Contains NO secrets, only credential file paths
  - Reads credentials dynamically from `/.credentials/` at runtime
  - Supports PostgreSQL and Snowflake connections
  - Provides graceful fallbacks and error notifications

- `lua/plugins/languages.lua` - Plugin configuration for vim-dadbod integration
  - Integrates with blink.cmp for SQL autocompletion
  - Loads database connections on plugin initialization
  - Configures keymapping (`<leader>D` for DBUI toggle)


### Credential Management

**Security Architecture:**
```
/.credentials/              # Secure credential storage (NOT in version control)
├── <username>_postgres_dev_password
└── <username>_postgres_prod_password
```

**Available Connections:**
- `dev` - PostgreSQL DEV environment
- `prod` - PostgreSQL PROD (read-write)
- `prod_ro` - PostgreSQL PROD (read-only)

**Usage:**
1. Press `<leader>D` to open database UI
2. All connections load automatically from credential files
3. SQL queries benefit from intelligent autocompletion

### Maintenance Notes

- Database configuration is safe to modify and commit
- Adding new databases: extend patterns in `databases.lua`
- All credential paths are centralized for easy management
- No secrets ever touch the version control system

## Agent Skills (Git Submodule)

The `agent_skills/` directory is a git submodule pointing to the user's fork of [castlenthesky/agent_skills](https://github.com/castlenthesky/agent_skills). It provides custom SKILL.md-based skills (code-review, pytest-unit, etc.) that Claude Code discovers globally via `~/.claude/skills/`.

### Symlink Chain

```
common/.claude/skills → ../../agent_skills/.agent/skills    (relative symlink)
        ↓ stow
~/.claude/skills → resolves to ~/.dotfiles/agent_skills/.agent/skills
```

### Key Points

- **Submodule remote**: `origin` = `areese801/agent_skills` (user's fork)
- **Upstream remote**: `castlenthesky/agent_skills` (add manually per-machine for syncing)
- **Stow note**: The symlink must be relative — Stow rejects absolute symlinks
- **New machine setup**: `git clone --recurse-submodules` pulls the submodule automatically
- **Updating skills**: Changes to skills happen in the `agent_skills/` submodule directory, then `git add agent_skills` in the dotfiles repo to update the pinned commit

### Syncing Upstream

```bash
cd ~/.dotfiles/agent_skills
git remote add upstream git@github.com:castlenthesky/agent_skills.git  # one-time
git fetch upstream && git merge upstream/master
git push origin main
cd ~/.dotfiles && git add agent_skills && git commit -m "Update agent_skills submodule"
```

## Stow Configuration Management

This repository uses GNU Stow for symlink management with a package-based structure.

### Machine Setup

**macOS (current):**
```bash
cd ~/.dotfiles
stow common
# stow macos  # when/if macos-specific configs exist
```

**Fedora (future):**
```bash
cd ~/.dotfiles
stow common
stow fedora
```

### Adding a New OS Package (e.g., Fedora)

1. **Create the package directory structure:**
   ```bash
   mkdir -p fedora/.config
   ```

2. **Copy OS-specific configs:**
   ```bash
   # Example: Hyprland window manager
   cp -r ~/.config/hypr fedora/.config/

   # Example: Waybar status bar
   cp -r ~/.config/waybar fedora/.config/
   ```

3. **Stow with adopt to convert existing files:**
   ```bash
   stow --adopt fedora
   ```

4. **Commit the new package:**
   ```bash
   git add fedora/
   git commit -m "Add Fedora-specific configs (hyprland, waybar)"
   ```

### Adding Cross-Platform Configs

**For configs that work on all machines (add to `common/`):**

1. **Copy files to dotfiles repo first:**
   ```bash
   cp -r ~/.config/newapp common/.config/
   git add common/.config/newapp/
   git commit -m "Add newapp configuration"
   ```

2. **Use `--adopt` to convert existing files to symlinks:**
   ```bash
   stow --adopt common
   ```

### Common Stow Commands

| Command | Description |
|---------|-------------|
| `stow common` | Create symlinks for common configs |
| `stow fedora` | Create symlinks for Fedora configs |
| `stow --adopt common` | Adopt existing files and create symlinks |
| `stow -D common` | Remove symlinks for a package |
| `stow -R common` | Restow (remove and recreate symlinks) |
| `stow -n common` | Dry run (show what would be done) |

### Stow Safety Notes

- `stow -D common` removes symlinks for that package only
- Always use `stow -n <package>` first to preview changes
- The `--adopt` method is safer than manual file removal
- Packages don't conflict if they manage different paths