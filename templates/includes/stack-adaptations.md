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
