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
/plugin marketplace add BeMySlaveDarlin/cc-bootstrapper
/plugin install cc-bootstrapper@bemyslavedarlin-cc-bootstrapper
```

### Manual (legacy)
```bash
git clone https://github.com/BeMySlaveDarlin/cc-bootstrapper.git
cd cc-bootstrapper && bash install.sh
```

### Usage
```
/cc-bootstrapper:bootstrap    # Plugin mode
```

### Verification
```bash
bash -n templates/hooks/*.sh

for dir in agents skills pipelines scripts/hooks memory input; do [ -d ".claude/$dir" ] && echo "[OK] $dir" || echo "[MISS] $dir"; done
```

## Architecture

### Module Structure
```
.claude-plugin/
  plugin.json                           # Plugin manifest
  marketplace.json                      # Marketplace registry
install.sh                              # Legacy install script
scripts/
  bump-version.sh                       # Version bump across all files
skills/
  bootstrap/
    SKILL.md                            # /cc-bootstrapper:bootstrap — orchestrator (inline)
    references/                         # Step files (loaded by subagents)
      step-1-scan.md                    # Light scan: manifests, structure, stack
      step-2-detect.md                  # Mode detection (fresh/resume/validate)
      step-3-configure.md               # User config: data collection (phase 3A)
      step-3-apply.md                  # User config: apply to state (phase 3B)
      step-4-settings.md                # Settings.json generation (before plugins)
      step-5-plugins.md                 # Plugins & MCP: data collection (phase 5A)
      step-5-apply.md                  # Plugins & MCP: apply configuration (phase 5B)
      step-6-preview.md                 # Dry-run preview + PAUSE POINT
      step-7-analyze.md                 # Deep analysis (optional, per-domain)
      step-8-lang.md                    # Generation: per-language artifacts
      step-8-common.md                  # Generation: shared agents, skills, pipelines
      step-8-infra.md                   # Generation: hooks, memory, MCP configs
      step-9-claude-md.md               # Generation: CLAUDE.md
      step-10-finalize.md               # Verification + .bootstrap-version + cleanup
templates/
  agents/                               # 8 agent templates (4 per-lang + 4 common)
  skills/                               # 7 skill templates (incl. pipeline routing)
  pipelines/                            # 8 pipeline templates with Task() syntax
  hooks/                                # 3 hook scripts
  includes/                             # Shared includes (stack-adaptations, capability-detect)
  verify-bootstrap.sh                   # Verification script
```

### Key Principles
- Модульная архитектура: skill → orchestrator → step files → templates
- Pipeline routing: ЖЁСТКОЕ ПРАВИЛО в CLAUDE.md + `/pipeline` skill с frontmatter `user-invocable: true`
- Task() pseudo-syntax для вызова агентов в пайплайнах
- Три режима: `fresh` (полная генерация), `validate` (проверка + auto-fix), `resume` (продолжение после crash)
- 9 шагов: Scan → Detect → Configure → Settings → Plugins → Preview → Analyze → Generate → Finalize
- Каждый шаг — атомарный субагент с изолированным контекстом
- State file `.bootstrap-cache/state.json` — единственный канал между шагами
- Генерация per-domain: per-lang + common + infra параллельно

### Main Modules

**Skill (`skills/bootstrap/SKILL.md`):**
- Прямой путь к meta-prompt через `${CLAUDE_SKILL_DIR}`
- Поддержка кастомного meta-prompt через `$ARGUMENTS`
- Resume detection: проверка `.bootstrap-state.json` перед определением режима
- Auto-detect режима: `fresh` (нет `.claude/`), `validate` (есть `.claude/`), `resume` (есть state file)

**Orchestrator (`prompts/meta-prompt-bootstrap.md`):**
- Запускает 7 шагов как изолированные субагенты
- Checkpoint protocol: state file обновляется после каждого шага
- Pause point после step-4 (dry-run preview)
- При ошибке: retry / skip / abort

**Step files (`skills/bootstrap/references/step-*.md`):**
- step-1-scan: Light scan проекта (манифесты, структура, стек)
- step-2-detect: Определение режима (fresh/validate/resume) + legacy detection
- step-3-configure: Настройка — формирование вопросов (фаза 3A, без интерактива)
- step-3-apply: Настройка — запись ответов в state (фаза 3B, без интерактива)
- step-4-settings: Settings.json (базовые permissions + hooks)
- step-5-plugins: Плагины и MCP — сбор данных (фаза 5A, интерактив)
- step-5-apply: Плагины и MCP — применение конфигурации (фаза 5B, без интерактива)
- step-6-preview: Dry-run preview + PAUSE POINT
- step-7-analyze: Глубокий анализ (optional, per-domain субагенты)
- step-8-lang/common/infra: Генерация per-domain параллельно
- step-8-claude-md: CLAUDE.md (последний, таблицы по факту генерации)
- step-9-finalize: Верификация + `.bootstrap-version` + cleanup

### Generated Output (in target project)
```
.claude/
  agents/           # {lang}-architect, {lang}-developer, {lang}-test-developer,
                    # {lang}-reviewer, analyst, storage-architect (conditional),
                    # devops, qa-engineer
  skills/           # code-style/, architecture/, storage/, testing/, memory/,
                    # pipeline/ (CRITICAL: routing), p/ (alias)
  pipelines/        # new-code, fix-code, review, tests, api-docs, qa-docs,
                    # full-feature, hotfix — all with Task() syntax
  scripts/hooks/    # track-agent.sh, maintain-memory.sh, update-schema.sh (conditional)
  scripts/          # verify-bootstrap.sh
  memory/           # facts.md, patterns.md, issues.md, sessions/, decisions/, decisions/archive/
  output/           # contracts/, qa/, plans/, reviews/
  input/            # Tasks, plans
  database/         # Schema, migrations
  settings.json     # Permissions + hooks (diff-based merge in validate mode)
  .bootstrap-version  # SHA256 hashes
.mcp.json           # MCP server config (optional, GitLab)
CLAUDE.md           # Project overview with routing rule + agents/skills/pipelines index
```

