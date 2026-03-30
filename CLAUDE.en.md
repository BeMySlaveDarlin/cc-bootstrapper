# CLAUDE.md

[Русский](CLAUDE.md)

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

cc-bootstrapper — Claude Code automation bootstrap system. Analyzes any project and generates a complete `.claude/` automation structure with pipeline routing.

- Markdown + Bash (prompt templates, shell hooks)
- Claude Code CLI framework
- Modular architecture: orchestrator + bootstrap/ templates
- No DB, no container

## Rules

- Brief, to the point, no theory
- Code — only on direct request
- No docblocks or comments in code unless required for static analysis
- No git commit or git push unless asked
- All prompts and templates are in Russian
- Shell scripts use `jq` for JSON, `$CLAUDE_PROJECT_DIR` for paths
- Agent naming: `{lang}-{role}.md` (e.g., `php-developer.md`)
- **CRITICAL:** The `skills/pipeline/` directory name must be copied AS-IS. DO NOT rename.

## Installation

### As a Plugin (recommended)
```bash
# In Claude Code CLI
/install-plugin cc-bootstrapper
```

### Manual (legacy)
```bash
cp prompts/meta-prompt-bootstrap.md ~/.claude/prompts/
cp -r prompts/bootstrap ~/.claude/prompts/
```

### Usage
```
/cc-bootstrapper:bootstrap    # Plugin mode
```

### Verification
```bash
for dir in agents skills pipelines scripts/hooks memory input; do [ -d ".claude/$dir" ] && echo "[OK] $dir" || echo "[MISS] $dir"; done
```

## Architecture

### Module Structure
```
.claude-plugin/
  plugin.json                           # Plugin manifest
skills/
  bootstrap/
    SKILL.md                            # /cc-bootstrapper:bootstrap — entry point
prompts/
  meta-prompt-bootstrap.md              # Orchestrator — reads steps sequentially
  bootstrap/
    step-1-analyze.md                   # Stack analysis
    step-2-claude-md.md                 # CLAUDE.md generation with routing rule
    step-3-plan.md                      # Interactive planning (registries)
    step-4-generate.md                  # Generation batch 1: directories + agents
    step-4b-generate.md                 # Generation batch 2: skills + pipelines
    step-4c-generate.md                 # Generation batch 3: hooks, settings, memory, MCP
    step-5-verify.md                    # Verification + final report
    templates/
      agents/                           # 11 agent templates
      skills/                           # 7 skill templates (incl. pipeline routing)
      pipelines/                        # 8 pipeline templates with Task() syntax
      hooks/                            # 3 hook scripts
      settings.json.tpl                 # Settings template (permissions + hooks)
      verify-bootstrap.sh               # Verification script
```

### Key Principles
- Modular architecture: skill → orchestrator → step files → templates
- Pipeline routing: HARD RULE in CLAUDE.md + `/pipeline` skill with frontmatter `user-invocable: true`
- Task() pseudo-syntax for calling agents in pipelines
- Two modes: `fresh` (full generation) and `validate` (check + auto-fix)
- 7 steps: Analysis → CLAUDE.md → Planning → Generation (3 batches) → Verification

### Main Modules

**Skill (`skills/bootstrap/SKILL.md`):**
- Direct path to meta-prompt via `${CLAUDE_SKILL_DIR}`
- Custom meta-prompt support via `$ARGUMENTS`
- Auto-detect mode: `fresh` (no `.claude/`) or `validate` (`.claude/` exists)

**Orchestrator (`prompts/meta-prompt-bootstrap.md`):**
- Reads step files sequentially
- Passes `BOOTSTRAP_MODE` to each step

**Step files (`prompts/bootstrap/step-*.md`):**
- step-1: Stack analysis by manifest files
- step-2: CLAUDE.md — create (fresh) or validate + auto-fix (validate)
- step-3: Agent, skill, pipeline, MCP registry
- step-4: File generation with validation (`[OK]`/`[FIX]`/`[NEW]`/`[REGEN]`)
- step-5: Verification + `.bootstrap-version` (SHA256 hashes) + final report

### Generated Output (in target project)
```
.claude/
  agents/           # {lang}-architect, {lang}-developer, {lang}-test-developer,
                    # {lang}-reviewer-logic, {lang}-reviewer-security,
                    # db-architect, devops, + frontend agents
  skills/           # code-style/, architecture/, database/, testing/, memory/,
                    # pipeline/ (CRITICAL: routing), p/ (alias)
  pipelines/        # new-code, fix-code, review, tests, api-docs, qa-docs,
                    # full-feature, hotfix — all with Task() syntax
  scripts/hooks/    # track-agent.sh, maintain-memory.sh, update-schema.sh (conditional)
  scripts/          # verify-bootstrap.sh
  memory/           # facts.md, patterns.md, issues.md, sessions/, decisions/, decisions/archive/
  output/           # contracts/, qa/
  input/            # Tasks, plans
  database/         # Schema, migrations
  settings.json     # Permissions + hooks
  .bootstrap-version  # SHA256 hashes
.mcp.json           # MCP server config (optional, GitLab)
CLAUDE.md           # Project overview with routing rule + agents/skills/pipelines index
```
