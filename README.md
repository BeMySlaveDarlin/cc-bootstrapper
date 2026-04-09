# cc-bootstrapper

[English](README.en.md)

Генератор системы автоматизации Claude Code. Запускаешь `/cc-bootstrapper:bootstrap` в любом проекте — получаешь полную `.claude/` структуру: агенты, пайплайны, скиллы, memory, hooks, settings. Дальше работаешь через `/pipeline`.

## Требования

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Bash 4+
- `jq`
- macOS, Linux или Windows (WSL)

## Установка

### Как плагин Claude Code (рекомендуется)

В Claude Code CLI:
```
/plugin marketplace add BeMySlaveDarlin/cc-bootstrapper
/plugin install cc-bootstrapper@bemyslavedarlin-cc-bootstrapper
```

### Локальная установка (для разработки)

```
/plugin marketplace add /path/to/cc-bootstrapper
/plugin install cc-bootstrapper@bemyslavedarlin-cc-bootstrapper
```

## Запуск

```
/cc-bootstrapper:bootstrap
```

Если Agent Teams доступны — предложит выбор: **Team** (параллельные агенты, ~x2 быстрее) или **Sequential** (последовательный, стабильнее).

Автоопределение режима:
- Пустой проект → генерирует шаблон спецификации, останавливается
- Нет `.claude/` → полная генерация (fresh)
- Есть `.claude/` → валидация + миграция (validate)
- Есть state → resume с последнего шага

Поддерживаемые стеки: PHP, Node.js/TypeScript, Python, Go, Rust, Java, C#, Ruby. Мульти-язычные проекты — набор агентов для каждого языка.

## Процесс bootstrap (10 шагов)

| Шаг | Название | Что делает |
|-----|----------|------------|
| 1 | Сканирование | Light scan: манифесты, структура, стек, git remote |
| 2 | Определение режима | empty / fresh / validate / resume |
| 3 | Настройка | permissions, git, глубина анализа, custom agents/skills/pipelines |
| 4 | Settings.json | Базовые permissions + hooks |
| 5 | Плагины и MCP | Playwright, Context7, LSP, GitLab/GitHub/Docker MCP |
| 6 | План и превью | Dry-run preview, оценка токенов, **pause point** |
| 7 | Глубокий анализ | Per-lang паттерны, архитектура, API (опционально) |
| 8 | Генерация | Per-domain параллельно: per-lang + common + infra |
| 9 | CLAUDE.md | Генерация с таблицами агентов/скиллов/пайплайнов |
| 10 | Финализация | Верификация, .bootstrap-version, cleanup |

**Team mode:** фазы A(scan∥) → B(config) → C(preview) → D(gen∥) → E(finalize∥). Генерация per-lang параллельно через TeamCreate.

Каждый шаг — изолированный субагент. Данные передаются через `.bootstrap-cache/state.json`. При crash — resume с последнего шага.

---

# Сгенерированная система

Всё ниже — описание того, что появляется в целевом проекте после bootstrap и как с этим работать.

## Routing

CLAUDE.md содержит ЖЁСТКОЕ ПРАВИЛО: любой запрос связанный с кодом маршрутизируется через `/pipeline`.

```
/pipeline review          → ревью кода
/p fix баг в авторизации  → fix-code pipeline
/p новый эндпоинт users   → new-code pipeline
/p                        → определит тип по контексту
```

## Пайплайны

9 базовых + кастомные. Пайплайны имеют YAML frontmatter с triggers, error_routing, adaptive_teams.

| Pipeline | Когда | Ключевые фазы | Agent Teams |
|----------|-------|---------------|-------------|
| `new-code` | Новый модуль, сервис, эндпоинт | Analysis → Architecture → Storage → Code → Tests → Review | developer + test-developer + reviewer |
| `fix-code` | Баг, ошибка, regression | Diagnosis → Fix → Tests → Review | developer + test-developer + reviewer |
| `review` | Ревью кода | Per-lang Review → Report | reviewers per-lang ∥ |
| `tests` | Написание тестов | Analyze → Generate → Verify → Review | test-developer + reviewer |
| `brainstorm` | Обсуждение идеи, подхода | Frame → Perspectives → Capture | analyst ∥ architect ∥ storage ∥ devops |
| `api-docs` | API-контракты | Scan → Generate → Save | — |
| `qa-docs` | Чеклисты, Postman, E2E | Input → Checklist → Automation → Save | — |
| `full-feature` | Полный цикл фичи | new-code + api-docs + qa-docs | — (chains) |
| `hotfix` | Срочное исправление | fix-code + review | — (chains) |

5 пайплайнов поддерживают **Agent Teams**: TeamCreate → Agent spawn → SendMessage координация → TeamDelete. Fallback на sequential автоматический.

### Peer Validation (v8.2.0)

Перед каждым user approval gate — внутренний peer review: валидатор (существующий агент) проверяет результат автора, отправляет замечания обратно, автор исправляет. Макс 2-3 итерации. Пользователь видит уже проверенный план.

| Gate | Автор | Валидатор |
|------|-------|-----------|
| new-code Phase 1 (ТЗ) | analyst | {lang}-architect |
| new-code Phase 2 (архитектура) | {lang}-architect | {lang}-reviewer |
| fix-code Phase 1 (диагностика) | analyst | {lang}-developer |
| tests Phase 1 (план тестирования) | analyst | qa-engineer |
| brainstorm Phase 2 (варианты) | {lang}-architect | analyst |

