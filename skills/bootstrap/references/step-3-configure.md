# Шаг 3: Настройка bootstrap

## Вход
- `.bootstrap-cache/state.json` (stack + mode из step 1-2)

## Выход
- `state.config` заполнен
- Частично `state.registries` (кастомные элементы)

## Правило resume

Если `state.mode = "resume"` и `state.config` уже содержит ответы — **пропустить** соответствующие вопросы. Спрашивать только то, чего нет в state.

---

## 3.1 Опциональные фичи (multiSelect)

Используй AskUserQuestion:
- question: "Какие опции включить? (Enter — базовая конфигурация)"
- header: "Конфигурация bootstrap"
- options:
  - {label: "Custom agents", description: "Добавить кастомных агентов помимо базовых по стеку"}
  - {label: "Custom skills", description: "Добавить кастомные скиллы"}
  - {label: "Custom pipelines", description: "Добавить кастомные пайплайны"}
- multiSelect: true

Сохрани выбранные опции в `state.config.features[]`.

---

## 3.2 Глубина анализа (singleSelect, ВСЕГДА спрашивать, даже если 3.1 = базовая)

Перед вопросом рассчитай оценку стоимости анализа на основе данных из state.stack:

```
FILE_COUNT = количество исходных файлов в проекте (из state.stack или быстрый подсчёт через find)
LANG_COUNT = количество языков

ESTIMATE_LIGHT = 0  # уже выполнен на шаге 1
ESTIMATE_STANDARD = LANG_COUNT * 3000 + min(FILE_COUNT, 50) * 200  # ~tokens на чтение ключевых файлов
ESTIMATE_DEEP = LANG_COUNT * 8000 + min(FILE_COUNT, 200) * 300     # ~tokens на полный скан
```

Используй AskUserQuestion:
- question: "Глубина анализа проекта?"
- header: "Анализ"
- options:
  - {label: "light", description: "Только manifest + структура (уже выполнен, +0 tokens)"}
  - {label: "standard (рекомендуется)", description: "+ паттерны кода, naming conventions (~{ESTIMATE_STANDARD} tokens)"}
  - {label: "deep", description: "+ архитектура, API-контракты, test coverage (~{ESTIMATE_DEEP} tokens)"}
- multiSelect: false

Сохрани в `state.config.analysis_depth`: `"light"` | `"standard"` | `"deep"`.

---

## 3.3 Уровень permissions (singleSelect, ВСЕГДА спрашивать, даже если 3.1 = базовая)

Используй AskUserQuestion:
- question: "Уровень permissions для settings.json?"
- header: "Permissions"
- options:
  - {label: "conservative", description: "Только read-операции: Bash(git status/log/diff), Read, Glob, Grep"}
  - {label: "balanced (рекомендуется)", description: "+ lint/test команды, language tools (composer, npm, pip, cargo)"}
  - {label: "permissive", description: "+ docker, git write (add/commit/push), deploy-скрипты"}
- multiSelect: false

Сохрани в `state.config.permissions_level`: `"conservative"` | `"balanced"` | `"permissive"`.

## 3.3.1 Git permissions (multiSelect, ВСЕГДА спрашивать)

Используй AskUserQuestion:
- question: "Какие git-операции разрешить?"
- header: "Git"
- options:
  - {label: "Read", description: "git status, git log, git diff, git show, git branch (рекомендуется)"}
  - {label: "Write", description: "git add, git commit"}
  - {label: "Push", description: "git push, git pull, git fetch"}
  - {label: "Delete", description: "git reset, git checkout --, git clean, git branch -D"}
- multiSelect: true

Сохрани в `state.config.git_permissions[]`: массив выбранных (`["read"]`, `["read", "write"]`, etc.).

Маппинг на Bash permissions:
- Read → `Bash(git status:*)`, `Bash(git log:*)`, `Bash(git diff:*)`, `Bash(git show:*)`, `Bash(git branch:*)`, `Bash(git rev-parse:*)`
- Write → `Bash(git add:*)`, `Bash(git commit:*)`
- Push → `Bash(git push:*)`, `Bash(git pull:*)`, `Bash(git fetch:*)`
- Delete → `Bash(git reset:*)`, `Bash(git checkout:*)`, `Bash(git clean:*)`, `Bash(git branch -D:*)`, `Bash(git stash:*)`


Маппинг:
- host → `Bash(docker:*)`, `Bash(docker compose:*)`
- read → `Bash(docker ps:*)`, `Bash(docker logs:*)`, `Bash(docker inspect:*)`
- none → ничего

