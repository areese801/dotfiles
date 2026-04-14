# Global Claude Code Configuration

**Last Updated**: 2026-04-14
**Next Review**: 2026-05-14 (30 days)

This file provides universal guidance to Claude Code across all projects.

---

## Maintenance

When 30+ days have passed since "Last Updated":
1. Review this file for outdated conventions
2. Check project-specific CLAUDE.md files for new patterns worth globalizing
3. Update or remove sections that are no longer relevant
4. Update the "Last Updated" and "Next Review" dates

### Last Update Summary (2026-04-14)

Trimmed from ~1250 lines to ~650 lines. Removed verbose code templates
(shell script boilerplate, GraphQL introspection queries, .gitignore patterns)
that are better served by snippets or project-specific CLAUDE.md files.
Fixed stale snippets path, settings file references, and git workflow guidance.

**Configuration Files:**
- `~/.claude/CLAUDE.md` - This file
- `~/.claude/settings.json` - Auto-approved commands (22), hooks, plugins
- `~/.claude/settings.local.json` - Per-machine MCP permissions

---

## Python Conventions

### Docstrings
- Use multi-line docstrings:
  ```python
  """
  Like this
  """
  ```
  Not: `"""Not like this"""`
- Follow PEP 257, include params/returns/exceptions

### General Rules
- Virtual environments: name folders `venv`, not `.venv`
- Use type hints for function signatures and complex variables
- Use specific exception types, not bare `except:`; always log errors with context
- All imports at the top of the file — no inline or lazy imports
- Follow ordering: stdlib, third-party, local (enforced by Ruff/isort)

### Code Formatting
- Use Ruff for formatting and linting (replaces Black, flake8, isort)
- Configure in `pyproject.toml` under `[tool.ruff]` (line-length=88)
- Run `ruff format .` and `ruff check --fix .` before committing
- If a project still uses Black, follow the project's convention

---

## Development Workflow

### Build Commands
- Prefer Makefiles (`make build`, `make test`, `make lint`, `make run`, `make help`)
- Document all build/test/lint commands in project CLAUDE.md

### Environment Configuration
- Use .env files for local configuration (git-ignored), never commit secrets
- **Naming Convention**: Prefix env vars with project/context identifier (e.g., `_POSTGRES_`, `_SNOWFLAKE_`)
- **Underscore Prefix**: Use for special/non-standard values (`_first_name`, `_START_DATE`)
- Provide `.env.example` with dummy values

### Dependencies
- Pin versions in production
- Use `venv` for Python virtual environments

---

## .gitignore Best Practices

### Core Principles
- **Secrets first**: Ensure secrets are ignored before creating them
- **Generated files**: Don't commit files that can be regenerated
- **Local environment**: Don't commit user/machine-specific configs

### Key Patterns
- Python: `__pycache__/`, `*.py[cod]`, `build/`, `dist/`, `*.egg-info/`
- Venvs: `venv/`, `.venv/`
- IDE: `.idea/`, `.vscode/`, `.zed/`, `.fleet/`
- OS: `.DS_Store`
- Secrets: `.env`, `*_config.json`
- Working files: `TODO.md`
- Singer projects: `tap_config.json`, `state.json`, `transform_config.json`, `target_config.json`

### When Creating Sensitive Files
1. Verify .gitignore has the pattern **before** creating the file
2. Provide `.example` versions for documentation

---

## Database Conventions

**Note:** These apply primarily to **dbt projects**. Suggest conventions, don't enforce — ask before applying.

### dbt Naming
- Primary keys: `_id` suffix (`company_id`, `user_id`)
- Timestamps: `_at` suffix, convert to UTC (`created_at`, `updated_at`, `deleted_at`)
- Dates: `_date` suffix (`birth_date`, `hire_date`)
- Booleans: `is_` or `has_` prefix (`is_active`, `has_opted_in`)
- All fields: snake_case. Derived fields: underscore prefix
- **Django note**: rename `created_when`/`updated_when`/`deleted_when` to `*_at` in stnd layer

### dbt Layers
- **Standardized (`stnd_`)**: Pull from `static_lake`, UTC timestamps, dedup with QUALIFY, CTE prefix `_cte_`, end with `_cte_final`
- **Staging (`stg_`)**: Reference `stnd_` model, soft-delete macro, unique/not_null tests on PK
- **Warehouse**: Reference `stg_` model, full docs with tests and field descriptions

### Standard Tracking Fields
`created_at`, `updated_at`, `deleted_at` (UTC), `is_deleted`, `__record_is_deleted`

---

## Documentation Standards

