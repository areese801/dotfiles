# Global Claude Code Configuration

**Last Updated**: 2026-02-28
**Next Review**: 2026-03-30 (30 days)

This file provides universal guidance to Claude Code across all projects.

---

## Maintenance

When 30+ days have passed since "Last Updated":
1. Review this file for outdated conventions
2. Check project-specific CLAUDE.md files for new patterns worth globalizing
3. Update or remove sections that are no longer relevant
4. Update the "Last Updated" and "Next Review" dates

### Last Update Summary (2026-02-28)

Consolidated conventions from 13 project-specific CLAUDE.md files:

**Added to Global Config:**
- Python coding standards (type hints, error handling, Black formatting)
- Development workflow (Makefiles, venv, .env files, underscore conventions)
- .gitignore best practices (TODO.md ignored, secrets-first approach)
- Database conventions (dbt-focused, suggest not enforce)
- Documentation standards (CLAUDE.md, README.md, TODO.md)
- Command permissions (18 auto-approved read-only commands)
- Shell script conventions (from postgres-writeback patterns)
- API integration patterns (REST + GraphQL introspection workflow)

**Skipped for Now:**
- Testing standards (revisit if needed)
- Frontend conventions (rarely used)

**Configuration Files:**
- `~/.claude/CLAUDE.md` - This file (987 lines, 28KB)
- `~/.claude/settings.local.json` - Command auto-approval (18 commands)
- `~/.claude/CLAUDE_RECOMMENDATIONS.md` - Full recommendations for reference

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

- Follow PEP 257 for docstring formatting
- Include docstrings for all public modules, classes, and functions
- Include parameter descriptions, return values, and exceptions in docstrings

### Virtual Environments
- Name virtual environment folders `venv`, not `.venv`

### Type Hints
- Use type hints for function signatures
- Use type hints for complex variables
- Consider using mypy for type checking

### Error Handling
- Implement proper exception handling
- Log errors appropriately with context
- Don't suppress exceptions without logging
- Use specific exception types, not bare `except:`

### Imports
- All imports must be at the top of the file — no inline or lazy imports inside functions
- Follow standard ordering: stdlib, third-party, local (enforced by Ruff/isort)

### Code Formatting
- Use Ruff for formatting and linting (replaces Black, flake8, isort)
- Configure in `pyproject.toml` under `[tool.ruff]` (line-length=88)
- Run `ruff format .` and `ruff check --fix .` before committing
- If a project still uses Black, follow the project's convention

---

## Development Workflow

### Build Commands
- Document all build, test, and lint commands in project CLAUDE.md
- Prefer Makefiles for command organization
  - Common targets: `make build`, `make test`, `make lint`, `make run`
  - Keep targets simple and discoverable
  - Add help target: `make help`
- Alternative: Shell scripts for simpler projects

### Python Environment
- Use venv for Python virtual environments
- Name virtual environment folders `venv`
- Document setup in project CLAUDE.md or README
- Pin dependency versions: `pip freeze > requirements.txt`

### Docker Usage (Optional)
- Consider Docker for complex multi-service projects
- Document both Docker and local development options when available
- Use docker-compose.yml for multi-service setups

### Environment Configuration
- Use .env files for local configuration (git-ignored)
- Use environment variables for deployment configuration
- **Naming Convention**: Prefix environment variables with project/context identifier
  - Allows grouping with `set` or `printenv | grep PREFIX`
  - Example: `_PROJECT_TABLE_`, `_POSTGRES_`, `_SNOWFLAKE_`
- **Underscore Prefix**: Use underscore prefix for special/non-standard values
  - Calculated fields: `_first_name`, `_last_name`
  - Environment variables: `_POSTGRES_PASSWORD`, `_START_DATE`
  - SQL variables: `${_START_DATE}`
  - Bash special variables
- Document ALL required environment variables in CLAUDE.md or README
- Provide .env.example with dummy values
- Never commit secrets or credentials (use .gitignore)

### Pre-commit Checks
- Run Black formatter before committing Python code
- Run linters before committing (language-specific)
- Run tests before committing (when feasible)
- Document pre-commit workflow in CLAUDE.md

### Dependencies
- Pin dependency versions in production
- Document how to update dependencies
- Run tests after dependency updates
- Keep dependencies up to date for security

---

