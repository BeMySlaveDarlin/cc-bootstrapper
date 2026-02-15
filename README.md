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
  bootstrap.md                          # /bootstrap slash command — точка входа
prompts/
  meta-prompt-bootstrap.md              # Оркестратор — читает шаги последовательно
  bootstrap/
    step-1-analyze.md                   # Анализ стека
    step-2-claude-md.md                 # CLAUDE.md генерация/валидация
    step-3-plan.md                      # Интерактивное планирование
    step-4-generate.md                  # Генерация файлов с валидацией
    step-5-verify.md                    # Верификация + отчёт
    templates/
      agents/                           # 11 шаблонов агентов
      skills/                           # 7 шаблонов скиллов
      pipelines/                        # 8 шаблонов пайплайнов
      hooks/                            # 5 шаблонов хуков
      settings.json.tpl                 # Шаблон shared settings
      settings.local.json.tpl           # Шаблон local settings
      verify-bootstrap.sh               # Скрипт верификации
```

## Установка

```bash
cp commands/bootstrap.md ~/.claude/commands/
cp prompts/meta-prompt-bootstrap.md ~/.claude/prompts/
cp -r prompts/bootstrap ~/.claude/prompts/
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

### Режимы работы

Режим определяется автоматически:

| Условие | Режим | Поведение |
|---------|-------|-----------|
| `.claude/` не существует | `fresh` | Полная генерация с нуля |
| `.claude/` существует | `validate` | Проверка каждого файла + auto-fix |

В режиме `validate` каждый файл проверяется на соответствие эталону:
- `[OK]` — файл соответствует
- `[FIX]` — проблема найдена и исправлена автоматически
- `[NEW]` — файл отсутствовал, создан из шаблона
- `[REGEN]` — файл пересоздан (критичные расхождения)
- `[WARN]` — предупреждение (устаревший файл)

Ноль интерактивных вопросов при валидации (кроме settings.json).

## Что генерируется

```
.claude/
  agents/           # Агенты по ролям (architect, developer, reviewer и др.)
  skills/           # code-style, architecture, database, testing, memory, pipeline, p
  pipelines/        # new-code, fix-code, review, tests, api-docs, qa-docs, full-feature, hotfix
  scripts/hooks/    # track-agent, session-summary, update-schema, maintain-memory, git-context
  scripts/          # verify-bootstrap.sh
  state/            # facts.md, memory/, sessions/, decisions/
  output/           # contracts/, qa/
  input/            # tasks/, plans/
  database/         # Схема, миграции
  settings.json     # Общие permissions
  settings.local.json # Hooks + локальные permissions
  .bootstrap-version  # SHA256 хеши файлов
CLAUDE.md           # Обзор проекта с индексом агентов/скиллов/пайплайнов
```

## Invocable Skills

| Команда | Назначение |
|---------|------------|
| `/pipeline [action]` | Роутер пайплайнов — классифицирует задачу и запускает pipeline |
| `/p [action]` | Alias для `/pipeline` |

Примеры:
```
/pipeline review          → запуск review pipeline
/p fix баг в авторизации  → определит fix-code pipeline
/p                        → определит тип по контексту
```

## Pipeline-система

8 базовых пайплайнов + кастомные при генерации:

| Pipeline | Когда |
|----------|-------|
| `new-code` | Новый модуль, сервис, эндпоинт |
| `fix-code` | Баг, ошибка, regression |
| `review` | Ревью кода |
| `tests` | Написание тестов |
| `api-docs` | API-контракты для фронта |
| `qa-docs` | Чеклисты, Postman |
| `full-feature` | Полный цикл фичи |
| `hotfix` | Срочное исправление |

CLAUDE.md содержит ЖЁСТКОЕ ПРАВИЛО автоматического вызова `/pipeline` для релевантных запросов.

## Memory-система

Трёхуровневая система памяти проекта:

