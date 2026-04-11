# Шаг 1-2: Инициализация (scan + detect)

> Modes: fresh, patch, upgrade

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.
> Объединяет сканирование проекта и определение режима в один вызов.

## Вход
- Проект (файловая система)

## Выход
- `.claude/.cache/state.json` (инициализирован, mode определён)
- `state.stack` заполнен
- `state.mode`: empty | fresh | patch | upgrade
- `.claude/.cache/analysis/` — manifest.json, structure.json, plugin-recommendations.md
- `.claude/.cache/` создан
- Информация о предыдущем bootstrap (если есть)
- Список deprecated файлов для миграции (если patch/upgrade)

---

## ЧАСТЬ 1: Сканирование проекта

### 1.1 Инициализация state

Создай `.claude/.cache/state.json`:

```json
{
  "version": "9.0.0",
  "mode": null,
  "started_at": "{ISO8601}",
  "updated_at": "{ISO8601}",
  "steps": {
    "init": {"status": "in_progress", "started_at": "{ISO8601}"}
  },
  "config": {},
  "stack": {},
  "registries": {"agents": [], "skills": [], "pipelines": []},
  "plugin_recommendations": [],
  "cache_refs": {
    "analysis": ".claude/.cache/analysis/",
    "deep_analysis": ".claude/.cache/deep/"
  },
  "generation": {"checkpoint": null, "completed_files": [], "failed_files": []},
  "errors": []
}
```

### 1.2 Сканирование manifest-файлов

Только manifest-файлы и структура. **НЕ анализировать код** — глубокий анализ на step 7.

