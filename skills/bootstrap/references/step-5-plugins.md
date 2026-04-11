# Шаг 5A: Плагины, MCP и LSP — Сканирование

> Modes: fresh

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.

## Роль

Ты — сканер. Проверяешь что установлено через ToolSearch, определяешь что нужно, формируешь вопросы и авто-действия для оркестратора. **НЕ задаёшь вопросов пользователю. НЕ пишешь файлы.**

## Вход
- `.claude/.cache/state.json` → `plugin_recommendations[]`, `stack`, `mode`

## Выход

Верни JSON-блок:

```json
{
  "auto": {
    "plugins_already_installed": ["playwright", "context7"],
    "permissions_to_add": ["mcp__plugin_playwright_playwright__*", "mcp__plugin_context7_context7__*"]
  },
  "questions": [
    {
      "question": "Context7 — актуальная документация Laravel.\n\nДля установки:\n/plugin install context7",
      "header": "Context7",
      "options": [
        {"label": "Установил", "description": "Плагин установлен, продолжить"},
        {"label": "Пропустить", "description": "Не устанавливать"}
      ],
      "multiSelect": false,
      "_type": "plugin",
      "_id": "context7",
      "_permission": "mcp__plugin_context7_context7__*"
    },
    {
      "question": "Обнаружен GitLab. Подключить GitLab MCP?",
      "header": "GitLab MCP",
      "options": [
        {"label": "Подключить", "description": "Настроить интеграцию с GitLab API"},
        {"label": "Пропустить", "description": "Не подключать"}
      ],
      "multiSelect": false,
      "_type": "mcp_gate",
      "_id": "gitlab"
    }
  ],
  "questions_conditional": {
    "gitlab": {
      "condition": "Подключить",
      "questions": [
        {
          "question": "GitLab API URL?",
          "header": "GitLab URL",
          "options": [
            {"label": "gitlab.com", "description": "https://gitlab.com/api/v4"},
            {"label": "Self-hosted", "description": "Укажи URL через Other"}
          ],
          "multiSelect": false
        },
        {
          "question": "GitLab username? (или введи через Other)",
          "header": "Username",
          "options": [
            {"label": "Из git config", "description": "Использовать git config user.name"}
          ],
          "multiSelect": false
        },
        {
          "question": "GitLab Personal Access Token?\n\nSettings → Access Tokens → scopes: api, read_user.\nВведи через Other (glpat-...)",
          "header": "Token",
          "options": [
            {"label": "Введу позже", "description": "Плейсхолдер YOUR_TOKEN_HERE"}
          ],
          "multiSelect": false
        },
        {
          "question": "Какие функции GitLab включить?",
          "header": "Функции",
          "options": [
            {"label": "Issues + MR", "description": "Задачи и merge requests"},
            {"label": "Issues + MR + Wiki", "description": "Плюс Wiki"},
            {"label": "Всё", "description": "Issues, MR, Pipelines, Milestones, Wiki"}
          ],
          "multiSelect": false
        }
      ]
    },
    "github": {
      "condition": "Other|Введу позже",
      "questions": []
    }
  },
  "skipped": ["typescript-lsp"]
}
```

## Логика сканирования

### Плагины

Для каждого плагина:
1. Проверь условие (нужен ли по stack)
2. Если не нужен → в `skipped`
3. Если нужен → ToolSearch для проверки рантайма
4. Если уже работает → в `auto.plugins_already_installed` + permission в `auto.permissions_to_add`
5. Если не установлен → сформируй вопрос в `questions`

Проверка доступности — только через ToolSearch (рантайм), не через settings.json.

#### 5.1 Playwright
- Условие: `stack.frontend != none` ИЛИ E2E тесты
- Проверка: `ToolSearch(query: "mcp playwright", max_results: 1)`
- Permission: `mcp__plugin_playwright_playwright__*`

#### 5.2 Context7
- Условие: популярный фреймворк
- Проверка: `ToolSearch(query: "mcp context7", max_results: 1)`
- Permission: `mcp__plugin_context7_context7__*`

#### 5.3 LSP серверы

| Язык | Плагин | Проверка |
|------|--------|----------|
| TypeScript/JS | typescript-lsp | `ToolSearch("typescript lsp")` |
| PHP | php-lsp | `ToolSearch("php lsp")` |
| Python | pyright-lsp | `ToolSearch("pyright lsp")` |
| Go | gopls-lsp | `ToolSearch("gopls lsp")` |

### MCP серверы

#### 5.4 GitLab MCP
- Условие: `stack.git_hosting == "gitlab"` ИЛИ `.gitlab-ci.yml`
- Проверка: `ToolSearch(query: "mcp gitlab", max_results: 1)`
- Если работает → `auto` + permission `mcp__gitlab__*`
- Если нет → gate-вопрос "Подключить?" в `questions` + детальные вопросы в `questions_conditional.gitlab`

#### 5.5 GitHub MCP
- Условие: `stack.git_hosting == "github"` ИЛИ `.github/workflows/`
- Проверка: `ToolSearch(query: "mcp github", max_results: 1)`
- Если работает → `auto` + permission `mcp__github__*`
- Если нет → вопрос с token в `questions` (Other = token, "Введу позже" = placeholder, "Пропустить" = skip)

#### 5.6 Docker MCP
- Условие: `stack.container == "docker"` ИЛИ `docker-compose.yml`
- Проверка: `ToolSearch(query: "mcp docker", max_results: 1)`
- Если работает → `auto` + permission `mcp__docker__*`
- Если нет → вопрос "Подключить?" в `questions`

## Финал

Верни JSON-блок и слово `done`.
**НЕ задавай вопросов. НЕ пиши файлы. НЕ обновляй state.**
