# Шаг 8: Генерация инфраструктуры

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.
> Используй ТОЛЬКО переменные из state-файла. НЕ обращайся к результатам других шагов напрямую.

## Вход
- `.bootstrap-cache/state.json` → `config` (db, container, gitlab_mcp, gitlab.*), `stack`

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

### Валидация (режим `validate`)
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

### Режим `validate` для memory-файлов
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

**ВАЖНО:** добавь `.mcp.json` в `.gitignore` проекта (содержит токен).

### MCP-скиллы (условные)

Генерируются из шаблонов в `templates/skills/`. Каждый шаблон имеет поле `condition` в frontmatter — генератор проверяет условие и включает скилл только если оно выполнено.

| Шаблон | Выходной файл | Условие |
|--------|---------------|---------|
| `templates/skills/gitlab.md` | `.claude/skills/gitlab/SKILL.md` | `config.gitlab_mcp = true` |
| `templates/skills/github.md` | `.claude/skills/github/SKILL.md` | `config.github_mcp = true` |
| `templates/skills/playwright.md` | `.claude/skills/playwright/SKILL.md` | playwright в `auto.plugins_already_installed[]` ИЛИ `mcp__plugin_playwright_playwright__*` в permissions |

Проверка условий:
- `config.gitlab_mcp` / `config.github_mcp` — из `state.json → config`
- playwright — проверь `state.json → auto.plugins_already_installed[]` содержит `"playwright"` ИЛИ `state.json → config.permissions[]` содержит `mcp__plugin_playwright_playwright__*`. Если любое из двух true → генерировать скилл

Скиллы подключаются к существующим агентам через `## Контекст`:
- `devops` → читает gitlab/github скилл для CI/CD операций
- `qa-engineer` → читает playwright скилл для E2E
- `{lang}-developer` → читает github скилл для PR workflow
- Любой агент может использовать скилл по необходимости

### skills/gitlab/SKILL.md

Генерируется из шаблона `templates/skills/gitlab.md` → `.claude/skills/gitlab/SKILL.md`.

### pipelines/gitlab.md

```markdown
---
name: "gitlab"
description: "Операции с GitLab через MCP"
version: "8.2.0"
phases: 4
capture: "none"
user_prompts: false
parallel_per_lang: false
error_matrix: true
chains: []
triggers:
  - gitlab
  - MR
  - merge request
  - issue
  - "задача #"
error_routing:
  auth_fail: stop_and_report
  not_found: stop_and_report
  execute_fail: retry_current
---

# Pipeline: GitLab

## Phase 1: ANALYZE
1. Определи тип операции из запроса
2. Собери параметры (projectId, IID, branch, etc.)
3. Покажи план пользователю

## Phase 2: EXECUTE

Task(.claude/agents/gitlab-manager.md, subagent_type: "general-purpose"):
  Вход: параметры операции + `.claude/skills/gitlab/SKILL.md`
  Выход: результат MCP-вызова
  Ограничение: read-only
  Верни: summary (операция, статус, URL)

## Phase 3: VERIFY (для критичных операций)
Только для: merge MR, delete issue, create release
- Повторно запроси объект для подтверждения статуса

## Phase 4: REPORT
- Summary с URL
- Обнови memory если релевантно

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| EXECUTE | 401 Unauthorized | Проверить токен в .mcp.json |
| EXECUTE | 403 Forbidden | Проверить permissions |
| EXECUTE | 404 Not Found | Проверить projectId/IID |
| EXECUTE | 409 Conflict | Сообщить пользователю (MR уже существует) |
```

### Обновления в существующих файлах

**skills/pipeline/SKILL.md** — добавить в Keyword-таблицу:
```
| gitlab, MR, merge request, issue, задача #N | `gitlab.md` |
```

---

## Правила записи файлов

### Режим `fresh`
Записывать все файлы без проверок.

### Режим `validate`
- Хуки: валидация → `[OK]`/`[FIX]`/`[NEW]`/`[REGEN]`
- Memory: НЕ перезаписывать существующие (данные пользователя!)
- MCP: перегенерировать если структура изменилась

### Паттерн "Write first"
ОБЯЗАТЕЛЬНО Write файл ПЕРЕД возвратом результата. Не возвращай содержимое без записи на диск.

### Error tracking

Для КАЖДОЙ операции Write:
1. Выполни Write
2. Если Write вернул ошибку или был отклонён пользователем:
   - Добавь в массив failed: `{"path": "{file_path}", "error": "{error_text}", "status": "[WRITE_FAIL]"}`
   - **ПРОДОЛЖАЙ** со следующим файлом — НЕ останавливайся
3. Если Write успешен — добавь путь в массив written[]

---

## Выход
- `.bootstrap-cache/gen-report-8-infra.json`

Формат отчёта:
```json
{
  "step": "8-infra",
  "hooks": [
    {"name": "track-agent.sh", "path": ".claude/scripts/hooks/track-agent.sh", "status": "[NEW]"},
    {"name": "maintain-memory.sh", "path": ".claude/scripts/hooks/maintain-memory.sh", "status": "[NEW]"}
  ],
  "memory": [
    {"name": "facts.md", "path": ".claude/memory/facts.md", "status": "[NEW]"},
    {"name": "patterns.md", "path": ".claude/memory/patterns.md", "status": "[NEW]"}
  ],
  "mcp": {"status": "configured|skipped", "files": []},
  "written": [".claude/scripts/hooks/track-agent.sh", ".claude/memory/facts.md", "..."],
  "failed": [],
  "errors": []
}
```

**Важно:** `failed` содержит объекты `{"path", "error", "status"}`. Если `failed` не пуст — оркестратор обработает partial failure.

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-8-infra-log.md`:

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

После завершения обнови state:
```json
{
  "generation": {
    "checkpoint": "8-infra_done",
    "completed_files": ["...список созданных файлов..."]
  }
}
```

Запиши отчёт в `.bootstrap-cache/gen-report-8-infra.json`.