Просканируй:
- `package.json`, `composer.json`, `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, `*.csproj`, `pom.xml`, `build.gradle`, `Gemfile`
- `tsconfig.json`, `angular.json`, `next.config.*`, `vite.config.*`, `nuxt.config.*`, `svelte.config.*`
- `docker-compose.yml`, `docker-compose.yaml`, `Dockerfile`
- `.env`, `.env.example`
- `.gitlab-ci.yml`, `.github/workflows/`
- `Makefile`, `Taskfile.yml`

Сохрани сырые данные в `.claude/.cache/analysis/manifest.json`.

### 1.3 Сканирование структуры

Дерево директорий (top 3 уровня, без `node_modules/`, `vendor/`, `.git/`, `dist/`, `build/`).

Сохрани в `.claude/.cache/analysis/structure.json`.

### 1.4 Определение стека

| Параметр | Как определить |
|----------|----------------|
| **Языки backend** | composer.json → PHP; package.json + tsconfig → Node/TS; go.mod → Go; Cargo.toml → Rust; requirements.txt/pyproject.toml → Python; *.csproj → C#; pom.xml/build.gradle → Java; Gemfile → Ruby |
| **Фреймворк backend** | Laravel/Lumen, Express/Nest/Fastify, Gin/Echo/Fiber, Actix/Axum, Django/FastAPI/Flask, ASP.NET, Spring Boot, Rails |
| **Фреймворк frontend** | angular.json → Angular; next.config → Next.js; vite.config + react → React; nuxt.config → Nuxt/Vue; svelte.config → SvelteKit |
| **БД** | docker-compose (mysql/postgres/mongo), .env (DB_CONNECTION), миграции |
| **Storage** | Redis/Memcached → cache; RabbitMQ/Kafka/SQS → queue; S3/MinIO → object storage |
| **ORM/Query** | Eloquent, Prisma, TypeORM, GORM, SQLAlchemy, ActiveRecord, raw SQL |
| **Тесты backend** | PHPUnit, Jest, pytest, go test, cargo test, NUnit, JUnit, RSpec |
| **Тесты frontend** | Jest, Vitest, Cypress, Playwright, Karma/Jasmine |
| **Инфра** | Docker/docker-compose, Makefile, CI (GitHub Actions, GitLab CI) |
| **Git hosting** | Выполни `git remote -v`: URL содержит `gitlab` → gitlab, `github.com` → github. Fallback: `.gitlab-ci.yml` → gitlab; `.github/workflows/` → github. Без remote и CI файлов → none |
| **API стиль** | REST, GraphQL, gRPC |
| **Auth** | JWT, Session, OAuth, API keys |
| **Package managers** | composer, npm, yarn, pnpm, pip, cargo, go, maven, gradle, bundler |

Запиши результат в `state.stack`:

```json
{
  "langs": ["php", "node"],
  "primary_lang": "php",
  "frameworks": {"php": "laravel", "node": "nestjs"},
  "test_frameworks": {"php": "phpunit", "node": "jest"},
  "test_cmds": {"php": "php artisan test", "node": "npm test"},
  "lint_cmds": {"php": "phpstan", "node": "eslint"},
  "frontend": "react",
  "frontend_test": "vitest",
  "db": "postgres",
  "storage": {
    "cache": "redis",
    "queue": "rabbitmq",
    "object": "none"
  },
  "container": "docker",
  "pkg_managers": ["composer", "npm"],
  "git_hosting": "определи по git remote -v: gitlab.* → gitlab, github.com → github, иначе → none",
  "api_style": "rest",
  "auth": "jwt"
}
```

### 1.5 Рекомендации плагинов

Определи полезные плагины на основе стека. **Показать таблицу, НЕ устанавливать.**

| Условие | Плагин | Причина | Команда установки |
|---------|--------|---------|-------------------|
| Frontend с тестами | Playwright MCP | E2E тесты в Claude Code | `npx @anthropic-ai/claude-code plugins install @anthropic-ai/claude-code-playwright` |
| Популярные фреймворки (Laravel, Next.js, Django, Spring, Rails) | context7 | Актуальная документация фреймворков | `npx @anthropic-ai/claude-code plugins install upstash/context7-mcp` |
| docker-compose в проекте | Docker MCP | Управление контейнерами | `npx @anthropic-ai/claude-code plugins install docker/docker-mcp` |
| TypeScript / Go / Rust | LSP MCP | Навигация по коду, автодополнение | соответствующий LSP сервер |

Сохрани рекомендации в:
- `state.plugin_recommendations[]` — `{name, reason, install_cmd, accepted: null}`
- `.claude/.cache/analysis/plugin-recommendations.md` — читаемая таблица

---

## ЧАСТЬ 2: Определение режима

### 2.1 Проверка состояния проекта

Проверь наличие (в порядке приоритета):
1. **Стек проекта**: `state.stack.langs` из части 1
3. Директория `.claude/`
4. Файл `.claude/.bootstrap-manifest.json` (v9+)
5. Файл `.claude/.bootstrap-version` (legacy, v6–v8)
6. YAML frontmatter `version:` в `.claude/pipelines/*.md`

#### Version detection order

```
1. .claude/.bootstrap-manifest.json → поле "version"
2. .claude/.bootstrap-version → поле "version" (legacy)
3. YAML frontmatter version: в любом .claude/pipelines/*.md
4. Эвристики:
   - Есть .claude/agents/ + .claude/pipelines/ → "pre-v6"
   - Есть .claude/ без agents/pipelines → "unknown"
```

### 2.2 Определение режима

```
state.stack.langs пустой И нет манифестов  → empty
Нет .claude/                                → fresh
Есть .claude/ + version v8.x               → patch или upgrade (спросить)
Есть .claude/ + version < v8.0             → upgrade (принудительно)
Есть .claude/ + version = v9.x             → patch (re-validate)
Есть .claude/ без version info              → upgrade (legacy)
```

> Resume обрабатывает оркестратор до твоего вызова. Ты не обрабатываешь resume.

#### Режим `empty`

Проект пустой — нет исходного кода, нет манифестов, стек не определён.

1. Создай минимальную структуру:
```bash
mkdir -p .claude/input/tasks .claude/input/plans .claude/memory
```

2. Запиши шаблон спецификации `.claude/input/plans/project-spec.md`:
```markdown
# Спецификация проекта

## Название
{название проекта}

## Описание
{что делает проект, 2-3 предложения}

## Стек
- **Язык:** {php / typescript / python / go / ...}
- **Фреймворк:** {laravel / nestjs / fastapi / gin / ...}
- **БД:** {postgres / mysql / mongo / none}
- **Frontend:** {react / vue / none}
- **Контейнеры:** {docker / none}

## Модули
- {модуль 1 — описание}
- {модуль 2 — описание}

## API
- {endpoint 1}
- {endpoint 2}

## Ограничения и требования
- {требование 1}
- {требование 2}
```

3. Покажи пользователю:

```
[EMPTY PROJECT]
Проект пустой — нет исходного кода и манифестов.
Создан шаблон спецификации: .claude/input/plans/project-spec.md

Заполни спецификацию и запусти /cc-bootstrapper:bootstrap повторно.
Bootstrap подхватит стек из спецификации.
```

4. Установи `state.mode = "empty"`. Переходи к checkpoint. **BOOTSTRAP ЗАВЕРШАЕТСЯ ЗДЕСЬ.**

#### Режим `fresh`

Установи `state.mode = "fresh"`. Переходи к checkpoint.

#### Режим `patch` / `upgrade` (v8.x detected)

1. Определи версию по version detection order (2.1)
2. Покажи пользователю:

```
Обнаружен предыдущий bootstrap v{version}.
```

3. Используй AskUserQuestion:
- question: "Обнаружена v{version}. Как обновить?"
- options:
  - {label: "Upgrade (рекомендуется)", description: "Бэкап → выбор что сохранить → удаление legacy → fresh генерация v9. Пользовательские файлы сохраняются по выбору."}
  - {label: "Patch (mini-upgrade)", description: "Cleanup deprecated + конвертация frontmatter v8→v9 + v9 роутер + diff preview. Пользовательские файлы не трогаем."}

Если "Upgrade" → `state.mode = "upgrade"`, `state.detected_version = "{version}"`.
Если "Patch" → `state.mode = "patch"`, `state.detected_version = "{version}"`.

**Исключение:** version < v8.0 → сразу `state.mode = "upgrade"` без вопроса (patch невозможен, формат несовместим).

#### Режим `patch` (v9.x detected)

Если version = v9.x — patch mode без вопроса (re-validate текущую структуру).

```
Обнаружен bootstrap v{version}. Режим: patch (re-validate).
```

Установи `state.mode = "patch"`, `state.detected_version = "{version}"`.

### 2.3 Детект deprecated файлов (только patch/upgrade)

Проверь наличие устаревших файлов/структур:

| Deprecated | Замена в v7 | Действие |
|-----------|-------------|----------|
| `.claude/agents/frontend-developer.md` | `{lang}-developer.md` (frontend) | миграция |
| `.claude/agents/frontend-test-developer.md` | `{lang}-test-developer.md` (frontend) | миграция |
| `.claude/agents/frontend-reviewer.md` | `{lang}-reviewer.md` (frontend) | миграция |
| `.claude/agents/frontend-contract.md` | удаляется, функции в analyst | удаление |
| `.claude/agents/{lang}-reviewer-logic.md` | `{lang}-reviewer.md` (объединён) | миграция |
| `.claude/agents/{lang}-reviewer-security.md` | `{lang}-reviewer.md` (объединён) | миграция |
| `.claude/skills/routing/` | `skills/pipeline/` | переименование |
| `.claude/skills/database/` | `skills/storage/` | переименование |
| `.claude/state/` | `.claude/memory/` | миграция (pre-v5.1) |

Если найдены deprecated файлы — покажи:

```
Обнаружены устаревшие файлы:

| Файл | Статус | Действие |
|------|--------|----------|
| agents/frontend-developer.md | deprecated | → миграция в node-developer.md |
| agents/php-reviewer-logic.md | deprecated | → объединение в php-reviewer.md |
| skills/database/ | deprecated | → переименование в storage/ |

Миграция будет выполнена на шаге генерации (step 8).
```

Сохрани список deprecated в `state.deprecated_files[]`:
```json
[
  {"path": "agents/frontend-developer.md", "action": "migrate", "target": "agents/node-developer.md"},
  {"path": "skills/database/", "action": "rename", "target": "skills/storage/"}
]
```

---

## Лог

Перед checkpoint запиши лог в `.claude/.cache/step-init-log.md`:

```markdown
# Step 1-2: Инициализация (scan + detect) — Log

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
- `state.mode` → определённый режим
- `steps.init.status` → `"completed"`
- `steps.init.completed_at` → `"{ISO8601}"`
- `updated_at` → `"{ISO8601}"`

## Отчёт

Покажи таблицу результатов:

| Параметр | Значение |
|----------|----------|
| Языки | {langs} |
| Основной язык | {primary_lang} |
| Фреймворки | {frameworks} |
| Frontend | {frontend} |
| БД | {db} |
| Storage | cache: {cache}, queue: {queue}, object: {object} |
| Контейнер | {container} |
| Git hosting | {git_hosting} |
| API | {api_style} |
| Auth | {auth} |
| Pkg managers | {pkg_managers} |
| **Режим** | {mode} |

Рекомендации плагинов НЕ показывай — они будут предложены на шаге 5.

**Отчёт режима:** ({fresh|patch|upgrade}), версия предыдущего bootstrap (если patch/upgrade), количество deprecated файлов (если есть).
