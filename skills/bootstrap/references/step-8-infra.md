# Шаг 8: Генерация инфраструктуры

> Modes: fresh, upgrade

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.
> Используй ТОЛЬКО переменные из state-файла. НЕ обращайся к результатам других шагов напрямую.

## Вход
- `.claude/.cache/state.json` → `config` (db, container, gitlab_mcp, gitlab.*), `stack`

---

## 8-infra.1 Hooks

### Генерация

Для каждого хука прочитай шаблон из `templates/hooks/` → запиши в `.claude/scripts/hooks/{name}.sh`:

| Шаблон | Выходной файл | Условие |
|--------|---------------|---------|
| `templates/hooks/track-agent.sh` | `.claude/scripts/hooks/track-agent.sh` | всегда |
| `templates/hooks/maintain-memory.sh` | `.claude/scripts/hooks/maintain-memory.sh` | всегда |
| `templates/hooks/update-schema.sh` | `.claude/scripts/hooks/update-schema.sh` | `stack.db != none` И это реальная БД (postgres, mysql, mariadb, mongo, etc.), НЕ кеш (redis) и НЕ очередь (rabbitmq) |

Скрипт верификации:
  `templates/verify-bootstrap.sh` → `.claude/scripts/verify-bootstrap.sh`

Сделай скрипты исполняемыми и проверь синтаксис:
```bash
chmod +x .claude/scripts/hooks/*.sh
chmod +x .claude/scripts/verify-bootstrap.sh
bash -n .claude/scripts/hooks/*.sh
bash -n .claude/scripts/verify-bootstrap.sh
```

### Валидация (режим `patch`)
- Все хук-файлы существуют
- Все executable (`chmod +x`)
- `bash -n` проходит (синтаксис OK)
- Устаревшие хуки (`git-context.sh`, `session-summary.sh`) → удалить → `[FIX] removed deprecated {path}`
→ Нет файла → создать из шаблона → `[NEW] {path}`
→ Не executable → chmod +x → `[FIX] chmod +x {path}`
→ Синтаксис broken → перегенерировать → `[REGEN] {path}`

---

## 8-infra.2 Memory

### memory/facts.md

```markdown
# Project Facts

## Stack
- **Lang:** {stack.langs}
- **Framework:** {stack.frameworks}
- **DB:** {stack.db}
- **Frontend:** {stack.frontend}

## Key Paths
- Source: {SOURCE_DIR}
- Tests: {TEST_DIR}
- Migrations: {MIGRATIONS_DIR}

## Active Decisions
{ссылки на файлы в memory/decisions/}

## Known Issues
—

## Last Updated
{DATE}
```

### memory/patterns.md

```markdown
# Code Patterns

Повторяющиеся паттерны кода, выявленные при разработке.

## Naming
—

## Architecture
—

## Error Handling
—

## Last Updated
—
```

### memory/issues.md

```markdown
# Known Issues

Повторяющиеся проблемы, выявленные при ревью.

| Date | Issue | Frequency | Resolution |
|------|-------|-----------|------------|
```

### input/tasks/TEMPLATE.md

```markdown
# Task: {название}

## Description
{описание задачи}

## Acceptance Criteria
- [ ] {критерий 1}
- [ ] {критерий 2}

## Priority
{high | medium | low}

## Affected Modules
{список модулей}
```

### input/plans/TEMPLATE.md

```markdown
# Plan: {название}

## Goal
{цель плана}

## Steps
1. {шаг 1}
2. {шаг 2}

## Dependencies
{зависимости}

## Risks
{риски}
```

### Режим `patch` для memory-файлов
- Если файл существует → `[OK]`, **НЕ перезаписывать** (пользователь мог добавить данные!)
- Если файла нет → `[NEW]`, создать из шаблона
- Исключение: `TEMPLATE.md` — перезаписывать всегда (это шаблон, не данные)

---

## 8-infra.3 GitLab MCP

Генерируй ТОЛЬКО если `config.gitlab_mcp=true`.

### .mcp.json (корень проекта)

```json
{
  "mcpServers": {
    "gitlab": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@zereight/mcp-gitlab"],
      "env": {
        "GITLAB_USERNAME": "{config.gitlab.username}",
        "GITLAB_PERSONAL_ACCESS_TOKEN": "{config.gitlab.token}",
        "GITLAB_API_URL": "{config.gitlab.api_url}",
        "USE_PIPELINE": "true",
        "USE_MILESTONE": "true",
        "USE_GITLAB_WIKI": "true"
      }
    }
  }
}
```

Важно: `.mcp.json` может содержать токены. Пользователь сам решает добавлять ли его в `.gitignore`.

### MCP-скиллы (условные)

Генерируются из шаблонов в `templates/skills/`. Каждый шаблон имеет поле `condition` в frontmatter — генератор проверяет условие и включает скилл только если оно выполнено.

| Шаблон | Выходной файл | Условие |
|--------|---------------|---------|
| `templates/skills/gitlab.md` | `.claude/skills/gitlab/SKILL.md` | `config.gitlab_mcp = true` |
| `templates/skills/github.md` | `.claude/skills/github/SKILL.md` | `config.github_mcp = true` |
| `templates/skills/playwright.md` | `.claude/skills/playwright/SKILL.md` | playwright MCP доступен (см. проверку ниже) |

Проверка условий:
- `config.gitlab_mcp` / `config.github_mcp` — из `state.json → config`
- playwright — проверь `.claude/settings.json → permissions.allow[]` содержит `mcp__plugin_playwright_playwright__*` ИЛИ `.mcp.json` содержит playwright-сервер. Если любое true → генерировать скилл

