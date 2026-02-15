# Шаг 3: Планирование системы

На основе анализа определи полный набор агентов, скиллов, пайплайнов.

## 3.1 Реестр агентов

### Языко-специфичные агенты

Для КАЖДОГО `{lang}` из `LANGS` сгенерируй набор из 5 агентов:

| Агент | Файл | Роль | Условие |
|-------|------|------|---------|
| {Lang} Architect | `{lang}-architect.md` | Планирование модулей | всегда |
| {Lang} Developer | `{lang}-developer.md` | Написание кода | всегда |
| {Lang} Test Developer | `{lang}-test-developer.md` | Написание тестов | всегда |
| {Lang} Reviewer Logic | `{lang}-reviewer-logic.md` | Ревью бизнес-логики | всегда |
| {Lang} Reviewer Security | `{lang}-reviewer-security.md` | Ревью безопасности | всегда |

Пример: если `LANGS=php,node` — будет 10 агентов: php-architect, php-developer, ..., node-architect, node-developer, ...

### Общие агенты (один экземпляр)

| Агент | Файл | Роль | Условие |
|-------|------|------|---------|
| DB Architect | `db-architect.md` | БД, миграции, индексы | если есть БД |
| DevOps | `devops.md` | Docker, инфра, диагностика | всегда |
| Frontend Developer | `frontend-developer.md` | Компоненты, страницы | если FRONTEND != none |
| Frontend Test Developer | `frontend-test-developer.md` | Тесты фронта | если FRONTEND != none |
| Frontend Reviewer | `frontend-reviewer.md` | Ревью фронта | если FRONTEND != none |
| Frontend Contract | `frontend-contract.md` | API-контракты | если FRONTEND != none |
| QA Engineer | `qa-engineer.md` | Чеклисты, Postman | всегда |
| CI Manager | `ci-manager.md` | CI/CD пайплайны | если `.gitlab-ci.yml` или `.github/workflows/` |

**Итого:** `len(LANGS) * 5 + общие_агенты`

### 3.1.1 Кастомные агенты

После формирования базового реестра:

**Шаг 1.** Используй AskUserQuestion:
- question: "Добавить кастомных агентов помимо базовых?"
- header: "Агенты"
- options:
  - {label: "Нет", description: "Только базовые агенты по стеку"}
  - {label: "Да", description: "Добавить кастомных агентов"}
- multiSelect: false

**Шаг 2.** Если "Да" или "Other" — используй AskUserQuestion:
- question: "Какие кастомные агенты добавить? Выбери из примеров или укажи свои через Other"
- header: "Агенты"
- options:
  - {label: "api-documenter", description: "Генерация API-документации из кода"}
  - {label: "migration-manager", description: "Управление миграциями БД и данных"}
- multiSelect: true

**Шаг 3.** Для КАЖДОГО кастомного агента — используй AskUserQuestion:
- question: "Роль агента {name}? Опиши одним предложением"
- header: "{name}"
- options:
  - {label: "Определи сам", description: "Автоматически определить роль по названию и стеку"}
  - {label: "Ревью", description: "Ревью кода определённой области"}
- multiSelect: false
(пользователь может выбрать Other и описать роль вручную)

Для каждого кастомного агента:
1. Добавь в реестр с пометкой [CUSTOM]
2. Файл: `{name}.md` (kebab-case)

Сохрани список кастомных агентов в переменную CUSTOM_AGENTS для Шага 4.

## 3.2 Скиллы

| # | Скилл | Директория |
|---|-------|------------|
| 1 | Code Style | `skills/code-style/` |
| 2 | Architecture | `skills/architecture/` |
| 3 | Database | `skills/database/` |
| 4 | Testing | `skills/testing/` |
| 5 | Memory | `skills/memory/` |
| 6 | Pipeline | `skills/pipeline/` |
| 7 | Pipeline Alias | `skills/p/` |

### 3.2.1 Кастомные скиллы

**Шаг 1.** Используй AskUserQuestion:
- question: "Добавить кастомные скиллы?"
- header: "Скиллы"
- options:
  - {label: "Нет", description: "Только базовые скиллы"}
  - {label: "Да", description: "Добавить кастомные скиллы"}
- multiSelect: false

**Шаг 2.** Если "Да" или "Other" — используй AskUserQuestion:
- question: "Какие кастомные скиллы добавить? Выбери из примеров или укажи свои через Other"
- header: "Скиллы"
- options:
  - {label: "caching", description: "Паттерны кеширования данных"}
  - {label: "notifications", description: "Паттерны отправки уведомлений"}
  - {label: "logging", description: "Стандарты логирования"}
  - {label: "monitoring", description: "Паттерны мониторинга и метрик"}
- multiSelect: true

**Шаг 3.** Для КАЖДОГО кастомного скилла — используй AskUserQuestion:
- question: "Назначение скилла {name}?"
- header: "{name}"
- options:
  - {label: "Определи сам", description: "Автоматически определить назначение по названию и стеку"}
  - {label: "Паттерны кода", description: "Правила и примеры кода для этой области"}
