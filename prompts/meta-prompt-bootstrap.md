# Meta-Prompt: Bootstrap Claude Code Automation System

> **Назначение:** Самодостаточный промпт для LLM. Анализирует любой проект, генерирует полную систему автоматизации Claude Code: агенты, скиллы, пайплайны, hooks, state, settings, CLAUDE.md.
>
> **Использование:** Скопируй этот промпт целиком в новый чат Claude Code в корне проекта.

---

## VERSION

```
VERSION_CURRENT = "2.1.0"
```

## CHANGELOG

### 2.1.0 (2026-02-13)
- Все интерактивные вопросы через AskUserQuestion (структурированный UI вместо текстовых y/n)
- Кастомные агенты/скиллы/пайплайны: двухшаговый процесс (Да/Нет → multiSelect с примерами)

### 2.0.0 (2026-02-13)
- Pipeline skill-роутер (`/pipeline`, `/p`) вместо пассивного `skills/routing/`
- Memory-система по умолчанию (`state/memory/patterns.md`, `issues.md`)
- Удалены `session.md` и `task-log.md` (заменены hooks-based tracking)
- Починены хуки: maintain-memory.sh, update-schema.sh, session-summary.sh
- Верификация вынесена в `scripts/verify-bootstrap.sh`
- Auto-Pipeline Rule в CLAUDE.md
- Upgrade mode для обновления bootstrapped проектов
- `.bootstrap-version` — отслеживание версии и хешей

### 1.0.0 (initial)
- Базовая система: agents, skills, pipelines, hooks, state, CLAUDE.md

---

## ИНСТРУКЦИЯ

Все вопросы пользователю задавай через инструмент AskUserQuestion. Не задавай вопросы текстом — используй структурированные варианты ответа с options. Для открытых вопросов пользователь может выбрать "Other" и ввести произвольный текст.

Ты — инженер автоматизации. Твоя задача — проанализировать текущий проект и создать полную систему автоматизации Claude Code в директории `.claude/`.

Выполни шаги последовательно. После каждого шага покажи краткий отчёт. Если шаг не применим — пропусти с пометкой `[SKIP]`.

---

## ШАГ 1: АНАЛИЗ ПРОЕКТА

Проанализируй проект и запиши результаты. Используй файловую структуру, package.json/composer.json/go.mod/Cargo.toml/requirements.txt, Dockerfile, CI configs.

### Что определить:

| Параметр | Как определить |
|----------|----------------|
| **Язык backend** | composer.json → PHP; package.json + tsconfig → Node/TS; go.mod → Go; Cargo.toml → Rust; requirements.txt/pyproject.toml → Python; *.csproj → C#; pom.xml/build.gradle → Java; Gemfile → Ruby |
| **Фреймворк backend** | Laravel/Lumen, Express/Nest/Fastify, Gin/Echo/Fiber, Actix/Axum, Django/FastAPI/Flask, ASP.NET, Spring Boot, Rails |
| **Язык frontend** | TypeScript/JavaScript |
| **Фреймворк frontend** | angular.json → Angular; next.config → Next.js; vite.config + react → React; nuxt.config → Nuxt/Vue; svelte.config → SvelteKit |
| **БД** | docker-compose (mysql/postgres/mongo), .env (DB_CONNECTION), миграции |
| **ORM/Query** | Eloquent, Prisma, TypeORM, GORM, SQLAlchemy, ActiveRecord, raw SQL |
| **Тесты backend** | PHPUnit, Jest, pytest, go test, cargo test, NUnit, JUnit, RSpec |
| **Тесты frontend** | Jest, Vitest, Cypress, Playwright, Karma/Jasmine |
| **Инфра** | Docker/docker-compose, Makefile, CI (GitHub Actions, GitLab CI) |
| **API стиль** | REST, GraphQL, gRPC |
| **Auth** | JWT, Session, OAuth, API keys |

### Сохрани результат анализа как переменные для дальнейшего использования:

```
LANGS=php,node           # все языки backend через запятую (определи ВСЕ языки проекта)
PRIMARY_LANG=php          # основной язык (больше кода / главный сервис)

# Для КАЖДОГО языка из LANGS определи:
FRAMEWORK_{lang}=lumen|laravel|express|nestjs|fastapi|django|gin|actix|spring|rails|aspnet
TEST_FRAMEWORK_{lang}=phpunit|jest|pytest|gotest|cargotest|junit|nunit|rspec
TEST_CMD_{lang}="<команда запуска тестов для {lang}>"
LINT_CMD_{lang}="<команда линтера для {lang}>"

# Алиасы для PRIMARY_LANG (обратная совместимость):
LANG=$PRIMARY_LANG
FRAMEWORK=$FRAMEWORK_{PRIMARY_LANG}
TEST_FRAMEWORK=$TEST_FRAMEWORK_{PRIMARY_LANG}
TEST_CMD=$TEST_CMD_{PRIMARY_LANG}
LINT_CMD=$LINT_CMD_{PRIMARY_LANG}

# Общие (без изменений):
FRONTEND=angular|react|vue|svelte|nextjs|nuxtjs|none
FRONTEND_TEST=jest|vitest|cypress|playwright|karma|none
DB=mysql|postgres|mongo|sqlite|none
CONTAINER=docker|podman|none
PKG_MANAGER=composer|npm|yarn|pnpm|pip|cargo|go|maven|gradle|bundler
```

**Отчёт:** таблица с результатами анализа.

---

## ШАГ 2: ОБРАБОТКА CLAUDE.md

### Если CLAUDE.md существует:

1. Прочитай текущий `CLAUDE.md`
2. Вычлени из него:
   - **Правила кода** (стиль, именование, типизация, запреты) → будут в `skills/code-style/SKILL.md`
   - **Архитектура** (структура модулей, DI, паттерны) → будут в `skills/architecture/SKILL.md`
   - **БД паттерны** (миграции, типы, индексы) → будут в `skills/database/SKILL.md`
   - **Тест паттерны** (фреймворк, моки, структура) → будут в `skills/testing/SKILL.md`
   - **Команды** (build, test, deploy) → будут в агентах devops, developer

### Перезапиши CLAUDE.md по шаблону:

```markdown
# CLAUDE.md

## Project Overview

{PROJECT_NAME} — {краткое описание из анализа}.

{для каждого lang из LANGS:}
- {LANG} {VERSION} + {FRAMEWORK_{lang}}
{/для каждого}
- {DB} + {CONTAINER}
- {FRONTEND} (frontend)

## Rules

- Кратко, по делу, без теории
- Код — только по прямому запросу
- Никаких docblock или comments в коде, если они не требуются для static analysis
- Никаких git commit или git push, если не попросят
{LANG_SPECIFIC_RULES — вычлени из старого CLAUDE.md или определи по стеку}

## Commands

```bash
{BUILD_CMD}
{TEST_CMD}
{LINT_CMD}
{MIGRATE_CMD}
{OTHER_CMDS}
```

## Architecture

### Module Structure
```
{ACTUAL_MODULE_STRUCTURE — сканируй src/ или app/ или lib/}
```

### Key Principles
{PRINCIPLES — вычлени из старого CLAUDE.md или определи по стеку}

### Main Modules
{MODULES — сканируй реальные модули проекта}

### Database
{DB_INFO}

### Services (Docker)
{DOCKER_SERVICES — из docker-compose}

## Code Style
{CODE_STYLE_SUMMARY — краткая выжимка из skills/code-style}

## Agents

Промпты: `.claude/agents/{name}.md`

| Agent | Файл | Триггер |
|-------|------|---------|
{AGENTS_TABLE}

## Skills

Детали: `.claude/skills/{name}/SKILL.md`

| Skill | Файл | Назначение |
|-------|------|------------|
| Code Style | `code-style/` | паттерны кода, антипаттерны |
| Architecture | `architecture/` | структура модулей, DI, routes |
| Database | `database/` | миграции, типы данных, индексы |
| Testing | `testing/` | тест-паттерны |
| Memory | `memory/` | трёхуровневая память: facts, decisions, archive |
| Pipeline | `pipeline/` | `/pipeline` — роутер пайплайнов |
| Pipeline Alias | `p/` | `/p` — быстрый вызов /pipeline |
{CUSTOM_SKILLS_ROWS}

## Auto-Pipeline Rule

Каждый запрос пользователя проверять: если связан с написанием кода, фиксами, ревью, тестами — вызвать `/pipeline`. Роутер внутри определит тип.

## Pipelines

Детали: `.claude/pipelines/{name}.md`

Запуск: `/pipeline {имя}` или `/p {имя}`

| Pipeline | Файл | Когда использовать |
|----------|------|--------------------|
| New Code | `new-code.md` | новый модуль, сервис, эндпоинт |
| Fix Code | `fix-code.md` | баг, ошибка, regression |
| Review | `review.md` | ревью кода |
| Tests | `tests.md` | написание тестов |
| API Docs | `api-docs.md` | API-контракты для фронта |
| QA Docs | `qa-docs.md` | чеклисты, Postman |
| Full Feature | `full-feature.md` | полный цикл фичи |
| Hotfix | `hotfix.md` | срочное исправление |
{CUSTOM_PIPELINES_ROWS}

## State Management

- `.claude/state/facts.md` — текущие факты проекта (стек, пути, решения, проблемы)
- `.claude/state/memory/patterns.md` — повторяющиеся паттерны кода
- `.claude/state/memory/issues.md` — known issues из ревью
- `.claude/state/decisions/` — архитектурные решения (ADR-lite)
- `.claude/state/decisions/archive/` — устаревшие решения (авторотация 30 дней)
- `.claude/state/sessions/` — архив сессий
- `.claude/output/` — API-контракты, QA-документация
- `.claude/input/` — входные задачи, планы
- `.claude/database/` — схема БД, миграции
```