Скиллы подключаются к существующим агентам через `## Контекст`:
- `devops` → читает gitlab/github скилл для CI/CD операций
- `qa-engineer` → читает playwright скилл для E2E
- `{lang}-developer` → читает github скилл для PR workflow
- Любой агент может использовать скилл по необходимости

### skills/gitlab/SKILL.md

Генерируется из шаблона `templates/skills/gitlab.md` → `.claude/skills/gitlab/SKILL.md`.

### pipelines/gitlab.md

Генерируется из шаблона `templates/pipelines/gitlab.md` → `.claude/pipelines/gitlab.md`.
Условие: `config.gitlab_mcp = true`.

### skills/github/SKILL.md

Генерируется из шаблона `templates/skills/github.md` → `.claude/skills/github/SKILL.md`.

### pipelines/github.md

Генерируется из шаблона `templates/pipelines/github.md` → `.claude/pipelines/github.md`.
Условие: `config.github_mcp = true`.

### Обновления в существующих файлах

**skills/pipeline/SKILL.md** — добавить через placeholder-подстановку:

Если `config.gitlab_mcp = true`, в `{CUSTOM_PIPELINE_KEYWORDS}` добавить:
```
| **GITLAB** | gitlab, MR, merge request, issue, задача #N |
```
В `{CUSTOM_PIPELINE_OPTIONS}` добавить:
```
    - {label: "gitlab", description: "Операции с GitLab (MR, issues)"}
```

Если `config.github_mcp = true`, в `{CUSTOM_PIPELINE_KEYWORDS}` добавить:
```
| **GITHUB** | github, PR, pull request, issue, issue #N |
```
В `{CUSTOM_PIPELINE_OPTIONS}` добавить:
```
    - {label: "github", description: "Операции с GitHub (PR, issues)"}
```

---

## 8-infra.4 Include-подстановки

При генерации файлов на этом шаге подставлять ТОЛЬКО актуальные includes:
- `{CAPTURE:full}` → `templates/includes/capture-full.md`
- `{CAPTURE:partial}` → `templates/includes/capture-partial.md`
- `{CAPTURE:review}` → `templates/includes/capture-review.md`
- `{TEAM_AGENT_RULES}` → `templates/includes/team-agent-rules.md`
- `{AGENT_BASE_CONTEXT}` → `templates/includes/agent-base-context.md`
- `{MCP_SKILLS_CONTEXT}` → `templates/includes/mcp-skills-context.md`
- `{STACK_ADAPTATIONS}` → `templates/includes/stack-adaptations.md`
- `{TASK_SYNTAX}` → `templates/includes/task-syntax.md`

**УДАЛЁННЫЕ includes (НЕ подставлять, если встречаются в legacy файлах — удалить строку):**
- ~~`{CAPABILITY_DETECT}`~~ — удалён
- ~~`{PIPELINE_STATE_INIT}`~~ — удалён
- ~~`{PIPELINE_STATE_UPDATE}`~~ — удалён
- ~~`{PEER_REVIEW}`~~ — удалён
- ~~`{PARALLEL_PER_LANG}`~~ — удалён
- ~~`{TEAM_SHUTDOWN}`~~ — удалён

---

## Правила записи файлов

### Режим `fresh`
Записывать все файлы без проверок.

### Режим `patch`
- Хуки: валидация → `[OK]`/`[FIX]`/`[NEW]`/`[REGEN]`
- Memory: НЕ перезаписывать существующие (данные пользователя!)
- MCP: перегенерировать если структура изменилась

### Паттерн "Write first"
Записывай файл перед возвратом результата.

### Error tracking

Для КАЖДОЙ операции Write:
1. Выполни Write
2. Если Write вернул ошибку или был отклонён пользователем:
   - Добавь в массив failed: `{"path": "{file_path}", "error": "{error_text}", "status": "[WRITE_FAIL]"}`
   - **ПРОДОЛЖАЙ** со следующим файлом — НЕ останавливайся
3. Если Write успешен — добавь путь в массив written[]

---

## Выход
- `.claude/.cache/gen-report-8-infra.json`

Единый формат gen-report:
```json
{
  "step": "8-infra",
  "generated_at": "ISO8601",
  "files": [
    {"path": "scripts/hooks/track-agent.sh", "type": "hook", "status": "created", "source": "template"},
    {"path": "memory/facts.md", "type": "memory", "status": "created", "source": "template"},
    {"path": "scripts/verify-bootstrap.sh", "type": "script", "status": "created", "source": "template"}
  ],
  "errors": []
}
```

| Поле files[] | Описание |
|--------------|----------|
| path | Относительно .claude/ |
| type | agent, skill, pipeline, hook, script, memory, config |
| status | created, skipped, error, user_exists |
| source | template, custom |

`errors[]` — объекты `{"path", "error"}`. Если не пуст — оркестратор обработает partial failure.

## Лог

Перед checkpoint запиши лог в `.claude/.cache/step-8-infra-log.md`:

```markdown
# Step 8: Генерация инфраструктуры — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

Записать лог ПЕРЕД checkpoint.

## Checkpoint

> **НЕ пиши в state.json** — при параллельном выполнении это вызывает race condition.
> Оркестратор обновит state после сбора всех gen-reports.

Запиши отчёт в `.claude/.cache/gen-report-8-infra.json`.
