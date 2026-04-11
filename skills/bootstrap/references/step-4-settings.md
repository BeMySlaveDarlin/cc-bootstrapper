# Шаг 4: Settings.json

> Modes: fresh

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.

## Вход
- `.claude/.cache/state.json` → `config` (permissions_level, git_permissions), `stack`

**Defaults если поля отсутствуют в config:**
- `permissions_level` → `"balanced"`
- `git_permissions` → `["read"]`
- `analysis_depth` → `"standard"`

## Выход
- `.claude/settings.json` (базовые permissions + hooks)
- Обновлённый state

---

## ФОРМАТ SETTINGS.JSON

Важно: Соблюдай точный формат Claude Code settings.json.

### Permissions

Все bash-команды обёрнуты в `Bash(command:*)`:
```json
{
  "permissions": {
    "allow": [
      "Read",
      "Write",
      "Edit",
      "Bash(git status:*)"
    ],
    "deny": [
      "Read(**/node_modules/**/SKILL.md)",
      "Read(**/node_modules/**/CLAUDE.md)",
      "Read(**/node_modules/**/AGENTS.md)",
      "Read(**/node_modules/**/.cursorrules)",
      "Read(**/vendor/**/SKILL.md)",
      "Read(**/vendor/**/CLAUDE.md)",
      "Read(**/vendor/**/AGENTS.md)",
      "Read(**/vendor/**/.cursorrules)",
      "Read(**/site-packages/**/SKILL.md)",
      "Read(**/site-packages/**/CLAUDE.md)",
      "Read(**/site-packages/**/AGENTS.md)",
      "Read(**/site-packages/**/.cursorrules)",
      "Glob(**/node_modules/**/SKILL.md)",
      "Glob(**/node_modules/**/CLAUDE.md)",
      "Glob(**/vendor/**/SKILL.md)",
      "Glob(**/vendor/**/CLAUDE.md)",
      "Glob(**/site-packages/**/SKILL.md)",
      "Glob(**/site-packages/**/CLAUDE.md)",
      "Bash(*npm install -g*)",
      "Bash(*npm i -g*)",
      "Bash(*yarn global add*)",
      "Bash(*pnpm add -g*)",
      "Bash(*curl*|*bash*)",
      "Bash(*curl*|*sh*)",
      "Bash(*wget*|*bash*)",
      "Bash(*wget*|*sh*)"
    ]
  }
}
```

Формат: `Bash(команда:*)` — двоеточие перед wildcard.
Инструменты без Bash: `Read`, `Write`, `Edit`, `Glob`, `Grep`, `WebSearch`, `WebFetch`, `Agent`, `Task`.

### Hooks