## .gitignore Best Practices

### Core Principles
- **Secrets first**: Always ensure secrets/credentials are ignored before creating them
- **Generated files**: Don't commit files that can be regenerated from source
- **Local environment**: Don't commit user-specific or machine-specific configurations
- **Dependencies**: Don't commit vendored dependencies (can be reinstalled)

### Standard Patterns to Always Ignore

**Python Artifacts**
```
__pycache__/
*.py[cod]
build/
dist/
wheels/
*.egg-info/
```

**Virtual Environments**
```
venv/
.venv/
virtualenv/
```

**IDE Files**
```
.idea/          # JetBrains (PyCharm, IntelliJ)
.fleet/         # Fleet
.vscode/        # VS Code
.zed/           # Zed
```

**OS Files**
```
.DS_Store               # Mac temp file
*:Zone.Identifier       # Windows download markers
```

**Secrets and Configuration**
```
.env                    # Environment variables with secrets
*_config.json           # Project-specific config files (adjust pattern as needed)
*.ini                   # If contains passwords
```

**Working Files (Local Only)**
```
TODO.md                 # Working memory for cross-session context
```

**Jupyter Artifacts**
```
.ipynb_checkpoints/
*/.ipynb_checkpoints/*
```

### Dependencies: setup.py vs requirements.txt
- If dependencies are managed in `setup.py` or `pyproject.toml`, ignore `requirements.txt`
- If using `requirements.txt` for dependencies, keep it in version control
- Pin versions for production deployments

### Project-Specific Patterns
Always add patterns for:
- Output files (`*_out*.txt`, `*.log`, `output/`)
- Temporary files (`*.tmp`, `*.tmp.txt`, `pq.tmp.txt`)
- Local development symlinks (`tap-wip`, symlinked checklists)
- Build artifacts specific to your tools

### Singer Tap/Target Projects
For Singer-based projects, ignore local config files:
```
tap_config.json
state.json
transform_config.json
transform_config.json.bak*
target_config.json
target_config_DEV.json
target_config_PROD.json
```

### When Creating Sensitive Files
1. **Before** creating files with secrets (.env, credentials, etc.):
   - Verify .gitignore exists
   - Verify pattern is included
   - If missing, add pattern to .gitignore first
2. Provide `.example` versions (e.g., `.env.example`) for documentation
3. Document required variables in CLAUDE.md or README

### Starting New Projects
- Use language-specific templates from GitHub as starting point
- Add patterns from this list that apply
- Customize for project-specific build artifacts
- Document non-obvious ignored files in README

### Reference
See: https://www.atlassian.com/git/tutorials/saving-changes/gitignore

---

## Database Conventions

**Note:** These conventions apply primarily to **dbt projects**. For application databases, conventions may differ based on framework (Django, Rails, etc.).

### dbt Naming Conventions

**Primary Keys**
- Suffix with `_id` (e.g., `company_id`, `user_id`, `account_id`)
- Use `id` alone only for the table's own primary key

**Timestamps**
- Suffix with `_at` (e.g., `created_at`, `updated_at`, `deleted_at`)
- Convert to UTC in standardized layer: `convert_timezone('UTC', field_name)`
- **Important**: Django app outputs `created_when`, `updated_when`, `deleted_when` - these should be renamed to `*_at` in dbt standardized layer

**Dates (without time)**
- Suffix with `_date` (e.g., `birth_date`, `hire_date`, `created_date`)

**Booleans**
- Prefix with `is_` or `has_` (e.g., `is_active`, `has_opted_in`, `is_deleted`)

**Field Names**
- Use lowercase_with_underscores (snake_case) for all fields
- Prefix calculated/derived fields with underscore when non-standard

### Suggesting vs Enforcing Conventions

**When working on dbt projects:**
1. **Suggest** dbt naming conventions when creating or modifying models
2. **Check** with user before enforcing conventions - we break these rules frequently enough to warrant asking
3. **Note** when existing code deviates from conventions, but don't automatically fix without permission
4. **Remind** about conventions when they seem forgotten, but respect user's choice to deviate

Example:
> "I notice this timestamp field is named `update_time`. Per dbt conventions, this would typically be `updated_at`. Should we follow the convention or keep it as is?"

### dbt Layer-Specific Standards

