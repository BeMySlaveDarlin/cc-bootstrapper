# Реестр плейсхолдеров

Все `{PLACEHOLDER}` переменные, используемые в шаблонах. Генератор (step-8) подставляет значения из `state.json` и includes.

## Value-плейсхолдеры

Подставляются как строки из state.json или вычисляются по стеку.

| Placeholder | Источник | Используется в |
|-------------|----------|---------------|
| `{lang}` | `state.stack.langs[]` | agents (lang-*), pipelines, skills |
| `{LANG}` | Display name: PHP, Node.js, Go | agents (lang-*), skills |
| `{Lang}` | Title case: Php, Node, Go | agents (заголовки) |
| `{FRAMEWORK}` | `state.stack.frameworks[lang]` | agents, skills |
| `{SOURCE_DIR}` | stack-adaptations.md по стеку | agents, skills, memory |
| `{TEST_DIR}` | По стеку (tests/, spec/, __tests__/) | memory/facts.md |
| `{MIGRATIONS_DIR}` | По стеку | memory/facts.md |
| `{SYNTAX_CHECK_CMD}` | stack-adaptations.md | lang-developer, pipelines |
| `{TEST_CMD}` | stack-adaptations.md | lang-test-developer, pipelines |
| `{MIGRATE_CMD}` | stack-adaptations.md | pipelines (new-code, fix-code) |
| `{TEST_FRAMEWORK}` | `state.stack.test_frameworks[lang]` | skills/testing |
| `{MOCK_LIBRARY}` | По стеку | skills/testing |
| `{ASSERTION_LIBRARY}` | По стеку | skills/testing |
| `{TEST_RUN_CMD}` | = `{TEST_CMD}` | skills/testing |
| `{TEST_WATCH_CMD}` | По стеку | skills/testing |
| `{TEST_FILE_NAMING}` | По стеку (*Test.php, *.spec.ts) | skills/testing |
| `{TEST_CLASS_NAMING}` | По стеку | skills/testing |
| `{DB_TYPE}` | `state.stack.db` | skills/storage |
| `{DB_VERSION}` | `state.stack.db_version` | skills/storage |
| `{ORM_NAME}` | По стеку | skills/storage |
| `{CACHE_TYPE}` | `state.stack.cache` | skills/storage, architecture |
| `{QUEUE_TYPE}` | `state.stack.queue` | skills/storage |
| `{LINT_CMD}` | `state.stack.lint_cmds[lang]` | agents |
| `{LANG_EXT}` | По стеку (.php, .ts, .go) | skills/code-style |

## Контентные плейсхолдеры

Генерируются step-8 на основе анализа проекта.

| Placeholder | Описание | Используется в |
|-------------|----------|---------------|
| `{ORDER}` | Порядок реализации по фреймворку | lang-developer |
| `{LANG_SPECIFIC_RULES}` | Правила кода из code-style + CLAUDE.md | lang-developer |
| `{TEST_RULES}` | Правила тестирования | lang-test-developer |
| `{NAMING}` | Naming conventions тестов | lang-test-developer |
| `{TEST_PATH_PATTERN}` | Паттерн пути к тестам | lang-test-developer |
| `{ARCHITECTURE_PLAN_TEMPLATE}` | Шаблон плана архитектуры | lang-architect |
| `{ARCH_CHECKLIST}` | Чеклист архитектурного ревью | lang-reviewer |
| `{LOGIC_CHECKLIST}` | Чеклист логического ревью | lang-reviewer |
| `{SECURITY_CHECKLIST}` | Чеклист безопасности | lang-reviewer |
| `{STATIC_CHECKLIST}` | Чеклист статического анализа | lang-reviewer |
| `{PERF_CHECKLIST}` | Чеклист производительности | lang-reviewer |
| `{CLASS_NAMING}` | Конвенция именования классов | skills/code-style |
| `{METHOD_NAMING}` | Конвенция именования методов | skills/code-style |
| `{VAR_NAMING}` | Конвенция именования переменных | skills/code-style |
| `{CONST_NAMING}` | Конвенция именования констант | skills/code-style |
| `{TYPING_RULES}` | Правила типизации | skills/code-style |
| `{DI_RULES}` | Правила DI/injection | skills/code-style |
| `{ANTIPATTERNS}` | Антипаттерны кода | skills/code-style |
| `{MODULE_STRUCTURE}` | Структура модулей | skills/architecture |
| `{DEPENDENCY_CHAIN}` | Цепочка зависимостей | skills/architecture |
| `{DI_BINDINGS}` | DI-биндинги | skills/architecture |
| `{ROUTES_TABLE}` | Таблица маршрутов | skills/architecture |
| `{STORAGE_ANTIPATTERNS}` | Антипаттерны хранилищ | skills/storage |
| `{SERVICES_TABLE}` | Таблица Docker-сервисов | agents/devops |
| `{HOST_ENV}` | Описание хост-окружения | agents/devops |
| `{ALL_COMMANDS}` | Все команды проекта | agents/devops |
| `{CI_SECTION}` | Секция CI/CD | agents/devops |
| `{DEPLOY_SECTION}` | Секция деплоя | agents/devops |
| `{COMMON_ISSUES}` | Типичные проблемы | agents/devops |
| `{DB_SECTION}` | Секция БД | agents/storage-architect |
| `{CACHE_SECTION}` | Секция кэша | agents/storage-architect |
| `{QUEUE_SECTION}` | Секция очередей | agents/storage-architect |
| `{OBJECT_STORAGE_SECTION}` | Секция object storage | agents/storage-architect |

