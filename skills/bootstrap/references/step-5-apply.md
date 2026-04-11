# Шаг 5B: Плагины, MCP и LSP — Применение конфигурации

> Modes: fresh

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.

## Роль

Ты — конфигуратор. Получаешь готовые данные от оркестратора. **НЕ задаёшь вопросов пользователю.** Молча пишешь файлы и обновляешь state.

## Вход

Данные передаются в prompt от оркестратора как JSON:

```json
{
  "plugins_installed": [...],
  "plugins_skipped": [...],
  "mcp": {
    "gitlab": {"enabled": true, "api_url": "...", "username": "...", "token": "...", "features": {...}},
    "github": {"enabled": true, "token": "..."},
    "docker": {"enabled": true}
  },
  "permissions": [...]
}
```

## Действия

### 1. MCP серверы → `.mcp.json`

Для каждого `mcp.*` где `enabled == true`:

**GitLab:**
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
        "USE_PIPELINE": "{features.pipeline}",
        "USE_MILESTONE": "{features.milestone}",
        "USE_GITLAB_WIKI": "{features.wiki}"
      }
    }
  }
}
```

Установи пакет: `npx -y @zereight/mcp-gitlab --version`

**GitHub:**
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

Установи пакет: `npx -y @modelcontextprotocol/server-github --version`

**Docker:**
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

Установи пакет: `npx -y mcp-docker-server --version`

Если `.mcp.json` уже существует — мержи `mcpServers`, не перезаписывай.

### 2. Settings.json

Прочитай `.claude/settings.json`. Добавь permissions из входных данных в массив `allow`. Не дублируй.

Если GitLab enabled → добавь `"enableAllProjectMcpServers": true`.

### 4. State

Обнови `.claude/.cache/state.json`:
- `config.gitlab_mcp` / `config.github_mcp` / `config.docker_mcp` → true/false
- `steps.plugins.status` → `"completed"`
- `steps.plugins.completed_at` → `"{ISO8601}"`

### 5. Лог

Запиши `.claude/.cache/step-5-log.md`:

```markdown
# Step 5: Plugins & MCP — Log

## Проверки
| Плагин/MCP | Результат | Действие |
|------------|-----------|----------|
| {name} | нужен/не нужен | установлен/пропущен/уже был |

## Settings.json изменения
- Добавлено: {список permissions}
```

## Финал

Верни `done` после записи всех файлов.
