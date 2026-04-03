# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [8.0.0] - 2026-04-03

### Breaking Changes
- Pipeline templates: `<!-- version -->` HTML comment replaced with YAML frontmatter
- `bump-version.sh` updated — uses `sed` on YAML frontmatter for pipelines instead of HTML comments
- Pipelines validated against `version: "8.0.0"` — all `< 8.0.0` trigger `[REGEN]`

### Added
- **YAML frontmatter in pipelines** — `name`, `description`, `version`, `phases`, `capture`, `triggers`, `error_routing`, `adaptive_teams`, `chains` fields. Enables machine-readable pipeline metadata and self-describing router triggers
- **Include mechanism** — `{CAPTURE:full/partial/review}`, `{PARALLEL_PER_LANG}`, `{CAPABILITY_DETECT}` placeholders resolved from `templates/includes/` at generation time
- **Agent Teams (adaptive)** in 5 pipelines: new-code, fix-code, tests, review, brainstorm. Phase 0 detects `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, dual "Режим TEAM / Режим SEQUENTIAL" branches, automatic fallback
- **File-based communication** for team mode — agents read/write `.claude/output/` as message bus; reviewer returns BLOCK via verdict file, developer reads and fixes
- **brainstorm pipeline** (9th pipeline) — FRAME → PERSPECTIVES → CAPTURE. Team mode: analyst + architect + storage-architect + devops discuss in parallel. Sequential fallback
- **Error matrix** in all 9 pipelines (was only in new-code)
- **`error_routing` in frontmatter** — formalized error handling rules (`retry_current`, `retry_from:N`, `stop_and_report`, `fallback_sequential`, `skip_capture`, `prerequisite:pipeline`)
- **`triggers` in frontmatter** — pipeline keywords for router classification, self-describing instead of hardcoded table
- **`mode` field in agent frontmatter** — `"plan"` (read-only, 6 agents) or `"implement"` (writes project files, 2 agents: developer, test-developer)
- **Task() syntax spec** — `templates/includes/task-syntax.md`, 4 mandatory fields: Вход, Выход, Ограничение (`read-only`/`project-write`), Верни
- **Placeholder registry** — `templates/includes/placeholder-registry.md`, 50+ variables with source mapping
- **`capture-full.md`**, **`capture-partial.md`**, **`capture-review.md`** — deduplicated CAPTURE phase from 5 pipelines into 3 include files
- **`parallel-per-lang.md`** — deduplicated per-lang parallelization rule from 4 pipelines
- **BRAINSTORM in pipeline router** — added to intent classification table and fallback options

### Changed
- All 9 pipelines rewritten with YAML frontmatter, standardized Task() format, include placeholders
- Step-8 generators (lang, common, infra) updated: know about frontmatter, includes, `mode` field, Task() format
- Step-8 adaptive teams: generators no longer inject dual modes on-the-fly — templates are self-contained
- Validation rules: check YAML frontmatter presence, `adaptive_teams` ↔ Phase 0 consistency
- Pipelines: 8 → 9 (added brainstorm)

### Fixed
- Inconsistent frontmatter quoting in `p.md` and `pipeline.md` skills (unquoted `name:` → quoted)
- Malformed placeholder in `storage.md:71` (`{STORAGE_ANTIPATTERNS — адаптируй:...}` → `{STORAGE_ANTIPATTERNS}`)
- `bump-version.sh` verification: `head -1` → `grep -m1 'version:'` for pipeline version check

## [7.3.1] - 2026-04-03

### Changed
- Steps 3 & 5 orchestrator phases: explicit imperative tone to prevent LLM skipping phases
- Control checks after apply phase (verify state not empty)
- Renumbered phases: 3A/3B/3C and 5A/5B/5C

## [7.3.0] - 2026-04-02

### Changed
- **Anti-loop architecture**: steps 3 & 5 refactored to three-phase pattern (scan → ask → apply). Subagent collectors return JSON, never call AskUserQuestion. Orchestrator batches questions, eliminates resume-loop
- **Templates path flatten**: `prompts/bootstrap/templates/` → `templates/`
- Batch AskUserQuestion in step-3 (4 questions in one call)
- Batch AskUserQuestion in step-4 validate mode (1 question)

### Fixed
- step-1 initial state missing step "10"
- step-9 misleading comment ("last of step 8")
- step-10 reference to nonexistent "step 9.5"
- All path references updated (CLAUDE.md, bump-version.sh, SKILL.md)

## [7.2.1] - 2026-04-02

### Fixed
- AskUserQuestion schema: `questions` array + `multiSelect` required field
- Deferred tools: AskUserQuestion schema + SendMessage summary format

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

## [7.0.0] - 2026-04-02

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

## [6.0.1] - 2026-03-30

### Added
- `marketplace.json` for self-hosted plugin distribution
- `install.sh` and `commands/bootstrap.md` for one-step legacy install

## [6.0.0] - 2026-03-30

### Added
- **Claude Code Plugin** — plugin manifest (`.claude-plugin/plugin.json`)
- Command → Skill migration (`commands/bootstrap.md` → `skills/bootstrap/SKILL.md`)
- English versions: `README.en.md`, `CLAUDE.en.md`
- `PRIVACY.md` (no data collection, all local)

## [5.4.2] - 2026-03-17

### Changed
- AskUserQuestion for all interactive prompts in bootstrap and runtime
- Teams API: natural language Teammate syntax instead of deprecated TeamCreate/Spawn/Shutdown

## [5.4.1] - 2026-03-17

### Added
- Template versioning — `version` field in skill/pipeline frontmatter
- Auto-`[REGEN]` for outdated skills/pipelines in validate mode

## [5.4.0] - 2026-03-17

### Added
- **Analyst agent** (`analyst.md`) — technical analysis, reads code/schema/infra, creates spec
- Phase 1 ANALYSIS in new-code and full-feature pipelines
- Pipeline router: skip-analysis flag (`--no-analysis`, `--skip-analyst`)

## [5.3.0] - 2026-03-13

### Added
- File-based context: agents write results to `output/plans/` and `output/reviews/`, return summary only
- Sectional CAPTURE: REPLACE/MERGE semantics for `facts.md` with dedup rules
- Pipeline router: structured context collection via AskUserQuestion (Step 3.5)
- Plan approval in fix-code and tests pipelines
- Stack tables extracted to `includes/stack-adaptations.md`

### Changed
- Architect agent enforced PLAN MODE — no file creation/modification
- Orchestrator converted to Task() dispatcher with parallel step-4/4b/4c
- All step files have input/output contracts
- `issues.md`: 30-row limit, frequency dedup
- `maintain-memory.sh`: dead link cleanup, issues compaction, `output/` rotation

## [5.2.0] - 2026-02-23

### Changed
- Hook system refactor: 5 → 3 hooks
- Removed `git-context.sh` (Claude Code has native git access)
- Removed `session-summary.sh` (generated unused reports)
- `track-agent.sh`: `grep -oP` → `jq capture()`, drop session_id/char counters
- `maintain-memory.sh`: drop file init, POSIX-only commands, env var thresholds
- `update-schema.sh`: credentials via `docker exec printenv`, staleness check
- `settings.json.tpl`: hooks integrated, Stop section removed

## [5.1.0] - 2026-02-23

### Changed
- Cleanup README: remove generated output descriptions (Invocable Skills, Pipeline-система, Memory-система, Hooks, MCP, Кастомизация)
- Fix `state/` → `memory/` references

## [5.0.0] - 2026-02-16

### Added
- **Adaptive Teams** — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env detection
- `includes/capability-detect.md` — Phase 0 for team/sequential mode selection
- Team mode sections in new-code and review pipelines
- Graceful degradation: team spawn fail → sequential fallback

## [4.0.0] - 2026-02-15

### Changed
- **Modular architecture** — monolithic meta-prompt extracted into 5 step files + templates/
- step-4-generate (638 lines) split into 3 batches: agents, skills+pipelines, hooks+settings+MCP
- Fixes context window overflow on late generation steps
- Orchestrator runs 7 sequential steps with compression between batches

## [3.0.0] - 2026-02-13

### Added
- **Optional GitLab MCP integration** — `.mcp.json` generation, `gitlab-manager` agent, `skills/gitlab/SKILL.md`

## [2.1.0] - 2026-02-13

### Changed
- Replace text-based questions (y/n, comma-separated) with structured AskUserQuestion calls
- Two-step flow for custom agents/skills/pipelines with multiSelect support

## [2.0.0] - 2026-02-13

### Added
- **Pipeline skill-router** (`/pipeline`, `/p`) replaces passive routing
- **Memory system**: `patterns.md`, `issues.md`, `maintain-memory.sh`
- Verification moved to `scripts/verify-bootstrap.sh`
- Upgrade mode with SHA256 diff detection
- `git-context.sh` hook, CI Manager agent, input templates
- Error handling (`trap ERR`) in all hooks
- Auto-Pipeline Rule in CLAUDE.md template

### Removed
- Dead `session.md` and `task-log.md`

## [1.0.0] - 2026-02-10
- Initial commit — bootstrap system with meta-prompt, agents, commands
