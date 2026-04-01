# Шаг 5: Плагины, MCP и LSP

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.

## Вход
- `.bootstrap-cache/state.json` → `plugin_recommendations[]`, `stack`, `mode`

## Выход
- Установленные плагины/MCP/LSP (по выбору пользователя)
- Обновлённый settings.json (MCP permissions)
- Обновлённый state

## Как проверять установку

Для проверки что плагин/MCP реально работает в рантайме — используй ToolSearch:
```
ToolSearch(query: "mcp {keyword}", max_results: 1)
```
Если результат содержит tools — плагин работает.
Если пусто — не установлен или не подключён.

## Принцип для каждого плагина/MCP

**ВАЖНО:** НЕ проверяй settings.json для определения установки. Settings.json может содержать permissions от прошлого bootstrap. Проверяй ТОЛЬКО через ToolSearch (рантайм).

1. Проверь условие (нужен ли для проекта по stack)
2. Если условие не выполнено → пропусти молча
3. Если нужен → проверь через ToolSearch — уже работает в рантайме?
4. Если ДА → добавь permissions в settings.json (если ещё нет), пропусти вопрос
5. Если НЕТ → AskUserQuestion с инструкцией по установке в тексте вопроса
6. Если пользователь выбрал "Установил" → проверь через ToolSearch ещё раз
7. Если всё ещё нет → повтори вопрос или пропусти

---

## ПЛАГИНЫ

### 5.1 Playwright

Условие: `stack.frontend != none` ИЛИ обнаружены E2E тесты.
Проверка: ToolSearch(query: "mcp playwright", max_results: 1)

Если уже работает → добавь `"mcp__plugin_playwright_playwright__*"` в settings.json, пропусти.

Если не установлен:

AskUserQuestion:
  question: "Playwright — E2E тесты, скриншоты, browser automation.\n\nДля установки выполни команду:\n/plugin install playwright\n\nЕсли ты root — после установки добавь:\nPLAYWRIGHT_CHROMIUM_ARGS=--no-sandbox"
  header: "Playwright"
  options:
    - {label: "Установил", description: "Плагин установлен, продолжить"}
    - {label: "Пропустить", description: "Не устанавливать"}

Если "Установил":
  Проверь: ToolSearch(query: "mcp playwright", max_results: 1)
  Если найден → добавь `"mcp__plugin_playwright_playwright__*"` в settings.json
  Если не найден → AskUserQuestion:
    question: "Playwright не обнаружен. Возможно нужен /reload-plugins.\n\nПопробуй:\n/reload-plugins\n\nИли установи заново:\n/plugin install playwright"
    header: "Playwright"
    options:
      - {label: "Готово", description: "Попробовал, продолжить"}
      - {label: "Пропустить", description: "Установлю позже"}

---

### 5.2 Context7

Условие: обнаружен популярный фреймворк.
Проверка: ToolSearch(query: "mcp context7", max_results: 1)

Если уже работает → добавь `"mcp__plugin_context7_context7__*"` в settings.json, пропусти.

Если не установлен:

AskUserQuestion:
  question: "Context7 — актуальная документация {framework}.\n\nДля установки:\n/plugin install context7"
  header: "Context7"
  options:
    - {label: "Установил", description: "Плагин установлен, продолжить"}
    - {label: "Пропустить", description: "Не устанавливать"}

Если "Установил":
  Проверь: ToolSearch(query: "mcp context7", max_results: 1)
  Если найден → добавь `"mcp__plugin_context7_context7__*"` в settings.json

---

### 5.3 LSP серверы

| Язык | Плагин | Проверка | Permission |
|------|--------|----------|------------|
| TypeScript/JS | typescript-lsp | ToolSearch("typescript lsp") | — |
| PHP | php-lsp | ToolSearch("php lsp") | — |
| Python | pyright-lsp | ToolSearch("pyright lsp") | — |
| Go | gopls-lsp | ToolSearch("gopls lsp") | — |

Для КАЖДОГО языка из `stack.langs`:
1. Проверь через ToolSearch — уже работает?
2. Если да → пропусти
3. Если нет:

AskUserQuestion:
  question: "{lsp_name} — автокомплит, go-to-definition, диагностика для {lang}.\n\nДля установки:\n/plugin install {lsp_plugin}"
  header: "LSP"
  options:
    - {label: "Установил", description: "Продолжить"}
    - {label: "Пропустить", description: "Не устанавливать"}

---

## MCP СЕРВЕРЫ

### 5.4 GitLab MCP

Условие: `stack.git_hosting == "gitlab"` ИЛИ обнаружен `.gitlab-ci.yml`.
Проверка: ToolSearch(query: "mcp gitlab", max_results: 1)

Если уже работает → добавь `"mcp__gitlab__*"` в settings.json, установи `state.config.gitlab_mcp = true`, пропусти.

Если не настроен:

AskUserQuestion:
  question: "Обнаружен GitLab. Подключить GitLab MCP?"
  header: "GitLab MCP"
  options:
    - {label: "Подключить", description: "Настроить интеграцию с GitLab API"}
    - {label: "Пропустить", description: "Не подключать"}

Если "Подключить":

AskUserQuestion:
  question: "GitLab API URL?"
  header: "GitLab"
  options:
    - {label: "gitlab.com", description: "https://gitlab.com/api/v4"}
    - {label: "Self-hosted", description: "Укажи URL через Other"}