**Standardized Layer (`stnd_`)**
- Pull from `static_lake` source
- Convert timestamps to UTC with `_at` suffix
- Add `__record_is_deleted` and `is_deleted` columns
- Deduplicate using `QUALIFY row_number() OVER (...)`
- Prefix CTEs with `_cte_` (e.g., `_cte_unioned_sources`)
- End with `_cte_final` and `SELECT * FROM _cte_final`

**Staging Layer (`stg_`)**
- Reference corresponding `stnd_` model
- Apply soft-delete handling macro
- Ensure single row per primary key with QUALIFY when necessary
- Add `unique` and `not_null` tests for primary key

**Warehouse Layer**
- Reference corresponding `stg_` model
- Model name matches source table name from Postgres
- Apply soft-delete handling macro
- Full documentation with tests and field descriptions

### Standard Tracking Fields (dbt)
- `created_at` - timestamp when record created (UTC)
- `updated_at` - timestamp when record last updated (UTC)
- `deleted_at` - timestamp when record soft-deleted (UTC, null if active)
- `is_deleted` - boolean for soft delete status
- `__record_is_deleted` - internal tracking for deletions

### Reference
For complete dbt project standards, see the project-specific CLAUDE.md in your dbt repository

---

## Documentation Standards

### Code Documentation
- Follow language-specific documentation standards:
  - Python: PEP 257 for docstrings
  - JavaScript: JSDoc comments
  - Other: Language conventions
- Document all public APIs, classes, and functions
- Include examples in docstrings for complex functionality
- Document parameters, return values, and exceptions
- Document side effects and assumptions
- Keep documentation close to code (not separate docs that get stale)

### Project Documentation Files
- **CLAUDE.md**: Claude-specific instructions, architecture, conventions
  - Coding patterns and preferences
  - Build and test commands
  - Architecture decisions and context
  - Framework-specific patterns
- **README.md**: Human-readable project overview
  - What the project does
  - How to set up and run
  - Basic usage examples
  - Links to additional documentation
- **TODO.md**: Track work items and context for resuming work across sessions (git-ignored)
  - Use to help Claude pick up where you left off
  - Document blockers, decisions needed, next steps
  - Keep local only - don't version control

### Asking for Help
- When uncertain about requirements, ask the user instead of assuming
- Link to official documentation when available
- Reference specific files and line numbers when discussing code
- Provide context when asking questions

### Architecture Documentation
- Document key architectural decisions in CLAUDE.md
- Explain "why" not just "what"
- Include diagrams for complex architectures
- Document data flow and system boundaries
- Keep architecture docs updated with significant changes

---

## User Environment

### Custom Commands
- The human user has set up many custom aliases and commands that he uses on the terminal
- If instructed to run an unfamiliar command, use `which` or `alias` to understand it

### Remote Servers

**ETL Server:**
- When the user asks to check or run something on the ETL server, access it via `ssh etl`
- Requires VPN connection (user must be connected first)
- SSH config is already in place - no additional configuration needed

---

## Command Permissions

### Auto-Approved Commands

The following read-only commands are pre-approved and do not require user permission. These commands are safe, non-destructive, and commonly used for exploration and analysis.

**Configuration**: Auto-approval is configured in `~/.claude/settings.local.json`

### Pre-Approved Command Categories

**File Reading:**
- `cat` - Display file contents
- `head` - Display first lines of file
- `tail` - Display last lines of file
- `wc` - Count lines, words, characters

**File/Directory Listing:**
- `ls` - List directory contents
- `find` - Search for files and directories
- `pwd` - Print working directory

**Searching and Processing:**
- `grep` - Search text patterns
- `jq` - Process and query JSON data

**System Information:**
- `which` - Locate command binary
- `alias` - Show command aliases
- `whoami` - Display current user
- `date` - Display date and time

**Git Read Operations:**
- `git status` - Show working tree status
- `git log` - Show commit logs
- `git diff` - Show changes between commits
- `git branch` - List branches
- `git show` - Show commit details

### Commands That Require Approval

The following commands always require user permission, even if they appear read-only:

**Environment and Configuration:**
- `env` - Display environment variables (may contain secrets)
- `printenv` - Print environment variables (may contain secrets)
- `set` - Display shell variables (may contain secrets)