---

## 3.4 Условные follow-ups

Спрашивать только если соответствующая опция выбрана в 3.1.

### Custom agents (если выбрано)

Покажи базовый набор агентов по стеку:

```
Базовые агенты по стеку:
- {lang}-architect, {lang}-developer, {lang}-test-developer, {lang}-reviewer (для каждого lang)
- analyst, storage-architect (условный), devops, qa-engineer
- ci-manager (если CI обнаружен)
```

Используй AskUserQuestion:
- question: "Какие кастомные агенты добавить?"
- header: "Custom agents"
- options:
  - {label: "api-documenter", description: "Генерация API-документации из кода"}
  - {label: "migration-manager", description: "Управление миграциями БД и данных"}
  - {label: "performance-engineer", description: "Оптимизация производительности, профилирование"}
- multiSelect: true

Для КАЖДОГО выбранного/введённого агента — AskUserQuestion:
- question: "Роль агента {name}?"
- header: "{name}"
- options:
  - {label: "Определи сам", description: "Автоматически по названию и стеку"}
- multiSelect: false
(пользователь может описать роль через Other)

Сохрани в `state.config.custom_agents[]`: `[{name, role}]`.

### Custom skills (если выбрано)

Покажи базовые 7 скиллов:

```
Базовые скиллы: code-style, architecture, storage, testing, memory, pipeline, p (alias)
```

Используй AskUserQuestion:
- question: "Какие кастомные скиллы добавить?"
- header: "Custom skills"
- options:
  - {label: "caching", description: "Паттерны кеширования данных"}
  - {label: "notifications", description: "Паттерны отправки уведомлений"}
  - {label: "logging", description: "Стандарты логирования"}
  - {label: "monitoring", description: "Паттерны мониторинга и метрик"}
  - {label: "queue", description: "Паттерны очередей и async-обработки"}
- multiSelect: true

Для КАЖДОГО — AskUserQuestion:
- question: "Назначение скилла {name}?"
- header: "{name}"
- options:
  - {label: "Определи сам", description: "Автоматически по названию и стеку"}
- multiSelect: false

Сохрани в `state.config.custom_skills[]`: `[{name, description}]`.

### Custom pipelines (если выбрано)

Покажи базовые 8 пайплайнов:

```
Базовые пайплайны: new-code, fix-code, review, tests, api-docs, qa-docs, full-feature, hotfix
```

Используй AskUserQuestion:
- question: "Какие кастомные пайплайны добавить?"
- header: "Custom pipelines"
- options:
  - {label: "deploy", description: "Деплой на окружение"}
  - {label: "seed-data", description: "Генерация тестовых данных"}
  - {label: "generate-types", description: "Генерация TypeScript типов из API"}
  - {label: "migration", description: "Создание и применение миграций БД"}
- multiSelect: true

Для КАЖДОГО кастомного пайплайна — 2 вопроса:

Вопрос 1 — AskUserQuestion:
- question: "Когда использовать {name}?"
- header: "{name} — триггер"
- options:
  - {label: "Определи сам", description: "Автоматически по названию и стеку"}
  - {label: "По запросу", description: "Только по явному вызову пользователя"}
- multiSelect: false

Вопрос 2 — AskUserQuestion:
- question: "Какие агенты задействованы в {name}?"
- header: "{name} — агенты"
- options из текущего реестра (developer, architect, test-developer, reviewer, devops, analyst) + {label: "Определи сам", description: "Подобрать автоматически"}
- multiSelect: true

Сохрани в `state.config.custom_pipelines[]`: `[{name, trigger, agents}]`.

---

## 3.5 Значения по умолчанию

Если опция НЕ выбрана в 3.1 — установи значения по умолчанию:

| Опция | Default |
|-------|---------|
| custom_agents | `[]` |
| custom_skills | `[]` |
| custom_pipelines | `[]` |
| gitlab_mcp | `false` |
| gitlab | `{}` |

---

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-3-log.md`:

```markdown
# Step 3: Настройка bootstrap — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

Записать лог ПЕРЕД checkpoint.

## 3.6 Checkpoint

Обнови `.bootstrap-cache/state.json`:
- `state.config` — все ответы
- `steps.3.status` → `"completed"`
- `steps.3.completed_at` → `"{ISO8601}"`
- `current_step` → `4`
- `updated_at` → `"{ISO8601}"`

**Отчёт:** краткая сводка выбранной конфигурации.