### Project Documentation Files
- **CLAUDE.md**: Claude-specific instructions, architecture, conventions, build commands
- **README.md**: Human-readable overview, setup, usage
- **TODO.md**: Cross-session work tracking (git-ignored)

### Code Documentation
- Follow language-specific standards (PEP 257, JSDoc, etc.)
- Document public APIs, params, returns, exceptions, side effects

---

## User Environment

### Custom Commands
- The user has many custom aliases and commands
- If instructed to run an unfamiliar command, use `which` or `alias` to understand it

### Remote Servers
- **ETL Server**: Access via `ssh etl` (requires VPN, SSH config already in place)

---

## Command Permissions

Auto-approval is configured in `~/.claude/settings.json` (22 commands).

**Auto-approved (read-only):** `cat`, `head`, `tail`, `wc`, `ls`, `find`, `pwd`, `grep`, `jq`, `which`, `alias`, `whoami`, `date`, `echo`, `curl`, `sed`, `source *activate*`, `deactivate`, `git status`, `git log`, `git diff`, `git branch`, `git show`

**Always require approval:** `env`/`printenv`/`set` (may contain secrets), all write operations, git writes, package management, process management

---

## Versioning

Follow [Semantic Versioning](https://semver.org/) for published packages: `MAJOR.MINOR.PATCH`

- Suggest version bumps when committing behavior changes (don't bump automatically)
- Don't bump for docs-only, test-only, or internal refactoring changes

---

## Git Commit Conventions

### Commits Are Atomic Actions
- **Never commit automatically** — always ask the user first
- Don't chain commits to other operations (`stow -R common && git commit`)

### Always Use Feature Branches and PRs

**Never commit directly to main.** Always create a feature branch, commit there, push, and open a PR via `gh pr create`.

If changes are being made on main, create a feature branch immediately before modifying any files.

**When starting work, ask:**
> "Are you working on a specific Jira card?"

**Branch naming:**
- Jira card: `DATA-1234_fix_specific_issue`
- Otherwise: `feature/<description>`, `fix/<description>`, `chore/<description>`

### Post-Merge Branch Cleanup
After merging, suggest `clean` to tidy up stale branches. Don't run automatically.
- `clean` — delete local merged branches
- `clean -r` — also delete merged remote branches (GitHub only)
- `clean -n` — dry run

---

## Shell Script Conventions

### Naming
- Internal variables: underscore prefix (`_internal_var`)
- Constants: UPPERCASE with `readonly`
- Local variables: lowercase snake_case
- Internal functions: underscore prefix (`_validate_input`)
- Public functions: verb-noun pattern (`get_user`, `check_file_exists`)

### Structure
- Always start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Include header block: purpose, usage, options, examples, dependencies
- Use `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"` for directory resolution
- Use `trap cleanup EXIT` for cleanup on failure
- Use case-based argument parsing with `--help` support

### Style
- Use color-coded logging functions (`log_info`, `log_error`, `log_success`, `log_warn`)
- Use Unicode box-drawing for visual section headers
- Document WHY, not just WHAT
- Exit codes: 0=success, 1=error, 2=invalid arguments

---

## API Integration

### General
- Never hardcode credentials — use env vars or .env files
- Implement rate limiting with exponential backoff
- Retry transient failures (5xx), fail fast on permanent errors (4xx)
- Set timeouts, log requests (sanitize secrets), validate responses

### GraphQL
- **Always offer to introspect** the API before implementing queries
- Workflow: introspect → document findings as JSON → analyze relationships → test queries → implement
- Save results as `{typename}_introspection.json` (or `_dev.json` / `_prod.json`)
- Document navigation property limitations (some are one-way only)
- Use cursor-based pagination: `first: N`, `after: cursor`, `pageInfo { hasNextPage, endCursor }`

---

## Snippets Repository

Personal code snippets at `~/projects/personal/snippets` with script-driven CRUD.

**Quick Reference:**
```bash
~/projects/personal/snippets/get <uuid>                    # Copy to clipboard
~/projects/personal/snippets/get --list                    # List all IDs
~/projects/personal/snippets/.scripts/add.py --title "X" --language sql --tags "a,b" --description "Y" --code "Z" --format json
~/projects/personal/snippets/.scripts/search.py --tag dbt --format json
```

**When to use:**
- Offer to save reusable code, refined commands, or patterns as snippets
- Search snippets before writing new code when user asks for something that might exist
- Always use `--format json` for programmatic operations

---

## SEO Awareness

When modifying web projects, flag potential SEO issues (don't block on them):
- URL/route changes: verify 301 redirects exist
- Page deletions: suggest redirect to replacement or `/`
- Title/meta changes: note previous values
- Content removal: flag if substantial
- New pages: confirm title, meta description, and internal links exist