**Potentially Destructive Operations:**
- Any write operations (`rm`, `mv`, `cp`, `mkdir`, `touch`, etc.)
- Any git write operations (`git commit`, `git push`, `git add`, etc.)
- Package management (`pip install`, `npm install`, `brew install`, etc.)
- Process management (`kill`, `killall`, etc.)
- System modification (`chmod`, `chown`, `sudo`, etc.)

### Rationale

**Why auto-approve read-only commands:**
- Dramatically improves workflow efficiency
- These commands cannot modify files or system state
- Enables rapid exploration and debugging
- Based on analysis of actual usage patterns

**Why require approval for `env`:**
- Environment variables often contain sensitive information (API keys, passwords, tokens)
- Values should only be exposed when explicitly needed
- User should be aware when environment is being inspected

### Modifying Auto-Approved Commands

To add or remove commands from the auto-approval list, edit `~/.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(command:*)",
      "Bash(git subcommand:*)"
    ]
  }
}
```

**Pattern Syntax:**
- `Bash(command:*)` - Auto-approve all uses of command
- `Bash(git status:*)` - Auto-approve specific git subcommand
- Wildcard `*` matches any arguments

**Note:** Changes to `settings.local.json` take effect immediately; no restart required.

---

## Versioning

### Semantic Versioning

For projects that publish packages (PyPI, npm, etc.), follow [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`

- **MAJOR** — breaking changes (renamed commands/APIs, changed config format, dropped features)
- **MINOR** — new features, backwards-compatible (new commands, new config options, new modules)
- **PATCH** — bug fixes, docs-only changes, no behavior change

Pre-1.0 (`0.x.y`) signals the project is in active development and the interface may change.

### When to Prompt About Version Bumps

**Always suggest a version bump** when committing work that changes behavior:
- New feature added → suggest minor bump (`0.1.0` → `0.2.0`)
- Bug fix → suggest patch bump (`0.2.0` → `0.2.1`)
- Breaking change → suggest major bump (`0.2.1` → `1.0.0`)

**Don't bump automatically** — ask the user first. They may want to batch multiple changes into a single version bump.

**Don't bump for:**
- Docs-only changes (README, CLAUDE.md) unless they're part of a release
- Test additions with no behavior change
- Internal refactoring with no user-facing impact

---

## Git Commit Conventions

### Commits Are Atomic Actions

**IMPORTANT**: Treat git commits as discrete, user-approved actions - never chain them automatically.

**Do NOT:**
```bash
# Don't chain commits to the end of other operations
stow -R common && git add . && git commit -m "message"
```

**Do:**
```bash
# Complete the work first
stow -R common

# Then, separately, ask about committing
```

### Always Ask Before Committing

- **Never commit automatically** after completing a task
- **Always prompt the user** to see if they'd like to commit
- Commits should be explicit user decisions, not automated side effects

**Good pattern:**
> "The changes are complete and tested. Would you like me to commit these changes?"

**Bad pattern:**
> Silently running `git commit` as part of a command chain

### Prompt for Feature Branches on Main

Before making changes on the main branch (or master - check `git config init.defaultBranch` or inspect remote), prompt the user to create a feature branch:

> "You're on the main branch. Would you like to create a feature branch for these changes? This allows you to merge via PR when done.
>
> Also, are you working on a specific Jira card?"

**When to prompt:**
- Before the first file modification in a session
- When the user asks to implement a feature or fix
- NOT for trivial one-off changes the user explicitly wants on main

**Branch naming:**
- If Jira card: `DATA-1234_fix_specific_issue` (card number + brief description)
- Otherwise use conventional prefixes:
  - `feature/<description>` - new functionality
  - `fix/<description>` - bug fixes
  - `chore/<description>` - maintenance, refactoring

### Rationale

- Commits are permanent history - users should consciously decide when to create them
- Users may want to review changes, make additional edits, or group commits differently
- Automatic commits can create noisy, poorly-organized git history
- The user maintains full control over their repository's commit history
- Feature branches enable code review via PRs and keep main stable

### Post-Merge Branch Cleanup

After merging a branch (locally or via PR), suggest running the `clean` command to tidy up stale branches. Do NOT run it automatically — just remind the user.

**When to suggest:**
- After a local merge into main/master
- After a PR is merged on GitHub
- When switching back to the default branch and stale branches are likely

**What to suggest:**
- `clean` — delete local branches already merged into main/master
- `clean -r` — also delete merged remote branches (GitHub repos only; skips Bitbucket)
- `clean -n` — dry run to preview what would be deleted

**Example:**
> "The merge is complete. Want to run `clean` to tidy up local merged branches? If you'd also like to prune merged remote branches, use `clean -r` (or `clean -n` to preview first)."

---

## Shell Script Conventions

### Variable Naming
- Prefix internal/implementation variables with underscore (e.g., `_internal_var`)
- Use UPPERCASE for environment variables and constants (e.g., `API_KEY`, `MAX_RETRIES`)
- Use lowercase for local variables (e.g., `user_name`, `temp_file`)
- Use `readonly` for constants that should never change

### Function Naming
- Use descriptive names for public functions (e.g., `deploy_application`, `backup_database`)
- Prefix internal functions with underscore (e.g., `_validate_input`)
- Use verb-noun naming pattern (e.g., `get_user`, `set_config`, `log_info`, `check_file_exists`)

### Script Structure

**Header Documentation Block**
Every script should start with a comprehensive header:
```bash
#!/usr/bin/env bash
################################################################################
# Script Name and Purpose
#
# Detailed description of what this script does, when to use it, and any
# important context or warnings.
#
# USAGE:
#   ./script_name.sh [--option value] [arguments]
#
# OPTIONS:
#   --option1   Description of option1
#   --option2   Description of option2 (default: value)
#
# EXAMPLES:
#   ./script_name.sh --option1 value           # Example 1
#   ./script_name.sh --option1 val --option2   # Example 2
#
# DEPENDENCIES:
#   - Required tools (psql, jq, etc.)
#   - Required files or config
#
# NOTES:
#   - Performance characteristics
#   - Safety considerations
#   - Known limitations
################################################################################
```

**Script Initialization Pattern**
```bash
set -euo pipefail  # Strict mode: exit on error, undefined vars, pipe failures

# Find script directory and repository root (reliable across symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"

# Parse arguments (including --target) BEFORE loading config
TARGET_ARG=""
OPTION_ARG=""
while [ $# -gt 0 ]; do
    case "$1" in
        --target)
            TARGET_ARG="--target $2"
            shift 2
            ;;
        --option)
            OPTION_ARG="--option $2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--target value] [--option value]" >&2
            exit 1
            ;;
    esac