- multiSelect: false
(пользователь может выбрать Other и описать назначение вручную)

Для каждого кастомного скилла:
1. Добавь в реестр с пометкой [CUSTOM]
2. Директория: `skills/{name}/SKILL.md` (kebab-case)

Сохрани в CUSTOM_SKILLS.

## 3.3 Пайплайны

Всегда 8 пайплайнов: new-code, fix-code, review, tests, api-docs, qa-docs, full-feature, hotfix.

### 3.3.1 Кастомные пайплайны

**Шаг 1.** Используй AskUserQuestion:
- question: "Добавить кастомные пайплайны?"
- header: "Пайплайны"
- options:
  - {label: "Нет", description: "Только базовые 8 пайплайнов"}
  - {label: "Да", description: "Добавить кастомные пайплайны"}
- multiSelect: false

**Шаг 2.** Если "Да" или "Other" — используй AskUserQuestion:
- question: "Какие кастомные пайплайны добавить? Выбери из примеров или укажи свои через Other"
- header: "Пайплайны"
- options:
  - {label: "deploy", description: "Деплой на окружение"}
  - {label: "seed-data", description: "Генерация тестовых данных"}
  - {label: "generate-types", description: "Генерация TypeScript типов из API"}
  - {label: "migration", description: "Создание и применение миграций БД"}
- multiSelect: true

**Шаг 3.** Для КАЖДОГО кастомного пайплайна — 2 вопроса через AskUserQuestion:

Вопрос 1:
- question: "Когда использовать {name}?"
- header: "{name}"
- options:
  - {label: "Определи сам", description: "Автоматически определить сценарий по названию и стеку"}
  - {label: "По запросу", description: "Только по явному вызову пользователя"}
- multiSelect: false
(пользователь может выбрать Other и описать сценарий вручную)

Вопрос 2:
- question: "Какие агенты задействованы в {name}?"
- header: "{name}"
- options из текущего реестра агентов (developer, architect, test-developer, reviewer) + {label: "Определи сам", description: "Автоматически подобрать агентов по типу пайплайна"}
- multiSelect: true

Для каждого кастомного пайплайна:
1. Добавь в реестр с пометкой [CUSTOM]
2. Файл: `pipelines/{name}.md` (kebab-case)

Сохрани в CUSTOM_PIPELINES.

## 3.4 MCP-интеграции

### 3.4.1 GitLab MCP

**Шаг 1.** Используй AskUserQuestion:
- question: "Настроить интеграцию с GitLab через MCP? Позволяет управлять issues, MR, pipelines, wiki прямо из Claude Code"
- header: "GitLab MCP"
- options:
  - {label: "Да", description: "Настроить GitLab MCP — потребуется URL, username и токен"}
  - {label: "Нет", description: "Пропустить интеграцию с GitLab"}
- multiSelect: false

Если GITLAB_DETECTED=true — показать рекомендацию "(Рекомендуется)" в описании первой опции.

**Если "Нет"** → пропустить, установить `GITLAB_MCP=false`.

**Шаг 2.** Если "Да" — используй AskUserQuestion:
- question: "GitLab API URL?"
- header: "GitLab URL"
- options:
  - {label: "gitlab.com", description: "https://gitlab.com/api/v4 (публичный GitLab)"}
  - {label: "Self-hosted", description: "Укажи URL через Other в формате https://your-gitlab.com/api/v4"}
- multiSelect: false

Сохрани в `GITLAB_API_URL`.

**Шаг 3.** Используй AskUserQuestion:
- question: "GitLab username?"
- header: "Username"
- options:
  - {label: "Из git config", description: "Использовать имя из git config user.name"}
  - {label: "Ввести вручную", description: "Укажи username через Other"}
- multiSelect: false

Сохрани в `GITLAB_USERNAME`. При "Из git config" — выполни `git config user.name`.

**Шаг 4.** Используй AskUserQuestion:
- question: "GitLab Personal Access Token? Создай в GitLab → Settings → Access Tokens (scopes: api, read_user)"
- header: "Token"
- options:
  - {label: "Введу позже", description: "Создать .mcp.json с плейсхолдером YOUR_TOKEN_HERE"}
  - {label: "Ввести сейчас", description: "Введи токен через Other (glpat-...)"}
- multiSelect: false

Сохрани в `GITLAB_TOKEN`.

**Шаг 5.** Используй AskUserQuestion:
- question: "Какие функции GitLab MCP включить?"
- header: "Функции"
- options:
  - {label: "Issues + MR", description: "Управление задачами и merge requests"}
  - {label: "Issues + MR + Wiki", description: "Плюс работа с Wiki страницами"}
  - {label: "Все", description: "Issues, MR, Pipelines, Milestones, Wiki, Releases"}
- multiSelect: false

Сохрани в переменные `USE_PIPELINE`, `USE_MILESTONE`, `USE_GITLAB_WIKI` (true/false).

Установи `GITLAB_MCP=true`.

**Отчёт:** финальный список агентов/скиллов/пайплайнов с пометками [CREATE] / [SKIP] / [CUSTOM].
