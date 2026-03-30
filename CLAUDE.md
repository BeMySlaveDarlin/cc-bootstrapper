# CLAUDE.md

[English](CLAUDE.en.md)

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

cc-bootstrapper — Claude Code automation bootstrap system. Analyzes any project and generates a complete `.claude/` automation structure with pipeline routing.

- Markdown + Bash (prompt templates, shell hooks)
- Claude Code CLI framework
- Modular architecture: orchestrator + bootstrap/ templates
- No DB, no container

## Rules

- Кратко, по делу, без теории
- Код — только по прямому запросу
- Никаких docblock или comments в коде, если они не требуются для static analysis
- Никаких git commit или git push, если не попросят
- Все промпты и шаблоны — на русском языке
- Shell-скрипты используют `jq` для JSON, `$CLAUDE_PROJECT_DIR` для путей
- Именование агентов: `{lang}-{role}.md` (e.g., `php-developer.md`)
- **CRITICAL:** Имя директории `skills/pipeline/` копировать AS-IS. НЕ переименовывать.

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
bash -n prompts/bootstrap/templates/hooks/*.sh

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
- Модульная архитектура: skill → orchestrator → step files → templates
- Pipeline routing: ЖЁСТКОЕ ПРАВИЛО в CLAUDE.md + `/pipeline` skill с frontmatter `user-invocable: true`
- Task() pseudo-syntax для вызова агентов в пайплайнах
- Два режима: `fresh` (полная генерация) и `validate` (проверка + auto-fix)
- 7 шагов: Анализ → CLAUDE.md → Планирование → Генерация (3 батча) → Верификация

### Main Modules

**Skill (`skills/bootstrap/SKILL.md`):**
- Прямой путь к meta-prompt через `${CLAUDE_SKILL_DIR}`
- Поддержка кастомного meta-prompt через `$ARGUMENTS`
- Auto-detect режима: `fresh` (нет `.claude/`) или `validate` (есть `.claude/`)

**Orchestrator (`prompts/meta-prompt-bootstrap.md`):**
- Читает step-файлы последовательно
- Передаёт `BOOTSTRAP_MODE` в каждый шаг

**Step files (`prompts/bootstrap/step-*.md`):**
- step-1: Анализ стека по manifest-файлам
- step-2: CLAUDE.md — создание (fresh) или валидация + auto-fix (validate)
- step-3: Реестр агентов, скиллов, пайплайнов, MCP
- step-4: Генерация файлов с валидацией (`[OK]`/`[FIX]`/`[NEW]`/`[REGEN]`)
- step-5: Верификация + `.bootstrap-version` (SHA256 хеши) + финальный отчёт

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

