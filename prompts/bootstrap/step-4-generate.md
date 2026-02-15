# Шаг 4: Генерация (Агенты)

## Правила записи файлов

### Режим `fresh`
Записывать все файлы без проверок.

### Режим `validate`
**Всё автоматически, без AskUserQuestion.** Для КАЖДОГО файла:

1. **Файл НЕ существует** → создать из шаблона → `[NEW] {path}`
2. **Файл существует** → провести ВАЛИДАЦИЮ содержимого:

#### Валидация агентов (.claude/agents/*.md)
- Содержит секцию `## Контекст` с ссылкой на `facts.md`
- Содержит ссылки на skills (`skills/code-style/SKILL.md`, etc.)
- НЕ содержит устаревших ссылок на `skills/routing/`
→ Проблемы найдены → исправить IN-PLACE → `[FIX] {path}: {что исправлено}`
→ Файл ОК → `[OK] {path}`

#### Валидация CLAUDE.md
- Содержит ЖЁСТКОЕ ПРАВИЛО routing первым в Rules
- Содержит `/pipeline` ссылку
- Содержит таблицы Agents, Skills, Pipelines
- НЕ содержит устаревшей секции "Auto-Pipeline Rule"
- Таблица Agents соответствует реальным файлам в .claude/agents/
- Таблица Skills соответствует реальным директориям в .claude/skills/
→ Проблемы → исправить IN-PLACE → `[FIX] CLAUDE.md: {что}`

## Cleanup легаси (автоматически, без вопросов)

В режиме `validate` выполняется автоматически:
- `skills/routing/` существует → переименовать в `skills/pipeline/`, обновить содержимое → `[FIX] routing/ → pipeline/`
- `CLAUDE.md` содержит "Auto-Pipeline Rule" → заменить на ЖЁСТКОЕ ПРАВИЛО → `[FIX] CLAUDE.md`
- Агенты без ссылок на skills → добавить ссылки → `[FIX] {path}`
- Устаревшие файлы (`state/session.md`, `state/task-log.md`) → предупредить → `[WARN] Устаревший: {path}`

---

## 4.1 Директории

```bash
mkdir -p .claude/{agents,skills/{code-style,architecture,database,testing,memory,pipeline,p},pipelines,scripts/hooks,state/{sessions,sessions/archive,decisions,decisions/archive,memory},output/{contracts,qa},input/{tasks,plans},database}
touch .claude/state/decisions/.gitkeep .claude/state/decisions/archive/.gitkeep
```

Если CUSTOM_SKILLS не пуст — создай дополнительные директории:
```bash
mkdir -p .claude/skills/{custom_skill_1,custom_skill_2,...}
```

Если GITLAB_MCP=true:
```bash
mkdir -p .claude/skills/gitlab
```

## 4.2 Агенты

**Мульти-языковая генерация:** Шаблоны генерируй для КАЖДОГО языка из `LANGS`. Для каждого языка подставляй соответствующие `FRAMEWORK_{lang}`, `TEST_FRAMEWORK_{lang}`, `TEST_CMD_{lang}`, `LINT_CMD_{lang}`.

Общие агенты (DB Architect, DevOps, Frontend*, QA Engineer) — генерируются в одном экземпляре.

Для каждого `{lang}` из LANGS:
  Прочитай шаблон `templates/agents/lang-architect.md` → подставь переменные → запиши в `.claude/agents/{lang}-architect.md`
  Прочитай шаблон `templates/agents/lang-developer.md` → подставь переменные → запиши в `.claude/agents/{lang}-developer.md`
  Прочитай шаблон `templates/agents/lang-test-developer.md` → подставь переменные → запиши в `.claude/agents/{lang}-test-developer.md`
  Прочитай шаблон `templates/agents/lang-reviewer-logic.md` → подставь переменные → запиши в `.claude/agents/{lang}-reviewer-logic.md`
  Прочитай шаблон `templates/agents/lang-reviewer-security.md` → подставь переменные → запиши в `.claude/agents/{lang}-reviewer-security.md`

Общие агенты (по условиям):
  Прочитай шаблон `templates/agents/db-architect.md` → подставь переменные → запиши в `.claude/agents/db-architect.md` (если есть БД)
  Прочитай шаблон `templates/agents/devops.md` → подставь переменные → запиши в `.claude/agents/devops.md`
  Прочитай шаблон `templates/agents/frontend-developer.md` → подставь переменные → запиши в `.claude/agents/frontend-developer.md` (если FRONTEND != none)
  Прочитай шаблон `templates/agents/frontend-test-developer.md` → подставь переменные → запиши в `.claude/agents/frontend-test-developer.md` (если FRONTEND != none)
  Прочитай шаблон `templates/agents/frontend-reviewer.md` → подставь переменные → запиши в `.claude/agents/frontend-reviewer.md` (если FRONTEND != none)
  Прочитай шаблон `templates/agents/qa-engineer.md` → подставь переменные → запиши в `.claude/agents/qa-engineer.md`

Условные агенты (создавай если есть соответствующий стек):
  Если FRONTEND != none: `frontend-contract` — API-контракты (`.claude/agents/frontend-contract.md`)
  Если есть CI (.gitlab-ci.yml, .github/workflows/): `ci-manager` — CI/CD (`.claude/agents/ci-manager.md`)

Для frontend-contract и ci-manager агентов используй универсальный шаблон ниже.

### 4.2.1 Кастомные агенты

Для каждого агента из CUSTOM_AGENTS, а также для frontend-contract и ci-manager, сгенерируй файл `.claude/agents/{name}.md` по универсальному шаблону:

```markdown
# Агент: {Name}

## Роль
{ROLE — из ответа пользователя или определи по стеку}

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- Код модуля: {SOURCE_DIR}
- `.claude/skills/code-style/SKILL.md` — стиль кода
- `.claude/skills/architecture/SKILL.md` — архитектура

## Задача
{Сгенерируй 3-5 шагов на основе роли и стека проекта}

## Правила
{Сгенерируй 3-5 правил на основе роли, стека и code-style}

## Формат вывода
{Определи на основе роли}
```

Адаптируй содержимое под стек проекта (LANG, FRAMEWORK, DB).

---

## СТЕК-СПЕЦИФИЧНЫЕ АДАПТАЦИИ

Используй эти адаптации при генерации агентов. Эти же адаптации применяются на шагах 4b и 4c.

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