Настраивается через `peer_validation` секцию в frontmatter пайплайна.

### Передача данных между фазами

Фазы обмениваются данными через файлы:

```
Analyst    → ТЗ в output/plans/{task-slug}-spec.md
Architect  → план в output/plans/{task-slug}.md
Developer  → код по плану
Tester     → тесты по коду (git diff)
Reviewer   → отчёт в output/reviews/{task-slug}-{lang}.md
Validator  → замечания в output/reviews/{task-slug}-peer-{phase}.md
```

Агенты **сначала записывают артефакт в файл, потом возвращают summary**. При crash артефакт не теряется.

### CAPTURE

Каждый пайплайн завершается фазой CAPTURE — обновление memory:
- `facts.md` обновляется посекционно (Stack, Key Paths, Active Decisions, Known Issues)
- Новые решения → `decisions/{date}-{slug}.md`
- Паттерны → `patterns.md`
- Баги → `issues.md`

## Агенты

Для каждого языка — 4 агента:

| Агент | Роль | Режим |
|-------|------|-------|
| `{lang}-architect` | Планирование модулей и архитектуры | PLAN MODE (read-only) |
| `{lang}-developer` | Написание кода по плану | Пишет файлы |
| `{lang}-test-developer` | Написание тестов | Пишет файлы |
| `{lang}-reviewer` | Комплексное ревью: архитектура, логика, безопасность, стат-анализ, оптимизация | READ-ONLY |

Общие агенты:

| Агент | Роль | Условие |
|-------|------|---------|
| `analyst` | Декомпозиция задач, ТЗ | Всегда |
| `storage-architect` | Проектирование хранилищ: SQL, NoSQL, Redis, S3, очереди | Если есть хранилище |
| `devops` | Docker, CI/CD, хост-машина (WSL/Linux/macOS), деплой | Всегда |
| `qa-engineer` | Тест-планы, чеклисты, Postman, Playwright E2E, smoke-тесты | Всегда |

## Скиллы

| Скилл | Что содержит | Условие |
|-------|-------------|---------|
| `code-style/` | Паттерны и антипаттерны кода проекта | всегда |
| `architecture/` | Структура модулей, DI, маршруты | всегда |
| `storage/` | Хранилища: БД, кэш, очереди, object storage | всегда |
| `testing/` | Тест-фреймворк, моки, E2E | всегда |
| `memory/` | Правила работы с memory-системой | всегда |
| `pipeline/` | Роутер `/pipeline` (invocable) | всегда |
| `p/` | Alias `/p` (invocable) | всегда |
| `gitlab/` | MCP-операции GitLab: MR, issues, pipelines, wiki | gitlab MCP |
| `github/` | GitHub CLI: PR, issues, actions, releases | github MCP |
| `playwright/` | Playwright MCP: навигация, формы, скриншоты, E2E | playwright plugin |

## Memory

| Файл | Назначение | Лимиты |
|------|------------|--------|
| `facts.md` | Стек, пути, активные решения, known issues | Секционное обновление, 10 issues max |
| `patterns.md` | Повторяющиеся паттерны кода | — |
| `issues.md` | Known issues из ревью | 30 строк, дедупликация |
| `decisions/*.md` | Архитектурные решения (ADR-lite) | 20 активных max |
| `decisions/archive/` | Устаревшие решения | Авторотация 30 дней |

## Hooks

| Hook | Event | Что делает |
|------|-------|------------|
| `track-agent.sh` | PostToolUse (Task) | Логирует использование агентов |
| `maintain-memory.sh` | SessionStart | Ротация decisions, компакция memory, cleanup |
| `update-schema.sh` | SessionStart (если DB) | Обновляет `database/schema.sql` из Docker |

## Плагины и MCP (step 5)

Bootstrap предлагает установить релевантные плагины и MCP:

| Тип | Что | Условие |
|-----|-----|---------|
| Plugin | Playwright | Фронтенд или E2E тесты |
| Plugin | Context7 | Популярный фреймворк |
| Plugin | LSP (TypeScript, PHP, Python, Go) | Per-lang |
| MCP | GitLab | git hosting = GitLab |
| MCP | GitHub | git hosting = GitHub |
| MCP | Docker | Docker в стеке |

Каждый предлагается через AskUserQuestion. После установки permissions автоматически добавляются в settings.json.

## Settings.json

Генерируется на step 4 с учётом выбора пользователя:

- **Permissions level**: conservative / balanced / permissive
- **Git permissions**: read / write / push / delete (multiSelect)
- **Lang-specific**: автоматически по стеку (npm, composer, pip, cargo, etc.)
- **MCP permissions**: добавляются на step 5 после установки плагинов

В validate mode: diff-based merge с маркерами `[KEEP]`/`[+ADD]`/`[-DEL]`/`[USER]`.

## Кастомизация

**Агент:** создай `.claude/agents/{name}.md`, добавь в CLAUDE.md, подключи в пайплайн.

**Скилл:** `mkdir -p .claude/skills/{name}`, создай `SKILL.md`. Для invocable — `user-invocable: true`.

**Пайплайн:** создай `.claude/pipelines/{name}.md`, добавь keywords в `skills/pipeline/SKILL.md`.

**Hook:** создай `.claude/scripts/hooks/{name}.sh`, `chmod +x`, добавь в `settings.json`.

## Лицензия

[MIT](LICENSE)