### Если CLAUDE.md не существует:

Создай по шаблону выше, заполнив из результатов анализа.

**Отчёт:** что вычленено, что создано.

---

## ШАГ 3: ПЛАНИРОВАНИЕ СИСТЕМЫ

На основе анализа определи полный набор агентов, скиллов, пайплайнов.

### 3.1 Реестр агентов

#### Языко-специфичные агенты

Для КАЖДОГО `{lang}` из `LANGS` сгенерируй набор из 5 агентов:

| Агент | Файл | Роль | Условие |
|-------|------|------|---------|
| {Lang} Architect | `{lang}-architect.md` | Планирование модулей | всегда |
| {Lang} Developer | `{lang}-developer.md` | Написание кода | всегда |
| {Lang} Test Developer | `{lang}-test-developer.md` | Написание тестов | всегда |
| {Lang} Reviewer Logic | `{lang}-reviewer-logic.md` | Ревью бизнес-логики | всегда |
| {Lang} Reviewer Security | `{lang}-reviewer-security.md` | Ревью безопасности | всегда |

Пример: если `LANGS=php,node` — будет 10 агентов: php-architect, php-developer, ..., node-architect, node-developer, ...

#### Общие агенты (один экземпляр)

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

### 3.2 Скиллы

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

### 3.3 Пайплайны

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

**Отчёт:** финальный список агентов/скиллов/пайплайнов с пометками [CREATE] / [SKIP] / [CUSTOM].

---

## ШАГ 4: ГЕНЕРАЦИЯ

### 4.1 Директории

```bash
mkdir -p .claude/{agents,skills/{code-style,architecture,database,testing,memory,pipeline,p},pipelines,scripts/hooks,state/{sessions,sessions/archive,decisions,decisions/archive,memory},output/{contracts,qa},input/{tasks,plans},database}
touch .claude/state/decisions/.gitkeep .claude/state/decisions/archive/.gitkeep
```

Если CUSTOM_SKILLS не пуст — создай дополнительные директории:
```bash
mkdir -p .claude/skills/{custom_skill_1,custom_skill_2,...}
```

### 4.2 Агенты

**Мульти-языковая генерация:** Шаблоны ниже (Architect, Developer, Test Developer, Reviewer Logic, Reviewer Security) генерируй для КАЖДОГО языка из `LANGS`. Для каждого языка подставляй соответствующие `FRAMEWORK_{lang}`, `TEST_FRAMEWORK_{lang}`, `TEST_CMD_{lang}`, `LINT_CMD_{lang}`.

Общие агенты (DB Architect, DevOps, Frontend*, QA Engineer) — генерируются в одном экземпляре.

Генерируй каждый файл агента по шаблонам ниже, адаптируя под конкретный стек.

---

#### ШАБЛОН: {Lang} Architect (`{lang}-architect.md`)

```markdown
# Агент: {Lang} Architect

## Роль
Планирование модулей, сервисов, архитектуры. READ-ONLY — не пишет код.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- `.claude/database/schema.sql` — схема БД (обновляется автоматически)
- {SOURCE_DIR} — код существующих модулей (сканируй напрямую)
- `.claude/skills/architecture/SKILL.md` — архитектурные паттерны
- `.claude/skills/database/SKILL.md` — паттерны БД

## Задача

1. Проанализируй требования задачи
2. Изучи существующие модули для понимания паттернов
3. Определи затрагиваемые модули и cross-module зависимости
4. Создай план реализации
5. Запиши ключевые архитектурные решения в `state/decisions/{date}-{slug}.md`
6. Обнови `state/facts.md` (Active Decisions, Key Paths если изменились)
7. Обнови `state/memory/patterns.md` если выявлены новые архитектурные паттерны

## Формат вывода

{ARCHITECTURE_PLAN_TEMPLATE — адаптируй под фреймворк:
- Laravel/Lumen: Controllers, Services/Contract, Repository/Contract, Requests, DTOs, Provider, Routes, Migrations
- NestJS: Modules, Controllers, Services, DTOs, Entities, Guards, Pipes
- Django/FastAPI: Views/Endpoints, Services, Models, Schemas, Serializers
- Go: Handlers, Services, Repositories, Models, Router
- Spring: Controllers, Services, Repositories, Entities, DTOs, Config
- Rails: Controllers, Services, Models, Serializers, Routes
- ASP.NET: Controllers, Services, Repositories, Models, DTOs}

## Ограничения
- НЕ пишет код — только план с сигнатурами
- Следует паттернам из `.claude/skills/architecture/SKILL.md`
- План показывается пользователю на утверждение перед реализацией
```

---

#### ШАБЛОН: {Lang} Developer (`{lang}-developer.md`)