AskUserQuestion:
  question: "GitLab username?"
  header: "GitLab"
  options:
    - {label: "Из git config", description: "Использовать git config user.name"}
    - {label: "Ввести вручную", description: "Укажи через Other"}

При "Из git config" — выполни `git config user.name`.

AskUserQuestion:
  question: "GitLab Personal Access Token?\n\nSettings → Access Tokens → scopes: api, read_user"
  header: "GitLab token"
  options:
    - {label: "Ввести сейчас", description: "Введи токен через Other (glpat-...)"}
    - {label: "Введу позже", description: "Плейсхолдер YOUR_TOKEN_HERE"}

AskUserQuestion:
  question: "Какие функции GitLab включить?"
  header: "GitLab функции"
  options:
    - {label: "Issues + MR", description: "Задачи и merge requests"}
    - {label: "Issues + MR + Wiki", description: "Плюс Wiki"}
    - {label: "Всё", description: "Issues, MR, Pipelines, Milestones, Wiki"}

Установи пакет: `npx -y @zereight/mcp-gitlab --version`

Запиши/обнови `.mcp.json`:
```json
{
  "mcpServers": {
    "gitlab": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@zereight/mcp-gitlab"],
      "env": {
        "GITLAB_USERNAME": "{username}",
        "GITLAB_PERSONAL_ACCESS_TOKEN": "{token}",
        "GITLAB_API_URL": "{api_url}",
        "USE_PIPELINE": "{true/false}",
        "USE_MILESTONE": "{true/false}",
        "USE_GITLAB_WIKI": "{true/false}"
      }
    }
  }
}
```

Добавь `.mcp.json` в `.gitignore`.
Добавь в settings.json: `"mcp__gitlab__*"` и `"enableAllProjectMcpServers": true`

AskUserQuestion:
  question: "GitLab MCP настроен. Перезапусти Claude Code после bootstrap чтобы подключить.\n\nПродолжить?"
  header: "GitLab"
  options:
    - {label: "Продолжить", description: "Перейти к следующему"}

Сохрани: `state.config.gitlab_mcp = true`

---

### 5.5 GitHub MCP

Условие: `stack.git_hosting == "github"` ИЛИ обнаружен `.github/workflows/`.
Проверка: ToolSearch(query: "mcp github", max_results: 1)

Если уже работает → добавь `"mcp__github__*"` в settings.json, установи `state.config.github_mcp = true`, пропусти.

Если не настроен:

AskUserQuestion:
  question: "Обнаружен GitHub. Подключить GitHub MCP?"
  header: "GitHub MCP"
  options:
    - {label: "Подключить", description: "Настроить интеграцию с GitHub API"}
    - {label: "Пропустить", description: "Не подключать"}

Если "Подключить":

AskUserQuestion:
  question: "GitHub Personal Access Token?\n\nSettings → Developer settings → Personal access tokens → Fine-grained"
  header: "GitHub token"
  options:
    - {label: "Ввести сейчас", description: "Введи токен через Other (ghp_...)"}
    - {label: "Введу позже", description: "Плейсхолдер ghp_your_token_here"}

Установи пакет: `npx -y @modelcontextprotocol/server-github --version`

Запиши/обнови `.mcp.json`:
```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "{token}"
      }
    }
  }
}
```

Добавь `.mcp.json` в `.gitignore`.
Добавь в settings.json: `"mcp__github__*"`

AskUserQuestion:
  question: "GitHub MCP настроен. Перезапусти Claude Code после bootstrap.\n\nПродолжить?"
  header: "GitHub"
  options:
    - {label: "Продолжить", description: "Перейти к следующему"}

Сохрани: `state.config.github_mcp = true`

---

### 5.6 Docker MCP

Условие: `stack.container == "docker"` ИЛИ обнаружен `docker-compose.yml` / `compose.yml`.
Проверка: ToolSearch(query: "mcp docker", max_results: 1)

Если уже работает → добавь `"mcp__docker__*"` в settings.json, установи `state.config.docker_mcp = true`, пропусти.

Если не настроен:

AskUserQuestion:
  question: "Docker MCP — управление контейнерами из Claude Code."
  header: "Docker MCP"
  options:
    - {label: "Подключить", description: "Настроить Docker MCP"}
    - {label: "Пропустить", description: "Не подключать"}

Если "Подключить":

Установи пакет: `npx -y mcp-docker-server --version`

Запиши/обнови `.mcp.json`:
```json
{
  "mcpServers": {
    "docker": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "mcp-docker-server"]
    }
  }
}
```

Добавь `.mcp.json` в `.gitignore`.
Добавь в settings.json: `"mcp__docker__*"`

Сохрани: `state.config.docker_mcp = true`

---

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-5-log.md`:

```markdown
# Step 5: Plugins & MCP — Log

## Проверки
| Плагин/MCP | Условие | Результат | Действие |
|------------|---------|-----------|----------|
| Playwright | frontend={значение} | нужен/не нужен | установлен/пропущен/уже был |
| Context7 | framework={значение} | нужен/не нужен | установлен/пропущен/уже был |
| PHP LSP | langs содержит php | нужен/не нужен | установлен/пропущен/уже был |
| ... | ... | ... | ... |

## Settings.json изменения
- Добавлено: {список permissions}
- Или: нет изменений
```

Записать лог ПЕРЕД checkpoint.

## Checkpoint

Обнови `.bootstrap-cache/state.json`:
- `steps.5.status` → `"completed"`
- `steps.5.completed_at` → `"{ISO8601}"`
- `current_step` → 6