done

# Load shared infrastructure
source "${REPO_ROOT}/config/shared_config.sh"
source "${REPO_ROOT}/lib/common_functions.sh"

# Setup cleanup trap
cleanup() {
    local exit_code=$?
    if [ ${exit_code} -ne 0 ]; then
        log_error "Script failed with exit code ${exit_code}"
    fi
    # Cleanup actions here
}
trap cleanup EXIT
```

### Strict Mode
Always use `set -euo pipefail` at the top of scripts:
- `-e`: Exit immediately if a command exits with non-zero status
- `-u`: Treat unset variables as errors
- `-o pipefail`: Return value of pipeline is status of last command to exit with non-zero

### Logging Functions
Create consistent logging functions with timestamps and colors:
```bash
# Color codes (define as readonly constants)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'  # No Color

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}
```

### File and Tool Validation
Provide helpful validation functions:
```bash
# Check if file exists and is readable
check_file_exists() {
    local file="$1"
    local description="${2:-File}"

    if [ ! -f "${file}" ]; then
        log_error "${description} not found: ${file}"
        return 1
    fi

    if [ ! -r "${file}" ]; then
        log_error "${description} is not readable: ${file}"
        return 1
    fi

    return 0
}

# Validate required tools are installed
validate_tools() {
    local missing_tools=()

    for tool in psql jq curl; do
        if ! command -v "${tool}" >/dev/null 2>&1; then
            missing_tools+=("${tool}")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Install with: brew install ${missing_tools[*]}"
        return 1
    fi

    return 0
}
```

### Error Handling
```bash
# Always use trap for cleanup
cleanup() {
    local exit_code=$?
    [ ${exit_code} -ne 0 ] && log_error "Script failed"
    # Remove temp files, cleanup credentials, etc.
}
trap cleanup EXIT

# Validate before proceeding
check_file_exists "${CONFIG_FILE}" "Config file" || exit 1
validate_tools || exit 1

