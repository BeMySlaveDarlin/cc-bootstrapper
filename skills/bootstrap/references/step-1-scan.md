# Шаг 1: Сканирование проекта

## Вход
- Проект (файловая система)

## Выход
- `.bootstrap-cache/state.json` (инициализирован)
- `state.stack` заполнен
- `.bootstrap-cache/analysis/` — manifest.json, structure.json, plugin-recommendations.md
- `.bootstrap-cache/` и `.bootstrap-cache/state.json` добавлены в `.gitignore`

## 1.1 Инициализация state

Создай `.bootstrap-cache/state.json`:

```json
{
  "version": "7.2.0",
  "mode": null,
  "started_at": "{ISO8601}",
  "updated_at": "{ISO8601}",
  "current_step": 1,
  "steps": {
    "1": {"status": "in_progress", "started_at": "{ISO8601}"},
    "2": {"status": "pending"},
    "3": {"status": "pending"},
    "4": {"status": "pending"},
    "5": {"status": "pending"},
    "6": {"status": "pending"},
    "7": {"status": "pending"},
    "8": {"status": "pending"},
    "9": {"status": "pending"}
  },
  "config": {},
  "stack": {},
  "registries": {"agents": [], "skills": [], "pipelines": []},
  "plugin_recommendations": [],
  "cache_refs": {
    "analysis": ".bootstrap-cache/analysis/",
    "deep_analysis": ".bootstrap-cache/deep/"
  },
  "generation": {"checkpoint": null, "completed_files": [], "failed_files": []},
  "errors": []
}
```

## 1.2 Сканирование manifest-файлов

Только manifest-файлы и структура. **НЕ анализировать код** — глубокий анализ на step 7.

Просканируй:
- `package.json`, `composer.json`, `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, `*.csproj`, `pom.xml`, `build.gradle`, `Gemfile`
- `tsconfig.json`, `angular.json`, `next.config.*`, `vite.config.*`, `nuxt.config.*`, `svelte.config.*`
- `docker-compose.yml`, `docker-compose.yaml`, `Dockerfile`
- `.env`, `.env.example`
- `.gitlab-ci.yml`, `.github/workflows/`
- `Makefile`, `Taskfile.yml`

Сохрани сырые данные в `.bootstrap-cache/analysis/manifest.json`.

## 1.3 Сканирование структуры

Дерево директорий (top 3 уровня, без `node_modules/`, `vendor/`, `.git/`, `dist/`, `build/`).

Сохрани в `.bootstrap-cache/analysis/structure.json`.

## 1.4 Определение стека

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
| **Git hosting** | `.gitlab-ci.yml` → GitLab; `.github/workflows/` → GitHub; `git remote -v` → по URL |
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
  "git_hosting": "github",
  "api_style": "rest",
  "auth": "jwt"
}
```

## 1.5 Рекомендации плагинов

Определи полезные плагины на основе стека. **Показать таблицу, НЕ устанавливать.**

| Условие | Плагин | Причина | Команда установки |
|---------|--------|---------|-------------------|
| Frontend с тестами | Playwright MCP | E2E тесты в Claude Code | `npx @anthropic-ai/claude-code plugins install @anthropic-ai/claude-code-playwright` |
| Популярные фреймворки (Laravel, Next.js, Django, Spring, Rails) | context7 | Актуальная документация фреймворков | `npx @anthropic-ai/claude-code plugins install upstash/context7-mcp` |
| docker-compose в проекте | Docker MCP | Управление контейнерами | `npx @anthropic-ai/claude-code plugins install docker/docker-mcp` |
| TypeScript / Go / Rust | LSP MCP | Навигация по коду, автодополнение | соответствующий LSP сервер |

Сохрани рекомендации в:
- `state.plugin_recommendations[]` — `{name, reason, install_cmd, accepted: null}`
- `.bootstrap-cache/analysis/plugin-recommendations.md` — читаемая таблица

## 1.6 Обновление .gitignore

Проверь `.gitignore`. Если отсутствуют — добавь:

```
.bootstrap-cache/state.json
.bootstrap-cache/
```

Не дублировать если уже есть.

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-1-log.md`:

```markdown
# Step 1: Сканирование проекта — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

Записать лог ПЕРЕД checkpoint.

## 1.7 Checkpoint

Обнови `.bootstrap-cache/state.json`:
- `steps.1.status` → `"completed"`
- `steps.1.completed_at` → `"{ISO8601}"`
- `current_step` → `2`
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

Рекомендации плагинов НЕ показывай — они будут предложены на шаге 3.
