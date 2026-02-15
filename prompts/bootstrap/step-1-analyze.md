# Шаг 1: Анализ проекта

Проанализируй проект и запиши результаты. Используй файловую структуру, package.json/composer.json/go.mod/Cargo.toml/requirements.txt, Dockerfile, CI configs.

## Что определить

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
| **Git hosting** | `.gitlab-ci.yml` → GitLab; `.github/workflows/` → GitHub; `git remote -v` → по URL |
| **API стиль** | REST, GraphQL, gRPC |
| **Auth** | JWT, Session, OAuth, API keys |

## Сохрани результат анализа как переменные

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

GIT_HOSTING=gitlab|github|bitbucket|none   # определи по CI-конфигам и remote URL
GITLAB_DETECTED=true|false                  # .gitlab-ci.yml ИЛИ remote содержит "gitlab"
```

**Отчёт:** таблица с результатами анализа.