```markdown
# Агент: {Lang} Developer

## Роль
Пишет {LANG}-код по плану архитектора.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- План архитектора (передаётся в prompt)
- Код модуля: {SOURCE_DIR}
- `.claude/skills/code-style/SKILL.md` — стиль кода
- `.claude/skills/architecture/SKILL.md` — архитектура
- `.claude/skills/database/SKILL.md` — БД

## Порядок реализации

{ORDER — адаптируй под фреймворк:
- PHP/Laravel: Interfaces → Repos → Services → DTOs → Requests → Controllers → Provider → Routes
- NestJS: Module → DTOs → Service → Controller → Guards
- Django: Models → Schemas → Services → Views → URLs
- Go: Models → Repository → Service → Handler → Router
- Spring: Entity → Repository → Service → Controller → Config
- Rails: Model → Service → Controller → Serializer → Routes
- ASP.NET: Entity → Repository → Service → Controller → Startup}

## Правила

{LANG_SPECIFIC_RULES — сгенерируй на основе:
- стиля из code-style скилла
- вычлененных из CLAUDE.md правил
- стандартных практик фреймворка}

## Память
- После реализации фиксируй повторяющиеся паттерны в `state/memory/patterns.md`

## Верификация
После написания кода проверь:
```bash
{SYNTAX_CHECK_CMD — определи по стеку:
- PHP: docker compose exec -T php php -l {file}
- TS/JS: npx tsc --noEmit
- Python: python -m py_compile {file}
- Go: go vet ./...
- Rust: cargo check
- Java: mvn compile
- C#: dotnet build}
```

## Формат вывода
Готовые файлы, каждый с полным содержимым.
```

---

#### ШАБЛОН: {Lang} Test Developer (`{lang}-test-developer.md`)

```markdown
# Агент: {Lang} Test Developer

## Роль
Пишет unit-тесты.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- Класс для тестирования + его интерфейс
- `.claude/skills/testing/SKILL.md` — паттерны тестирования
- `.claude/skills/code-style/SKILL.md` — стиль кода

## Задача

1. Прочитай класс и его интерфейс/контракт
2. Определи все public методы
3. Для каждого метода создай минимум 2 теста (позитивный + негативный)
4. Протестируй граничные случаи

## Правила

{TEST_RULES — адаптируй под стек:
- PHPUnit: final class, MockeryPHPUnitIntegration, setUp/tearDown, Mockery::mock
- Jest: describe/it, jest.mock, beforeEach/afterEach
- pytest: fixtures, mocker, parametrize
- Go: testing.T, testify/mock, table-driven tests
- JUnit: @Test, @Mock, @InjectMocks, Mockito
- RSpec: describe/context/it, let, allow/expect}

## Именование
{NAMING — адаптируй:
- PHP: test{Method}{Scenario}
- Jest: describe('{class}', () => it('should {behavior}'))
- pytest: test_{method}_{scenario}
- Go: Test{Method}_{Scenario}
- JUnit: @Test void {method}_{scenario}_{expected}()}

## Верификация

```bash
{TEST_CMD} {test_file}
```

Если тесты fail — исправить (максимум 2 итерации).

## Формат вывода

Путь: {TEST_PATH_PATTERN}
Готовый файл теста.
```

---

#### ШАБЛОН: {Lang} Reviewer Logic (`{lang}-reviewer-logic.md`)

```markdown
# Агент: {Lang} Reviewer — Logic

## Роль
Ревью бизнес-логики и архитектуры. READ-ONLY — не изменяет код.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- Файлы для ревью (передаются в prompt или diff)
- `.claude/skills/code-style/SKILL.md`
- `.claude/skills/architecture/SKILL.md`

## Память
- Добавляй recurring issues в `state/memory/issues.md`

## Чеклист (12 пунктов)

{LOGIC_CHECKLIST — адаптируй под стек, обязательно включи:
1. Strict types / type safety
2. Interfaces / abstractions для всех сервисов
3. Нет прямых вызовов ORM из контроллеров (только через сервисы)
4. Обработка ошибок
5. Нет N+1 запросов
6. Полная типизация
7. Правильная модификация доступа (final, private, readonly)
8. DI через интерфейсы
9. DTO для сложных структур
10. Provider/Module содержит все биндинги
11. Early returns
12. Нет дублирования кода}

## Формат вывода

| # | Severity | Файл:строка | Проблема | Рекомендация |
|---|----------|-------------|----------|--------------|

## Verdict
- **BLOCK** — критичные проблемы
- **PASS WITH WARNINGS** — мелкие замечания
- **PASS** — код чистый

## Severity
- **BLOCK** — архитектурное нарушение, баг, N+1
- **WARN** — нужно исправить, но не критично
- **INFO** — рекомендация
```

---

#### ШАБЛОН: {Lang} Reviewer Security (`{lang}-reviewer-security.md`)

```markdown
# Агент: {Lang} Reviewer — Security

## Роль
Ревью безопасности кода. READ-ONLY — не изменяет код.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- Файлы для ревью (передаются в prompt или diff)
- `.claude/skills/code-style/SKILL.md`

## Чеклист (12 пунктов)

{SECURITY_CHECKLIST — адаптируй под стек, обязательно включи:
1. SQL/NoSQL injection
2. XSS
3. CSRF
4. Input validation
5. Auth/AuthZ на всех endpoints
6. Mass assignment / over-posting
7. Data exposure (пароли, токены в response)
8. Rate limiting
9. File upload validation
10. Deserialization safety
11. Integer overflow / boundary checks
12. Type safety / loose comparison}

## Формат вывода

| # | Severity | Файл:строка | Уязвимость | CWE | Рекомендация |
|---|----------|-------------|------------|-----|--------------|

## Verdict
- **BLOCK** — CRITICAL/HIGH уязвимости
- **PASS WITH NOTES** — MEDIUM/LOW
- **PASS** — безопасность в порядке

## Severity
- **CRITICAL** — эксплуатируемая уязвимость
- **HIGH** — серьёзный риск
- **MEDIUM** — умеренный риск
- **LOW** — минимальный риск
```

---

#### ШАБЛОН: DB Architect (`db-architect.md`)

```markdown
# Агент: DB Architect

## Роль
Дизайн БД, миграции, оптимизация запросов.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- `.claude/database/schema.sql` — текущая схема
- `.claude/database/migrations.txt` — список миграций
- {MIGRATIONS_DIR} — файлы миграций
- `.claude/skills/database/SKILL.md` — паттерны БД

## Режимы работы

### 1. Новая таблица
Вход: описание сущности и полей
Выход: SQL/DDL + миграция

### 2. Изменение структуры
Вход: описание изменений
Выход: ALTER/миграция с up и down/rollback

### 3. Оптимизация запросов
Вход: медленный запрос или код
Выход: EXPLAIN анализ + рекомендации по индексам

### 4. Анализ схемы
Вход: название таблицы
Выход: структура + связи + индексы + рекомендации

## Правила

{DB_RULES — адаптируй:
- MySQL: raw SQL через DB::statement(), типы VARCHAR/INT/DECIMAL/BOOLEAN/TIMESTAMP
- PostgreSQL: raw SQL или migration DSL, типы TEXT/INTEGER/NUMERIC/BOOL/TIMESTAMPTZ
- MongoDB: schema validation, indexes
- SQLite: simple migrations}

## Формат вывода

| Столбец | Тип | Nullable | Default | Описание |
|---------|-----|----------|---------|----------|

{MIGRATION_CODE}
```

---

#### ШАБЛОН: DevOps (`devops.md`)

```markdown
# Агент: DevOps

## Роль
Docker, инфраструктура, окружение, диагностика.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- `{COMPOSE_FILE}` — конфигурация контейнеров
- `{CONFIG_DIR}` — конфиги сервисов
- `{ENV_FILE}` — переменные окружения
- `{BUILD_FILE}` — Makefile / package.json scripts

## Инфраструктура

{SERVICES_TABLE — из docker-compose, формат:
| Сервис | Порт | Описание |}

## Команды

```bash
{ALL_COMMANDS — из Makefile / package.json scripts / Taskfile}
```

## Диагностика

| Проблема | Диагностика | Решение |
|----------|-------------|---------|
{COMMON_ISSUES — адаптируй под стек}
```

---

#### ШАБЛОН: Frontend Developer (`frontend-developer.md`)

Создавай ТОЛЬКО если `FRONTEND != none`.

```markdown
# Агент: Frontend Developer

## Роль
Пишет frontend-код: компоненты, страницы, сервисы, стейт.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- `.claude/input/structure.json` — структура фронта
- `.claude/skills/code-style/SKILL.md` — стиль кода
- `.claude/skills/architecture/SKILL.md` — архитектура

## Стек
- Фреймворк: {FRONTEND}
- Язык: TypeScript
- Стейт: {STATE_MANAGEMENT — определи: NgRx, Redux, Zustand, Pinia, Svelte stores}
- Стили: {CSS_APPROACH — определи: SCSS, Tailwind, CSS Modules, styled-components}

## Правила

{FRONTEND_RULES — адаптируй под фреймворк:

### Angular:
- Standalone components (Angular 14+) или NgModules
- Сервисы с `@Injectable({ providedIn: 'root' })`
- Reactive Forms для форм
- RxJS для async, `async` pipe в templates
- Strict типизация, no `any`

### React:
- Functional components + hooks
- Props interface для каждого компонента
- Custom hooks для бизнес-логики
- Мемоизация: React.memo, useMemo, useCallback где нужно
- No `any`, strict TypeScript

### Vue:
- Composition API (`<script setup>`)
- defineProps/defineEmits с типами
- Composables для переиспользуемой логики
- Pinia для state management

### Svelte:
- TypeScript в `<script lang="ts">`
- Stores для shared state
- $: reactive declarations
- Type-safe props}

## Структура компонента

{COMPONENT_STRUCTURE — адаптируй:
- Angular: component.ts, component.html, component.scss, component.spec.ts
- React: Component.tsx, Component.module.css, Component.test.tsx
- Vue: Component.vue (SFC)
- Svelte: Component.svelte}

## Верификация

```bash
{FRONTEND_BUILD_CHECK — определи:
- Angular: ng build --configuration=production
- React/Next: npm run build / next build
- Vue/Nuxt: npm run build / nuxt build
- Svelte: npm run build / vite build}
```
```

---

#### ШАБЛОН: Frontend Test Developer (`frontend-test-developer.md`)

Создавай ТОЛЬКО если `FRONTEND != none`.

```markdown
# Агент: Frontend Test Developer

## Роль
Пишет тесты для frontend-компонентов и сервисов.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- Компонент/сервис для тестирования
- `.claude/skills/testing/SKILL.md`

## Стек тестирования
- Runner: {FRONTEND_TEST — Jest/Vitest/Karma}
- DOM: {DOM_LIB — Testing Library / Enzyme / built-in}
- E2E: {E2E — Cypress/Playwright/none}

## Правила

{FRONTEND_TEST_RULES — адаптируй:

### Angular + Karma/Jest:
- TestBed.configureTestingModule
- ComponentFixture, DebugElement
- Моки сервисов через jasmine.createSpyObj / jest.fn()
- fakeAsync/tick для async
- HttpClientTestingModule для HTTP

### React + Jest/Vitest:
- @testing-library/react: render, screen, fireEvent, waitFor
- jest.mock / vi.mock для модулей
- userEvent для UI-взаимодействий
- MSW для API-моков

### Vue + Vitest:
- @vue/test-utils: mount, shallowMount
- vi.mock для модулей
- Pinia testing: createTestingPinia

### Svelte + Vitest:
- @testing-library/svelte: render, fireEvent
- vi.mock для stores}

## Верификация

```bash
{FRONTEND_TEST_CMD}
```
```

---

#### ШАБЛОН: Frontend Reviewer (`frontend-reviewer.md`)

Создавай ТОЛЬКО если `FRONTEND != none`.

```markdown
# Агент: Frontend Reviewer

## Роль
Ревью frontend-кода. READ-ONLY.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- Файлы для ревью (передаются в prompt или diff)
- `.claude/skills/code-style/SKILL.md`

## Чеклист (10 пунктов)

| # | Проверка | Severity |
|---|----------|----------|
| 1 | TypeScript strict: нет `any`, все типизировано | BLOCK |
| 2 | Компоненты не содержат бизнес-логику (вынесена в сервисы/hooks) | WARN |
| 3 | Нет утечек подписок (unsubscribe, cleanup) | BLOCK |
| 4 | Мемоизация где нужно (тяжёлые вычисления, рендеры) | WARN |
| 5 | Обработка loading/error состояний | WARN |
| 6 | Accessibility: aria-*, keyboard nav, semantic HTML | INFO |
| 7 | Нет inline styles (используй CSS-модули / классы) | INFO |
| 8 | Правильная структура файлов по конвенции | WARN |
| 9 | Props/inputs типизированы | BLOCK |
| 10 | Нет прямых DOM-манипуляций | WARN |

## Формат вывода

| # | Severity | Файл:строка | Проблема | Рекомендация |
|---|----------|-------------|----------|--------------|

## Verdict
- **BLOCK** / **PASS WITH WARNINGS** / **PASS**
```

---

#### ШАБЛОН: Frontend Contract (`frontend-contract.md`)

Создавай ТОЛЬКО если `FRONTEND != none`.

```markdown
# Агент: Frontend Contract

## Роль
Генерация API-контрактов для фронтенд-разработчиков.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- Routes/endpoints модуля
- Controllers/handlers
- Validation/DTOs/Schemas

## Задача

1. Проанализируй routes модуля
2. Для каждого endpoint прочитай handler, validation, response
3. Сгенерируй контракт

## Формат вывода

Файл: `.claude/output/contracts/{module}.md`

Для каждого endpoint:
- Method + Path
- Auth requirements
- Request params (source: route/body/query, type, required, validation)
- Response 200 (JSON example)
- Response 4xx (JSON example)
- TypeScript interfaces

## Правила
- Все поля типизированы
- Source: route / body / query
- TypeScript интерфейсы для фронта
- Обязательно указать auth и middleware
```

---

#### ШАБЛОН: QA Engineer (`qa-engineer.md`)

```markdown
# Агент: QA Engineer

## Роль
Генерация тест-кейсов, чеклистов и Postman-коллекций.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- `.claude/output/contracts/{module}.md` — API-контракты
- Routes модуля
- Бизнес-требования (передаются в prompt)

## Задача

### 1. Чеклист тестирования

Файл: `.claude/output/qa/{module}-checklist.md`

Для каждого endpoint минимум 5 тест-кейсов:
| # | Тест-кейс | Тип | Приоритет | Ожидаемый результат |

Типы: Positive, Negative, Boundary, Security

### 2. Postman-коллекция

Файл: `.claude/output/qa/{module}-postman.json`

Postman Collection v2.1 с переменными base_url и token.
```

---

#### ШАБЛОН: CI Manager (`ci-manager.md`)

Создавай ТОЛЬКО если есть `.gitlab-ci.yml`, `.github/workflows/`, `Jenkinsfile` или аналогичные CI-конфиги.

```markdown
# Агент: CI Manager

## Роль
Управление CI/CD пайплайнами, анализ и оптимизация.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- {CI_CONFIG_FILE} — конфигурация CI/CD
- `.claude/skills/architecture/SKILL.md` — архитектура

## Задача

1. Анализ текущего CI/CD пайплайна
2. Оптимизация стадий и кеширования
3. Добавление новых стадий (тесты, линтинг, деплой)
4. Диагностика failed pipelines

## CI/CD Стек

{CI_STACK — определи:
- GitHub Actions: .github/workflows/*.yml
- GitLab CI: .gitlab-ci.yml
- Jenkins: Jenkinsfile
- CircleCI: .circleci/config.yml}

## Правила
- Не менять production deploy stages без явного подтверждения
- Кешировать зависимости
- Параллелизовать независимые джобы
- Минимизировать время пайплайна
```

---

### 4.2.1 Кастомные агенты

Для каждого агента из CUSTOM_AGENTS сгенерируй файл `.claude/agents/{name}.md` по универсальному шаблону:

```markdown
# Агент: {Name}

## Роль
{ROLE — из ответа пользователя}

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- Код модуля: {SOURCE_DIR}
- `.claude/skills/code-style/SKILL.md` — стиль кода
- `.claude/skills/architecture/SKILL.md` — архитектура
{+ кастомные скиллы если релевантны}

## Задача
{Сгенерируй 3-5 шагов на основе роли и стека проекта}

## Правила
{Сгенерируй 3-5 правил на основе роли, стека и code-style}

## Формат вывода
{Определи на основе роли: таблица для ревью, файлы для developer, план для architect}
```

Адаптируй содержимое под стек проекта (LANG, FRAMEWORK, DB).

---

### 4.3 Скиллы

#### skills/code-style/SKILL.md

Заполни на основе:
- Вычлененных правил из CLAUDE.md
- Стандартных практик {LANG} + {FRAMEWORK}
- Обязательные секции: **Именование**, **Типизация**, **DI**, **Антипаттерны**, **Примеры**

#### skills/architecture/SKILL.md

Заполни на основе:
- Реальной структуры модулей проекта (сканируй)
- Цепочка зависимостей: Controller → Service → Repository → DB
- Provider/Module DI bindings
- Routes patterns
- Base controller/handler methods

#### skills/database/SKILL.md

Заполни на основе:
- Тип БД, формат миграций
- Типичные типы столбцов (из существующей схемы)
- Индексы, именование
- Команды запуска миграций

#### skills/testing/SKILL.md

Заполни на основе:
- Test framework + mock library
- Шаблон теста с конкретным синтаксисом
- Правила моков
- Именование тестов
- Команда запуска

#### skills/pipeline/SKILL.md

```markdown
---
user-invocable: true
description: Роутер пайплайнов — классифицирует задачу и запускает соответствующий pipeline
---

# Skill: Pipeline Router

Вызов: `/pipeline [действие или имя]`

## Pre-routing

Перед маршрутизацией задачи ВСЕГДА:
1. Прочитай `.claude/state/facts.md` — актуальный контекст проекта
2. Проверь `.claude/state/decisions/` — есть ли релевантные решения
3. Учти контекст при выборе пайплайна и агентов

## Приоритеты роутинга

1. **Явное имя:** `/pipeline review` → `.claude/pipelines/review.md`
2. **"срочно"/"hotfix"** → `hotfix.md` (высший приоритет)
3. **"полный цикл"/"feature"** → `full-feature.md`
4. **Keyword matching** → соответствующий pipeline
5. **Неоднозначно** → спросить пользователя

## Keyword-таблица

| Keywords | Pipeline |
|----------|----------|
| новый, добавь, создай, фича | `new-code.md` |
| баг, ошибка, fix, не работает | `fix-code.md` |
| ревью, проверь, review | `review.md` |
| тест, покрытие, coverage | `tests.md` |
| документация, api docs, контракт | `api-docs.md` |
| чеклист, QA, postman | `qa-docs.md` |
| хотфикс, срочно | `hotfix.md` |
| полный цикл, от начала до конца | `full-feature.md` |
{CUSTOM_PIPELINES_KEYWORDS — если есть кастомные пайплайны, добавь строки:
| {ключевые слова для кастомного пайплайна} | `{name}.md` |}

## Действие

1. Определи тип задачи по приоритетам выше
2. Прочитай `.claude/pipelines/{type}.md`
3. Выполни ВСЕ фазы из пайплайна последовательно

## Кастомные пайплайны

Если в `.claude/pipelines/` есть нестандартные файлы (не из базовых 8) — добавь их keywords в таблицу выше при генерации.
```

#### skills/p/SKILL.md

```markdown
---
user-invocable: true
description: Быстрый alias для /pipeline
---

# Skill: Pipeline Alias

Вызови `/pipeline` с теми же аргументами.

Примеры:
- `/p review` = `/pipeline review`
- `/p срочно исправить баг` = `/pipeline срочно исправить баг`
- `/p` = `/pipeline` (без аргументов — определит тип по контексту)
```

#### skills/memory/SKILL.md

```markdown
# Skill: Memory — Трёхуровневая система памяти проекта

## Уровни

### 1. Facts (`state/facts.md`)
Текущие факты проекта: стек, пути, активные решения, известные проблемы.
- Обновляется агентами после значимых изменений
- Читается ПЕРВЫМ при старте любой задачи
- Один файл, компактный, актуальный

### 2. Decisions (`state/decisions/`)
Архитектурные решения в формате ADR-lite.
- Файл: `{YYYY-MM-DD}-{slug}.md`
- Содержит: контекст, решение, альтернативы, последствия
- Записывается Architect при планировании, пайплайнами в фазе CAPTURE
- Максимум 20 активных, остальные → archive

### 3. Archive (`state/decisions/archive/`)
Устаревшие decisions (старше 30 дней или вытесненные).
- Автоматическая ротация через `maintain-memory.sh`
- Доступны для поиска при необходимости

## Формат Decision

```
# Decision: {title}

**Date:** {YYYY-MM-DD}
**Status:** active | superseded | deprecated
**Author:** {agent}

## Context
{Почему возник вопрос}

## Decision
{Что решили}

## Alternatives
{Что рассматривали}

## Consequences
{Что это означает для проекта}
```

## Правила записи
- Пиши decision только для архитектурно-значимых решений (не для каждого бага)
- Обновляй facts.md после каждого нового decision
- Не дублируй информацию между facts и decisions
- Slug в имени файла — kebab-case, 3-5 слов максимум

## Правила чтения
- Агент ВСЕГДА читает `facts.md` перед началом работы
- Decisions читаются при планировании (Architect) и ревью (Reviewer)
- Archive читается только при явном поиске контекста

## Антипаттерны
- Записывать каждое мелкое изменение как decision
- Дублировать код или конфиги в facts.md
- Игнорировать facts.md при старте задачи
- Оставлять устаревшие facts без обновления
```

---

### 4.3.1 Кастомные скиллы

Для каждого скилла из CUSTOM_SKILLS сгенерируй файл `.claude/skills/{name}/SKILL.md`:

```markdown
# Skill: {Name} — {DESCRIPTION}

## Паттерны
{Сгенерируй на основе назначения скилла и стека проекта:
правила, рекомендации, примеры}

## Антипаттерны
{Типичные ошибки}

## Примеры
{Конкретные примеры для стека}
```

---

### 4.4 Пайплайны

**Правило выбора языка в мульти-язычных проектах:**
- `{lang}` в пайплайне = язык, релевантный текущей задаче
- Если задача затрагивает конкретный модуль — определи язык по модулю
- Если неоднозначно — используй `PRIMARY_LANG`
- Для задач, затрагивающих несколько языков — фазы CODE, TESTS, REVIEW повторяются для каждого затронутого языка с соответствующими агентами

Генерируй все 8 пайплайнов, адаптируя команды и агентов под стек.

#### pipelines/new-code.md

```markdown
# Pipeline: New Code

## Фазы

### Phase 1: ARCHITECTURE
**Агент:** `{lang}-architect`
1. Прочитай `.claude/agents/{lang}-architect.md`
2. Передай требования задачи
3. Получи план → покажи пользователю → жди одобрения

### Phase 2: DATABASE
**Агент:** `db-architect` (если есть изменения БД)
1. Прочитай `.claude/agents/db-architect.md`
2. Создай миграцию
3. Запусти: `{MIGRATE_CMD}`

### Phase 3: CODE
**Агент:** `{lang}-developer`
1. Прочитай `.claude/agents/{lang}-developer.md`
2. Реализуй код по плану
3. Проверка: `{SYNTAX_CHECK_CMD}`

### Phase 4: TESTS
**Агент:** `{lang}-test-developer`
1. Прочитай `.claude/agents/{lang}-test-developer.md`
2. Сгенерируй тесты
3. Запусти: `{TEST_CMD}`
4. Если fail → исправить (макс 2 итерации)

### Phase 5: REVIEW
**Агенты:** `{lang}-reviewer-logic` + `{lang}-reviewer-security`
1. Ревью логики + безопасности
2. Если BLOCK/CRITICAL → вернуться к Phase 3

### Phase 5.5: CAPTURE
1. Записать архитектурные решения в `state/decisions/{date}-{slug}.md`
2. Обновить `state/facts.md` (Key Paths, Active Decisions)

### Phase 6: FINALIZATION
1. Запусти полный test suite: `{TEST_CMD}`
2. Покажи summary

## Матрица ошибок

| Проблема | Действие | Откат |
|----------|----------|-------|
| План отклонён | Пересмотр | Phase 1 |
| Миграция fail | Исправить | Phase 2 |
| Syntax fail | Fix | Phase 3 |
| Тесты fail | Fix code/tests | Phase 3-4 |
| Review BLOCK | Fix issues | Phase 3 |
```

#### pipelines/fix-code.md

```markdown
# Pipeline: Fix Code

## Фазы

### Phase 1: DIAGNOSIS
1. Изучи описание бага
2. Найди затронутые файлы
3. Определи root cause → покажи пользователю

### Phase 2: FIX
**Агент:** `{lang}-developer`
1. Примени исправление
2. Проверка: `{SYNTAX_CHECK_CMD}`

### Phase 3: TESTS
**Агент:** `{lang}-test-developer`
1. Напиши regression test
2. Запусти: `{TEST_CMD}`

### Phase 4: REVIEW
**Агент:** `{lang}-reviewer-logic`
1. Ревью только изменённых файлов
2. Если BLOCK → Phase 2

### Phase 5: CAPTURE
1. Если фикс выявил системную проблему — записать decision в `state/decisions/{date}-{slug}.md`
2. Обновить `state/facts.md` (Known Issues, если проблема повторяющаяся)
```

#### pipelines/review.md

```markdown
# Pipeline: Review

## Фазы

### Phase 1: LOGIC REVIEW
**Агент:** `{lang}-reviewer-logic`

### Phase 2: SECURITY REVIEW
**Агент:** `{lang}-reviewer-security`

### Phase 3: REPORT
Объедини результаты. Приоритет: CRITICAL > BLOCK > HIGH > WARN > MEDIUM > INFO > LOW
```

#### pipelines/tests.md

```markdown
# Pipeline: Tests

## Фазы

### Phase 1: ANALYZE
Прочитай целевой класс, определи coverage gaps

### Phase 2: GENERATE
**Агент:** `{lang}-test-developer`
Сгенерируй тесты (мин. 2 на public метод)

### Phase 3: VERIFY
Запусти `{TEST_CMD}`, макс 2 итерации исправлений

### Phase 4: REVIEW
**Агент:** `{lang}-reviewer-logic`
Ревью качества тестов
```

#### pipelines/api-docs.md

```markdown
# Pipeline: API Docs

### Phase 1: SCAN — определи endpoints
### Phase 2: GENERATE — `frontend-contract` agent
### Phase 3: SAVE — `.claude/output/contracts/{module}.md`
```

#### pipelines/qa-docs.md

```markdown
# Pipeline: QA Docs

### Phase 1: INPUT — прочитай контракт (или сначала api-docs)
### Phase 2: CHECKLIST — `qa-engineer` agent
### Phase 3: POSTMAN — `qa-engineer` agent
### Phase 4: SAVE — `.claude/output/qa/{module}-checklist.md` + `{module}-postman.json`
```

#### pipelines/full-feature.md

```markdown
# Pipeline: Full Feature

### 1. New Code — pipeline `new-code`
### 2. API Docs — pipeline `api-docs`
### 3. QA Docs — pipeline `qa-docs`
### 3.5. CAPTURE — записать архитектурные решения фичи в `state/decisions/{date}-{slug}.md`, обновить `state/facts.md`
### 4. Final Summary — обновить state, показать итоги
```

#### pipelines/hotfix.md

```markdown
# Pipeline: Hotfix

### 1. Fix Code — pipeline `fix-code`
### 2. Review — pipeline `review` (diff only)
### 2.5. CAPTURE — если исправление выявило архитектурную проблему, записать decision в `state/decisions/{date}-{slug}.md`, обновить `state/facts.md` (Known Issues)
### 3. Finalization — обновить state, показать итоги
```

---

### 4.4.1 Кастомные пайплайны

Для каждого пайплайна из CUSTOM_PIPELINES сгенерируй файл `.claude/pipelines/{name}.md`:

```markdown
# Pipeline: {Name}

## Фазы

{Сгенерируй фазы на основе:
- описания «когда использовать»
- указанных агентов
- стека проекта
Минимум 2 фазы, максимум 5.}

## Матрица ошибок

| Проблема | Действие | Откат |
|----------|----------|-------|
```

---

### 4.5 Hooks

#### scripts/hooks/track-agent.sh

```bash
#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/state/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/state"
LOG_FILE="$LOG_DIR/usage.jsonl"
mkdir -p "$LOG_DIR"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')

if [ "$TOOL_NAME" != "Task" ]; then
    exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_input.prompt // ""' | grep -oP '\.claude/agents/\K[^.]+' | head -1)
if [ -z "$AGENT_NAME" ]; then
    AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_input.description // ""' | tr '[:upper:]' '[:lower:]')
fi
if [ -z "$AGENT_NAME" ]; then
    AGENT_NAME="unknown-agent"
fi

INPUT_CHARS=$(echo "$INPUT" | jq -r '.tool_input | tostring' | wc -c)
OUTPUT_CHARS=$(echo "$INPUT" | jq -r '.tool_response // "" | tostring' | wc -c)

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BRANCH=$(cd "$CLAUDE_PROJECT_DIR" && git branch --show-current 2>/dev/null || echo "unknown")

jq -n \
    --arg ts "$TIMESTAMP" \
    --arg sid "$SESSION_ID" \
    --arg agent "$AGENT_NAME" \
    --arg branch "$BRANCH" \
    --argjson in_chars "$INPUT_CHARS" \
    --argjson out_chars "$OUTPUT_CHARS" \
    '{
        timestamp: $ts,
        session_id: $sid,
        agent: $agent,
        branch: $branch,
        input_chars: $in_chars,
        output_chars: $out_chars
    }' >> "$LOG_FILE"

exit 0
```

#### scripts/hooks/session-summary.sh

```bash
#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/state/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/state"
LOG_FILE="$LOG_DIR/usage.jsonl"
SESSIONS_DIR="$LOG_DIR/sessions"
mkdir -p "$SESSIONS_DIR"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

if [ ! -f "$LOG_FILE" ]; then
    exit 0
fi

SESSION_ENTRIES=$(jq -c "select(.session_id == \"$SESSION_ID\")" "$LOG_FILE" 2>/dev/null)
ENTRY_COUNT=$(echo "$SESSION_ENTRIES" | jq -s 'length' 2>/dev/null)

if [ "$ENTRY_COUNT" -eq 0 ]; then
    exit 0
fi

TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
BRANCH=$(echo "$SESSION_ENTRIES" | jq -r -s 'last.branch // "unknown"')
SUMMARY_FILE="$SESSIONS_DIR/${TIMESTAMP}-${BRANCH}-session.md"

TOTAL_IN=$(echo "$SESSION_ENTRIES" | jq -s '[.[].input_chars] | add // 0')
TOTAL_OUT=$(echo "$SESSION_ENTRIES" | jq -s '[.[].output_chars] | add // 0')

AGENTS_BREAKDOWN=$(echo "$SESSION_ENTRIES" | jq -s '
    group_by(.agent) | map({
        agent: .[0].agent,
        calls: length,
        input_chars: [.[].input_chars] | add,
        output_chars: [.[].output_chars] | add
    }) | sort_by(-.calls)
')

cat > "$SUMMARY_FILE" << EOF
# Session Summary

**Date:** $(date +"%Y-%m-%d %H:%M")
**Session ID:** $SESSION_ID
**Branch:** $BRANCH

## Totals

| Metric | Value |
|--------|-------|
| Agent calls | $ENTRY_COUNT |
| Input chars | $TOTAL_IN |
| Output chars | $TOTAL_OUT |

## By Agent

| Agent | Calls | Input chars | Output chars |
|-------|-------|-------------|--------------|
EOF

echo "$AGENTS_BREAKDOWN" | jq -r '.[] | "| \(.agent) | \(.calls) | \(.input_chars) | \(.output_chars) |"' >> "$SUMMARY_FILE"

DECISIONS_DIR="$CLAUDE_PROJECT_DIR/.claude/state/decisions"
if [ -d "$DECISIONS_DIR" ]; then
    DECISION_FILES=$(find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null)
    if [ -n "$DECISION_FILES" ]; then
        echo "" >> "$SUMMARY_FILE"
        echo "## Decisions This Session" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        for df in $DECISION_FILES; do
            DNAME=$(basename "$df" .md)
            echo "- $DNAME" >> "$SUMMARY_FILE"
        done
    fi
fi

exit 0
```

#### scripts/hooks/update-schema.sh

Скрипт безусловного обновления схемы БД. Запускается на старте сессии и после завершения задач (Task agent).

```bash
#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/state/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
DB_DIR="$PROJECT_DIR/.claude/database"
LOCK_FILE="$DB_DIR/.update-lock"

# Prevent concurrent runs
if [ -f "$LOCK_FILE" ]; then
    LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
    if [ "$LOCK_AGE" -lt 30 ]; then
        exit 0
    fi
fi

mkdir -p "$DB_DIR"
touch "$LOCK_FILE"
trap "rm -f '$LOCK_FILE'" EXIT

# Detect DB type from docker-compose or .env
COMPOSE_FILE=""
for f in "$PROJECT_DIR/docker-compose.yml" "$PROJECT_DIR/docker-compose.yaml" "$PROJECT_DIR/docker/docker-compose.yml"; do
    [ -f "$f" ] && COMPOSE_FILE="$f" && break
done

if [ -z "$COMPOSE_FILE" ]; then
    rm -f "$LOCK_FILE"
    exit 0
fi

ERR_LOG="$PROJECT_DIR/.claude/state/.hook-errors.log"

# Dynamically detect service names from docker-compose
pg_service_name=$(awk '/^\s+\S+:/{svc=$1} /image:.*postgres/{gsub(/:$/,"",svc); print svc; exit}' "$COMPOSE_FILE" 2>/dev/null)
mysql_service_name=$(awk '/^\s+\S+:/{svc=$1} /image:.*(mysql|mariadb)/{gsub(/:$/,"",svc); print svc; exit}' "$COMPOSE_FILE" 2>/dev/null)

# Try PostgreSQL
if [ -n "$pg_service_name" ]; then
    PG_CONTAINER=$(cd "$PROJECT_DIR" && docker compose ps -q "$pg_service_name" 2>/dev/null)
    if [ -n "$PG_CONTAINER" ]; then
        DB_NAME=$(grep -oP 'POSTGRES_DB=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || grep -oP 'POSTGRES_DB:\s*\K\S+' "$COMPOSE_FILE" 2>/dev/null || echo "postgres")
        DB_USER=$(grep -oP 'POSTGRES_USER=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || grep -oP 'POSTGRES_USER:\s*\K\S+' "$COMPOSE_FILE" 2>/dev/null || echo "postgres")

        docker exec "$PG_CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" --schema-only --no-owner --no-privileges 2>"$ERR_LOG" > "$DB_DIR/schema.sql.tmp"
        if [ $? -eq 0 ] && [ -s "$DB_DIR/schema.sql.tmp" ]; then
            mv "$DB_DIR/schema.sql.tmp" "$DB_DIR/schema.sql"
        else
            rm -f "$DB_DIR/schema.sql.tmp"
        fi
    fi
fi

# Try MySQL/MariaDB
if [ -n "$mysql_service_name" ]; then
    MYSQL_CONTAINER=$(cd "$PROJECT_DIR" && docker compose ps -q "$mysql_service_name" 2>/dev/null)
    if [ -n "$MYSQL_CONTAINER" ]; then
        DB_NAME=$(grep -oP 'MYSQL_DATABASE=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || echo "app")
        DB_USER=$(grep -oP 'MYSQL_USER=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || echo "root")
        DB_PASS=$(grep -oP 'MYSQL_PASSWORD=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || grep -oP 'MYSQL_ROOT_PASSWORD=\K\S+' "$PROJECT_DIR/.env" 2>/dev/null || echo "")

        docker exec "$MYSQL_CONTAINER" mysqldump -u"$DB_USER" -p"$DB_PASS" --no-data --skip-comments "$DB_NAME" 2>"$ERR_LOG" > "$DB_DIR/schema.sql.tmp"
        if [ $? -eq 0 ] && [ -s "$DB_DIR/schema.sql.tmp" ]; then
            mv "$DB_DIR/schema.sql.tmp" "$DB_DIR/schema.sql"
        else
            rm -f "$DB_DIR/schema.sql.tmp"
        fi
    fi
fi

# List migrations if migration dir exists
for mig_dir in "$PROJECT_DIR/database/migrations" "$PROJECT_DIR/migrations" "$PROJECT_DIR/src/migrations" "$PROJECT_DIR/db/migrations"; do
    if [ -d "$mig_dir" ]; then
        ls -1 "$mig_dir" > "$DB_DIR/migrations.txt" 2>/dev/null
        break
    fi
done

exit 0
```

#### scripts/hooks/maintain-memory.sh

Скрипт поддержки системы памяти. Запускается на старте сессии. Архивирует старые decisions, валидирует facts.md.

```bash
#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/state/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
STATE_DIR="$PROJECT_DIR/.claude/state"
FACTS_FILE="$STATE_DIR/facts.md"
DECISIONS_DIR="$STATE_DIR/decisions"
ARCHIVE_DIR="$DECISIONS_DIR/archive"
MEMORY_DIR="$STATE_DIR/memory"
SESSIONS_DIR="$STATE_DIR/sessions"
SESSIONS_ARCHIVE="$SESSIONS_DIR/archive"
LOG_FILE="$STATE_DIR/usage.jsonl"

mkdir -p "$DECISIONS_DIR" "$ARCHIVE_DIR" "$MEMORY_DIR" "$SESSIONS_ARCHIVE"

if [ ! -f "$FACTS_FILE" ]; then
    cat > "$FACTS_FILE" << 'FACTSEOF'
# Project Facts

## Stack
—

## Key Paths
—

## Active Decisions
—

## Known Issues
—

## Last Updated
—
FACTSEOF
fi

if [ ! -f "$MEMORY_DIR/patterns.md" ]; then
    printf '# Code Patterns\n\n—\n' > "$MEMORY_DIR/patterns.md"
fi

if [ ! -f "$MEMORY_DIR/issues.md" ]; then
    printf '# Known Issues\n\n| Date | Issue | Frequency | Resolution |\n|------|-------|-----------|------------|\n' > "$MEMORY_DIR/issues.md"
fi

ARCHIVE_DAYS=${MEMORY_ARCHIVE_DAYS:-30}
find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" -mtime +$ARCHIVE_DAYS -exec mv {} "$ARCHIVE_DIR/" \; 2>/dev/null

DECISION_COUNT=$(find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
if [ "$DECISION_COUNT" -gt 20 ]; then
    OLDEST=$(find "$DECISIONS_DIR" -maxdepth 1 -name "*.md" -printf '%T+ %p\n' 2>/dev/null | sort | head -5 | awk '{print $2}')
    for f in $OLDEST; do
        mv "$f" "$ARCHIVE_DIR/" 2>/dev/null
    done
fi

if [ -f "$LOG_FILE" ]; then
    CUTOFF=$(date -d '90 days ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -v-90d +%Y-%m-%dT%H:%M:%S 2>/dev/null)
    if [ -n "$CUTOFF" ]; then
        jq -c "select(.timestamp > \"$CUTOFF\")" "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
fi

find "$SESSIONS_DIR" -maxdepth 1 -name "*-session.md" -mtime +60 -exec mv {} "$SESSIONS_ARCHIVE/" \; 2>/dev/null

exit 0
```

#### scripts/hooks/git-context.sh

Скрипт сбора git-контекста. Запускается на SessionStart. Собирает branch, recent commits, uncommitted changes.

```bash
#!/bin/bash
set -uo pipefail
ERR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/state/.hook-errors.log"
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR in $(basename "$0"):$LINENO" >> "$ERR_LOG" 2>/dev/null; exit 0' ERR

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
STATE_DIR="$PROJECT_DIR/.claude/state"
CONTEXT_FILE="$STATE_DIR/.git-context.md"

cd "$PROJECT_DIR" || exit 0

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
LAST_COMMITS=$(git log --oneline -5 2>/dev/null || echo "—")
UNCOMMITTED=$(git diff --stat 2>/dev/null || echo "—")
STAGED=$(git diff --cached --stat 2>/dev/null || echo "—")
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | head -10)

cat > "$CONTEXT_FILE" << EOF
# Git Context

**Branch:** $BRANCH
**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Last 5 Commits

$LAST_COMMITS

## Uncommitted Changes

$UNCOMMITTED

## Staged

$STAGED

## Untracked (top 10)

$UNTRACKED
EOF

exit 0
```

**Сделай скрипты исполняемыми:**
```bash
chmod +x .claude/scripts/hooks/track-agent.sh
chmod +x .claude/scripts/hooks/session-summary.sh
chmod +x .claude/scripts/hooks/update-schema.sh
chmod +x .claude/scripts/hooks/maintain-memory.sh
chmod +x .claude/scripts/hooks/git-context.sh
```

#### scripts/verify-bootstrap.sh

Скрипт верификации сгенерированной структуры. Вызывается один раз в конце bootstrap.

```bash
#!/bin/bash

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
EXIT_CODE=0

echo "=== Checking .claude/ structure ==="
for dir in agents skills pipelines scripts/hooks state state/sessions state/decisions state/decisions/archive output output/contracts output/qa input database; do
    if [ -d "$PROJECT_DIR/.claude/$dir" ]; then
        echo "[OK] .claude/$dir/"
    else
        echo "[MISS] .claude/$dir/"
        EXIT_CODE=1
    fi
done

echo ""
echo "=== Checking agents ==="
for f in "$PROJECT_DIR"/.claude/agents/*.md; do
    [ -f "$f" ] && echo "[OK] $(basename "$f")"
done

echo ""
echo "=== Checking skills ==="
for f in "$PROJECT_DIR"/.claude/skills/*/SKILL.md; do
    [ -f "$f" ] && echo "[OK] $f"
done

echo ""
echo "=== Checking pipelines ==="
for f in "$PROJECT_DIR"/.claude/pipelines/*.md; do
    [ -f "$f" ] && echo "[OK] $(basename "$f")"
done

echo ""
echo "=== Checking hooks ==="
for f in "$PROJECT_DIR"/.claude/scripts/hooks/*.sh; do
    if [ ! -f "$f" ]; then continue; fi
    if [ -x "$f" ]; then
        echo "[OK] $(basename "$f") (executable)"
    else
        echo "[WARN] $(basename "$f") (not executable)"
        chmod +x "$f"
        echo "[FIXED] $(basename "$f")"
    fi
    bash -n "$f" 2>/dev/null && echo "  [OK] syntax" || echo "  [ERR] syntax error"
done

echo ""
echo "=== Checking settings ==="
for f in "$PROJECT_DIR"/.claude/settings.json "$PROJECT_DIR"/.claude/settings.local.json; do
    if [ -f "$f" ]; then
        if jq empty "$f" 2>/dev/null; then
            echo "[OK] $(basename "$f") (valid JSON)"
        else
            echo "[ERR] $(basename "$f") (invalid JSON)"
            EXIT_CODE=1
        fi
    else
        echo "[MISS] $(basename "$f")"
    fi
done

echo ""
echo "=== Checking CLAUDE.md ==="
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    echo "[OK] CLAUDE.md exists"
    for section in "## Agents" "## Skills" "## Pipelines" "## Commands" "## Architecture"; do
        if grep -q "$section" "$PROJECT_DIR/CLAUDE.md"; then
            echo "  [OK] $section"
        else
            echo "  [WARN] Missing: $section"
        fi
    done
else
    echo "[ERR] CLAUDE.md not found"
    EXIT_CODE=1
fi

echo ""
echo "=== Checking memory ==="
for f in "$PROJECT_DIR"/.claude/state/facts.md "$PROJECT_DIR"/.claude/state/memory/patterns.md "$PROJECT_DIR"/.claude/state/memory/issues.md "$PROJECT_DIR"/.claude/skills/memory/SKILL.md; do
    if [ -f "$f" ]; then
        echo "[OK] $(basename "$f")"
    else
        echo "[MISS] $(basename "$f")"
    fi
done
[ -d "$PROJECT_DIR/.claude/state/decisions" ] && echo "[OK] state/decisions/" || echo "[MISS] state/decisions/"

echo ""
echo "=== Summary ==="
echo "Agents: $(ls -1 "$PROJECT_DIR"/.claude/agents/*.md 2>/dev/null | wc -l)"
echo "Skills: $(ls -1d "$PROJECT_DIR"/.claude/skills/*/SKILL.md 2>/dev/null | wc -l)"
echo "Pipelines: $(ls -1 "$PROJECT_DIR"/.claude/pipelines/*.md 2>/dev/null | wc -l)"
echo "Hooks: $(ls -1 "$PROJECT_DIR"/.claude/scripts/hooks/*.sh 2>/dev/null | wc -l)"

exit $EXIT_CODE
```

```bash
chmod +x .claude/scripts/verify-bootstrap.sh
```

---

### 4.6 Settings

#### .claude/settings.json (shared, в git)

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Write(**)",
      "WebSearch",
      "WebFetch",
      "Bash({CONTAINER_CMD}:*)",
      "Bash(make:*)",
      "Bash(git log:*)",
      "Bash(git show:*)",
      "Bash(git diff:*)",
      "Bash(git status:*)",
      "Bash(git rev-parse:*)",
      "Bash(git branch:*)",
      "Bash(curl:*)"
    ]
  }
}
```

Адаптируй `{CONTAINER_CMD}` под стек:
- Docker: `docker compose`, `docker exec`, `docker ps`, `docker network`
- Podman: `podman`, `podman-compose`
- Без контейнеров: убрать

#### .claude/settings.local.json (local, в .gitignore)

```json
{
  "permissions": {
    "allow": [
      "Bash({CONTAINER_CMD}:*)",
      "Bash(make:*)",
      "Bash({SYNTAX_CHECK_BINARY}:*)",
      "Bash({TEST_BINARY}:*)",
      "Bash(git log:*)",
      "Bash(git show:*)",
      "Bash(git add:*)",
      "Bash(git rev-parse:*)",
      "Bash(chmod:*)",
      "Bash(mkdir:*)",
      "Bash(touch:*)",
      "Bash(bash -n:*)",
      "Bash(bash .claude/scripts/hooks/*)",
      "Bash(bash .claude/scripts/verify-bootstrap.sh)",
      "Bash(curl:*)",
      "WebFetch(domain:www.anthropic.com)",
      "WebFetch(domain:claude.com)",
      "WebSearch"
    ],
    "deny": [],
    "ask": []
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/track-agent.sh"
          },
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/update-schema.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/update-schema.sh"
          },
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/maintain-memory.sh"
          },
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/git-context.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $CLAUDE_PROJECT_DIR/.claude/scripts/hooks/session-summary.sh"
          }
        ]
      }
    ]
  }
}
```

---

### 4.7 State

#### state/facts.md

```markdown
# Project Facts