| Уровень | Файл | Назначение |
|---------|------|------------|
| Facts | `state/facts.md` | Текущий стек, пути, активные решения |
| Patterns | `state/memory/patterns.md` | Повторяющиеся паттерны кода |
| Issues | `state/memory/issues.md` | Known issues из ревью |
| Decisions | `state/decisions/*.md` | Архитектурные решения (ADR-lite) |
| Archive | `state/decisions/archive/` | Устаревшие решения (авторотация 30 дней) |

Агенты пишут в memory при работе, `maintain-memory.sh` ротирует автоматически.

## Hooks

| Hook | Event | Что делает |
|------|-------|------------|
| `track-agent.sh` | PostToolUse (Task) | Логирует использование агентов в `usage.jsonl` |
| `session-summary.sh` | Stop | Создаёт отчёт в `state/sessions/` |
| `update-schema.sh` | SessionStart + PostToolUse | Обновляет `database/schema.sql` из Docker |
| `maintain-memory.sh` | SessionStart | Ротация decisions, usage.jsonl, сессий |
| `git-context.sh` | SessionStart | Собирает branch, commits, changes → `.git-context.md` |

Все хуки: error handling через `trap ERR` → `.hook-errors.log`.

## Поддерживаемые стеки

PHP, Node.js/TypeScript, Python, Go, Rust, Java, C#, Ruby.

Мульти-языковые проекты (PHP + Node, Go + Python и т.д.) — для каждого языка генерируется полный набор агентов: architect, developer, test-developer, reviewer-logic, reviewer-security.

## Кастомизация

После bootstrap вся сгенерированная структура — твоя. Редактируй под проект.

### Агенты (`.claude/agents/*.md`)

Каждый агент — markdown-файл с секциями: Роль, Контекст, Задача, Правила, Формат вывода.

**Что можно менять:**
- **Контекст** — добавить пути к файлам/директориям, которые агент должен читать
- **Правила** — добавить специфичные для проекта запреты или требования
- **Формат вывода** — изменить структуру ответа (таблица, список, файлы)
- **Чеклист** (для reviewer) — добавить/убрать пункты проверки

**Добавить нового агента:**
1. Создай `.claude/agents/{name}.md` по структуре существующих
2. Добавь строку в таблицу `## Agents` в `CLAUDE.md`
3. При необходимости подключи в пайплайн

### Скиллы (`.claude/skills/{name}/SKILL.md`)

Скиллы — базы знаний для агентов. `pipeline` и `p` — invocable (вызываются через `/`).

**Добавить новый скилл:**
1. `mkdir -p .claude/skills/{name}`
2. Создай `SKILL.md` с секциями: Паттерны, Антипаттерны, Примеры
3. Для invocable: добавь YAML frontmatter `user-invocable: true`
4. Добавь строку в таблицу `## Skills` в `CLAUDE.md`

### Пайплайны (`.claude/pipelines/*.md`)

Пайплайн — последовательность фаз, каждая вызывает агента через Task() pseudo-syntax.

**Добавить новый пайплайн:**
1. Создай `.claude/pipelines/{name}.md` (минимум 2 фазы)
2. Добавь keywords в `skills/pipeline/SKILL.md`
3. Добавь строку в таблицу `## Pipelines` в `CLAUDE.md`
4. Запуск: `/pipeline {name}` или `/p {name}`

### Hooks (`.claude/scripts/hooks/*.sh`)

Shell-скрипты, вызываемые автоматически через `settings.local.json`.

**Добавить новый hook:**
1. Создай `.claude/scripts/hooks/{name}.sh`
2. `chmod +x .claude/scripts/hooks/{name}.sh`
3. Добавь в `.claude/settings.local.json` в нужный event (`PostToolUse`, `SessionStart`, `Stop`)

### Настройки

- **`settings.json`** — общие (в git), только permissions
- **`settings.local.json`** — локальные (в .gitignore), permissions + hooks

## Лицензия

[MIT](LICENSE)
