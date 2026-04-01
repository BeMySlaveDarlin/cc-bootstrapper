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

### agents/gitlab-manager.md

```markdown
---
name: "gitlab-manager"
description: "Управление GitLab через MCP: issues, MR, pipelines, wiki, releases"
---

# Агент: GitLab Manager

## Роль
Управление GitLab через MCP: issues, merge requests, pipelines, wiki, releases.

## Контекст
- `.claude/memory/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/skills/gitlab/SKILL.md` — маппинг операций → MCP tools
- `.mcp.json` — конфигурация MCP-сервера

## Распознавание операций

| Паттерн в запросе | Операция | MCP Tool |
|-------------------|----------|----------|
| #N, задача N, issue N | Получить issue | mcp__gitlab__get_issue |
| MR #N, merge request N | Получить MR | mcp__gitlab__get_merge_request |
| создай задачу, new issue | Создать issue | mcp__gitlab__create_issue |
| создай MR, merge request из X в Y | Создать MR | mcp__gitlab__create_merge_request |
| мои задачи, my issues | Список issues | mcp__gitlab__list_issues |
| одобри MR, approve | Approve MR | mcp__gitlab__approve_merge_request |
| pipeline, CI/CD | Pipeline ops | mcp__gitlab__list_pipelines |

## Порядок работы

1. Распознай тип операции по запросу
2. Определи параметры (projectId, IID)
3. Выполни MCP-tool
4. Проверь HTTP-статус (200-299: OK, 400+: ошибка)
5. Верни структурированный отчёт с URL

## Обработка ошибок

| Код | Причина | Действие |
|-----|---------|----------|
| 401 | Невалидный токен | Проверить GITLAB_PERSONAL_ACCESS_TOKEN в .mcp.json |
| 403 | Недостаточно прав | Проверить permissions пользователя |
| 404 | Неверный projectId/IID | Проверить параметры |
| 409 | Конфликт | MR уже существует или branch conflict |

## Правила
- Деструктивные операции (delete, merge) — требуют подтверждения пользователя
- Не логировать токен
- При ошибке — показать причину и рекомендацию
```

### skills/gitlab/SKILL.md

```markdown
---
name: "gitlab"
description: "MCP-интеграция с GitLab: маппинг операций на MCP tools"
version: "7.2.1"
user-invocable: false
---

# Skill: GitLab MCP — Маппинг операций

## Merge Requests
| Операция | Tool | Обязательные параметры |
|----------|------|----------------------|
| Создать MR | mcp__gitlab__create_merge_request | projectId, sourceBranch, targetBranch, title |
| Получить MR | mcp__gitlab__get_merge_request | projectId, mergeRequestIid |
| Список MR | mcp__gitlab__list_merge_requests | projectId |
| Approve MR | mcp__gitlab__approve_merge_request | projectId, mergeRequestIid |
| Merge MR | mcp__gitlab__merge_merge_request | projectId, mergeRequestIid |
| Diff MR | mcp__gitlab__get_merge_request_diffs | projectId, mergeRequestIid |

## Issues
| Операция | Tool | Обязательные параметры |
|----------|------|----------------------|
| Создать issue | mcp__gitlab__create_issue | projectId, title |
| Получить issue | mcp__gitlab__get_issue | projectId, issueIid |
| Список issues | mcp__gitlab__list_issues | projectId |
| Мои issues | mcp__gitlab__list_issues | scope=assigned_to_me |

## Pipelines
| Операция | Tool | Обязательные параметры |
|----------|------|----------------------|
| Список | mcp__gitlab__list_pipelines | projectId |
| Retry | mcp__gitlab__retry_pipeline | projectId, pipelineId |
| Cancel | mcp__gitlab__cancel_pipeline | projectId, pipelineId |

## Wiki
| Операция | Tool | Обязательные параметры |
|----------|------|----------------------|
| Список страниц | mcp__gitlab__list_wiki_pages | projectId |
| Получить страницу | mcp__gitlab__get_wiki_page | projectId, slug |
| Создать страницу | mcp__gitlab__create_wiki_page | projectId, title, content |

## Типовые сценарии

### Создание MR
1. `mcp__gitlab__create_merge_request` (projectId, sourceBranch, targetBranch, title, description)
2. Проверить ответ → вернуть URL

### Ревью MR
1. `mcp__gitlab__get_merge_request` → получить метаданные
2. `mcp__gitlab__get_merge_request_diffs` → получить diff
3. Анализ кода
4. `mcp__gitlab__create_merge_request_note` → оставить комментарий
```

### pipelines/gitlab.md

```markdown
<!-- version: 7.2.1 -->
# Pipeline: GitLab

## Фазы

### Phase 1: ANALYZE
1. Определи тип операции из запроса
2. Собери параметры (projectId, IID, branch, etc.)
3. Покажи план пользователю

### Phase 2: EXECUTE
**Агент:** Task(`gitlab-manager`)
1. Выполни MCP-tool
2. Проверь HTTP-статус

### Phase 3: VERIFY (для критичных операций)
Только для: merge MR, delete issue, create release
- Повторно запроси объект для подтверждения статуса

### Phase 4: REPORT
- Summary с URL
- Обнови memory если релевантно
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
  "errors": []
}
```

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