Формат: `matcher` (опционально) + `hooks` array:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Task",
        "hooks": [
          {"type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/track-agent.sh"}
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {"type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/maintain-memory.sh"}
        ]
      }
    ]
  }
}
```

---

## 4.1 Построение permissions

### Базовые (всегда)
```json
"Read", "Write", "Edit",
"Read(.claude/**)", "Write(.claude/**)", "Edit(.claude/**)",
"WebSearch", "WebFetch",
"Bash(wc:*)", "Bash(sort:*)", "Bash(du:*)", "Bash(touch:*)",
"Bash(test:*)", "Bash(mkdir:*)"
```

> `Write(.claude/**)` и `Edit(.claude/**)` — explicit allow для .claude/ директории.

### Git (из `config.git_permissions[]`)

| Выбор | Permissions |
|-------|-------------|
| `read` | `Bash(git status:*)`, `Bash(git log:*)`, `Bash(git diff:*)`, `Bash(git show:*)`, `Bash(git branch:*)`, `Bash(git rev-parse:*)` |
| `write` | `Bash(git add:*)`, `Bash(git commit:*)` |
| `push` | `Bash(git push:*)`, `Bash(git pull:*)`, `Bash(git fetch:*)` |
| `delete` | `Bash(git reset:*)`, `Bash(git checkout:*)`, `Bash(git clean:*)`, `Bash(git branch -D:*)`, `Bash(git stash:*)` |

Добавь ТОЛЬКО те группы, которые пользователь выбрал на step 3.
Если `git_permissions` нет в state — по умолчанию `["read"]`.

### Level-based (из `config.permissions_level`)

#### conservative
Только базовые + git (по выбору).

#### balanced
Всё из conservative, плюс:
```json
"Bash(make:*)", "Bash(curl:*)", "Bash(chmod:*)", "Bash(mkdir:*)", "Bash(bash:*)"
```

Плюс lang-specific (на основе `stack.langs` и `stack.pkg_managers`):
- php → `"Bash(composer:*)"`, `"Bash(php:*)"`
- node/ts/js → `"Bash(npm:*)"`, `"Bash(npx:*)"`, `"Bash(node:*)"`
- yarn → `"Bash(yarn:*)"`
- pnpm → `"Bash(pnpm:*)"`
- go → `"Bash(go:*)"`
- python → `"Bash(python:*)"`, `"Bash(python3:*)"`, `"Bash(pip:*)"`, `"Bash(pip3:*)"`
- cargo/rust → `"Bash(cargo:*)"`
- ruby → `"Bash(bundle:*)"`, `"Bash(rails:*)"`, `"Bash(rake:*)"`
- dotnet → `"Bash(dotnet:*)"`
- java/mvn → `"Bash(mvn:*)"`
- java/gradle → `"Bash(gradle:*)"`

Плюс lint/test команды из `stack.lint_cmds` и `stack.test_cmds` — обернуть в `Bash(command:*)`.

#### permissive
Всё из balanced, плюс git write/push если не были выбраны:
```json
"Bash(git add:*)", "Bash(git commit:*)", "Bash(git push:*)", "Bash(git pull:*)"
```

---

## 4.2 Deny rules (всегда, независимо от стека)

Защита от prompt injection через supply chain (node_modules, vendor, site-packages).

```json
"deny": [
  "Read(**/node_modules/**/SKILL.md)",
  "Read(**/node_modules/**/CLAUDE.md)",
  "Read(**/node_modules/**/AGENTS.md)",
  "Read(**/node_modules/**/.cursorrules)",
  "Read(**/vendor/**/SKILL.md)",
  "Read(**/vendor/**/CLAUDE.md)",
  "Read(**/vendor/**/AGENTS.md)",
  "Read(**/vendor/**/.cursorrules)",
  "Read(**/site-packages/**/SKILL.md)",
  "Read(**/site-packages/**/CLAUDE.md)",
  "Read(**/site-packages/**/AGENTS.md)",
  "Read(**/site-packages/**/.cursorrules)",
  "Glob(**/node_modules/**/SKILL.md)",
  "Glob(**/node_modules/**/CLAUDE.md)",
  "Glob(**/vendor/**/SKILL.md)",
  "Glob(**/vendor/**/CLAUDE.md)",
  "Glob(**/site-packages/**/SKILL.md)",
  "Glob(**/site-packages/**/CLAUDE.md)",
  "Bash(*npm install -g*)",
  "Bash(*npm i -g*)",
  "Bash(*yarn global add*)",
  "Bash(*pnpm add -g*)",
  "Bash(*curl*|*bash*)",
  "Bash(*curl*|*sh*)",
  "Bash(*wget*|*bash*)",
  "Bash(*wget*|*sh*)"
]
```

Генерировать **ВСЕГДА**, даже для non-Node проектов (vendor, site-packages покрывают PHP/Python).

В patch mode: если deny отсутствует → `[+ADD]`. Если есть кастомные deny-правила пользователя → `[USER]`, сохранить.

---

## 4.3 Hooks

Базовые hooks (всегда):
- `track-agent.sh` → PostToolUse, matcher: "Task"
- `maintain-memory.sh` → SessionStart

Если `stack.db` != none (реальная БД, не кэш/очередь):
- `update-schema.sh` → SessionStart

### Deprecated hooks (удалять автоматически в patch mode)

Если в текущем `settings.json` найдены — удалить БЕЗ подтверждения пользователя:

| Hook | Event | Причина удаления |
|------|-------|-----------------|
| `session-summary.sh` | Stop | Удалён в v5.2 — генерировал неиспользуемые отчёты |
| `git-context.sh` | SessionStart | Удалён в v5.2 — Claude Code имеет нативный доступ к git |

Также удалить:
- Весь блок `"Stop"` из hooks, если содержит только deprecated хуки
- Ссылки на несуществующие скрипты (проверить `[ -f "$CLAUDE_PROJECT_DIR/.claude/scripts/hooks/{name}.sh" ]`)

Лог: `[DEL] hooks.Stop.session-summary.sh (deprecated since v5.2)`

---

## 4.3 Режим `fresh`

Собрать permissions + hooks → записать в `.claude/settings.json`.

Если Write отклонён пользователем — верни error.

---

## Лог

Перед checkpoint запиши лог в `.claude/.cache/step-4-log.md`:

```markdown
# Step 4: Settings.json — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

Записать лог ПЕРЕД checkpoint.

## Checkpoint

Обнови `.claude/.cache/state.json`:
- `steps.settings.status` → `"completed"`
- `steps.settings.completed_at` → `"{ISO8601}"`