## Include-плейсхолдеры

Подставляются как блоки текста из `templates/includes/`.

| Placeholder | Файл-источник | Используется в |
|-------------|--------------|---------------|
| `{PIPELINE_STATE_INIT}` | `includes/pipeline-state-init.md` | все pipeline-ы (после Phase 0) |
| `{PIPELINE_STATE_UPDATE}` | `includes/pipeline-state-update.md` | все pipeline-ы (после каждой рабочей фазы) |
| `{CAPTURE:full}` | `includes/capture-full.md` | new-code, full-feature |
| `{CAPTURE:partial}` | `includes/capture-partial.md` | fix-code, hotfix, brainstorm |
| `{CAPTURE:review}` | `includes/capture-review.md` | review |
| `{PARALLEL_PER_LANG}` | `includes/parallel-per-lang.md` | new-code, fix-code, review, tests |
| `{CAPABILITY_DETECT}` | `includes/capability-detect.md` | new-code, fix-code, tests, review, brainstorm |
| `{TEAM_AGENT_RULES}` | `includes/team-agent-rules.md` | все Agent() промпты в team-секциях пайплайнов |
| `{TEAM_SHUTDOWN}` | `includes/team-shutdown.md` | все adaptive пайплайны (после team flow) |
| `{AGENT_BASE_CONTEXT}` | `includes/agent-base-context.md` | все агенты (memory ссылки) |
| `{MCP_SKILLS_CONTEXT}` | `includes/mcp-skills-context.md` | все агенты (MCP skills ссылки) |
| `{PEER_REVIEW}` | `includes/peer-review.md` (параметризованный) | new-code, fix-code, brainstorm, tests |

### Параметры `{PEER_REVIEW}`

Генератор step-8 подставляет значения из `peer_validation` секции frontmatter пайплайна:

| Параметр | Описание | Пример |
|----------|----------|--------|
| `{PEER_AUTHOR}` | Агент-автор результата | `analyst`, `{lang}-architect` |
| `{PEER_VALIDATOR}` | Агент-валидатор | `{lang}-architect`, `{lang}-reviewer` |
| `{PEER_ARTIFACT}` | Путь к артефакту (относительно `.claude/output/`) | `plans/{task-slug}-spec.md` |
| `{PEER_PHASE}` | ID фазы (для имени review-файла) | `spec`, `arch`, `diagnosis` |
| `{PEER_MAX_ITERATIONS}` | Макс. итераций автор↔валидатор | `2`, `3` |

## Кастомные плейсхолдеры (pipeline router)

| Placeholder | Описание | Используется в |
|-------------|----------|---------------|
| `{CUSTOM_PIPELINE_KEYWORDS}` | Доп. строки в таблицу Intent | skills/pipeline |
| `{CUSTOM_PIPELINE_OPTIONS}` | Доп. options в AskUserQuestion | skills/pipeline |

## Условные секции

Обозначаются комментарием в шаблоне, генератор включает/исключает блок.

| Маркер | Условие | Файлы |
|--------|---------|-------|
| `(условная секция, если CACHE != none)` | `state.stack.cache != "none"` | skills/storage |
| `(условная секция, если QUEUE != none)` | `state.stack.queue != "none"` | skills/storage |
| `(условная секция, если FRONTEND != none)` | `state.stack.frontend != "none"` | skills/testing |