# Check exit codes explicitly for critical commands
if ! critical_command; then
    log_error "Critical command failed"
    exit 1
fi
```

### Argument Parsing Pattern
Use systematic case-based argument parsing:
```bash
TARGET_ARG=""
LIMIT_ARG=""
FLAG_ARG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --target)
            TARGET_ARG="--target $2"
            shift 2
            ;;
        --limit)
            LIMIT_ARG="--limit $2"
            shift 2
            ;;
        --flag)
            FLAG_ARG="--flag"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Forward arguments to child scripts
./child_script.sh ${TARGET_ARG} ${LIMIT_ARG} ${FLAG_ARG}
```

### Visual Formatting
Use Unicode box-drawing characters for visual sections:
```bash
# Box-drawing characters (define as readonly constants)
readonly BOX_H="═"  # Horizontal
readonly BOX_V="║"  # Vertical
readonly BOX_TL="╔"  # Top-left
readonly BOX_TR="╗"  # Top-right
readonly BOX_BL="╚"  # Bottom-left
readonly BOX_BR="╝"  # Bottom-right

log_box_header() {
    local message="$1"
    echo -e "${BLUE}${BOX_TL}$(printf "${BOX_H}%.0s" {1..64})${BOX_TR}${NC}"
    printf "${BLUE}${BOX_V}${NC} %-62s ${BLUE}${BOX_V}${NC}\n" "${message}"
    echo -e "${BLUE}${BOX_BL}$(printf "${BOX_H}%.0s" {1..64})${BOX_BR}${NC}"
}
```

### Directory Resolution
Use this pattern for reliable script directory resolution (works with symlinks):
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
```

### Constants and Configuration
- Use `readonly` for constants that should never change
- Define constants at the top of the script (after sourcing config)
- Use meaningful names with uppercase and underscores
```bash
readonly TARGET_TABLE="public.customers"
readonly BATCH_SIZE=5000
readonly MAX_RETRIES=3
```

### Documentation and Comments
- Use `#` for single-line comments
- Use multi-line `###...###` blocks for section headers
- Document non-obvious logic with comments
- Explain WHY, not just WHAT
- Include performance characteristics in header comments
```bash
################################################################################
# Phase 2: Load data into database
#
# This phase uses COPY for fast bulk loading, then batched updates with
# commit-per-batch for resilience. Each batch commits independently, so
# interrupted runs can resume without re-processing completed batches.
################################################################################
```

### Exit Codes
Use meaningful exit codes:
- `0`: Success
- `1`: General error
- `2`: Misuse of shell command (invalid arguments)
- Other codes for specific error conditions (documented in header)

---

## API Integration Best Practices

### Authentication
- Store tokens securely (environment variables or .env files)
- Never hardcode credentials in code
- Implement token refresh logic where supported
- Handle authentication failures gracefully
- Re-authenticate automatically when possible

### Rate Limiting
- Implement rate limiting for external API calls
- Add exponential backoff for retries
- Log rate limit events for monitoring
- Respect API rate limit headers (e.g., `X-RateLimit-Remaining`)
- Consider queueing requests to stay under limits

### Error Handling
- Parse and log API error responses
- Implement circuit breaker patterns for failing APIs
- Provide meaningful error messages to users
- Distinguish between client errors (4xx) and server errors (5xx)
- Retry transient failures (500, 502, 503, 504), fail fast on permanent errors (400, 401, 404)

### Request/Response Patterns
- Use connection pooling for efficiency
- Set appropriate timeouts (avoid hanging indefinitely)
- Log request/response for debugging (sanitize sensitive data like tokens, passwords)
- Validate responses against expected schema
- Handle partial failures in batch operations

### Testing
- Mock external APIs in tests
- Use recorded responses for integration tests (VCR pattern)
- Test error scenarios (timeouts, rate limits, auth failures)
- Document API dependencies in tests

---

## GraphQL-Specific Patterns

### GraphQL Introspection

**IMPORTANT**: When working with GraphQL APIs, **ALWAYS offer to introspect the API first** before implementing queries or making schema changes.

**What is Introspection:**
GraphQL has a built-in schema discovery mechanism that allows you to query the API to understand:
- Available types (objects, interfaces, enums)
- Fields on each type
- Field types and nullability
- Available queries and mutations
- Relationships between types (navigation properties)

