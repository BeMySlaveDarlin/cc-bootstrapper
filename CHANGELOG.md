# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [7.2.0] - 2026-04-02

### Added
- **Step 5: Plugins & MCP** — per-plugin AskUserQuestion with install instructions (Playwright, Context7, LSP, GitLab MCP, GitHub MCP, Docker MCP)
- **GitHub MCP** support with token configuration and .mcp.json generation
- **Docker MCP** support via mcp-docker-server
- **Per-lang parallelism** in pipelines: new-code, review, tests, fix-code run per-language reviewers/developers in parallel
- **Git permissions granularity**: read/write/push/delete as separate multiSelect options
- **Settings.json before plugins** (step 4→5): base permissions generated first, plugins append MCP permissions after installation

### Changed
- Bootstrap flow: 8 → 9 steps (added step 5 plugins, settings moved to step 4)
- Step order: scan → detect → configure → settings → plugins → preview → analyze → generate → finalize
- Generation step: per-artifact-type (6a/6b/6c) → per-domain (8-lang/8-common/8-infra)
- Removed Adaptive Teams from v7 scope (deferred)
- Docker permissions moved from configure to plugins step (MCP-based, not Bash)
- Agents write artifacts to files BEFORE returning summary ("write first" pattern)
- Removed legacy `commands/bootstrap.md` — skill-only invocation
- Removed all recommendations from finalize step

### Fixed
- `${CLAUDE_SKILL_DIR}` resolution for subagent step files
- settings.json format: `Bash(command:*)` syntax, hooks with matcher+hooks array
- bump-version.sh exit code on non-dry-run
- State file path: `.bootstrap-cache/state.json`

## [7.0.0] - 2026-04-XX

### Breaking Changes
- Bootstrap flow redesigned: 5 steps → 7 atomic subagent steps
- Agent templates: 12 → 8 (frontend-* removed, reviewers merged)
- `database` skill/agent renamed to `storage`
- Step files renamed (step-1..5 → step-1..7 with sub-steps)

### Added
- **Checkpoint/Resume**: `.bootstrap-state.json` + `.bootstrap-cache/` persist progress between sessions
- **Analysis Depth**: 3 levels (light/standard/deep) — user chooses token budget
- **Dry-Run Preview**: file counts, token estimates, artifact list before generation
- **Pause Point**: manual pause after planning step, resume via `/bootstrap`
- **Plugin Recommendations**: detect useful plugins (Playwright, context7, docker, LSP), show install commands
- **Settings Diff-Merge**: `[KEEP]/[+ADD]/[-DEL]/[USER]` markers, per-permission approval
- **Permission Levels**: conservative / balanced / permissive
- **Progress Indicators**: `[N/7] Step Name ✓` after each step
- **Git Commit Reminder**: before generation start
- **Custom File Protection**: `[USER]` marker in validate mode for unknown files
- **CHANGELOG.md**: version history
- **bump-version.sh**: automated version bump across all files

### Changed
- `{lang}-reviewer-logic` + `{lang}-reviewer-security` → single `{lang}-reviewer` (architecture, logic, security, static analysis, optimization)
- `db-architect` → `storage-architect` (SQL, NoSQL, Redis, S3, queues) — conditional on storage detection
- `devops` expanded: host machine support (WSL, native Linux, macOS)
- `qa-engineer` expanded: Playwright E2E, manual testing, smoke tests
- `review` pipeline simplified: single reviewer, no TEAM/SEQUENTIAL modes
- `new-code` pipeline: Phase STORAGE replaces Phase DATABASE
- `qa-docs` pipeline: +Playwright E2E stubs
- CLAUDE.md generation moved to end of step-6 (tables reflect actual generated files)
- All questions collected in single step-3 block (was spread across steps)
- Each step runs as isolated subagent (conversation context not used)

### Removed
- `frontend-developer`, `frontend-reviewer`, `frontend-test-developer` agents (covered by `{js/ts}-*`)
- `{lang}-reviewer-logic`, `{lang}-reviewer-security` (merged into `{lang}-reviewer`)

## [6.0.1] - 2026-03-31
- Marketplace + legacy install script

## [6.0.0] - 2026-03-30
- Claude Code Plugin — marketplace release

## [5.4.2] - 2026-03-29
- AskUserQuestion everywhere
- Teams API update (natural language instead of TeamCreate/Spawn)