## Stack
- **Lang:** {LANGS}
- **Framework:** {FRAMEWORK}
- **DB:** {DB}
- **Frontend:** {FRONTEND}

## Key Paths
- Source: {SOURCE_DIR}
- Tests: {TEST_DIR}
- Migrations: {MIGRATIONS_DIR}

## Active Decisions
{ссылки на файлы в state/decisions/}

## Known Issues
—

## Last Updated
{DATE}
```

#### state/memory/patterns.md

```markdown
# Code Patterns

Повторяющиеся паттерны кода, выявленные при разработке.

## Naming
—

## Architecture
—

## Error Handling
—

## Last Updated
—
```

#### state/memory/issues.md

```markdown
# Known Issues

Повторяющиеся проблемы, выявленные при ревью.

| Date | Issue | Frequency | Resolution |
|------|-------|-----------|------------|
```

#### input/tasks/TEMPLATE.md

```markdown
# Task: {название}

## Description
{описание задачи}

## Acceptance Criteria
- [ ] {критерий 1}
- [ ] {критерий 2}

## Priority
{high | medium | low}

## Affected Modules
{список модулей}
```

#### input/plans/TEMPLATE.md

```markdown
# Plan: {название}

## Goal
{цель плана}

## Steps
1. {шаг 1}
2. {шаг 2}

