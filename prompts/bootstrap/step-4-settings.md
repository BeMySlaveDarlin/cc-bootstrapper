# Шаг 4-settings: Генерация settings.json

## Вход
- Список агентов из step-4
- Список скиллов/пайплайнов из step-4b
- Список хуков из step-4c
- ADAPTIVE_TEAMS: true | false
- GITLAB_MCP: true | false
- DB: тип БД или none

## Выход
Верни результат:
- Статус settings.json: [OK] | [FIX] | [NEW]

## Задача

### Режим `validate`

1. Проверь `.claude/settings.json`:
   - Валидный JSON
   - Содержит `permissions.allow`
2. AskUserQuestion: "Что сделать с settings.json?"
   - "Merge (Recommended)" — добавить недостающие permissions, сохранить существующие
   - "Перезаписать" — заменить сгенерированным
   - "Оставить" — не трогать

### Режим `fresh`

Прочитай шаблон `templates/settings.json.tpl` → подставь переменные → запиши в `.claude/settings.json`.

Адаптируй `{CONTAINER_CMD}` под стек:
- Docker: `docker compose`, `docker exec`, `docker ps`, `docker network`
- Podman: `podman`, `podman-compose`
- Без контейнеров: убрать

Если в проекте есть DB — добавь `update-schema.sh` в `hooks.SessionStart[0].hooks`:
```json
{
  "type": "command",
  "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/update-schema.sh"
}
```

Если GITLAB_MCP=true — добавь в `permissions.allow`:
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

И добавь в корень settings.json:
```json
"enableAllProjectMcpServers": true
```
