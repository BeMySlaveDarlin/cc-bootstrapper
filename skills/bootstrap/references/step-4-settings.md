# Шаг 4: Settings.json

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.

## Вход
- `.bootstrap-cache/state.json` → `config` (permissions_level, git_permissions), `stack`

**Defaults если поля отсутствуют в config:**
- `permissions_level` → `"balanced"`
- `git_permissions` → `["read"]`
- `analysis_depth` → `"standard"`

## Выход
- `.claude/settings.json` (базовые permissions + hooks)
- Обновлённый state

---

## ФОРМАТ SETTINGS.JSON

**КРИТИЧЕСКИ ВАЖНО:** Соблюдай точный формат Claude Code settings.json.

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
"Read", "Write", "Edit", "WebSearch", "WebFetch",
"Bash(ls:*)", "Bash(find:*)", "Bash(cat:*)", "Bash(head:*)", "Bash(wc:*)",
"Bash(echo:*)", "Bash(test:*)", "Bash(sort:*)", "Bash(du:*)", "Bash(touch:*)",
"Bash(xargs:*)", "Bash(grep:*)", "Bash(cd:*)"
```

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

## 4.2 Hooks

Базовые hooks (всегда):
- `track-agent.sh` → PostToolUse, matcher: "Task"
- `maintain-memory.sh` → SessionStart

Если `stack.db` != none (реальная БД, не кэш/очередь):
- `update-schema.sh` → SessionStart

---

## 4.3 Режим `fresh`

Собрать permissions + hooks → записать в `.claude/settings.json`.

---

## 4.4 Режим `validate` (DIFF-BASED MERGE)

1. Прочитай `.claude/settings.json` (если существует)
2. Прочитай `.claude/settings.local.json` (если существует) — **НИКОГДА НЕ МОДИФИЦИРОВАТЬ**
3. Рассчитай diff:

| Маркер | Значение | Действие |
|--------|----------|----------|
| `[KEEP]` | Совпадает | Ничего |
| `[+ADD]` | Есть в целевом, нет в текущем | Предложить добавить |
| `[-DEL]` | Есть в текущем, нет в целевом | Предложить удалить |
| `[USER]` | Есть в текущем, нет в registry | НЕ ТРОГАТЬ |

4. Показать diff пользователю

5. AskUserQuestion:
   questions:
     - question: "Как применить изменения к settings.json?\n\nЕсли выборочно — укажи через Other номера строк для [+ADD] и [-DEL]"
       header: "Settings diff"
       options:
         - {label: "Принять все", description: "Применить все [+ADD] и [-DEL]"}
         - {label: "Только ADD", description: "Добавить новые, не удалять существующие"}
         - {label: "Пропустить", description: "Оставить без изменений"}
       multiSelect: false

   Если Other → парси список номеров/названий для применения.

6. Применить

**Примечание:** MCP permissions будут добавлены на step 5 (plugins) после установки плагинов.

---

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-4-log.md`:

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

Обнови `.bootstrap-cache/state.json`:
- `steps.4.status` → `"completed"`
- `steps.4.completed_at` → `"{ISO8601}"`
- `current_step` → 5