## Dependencies
{зависимости}

## Risks
{риски}
```

### 4.8 Version Tracking

Сгенерируй файл `.claude/.bootstrap-version` для отслеживания версии и кастомизаций:

```bash
AGENTS_LIST=$(ls -1 .claude/agents/*.md 2>/dev/null | xargs -I{} basename {} | jq -R -s 'split("\n") | map(select(. != ""))')
SKILLS_LIST=$(ls -1d .claude/skills/*/SKILL.md 2>/dev/null | sed 's|.claude/skills/||;s|/SKILL.md||' | jq -R -s 'split("\n") | map(select(. != ""))')
HOOKS_LIST=$(ls -1 .claude/scripts/hooks/*.sh 2>/dev/null | xargs -I{} basename {} | jq -R -s 'split("\n") | map(select(. != ""))')

HASHES="{}"
for f in .claude/agents/*.md .claude/skills/*/SKILL.md .claude/pipelines/*.md .claude/scripts/hooks/*.sh .claude/scripts/verify-bootstrap.sh; do
    [ -f "$f" ] || continue
    REL=$(echo "$f" | sed 's|^.claude/||')
    HASH=$(sha256sum "$f" | cut -d' ' -f1)
    HASHES=$(echo "$HASHES" | jq --arg k "$REL" --arg v "sha256:$HASH" '. + {($k): $v}')
done

jq -n \
    --arg version "2.0.0" \
    --arg date "$(date +%Y-%m-%d)" \
    --argjson langs '{LANGS_JSON_ARRAY}' \
    --arg frontend '{FRONTEND}' \
    --arg db '{DB}' \
    --argjson agents "$AGENTS_LIST" \
    --argjson skills "$SKILLS_LIST" \
    --argjson hooks "$HOOKS_LIST" \
    --argjson hashes "$HASHES" \
    '{
        version: $version,
        date: $date,
        stack: {langs: $langs, frontend: $frontend, db: $db},
        generated: {agents: $agents, skills: $skills, hooks: $hooks},
        hashes: $hashes
    }' > .claude/.bootstrap-version
```

Замени `{LANGS_JSON_ARRAY}`, `{FRONTEND}`, `{DB}` на реальные значения из Шага 1.

---

## ШАГ 5: ВЕРИФИКАЦИЯ

Запусти скрипт верификации одной командой:

```bash
bash .claude/scripts/verify-bootstrap.sh
```

### 5.1 Итоговый отчёт

Покажи:
- Количество агентов, скиллов, пайплайнов
- Стек проекта
- Что было вычленено из CLAUDE.md (если было)
- Список всех созданных файлов
- Результат верификации (все [OK] или есть [MISS]/[ERR])

---

## СТЕК-СПЕЦИФИЧНЫЕ АДАПТАЦИИ

### PHP (Laravel / Lumen)

| Параметр | Значение |
|----------|----------|
| Source dir | `src/app/Modules/` или `app/` |
| Interfaces | `Services/Contract/`, `Repository/Contract/` |
| Controller style | `final class`, extends Controller |
| DI | Provider `boot()`, `$this->app->bind()` |
| DB | `DB::table()`, no Eloquent |
| Migrations | raw SQL `DB::statement()` |
| Tests | PHPUnit + Mockery |
| Syntax check | `php -l {file}` |
| Test cmd | `./vendor/bin/phpunit {file} --no-coverage` |

### Node.js / TypeScript (NestJS)

| Параметр | Значение |
|----------|----------|
| Source dir | `src/modules/` или `src/` |
| DI | `@Injectable()`, Module `providers` |
| Controller style | `@Controller()`, class |
| DB | TypeORM / Prisma / Knex |
| Migrations | TypeORM migrations / Prisma migrate |
| Tests | Jest + ts-jest |
| Syntax check | `npx tsc --noEmit` |
| Test cmd | `npx jest {file}` |

### Python (Django / FastAPI)

| Параметр | Значение |
|----------|----------|
| Source dir | `app/` или `src/` |
| DI | FastAPI Depends / Django injection |
| Controller style | ViewSet / APIRouter |
| DB | SQLAlchemy / Django ORM |
| Migrations | Alembic / Django migrations |
| Tests | pytest + pytest-mock |
| Syntax check | `python -m py_compile {file}` |
| Test cmd | `pytest {file} -v` |

### Go (Gin / Echo / Fiber)

| Параметр | Значение |
|----------|----------|
| Source dir | `internal/` или `pkg/` |
| DI | Wire / manual constructor |
| Handler style | `func(c *gin.Context)` |
| DB | GORM / sqlx / pgx |
| Migrations | golang-migrate / goose |
| Tests | testing + testify |
| Syntax check | `go vet ./...` |
| Test cmd | `go test ./... -v` |

### Rust (Actix / Axum)

| Параметр | Значение |
|----------|----------|
| Source dir | `src/` |
| DI | App state / extractors |
| Handler style | `async fn handler()` |
| DB | Diesel / SQLx / SeaORM |
| Migrations | diesel migration / sqlx migrate |
| Tests | `#[cfg(test)]` + mockall |
| Syntax check | `cargo check` |
| Test cmd | `cargo test` |

### Java (Spring Boot)

| Параметр | Значение |
|----------|----------|
| Source dir | `src/main/java/` |
| DI | `@Autowired`, `@Service`, `@Repository` |
| Controller style | `@RestController` |
| DB | JPA / Spring Data / JDBC Template |
| Migrations | Flyway / Liquibase |
| Tests | JUnit 5 + Mockito |
| Syntax check | `mvn compile` |
| Test cmd | `mvn test -pl {module}` |

### C# (ASP.NET)

| Параметр | Значение |
|----------|----------|
| Source dir | `src/` |
| DI | `services.AddScoped<I, T>()` |
| Controller style | `[ApiController]`, ControllerBase |
| DB | EF Core / Dapper |
| Migrations | EF Core migrations |
| Tests | xUnit + Moq / NSubstitute |
| Syntax check | `dotnet build` |
| Test cmd | `dotnet test` |

### Ruby (Rails)

| Параметр | Значение |
|----------|----------|
| Source dir | `app/` |
| DI | Manual / dry-auto_inject |
| Controller style | ApplicationController |
| DB | ActiveRecord |
| Migrations | Rails migrations |
| Tests | RSpec + FactoryBot |
| Syntax check | `ruby -c {file}` |
| Test cmd | `bundle exec rspec {file}` |

---

## ФИНАЛ

После завершения всех шагов выведи:

```
╔══════════════════════════════════════════════╗
║  Claude Code Automation — Bootstrap Complete ║
╠══════════════════════════════════════════════╣
║  Project: {PROJECT_NAME}                     ║
║  Stack: {LANGS} + {FRONTEND}                  ║
║  DB: {DB}                                    ║
║                                              ║
║  Agents: {N_BASE + N_CUSTOM}                 ║
║  Skills: {7 + N_CUSTOM_SKILLS}               ║
║  Pipelines: {8 + N_CUSTOM_PIPELINES}         ║
║  Hooks: 5                                    ║
║  Memory: facts + patterns + issues + decisions║
║  Version: 2.0.0                              ║
║                                              ║
║  Quick start:                                ║
║  /pipeline new-code  или  /p new-code        ║
╚══════════════════════════════════════════════╝
```