**When to Use Introspection:**
1. **Starting a new GraphQL integration** - Understand the full schema before writing queries
2. **Adding new fields or streams** - Verify fields exist and understand their types
3. **Investigating data model relationships** - Discover navigation paths between types
4. **Debugging unexpected responses** - Confirm expected fields are actually available
5. **Before schema changes** - Document what changed (fields added/removed)

**Standard Introspection Pattern:**

```python
#!/usr/bin/env python3
"""GraphQL Schema Introspection Script"""

import requests
import json
import os
from dotenv import load_dotenv

load_dotenv()

# Configuration from environment
API_URL = os.getenv('GRAPHQL_API_URL')
AUTH_TOKEN = os.getenv('GRAPHQL_AUTH_TOKEN')  # Or authenticate first

# GraphQL introspection query for a specific type
introspection_query = """
{
  __type(name: "TypeName") {
    name
    description
    fields {
      name
      description
      type {
        name
        kind
        ofType {
          name
          kind
        }
      }
    }
  }
}
"""

headers = {
    'Authorization': f'Bearer {AUTH_TOKEN}',
    'Content-Type': 'application/json'
}

response = requests.post(
    f"{API_URL}/graphql",
    headers=headers,
    json={'query': introspection_query},
    timeout=10
)

result = response.json()

# Save introspection results
with open('typename_introspection.json', 'w') as f:
    json.dump(result, f, indent=2)

print(f"✅ Introspection saved to typename_introspection.json")

# Extract and display field names
if 'data' in result and result['data'].get('__type'):
    fields = [f['name'] for f in result['data']['__type'].get('fields', [])]
    print(f"Available fields ({len(fields)}):")
    for field in fields:
        print(f"  - {field}")
```

**Full Schema Introspection:**

For complete schema discovery, use the standard introspection query:

```graphql
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      args {
        ...InputValue
      }
    }
  }
}

fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}

fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
}

fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
      }
    }
  }
}
```

### GraphQL Workflow Pattern

When working with GraphQL APIs, follow this workflow:

1. **Introspect First**: Run introspection to understand schema
2. **Document Findings**: Save introspection results as JSON files (e.g., `user_introspection.json`)
3. **Analyze Relationships**: Understand navigation properties (one-way vs bidirectional)
4. **Test Queries**: Build small test queries to validate understanding
5. **Implement Queries**: Write production queries based on verified schema
6. **Track Changes**: Document schema changes in project (e.g., `API_SCHEMA_CHANGES.md`)

**Example Documentation Pattern:**

When introspection reveals important findings, document them in CLAUDE.md or README.md:

```markdown
### Data Model for UserType:

```
UserType (reference table)
├── userTypeId: Int!
├── description: String! (e.g., "Premium", "Basic", "Trial")
├── organizationId: Int!
└── userTypeInstances: [UserTypeInstance] ← Junction table

UserTypeInstance (many-to-many junction)
├── userTypeInstanceId: Int!
├── userId: Int                      ← Links to User
├── userTypeId: Int!                 ← Links to UserType
├── organizationUserId: Int!         ← Links to OrganizationUser
```

### Critical Discovery:
- ❌ User does NOT have a direct userTypeId field
- ✅ UserTypeInstance is the junction table linking users to types
- ⚠️  One-way navigation only: UserType → UserTypeInstance → User
```

### GraphQL-Specific Considerations

