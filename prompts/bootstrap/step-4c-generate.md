# Шаг 4c: Генерация (Hooks, Settings, State, MCP)

> Продолжение шага 4. Правила записи файлов и стек-адаптации — см. `step-4-generate.md`.

## Правила записи (краткое напоминание)
- `fresh`: записывать без проверок
- `validate`: файл есть → валидация → `[OK]`/`[FIX]`/`[REGEN]`; файла нет → `[NEW]`

---

## 4.5 Hooks

### Валидация (режим `validate`)
- Все 5 файлов существуют
- Все executable
- `bash -n` проходит (синтаксис OK)
→ Нет файла → создать из шаблона → `[NEW] {path}`
→ Не executable → chmod +x → `[FIX] chmod +x {path}`
→ Синтаксис broken → перегенерировать → `[REGEN] {path}`

---

### Генерация

Для каждого хука прочитай шаблон из `templates/hooks/` → запиши в `.claude/scripts/hooks/{name}.sh`:

  `templates/hooks/track-agent.sh` → `.claude/scripts/hooks/track-agent.sh`
  `templates/hooks/session-summary.sh` → `.claude/scripts/hooks/session-summary.sh`
  `templates/hooks/update-schema.sh` → `.claude/scripts/hooks/update-schema.sh`
  `templates/hooks/maintain-memory.sh` → `.claude/scripts/hooks/maintain-memory.sh`
  `templates/hooks/git-context.sh` → `.claude/scripts/hooks/git-context.sh`

Скрипт верификации:
  `templates/verify-bootstrap.sh` → `.claude/scripts/verify-bootstrap.sh`

Сделай скрипты исполняемыми:
```bash
chmod +x .claude/scripts/hooks/*.sh
chmod +x .claude/scripts/verify-bootstrap.sh
```

---

## 4.6 Settings

### Валидация (режим `validate`, ИСКЛЮЧЕНИЕ: AskUserQuestion)
- Валидный JSON
- Содержит `permissions.allow`
→ Файл существует → AskUserQuestion: "Что сделать с settings.json?"
  - "Merge (Recommended)" — добавить недостающие permissions, сохранить существующие
  - "Перезаписать" — заменить сгенерированным
  - "Оставить" — не трогать
→ Файл НЕ существует → создать из шаблона → `[NEW] settings.json`

---

### Генерация

Прочитай шаблон `templates/settings.json.tpl` → подставь переменные → запиши в `.claude/settings.json`.
Прочитай шаблон `templates/settings.local.json.tpl` → подставь переменные → запиши в `.claude/settings.local.json`.

Адаптируй `{CONTAINER_CMD}` под стек:
- Docker: `docker compose`, `docker exec`, `docker ps`, `docker network`
- Podman: `podman`, `podman-compose`
- Без контейнеров: убрать

---

## 4.7 Memory

### memory/facts.md

```markdown
# Project Facts

## Stack
- **Lang:** {LANGS}
- **Framework:** {FRAMEWORK}
- **DB:** {DB}
- **Frontend:** {FRONTEND}

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

---

## 4.8 Version Tracking

**Пропустить.** Генерация `.bootstrap-version` выполняется на Шаге 5 (верификация).

---

## 4.9 MCP-интеграции

Генерируй ТОЛЬКО если `GITLAB_MCP=true`.

### 4.9.1 `.mcp.json` (корень проекта)

```json
{
  "mcpServers": {
    "gitlab": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@zereight/mcp-gitlab"],
      "env": {
        "GITLAB_USERNAME": "{GITLAB_USERNAME}",
        "GITLAB_PERSONAL_ACCESS_TOKEN": "{GITLAB_TOKEN}",
        "GITLAB_API_URL": "{GITLAB_API_URL}",
        "USE_PIPELINE": "{USE_PIPELINE}",
        "USE_MILESTONE": "{USE_MILESTONE}",
        "USE_GITLAB_WIKI": "{USE_GITLAB_WIKI}"
      }
    }
  }
}
```

**Важно:** добавь `.mcp.json` в `.gitignore` проекта (содержит токен).

### 4.9.2 Агент: `agents/gitlab-manager.md`

```markdown
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

### 4.9.3 Скилл: `skills/gitlab/SKILL.md`

```markdown
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

### 4.9.4 Пайплайн: `pipelines/gitlab.md`

```markdown
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
- Обнови state если релевантно
```

### 4.9.5 Обновления в существующих файлах

**settings.local.json** — добавить в `permissions.allow`:
```json
"mcp__gitlab__list_issues",
"mcp__gitlab__get_issue",
"mcp__gitlab__search_repositories",
"mcp__gitlab__list_projects",
"mcp__gitlab__list_merge_requests",
"mcp__gitlab__get_merge_request",
"mcp__gitlab__get_merge_request_diffs",
"mcp__gitlab__my_issues"
```

И добавить в корень settings.local.json:
```json
"enableAllProjectMcpServers": true
```

**skills/pipeline/SKILL.md** — добавить в Keyword-таблицу:
```
| gitlab, MR, merge request, issue, задача #N | `gitlab.md` |
```

**CLAUDE.md шаблон** — добавить в таблицы Agents, Skills, Pipelines:
```
| GitLab Manager | `gitlab-manager.md` | Управление GitLab: issues, MR, pipelines |
| GitLab | `gitlab/` | MCP-интеграция с GitLab |
| GitLab | `gitlab.md` | Операции через GitLab MCP |
```
