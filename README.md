# cc-bootstrapper

Система автоматического bootstrap для Claude Code. Анализирует любой проект и генерирует полную структуру `.claude/`: агенты, скиллы, пайплайны, hooks, state, settings, CLAUDE.md.

## Требования

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Bash 4+
- `jq`
- macOS, Linux или Windows (WSL)

## Структура

```
commands/
  bootstrap.md              # /bootstrap команда — точка входа
prompts/
  meta-prompt-bootstrap.md  # Meta-prompt с логикой генерации
```

## Установка

```bash
cp commands/bootstrap.md ~/.claude/commands/
cp prompts/meta-prompt-bootstrap.md ~/.claude/prompts/
```

## Использование

`/bootstrap` — slash-команда, запускается **внутри Claude Code**, не в обычном терминале:

```bash
cd /path/to/your-project
claude
```
```
> /bootstrap
```

## Что генерируется

```
.claude/
  agents/           # Агенты по ролям (architect, developer, reviewer и др.)
  skills/           # Code style, architecture, database, testing, routing
  pipelines/        # new-code, fix-code, review, tests, api-docs, qa-docs, full-feature, hotfix
  scripts/hooks/    # track-agent.sh, session-summary.sh, update-schema.sh
  state/            # session.md, task-log.md, sessions/
  output/           # contracts/, qa/
  input/            # Задачи, планы
  database/         # Схема, миграции
  settings.json     # Общие permissions
CLAUDE.md           # Обзор проекта с индексом агентов/скиллов/пайплайнов
```

## Поддерживаемые стеки

PHP, Node.js/TypeScript, Python, Go, Rust, Java, C#, Ruby. Мульти-языковые проекты поддерживаются (например PHP + Node, Go + Python).

## Кастомизация

После bootstrap вся сгенерированная структура — твоя. Редактируй под проект.

### Агенты (`.claude/agents/*.md`)

Каждый агент — markdown-файл с секциями: Роль, Контекст, Задача, Правила, Формат вывода.

**Что можно менять:**
- **Контекст** — добавить пути к файлам/директориям, которые агент должен читать
- **Правила** — добавить специфичные для проекта запреты или требования
- **Формат вывода** — изменить структуру ответа (таблица, список, файлы)
- **Чеклист** (для reviewer) — добавить/убрать пункты проверки

**Пример:** добавить правило в `php-developer.md`:
```markdown
## Правила
- Все сервисы — final class
- Запрещён Eloquent, только DB::table()
+ - Все даты через CarbonImmutable
+ - Enum вместо строковых констант
```

**Добавить нового агента:**
1. Создай `.claude/agents/{name}.md` по структуре существующих
2. Добавь строку в таблицу `## Agents` в `CLAUDE.md`
3. При необходимости подключи в пайплайн

### Скиллы (`.claude/skills/{name}/SKILL.md`)

Скиллы — базы знаний, которые агенты читают как контекст. Не вызываются напрямую.

**Что можно менять:**
- **code-style** — правила именования, запреты, примеры хорошего/плохого кода
- **architecture** — структура модулей, DI-паттерны, цепочки зависимостей
- **database** — типы столбцов, правила миграций, именование индексов
- **testing** — шаблон теста, правила моков, именование тест-методов
- **routing** — ключевые слова для автоопределения пайплайна

**Добавить новый скилл:**
1. `mkdir -p .claude/skills/{name}`
2. Создай `SKILL.md` с секциями: Паттерны, Антипаттерны, Примеры
3. Добавь путь в секцию `## Контекст` нужных агентов
4. Добавь строку в таблицу `## Skills` в `CLAUDE.md`

### Пайплайны (`.claude/pipelines/*.md`)

Пайплайн — последовательность фаз, каждая вызывает агента.

**Что можно менять:**
- **Фазы** — добавить/убрать/переупорядочить шаги
- **Агенты** — заменить агента на другого в фазе
- **Матрица ошибок** — изменить поведение при сбое (откат, повтор, стоп)
- **Команды** — заменить `TEST_CMD`, `LINT_CMD` на актуальные

**Пример:** добавить lint-фазу в `new-code.md`:
```markdown
### Phase 3.5: LINT
1. Запусти: `npm run lint -- --fix`
2. Если ошибки → исправить
```

**Добавить новый пайплайн:**
1. Создай `.claude/pipelines/{name}.md` (минимум 2 фазы)
2. Добавь ключевые слова в `skills/routing/SKILL.md`
3. Добавь строку в таблицу `## Pipelines` в `CLAUDE.md`
4. Запуск: `{задача} by pipeline {name}`

### Hooks (`.claude/scripts/hooks/*.sh`)

Shell-скрипты, вызываемые автоматически через `settings.local.json`.

| Hook | Когда срабатывает | Что делает |
|------|-------------------|------------|
| `track-agent.sh` | После вызова Task | Логирует использование агентов |
| `session-summary.sh` | При завершении сессии | Создаёт отчёт в `state/sessions/` |
| `update-schema.sh` | На старте + после Task | Обновляет `database/schema.sql` |

**Добавить новый hook:**
1. Создай `.claude/scripts/hooks/{name}.sh`
2. `chmod +x .claude/scripts/hooks/{name}.sh`
3. Добавь в `.claude/settings.local.json` в нужный event (`PostToolUse`, `SessionStart`, `Stop`)

### Настройки

- **`settings.json`** — общие (в git), только permissions
- **`settings.local.json`** — локальные (в .gitignore), permissions + hooks

Добавляй разрешения в `permissions.allow` по паттерну `Tool(аргумент)`.