**Navigation Properties:**
- Some relationships are one-way only (can't query backwards)
- Use introspection to verify which navigation paths exist
- Document one-way limitations in project README

**Pagination:**
- Many GraphQL APIs use cursor-based pagination
- Standard pattern: `first: N`, `after: cursor`, `pageInfo { hasNextPage, endCursor }`

**Required Parameters:**
- Some queries require filter parameters even if empty (e.g., `filter: {}`)
- Use introspection to discover required arguments
- Document mandatory parameters in CLAUDE.md

**Batching:**
- GraphQL allows requesting multiple resources in one query
- Use this for efficiency (e.g., query user + their orders in one call)

### When Claude Should Offer Introspection

**Automatic Offer** - Claude should proactively suggest introspection when:
1. User mentions starting work on a new GraphQL API
2. User asks about available fields or data structure
3. User encounters unexpected "field not found" errors
4. User asks to add new fields to existing queries
5. User mentions schema changes or API updates

**Suggested Wording:**
> "Before we implement these queries, I recommend introspecting the GraphQL API to understand the available schema. This will help us:
> - Verify which fields actually exist
> - Understand field types and nullability
> - Discover navigation relationships
> - Document the data model
>
> Would you like me to create an introspection script?"

### Introspection File Naming Convention

Save introspection results with clear naming:
- `{typename}_introspection.json` - Schema for specific type
- `{typename}_introspection_dev.json` - Dev environment schema
- `{typename}_introspection_prod.json` - Prod environment schema
- `{typename}_data_sample.json` - Sample data from actual query

Examples:
- `user_introspection_dev.json`
- `product_introspection_dev.json`
- `order_introspection.json`
- `orderitem_data_sample.json`

---

## Snippets Repository

The user maintains a personal code snippets repository at `~/projects/snippets` with script-driven CRUD operations designed for both human and AI (Claude Code) usage.

### Repository Location

- **Path**: `~/projects/snippets`
- **Documentation**: See `~/projects/snippets/CLAUDE.md` for full integration guide

### Quick Reference

**Copy snippet to clipboard by UUID:**
```bash
~/projects/snippets/get <uuid>
~/projects/snippets/get --list  # List all IDs
```

**Add new snippet (Claude Code):**
```bash
~/projects/snippets/.scripts/add.py \
  --title "My Snippet" \
  --language sql \
  --tags "tag1,tag2" \
  --description "What it does" \
  --code "SELECT 1" \
  --format json
```

**Search snippets:**
```bash
~/projects/snippets/.scripts/search.py --tag dbt --format json
~/projects/snippets/.scripts/search.py --language sql --format json
```

### When to Use Snippets Repository

**Offer to save code as snippet when:**
- You write reusable code for the user
- User asks to "save this for later"
- User pastes code they want to preserve
- You create a useful pattern or template
- You help the user refine a long, complex, or obscure command through iteration (e.g., multi-flag CLI invocations, piped commands, one-liners). Once the final version works, prompt: "Want me to save this as a snippet?"

**Search snippets before writing new code when:**
- User asks for something that might already exist
- You need a common pattern (dbt models, API clients, etc.)
- User mentions they "have a snippet for this"

### Frontmatter Schema (v3)

All snippets have YAML frontmatter:
```yaml
---
id: <uuid4>              # For quick clipboard access
title: "Title"
language: "sql"          # sql | python | shell | yaml | toml | json | markdown | text
tags: [tag1, tag2]
description: "One sentence"
created: "YYYY-MM-DD"
last_updated: "YYYY-MM-DD"
---
```

### Claude Code Integration

- Always use `--format json` for programmatic operations
- Parse JSON responses and report results to user
- New snippets auto-generate UUIDs
- Check for duplicates with `search.py` before adding

---

## SEO Awareness When Making Website Changes

When making changes to any website or web application project, consider the
SEO implications before proceeding. Flag potential issues in your response,
but continue with the requested changes unless instructed otherwise.

### Check for the following when modifying pages:

**URL / Routing changes**
- If a page's route or slug is being changed, verify that a 301 redirect is
  defined from the old path to the new one (framework-specific: e.g.
  `next.config.js` redirects, `.htaccess`, server config, or middleware).
  Flag if one is missing.

**Page deletions**
- If a page is being deleted, check whether it had an established route.
  If so, flag that a 301 redirect should be added pointing to the most
  relevant replacement page, or to `/` as a fallback.

**Title and meta description changes**
- If page titles or meta descriptions are being changed, flag this and note
  the previous values so they can be compared. Avoid making these changes
  speculatively or as a side effect of unrelated work.

**Structural / navigation changes**
- If changes affect the site's navigation, internal linking, or page
  hierarchy, note the potential crawl impact. Large structural changes can
  affect how search engines discover and prioritize pages.

**Content removal or reduction**
- If substantial content is being removed from a page (not just edited), flag
  it. Thin content can negatively affect rankings for that page.

**New pages**
- When adding new pages, confirm that a page title and meta description are
  defined, and that the page is reachable via internal links or a sitemap.

### General guidance
- Do not change URLs, titles, or meta descriptions as a side effect of
  unrelated tasks without flagging it first.
- When in doubt, flag the concern and let the user decide.
