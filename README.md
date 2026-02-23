# cc-bootstrapper

Система автоматического bootstrap для Claude Code. Анализирует любой проект и генерирует полную структуру `.claude/`: агенты, скиллы, пайплайны, hooks, memory, settings, CLAUDE.md.

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
    step-3-plan.md                      # Интерактивное планирование (AskUserQuestion)
    step-4-generate.md                  # Генерация: директории + агенты
    step-4b-generate.md                 # Генерация: скиллы + пайплайны
    step-4c-generate.md                 # Генерация: hooks, settings, memory, MCP
    step-5-verify.md                    # Верификация + отчёт
    templates/
      agents/                           # 11 шаблонов агентов
      skills/                           # 7 шаблонов скиллов
      pipelines/                        # 8 шаблонов пайплайнов
      hooks/                            # 3 шаблона хуков
      includes/                         # Переиспользуемые модули (capability-detect)
      settings.json.tpl                 # Шаблон settings (permissions + hooks)
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

## Что генерируется

```
.claude/
  agents/           # Агенты по ролям (architect, developer, reviewer и др.)
  skills/           # code-style, architecture, database, testing, memory, pipeline, p
  pipelines/        # new-code, fix-code, review, tests, api-docs, qa-docs, full-feature, hotfix
  scripts/hooks/    # track-agent, maintain-memory, update-schema (условно)
  scripts/          # verify-bootstrap.sh
  memory/           # facts.md, patterns.md, issues.md, sessions/, decisions/
  output/           # contracts/, qa/
  input/            # tasks/, plans/
  database/         # Схема, миграции
  settings.json     # Permissions + hooks
  .bootstrap-version  # SHA256 хеши файлов
CLAUDE.md           # Обзор проекта с индексом агентов/скиллов/пайплайнов
.mcp.json           # MCP-конфиг (опционально, GitLab)
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

### Adaptive Teams (v5.0)

Пайплайны `new-code`, `review`, `full-feature` поддерживают **adaptive execution mode**:
- **Opus 4.6** (Teams API доступен) → параллельная работа агентов через TeamCreate/Spawn/SendMessage
- **Другие модели** → автоматический fallback на последовательный Task()

Режим определяется автоматически в Phase 0 через проверку доступности инструмента `TeamCreate`. Включается опционально через AskUserQuestion на этапе планирования.

## Memory-система

Трёхуровневая система памяти проекта:

| Уровень | Файл | Назначение |
|---------|------|------------|
| Facts | `memory/facts.md` | Текущий стек, пути, активные решения |
| Patterns | `memory/patterns.md` | Повторяющиеся паттерны кода |
| Issues | `memory/issues.md` | Known issues из ревью |
| Decisions | `memory/decisions/*.md` | Архитектурные решения (ADR-lite) |
| Archive | `memory/decisions/archive/` | Устаревшие решения (авторотация 30 дней) |

Агенты пишут в memory при работе, `maintain-memory.sh` ротирует автоматически.

## Hooks

| Hook | Event | Что делает |
|------|-------|------------|
| `track-agent.sh` | PostToolUse (Task) | Логирует использование агентов в `usage.jsonl` |
| `maintain-memory.sh` | SessionStart | Ротация decisions, usage.jsonl, сессий |
| `update-schema.sh` | SessionStart, условный (если DB) | Обновляет `database/schema.sql` из Docker |

Все хуки: error handling через `trap ERR` → `.hook-errors.log`.

## MCP-интеграции

### GitLab (опционально)

Генерирует `.mcp.json` с GitLab MCP server. Настраивается на шаге планирования:
- API URL (gitlab.com или self-hosted)
- Username, Personal Access Token
- Функции: Issues, MR, Pipelines, Wiki, Milestones, Releases

## Интерактивное планирование

На шаге 3 (step-3-plan.md) система задаёт вопросы через AskUserQuestion:
- Кастомные агенты, скиллы, пайплайны
- Adaptive Teams mode (параллельная работа агентов на Opus 4.6)
- GitLab MCP интеграция (URL, token, функции)

## Поддерживаемые стеки

PHP, Node.js/TypeScript, Python, Go, Rust, Java, C#, Ruby.

Мульти-языковые проекты (PHP + Node, Go + Python и т.д.) — для каждого языка генерируется полный набор агентов: architect, developer, test-developer, reviewer-logic, reviewer-security.

## Кастомизация

После bootstrap вся сгенерированная структура — твоя. Редактируй под проект.

### Агенты (`.claude/agents/*.md`)

Каждый агент — markdown-файл с секциями: Роль, Контекст, Задача, Правила, Формат вывода.

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

Shell-скрипты, вызываемые автоматически через `settings.json`.

**Добавить новый hook:**
1. Создай `.claude/scripts/hooks/{name}.sh`
2. `chmod +x .claude/scripts/hooks/{name}.sh`
3. Добавь в `.claude/settings.json` в нужный event (`PostToolUse`, `SessionStart`)

### Настройки

**`settings.json`** — единый файл настроек: permissions + hooks.

## Версионирование

| Версия | Что нового |
|--------|------------|
| v5.2.0 | Рефакторинг хуков — 5→3, кросс-платформенность, credentials через docker exec |
| v5.1.0 | Cleanup docs, миграция state/ → memory/ |
| v5.0.0 | Adaptive Teams — Teams API с graceful degradation |
| v4.0.0 | Модульная архитектура, step-4 split на 3 батча |
| v3.0.0 | Опциональная GitLab MCP интеграция |
| v2.1.0 | AskUserQuestion для интерактивных промптов |
| v2.0.0 | Pipeline skills, memory system, upgrade mode |

## Лицензия

[MIT](LICENSE)
