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

Плагин автоматически зарегистрирует скилл `/cc-bootstrapper:bootstrap`.

### Ручная установка (legacy)

```bash
git clone https://github.com/BeMySlaveDarlin/cc-bootstrapper.git
cd cc-bootstrapper
bash install.sh
```

Скрипт скопирует промпты и команду в `~/.claude/`.

## Запуск

```bash
cd /path/to/your-project
claude
```
```
> /cc-bootstrapper:bootstrap    # Плагин
> /bootstrap                    # Legacy (ручная установка)
```

Автоопределение: нет `.claude/` → полная генерация, есть → валидация + auto-fix.

Поддерживаемые стеки: PHP, Node.js/TypeScript, Python, Go, Rust, Java, C#, Ruby. Мульти-язычные проекты — набор агентов для каждого языка.

---

# Сгенерированная система

Всё ниже — описание того, что появляется в целевом проекте после `/bootstrap` и как с этим работать.

## Routing

CLAUDE.md содержит ЖЁСТКОЕ ПРАВИЛО: любой запрос связанный с кодом автоматически маршрутизируется через `/pipeline`. Свободная форма — только для вопросов и обсуждений.

```
/pipeline review          → ревью кода
/p fix баг в авторизации  → fix-code pipeline
/p новый эндпоинт users   → new-code pipeline
/p                        → определит тип по контексту
```

Роутер классифицирует задачу по ключевым словам, затем собирает контекст через AskUserQuestion. Для `new-code`/`full-feature` предлагает запустить анализ (аналитик формирует ТЗ); для остальных — scope/тип проблемы + затронутые модули. Флаг `--no-analysis` пропускает анализ.

## Пайплайны

8 базовых + кастомные (добавляются при bootstrap):

| Pipeline | Когда | Ключевые фазы |
|----------|-------|---------------|
| `new-code` | Новый модуль, сервис, эндпоинт | Analysis → Architecture → DB → Code → Tests → Review |
| `fix-code` | Баг, ошибка, regression | Diagnosis → Fix → Tests → Review |
| `review` | Ревью кода | Parallel Review (logic + security) → Report |
| `tests` | Написание тестов | Analyze → Generate → Verify → Review |
| `api-docs` | API-контракты | Scan → Generate → Save |
| `qa-docs` | Чеклисты, Postman | Input → Checklist → Postman → Save |
| `full-feature` | Полный цикл фичи | new-code + api-docs + qa-docs |
| `hotfix` | Срочное исправление | fix-code + review |

### Передача данных между фазами

Фазы обмениваются данными через файлы, не через контекст разговора:

```
Analyst    → читает код и инфру, задаёт вопросы, пишет ТЗ в output/plans/{task-slug}-spec.md
Architect  → читает ТЗ, пишет план в output/plans/{task-slug}.md
Developer  → читает план из файла, пишет код
Tester     → читает код (git diff), пишет тесты
Reviewers  → читают код (git diff), пишут отчёты в output/reviews/{task-slug}-{type}.md
```

В контекст пайплайна возвращается только summary (5-10 строк на фазу). Полные результаты доступны следующему агенту через чтение файла.

### Plan mode

- Analyst работает в PLAN MODE + READ-ONLY — читает код/схему/инфру, задаёт уточняющие вопросы, формирует ТЗ
- Architect работает в режиме PLAN MODE — только анализ, план показывается на утверждение, файлы проекта не трогает
- `fix-code` и `tests` запрашивают подтверждение плана через AskUserQuestion перед выполнением

### CAPTURE

Каждый пайплайн завершается фазой CAPTURE — обновление memory:
- `facts.md` обновляется посекционно (Stack, Key Paths, Active Decisions, Known Issues)
- Новые решения → `decisions/{date}-{slug}.md`
- Паттерны → `patterns.md`
- Баги → `issues.md`

### Adaptive Teams

`new-code`, `review`, `full-feature` поддерживают параллельный режим:
- **Opus 4.6** → reviewers работают параллельно через Teams API
- **Другие модели** → автоматический fallback на последовательный режим

## Агенты

Самодостаточные markdown-файлы. Агент сам читает нужный контекст (facts.md, decisions/, skills/), от пайплайна получает только task-slug и путь к входным данным.

Для каждого языка — 5 агентов:

| Агент | Роль | Режим |
|-------|------|-------|
| `{lang}-architect` | Планирование модулей и архитектуры | PLAN MODE (read-only) |
| `{lang}-developer` | Написание кода по плану | Пишет файлы |
| `{lang}-test-developer` | Написание тестов | Пишет файлы |
| `{lang}-reviewer-logic` | Ревью бизнес-логики | READ-ONLY |
| `{lang}-reviewer-security` | Ревью безопасности | READ-ONLY |

Общие агенты: `analyst`, `db-architect`, `devops`, `frontend-developer`, `frontend-test-developer`, `frontend-reviewer`, `qa-engineer`.

Секции агента: Роль → Режим → Контекст (читай сам) → Вход → Задача → Правила → Вывод.

## Скиллы

Базы знаний, которые агенты читают при работе:

| Скилл | Что содержит |
|-------|-------------|
| `code-style/` | Паттерны и антипаттерны кода проекта |
| `architecture/` | Структура модулей, DI, маршруты |
| `database/` | Миграции, типы данных, индексы |
| `testing/` | Тест-фреймворк, моки, структура тестов |
| `memory/` | Правила работы с memory-системой |
| `pipeline/` | Роутер `/pipeline` (invocable) |
| `p/` | Alias `/p` для быстрого вызова (invocable) |

## Memory

| Файл | Назначение | Лимиты |
|------|------------|--------|
| `facts.md` | Стек, пути, активные решения, known issues | Секционное обновление, 10 issues max |
| `patterns.md` | Повторяющиеся паттерны кода | — |
| `issues.md` | Known issues из ревью | 30 строк, дедупликация по Frequency |
| `decisions/*.md` | Архитектурные решения (ADR-lite) | 20 активных max |
| `decisions/archive/` | Устаревшие решения | Авторотация 30 дней |

Агенты читают `facts.md` посекционно (Stack, Key Paths, Active Decisions) — не весь файл.

Пайплайны обновляют `facts.md` по секциям с семантикой REPLACE/MERGE, не дописывая в конец. Дедупликация перед добавлением.

## Hooks

| Hook | Event | Что делает |
|------|-------|------------|
| `track-agent.sh` | PostToolUse (Task) | Логирует использование агентов в `usage.jsonl` |
| `maintain-memory.sh` | SessionStart | Ротация decisions, компакция facts/issues, cleanup output/ старше 7 дней |
| `update-schema.sh` | SessionStart (если DB) | Обновляет `database/schema.sql` из Docker |

## Output

| Директория | Что хранит | Жизненный цикл |
|-----------|------------|----------------|
| `output/plans/` | Планы архитектора | Auto-cleanup через 7 дней |
| `output/reviews/` | Отчёты ревью | Auto-cleanup через 7 дней |
| `output/contracts/` | API-контракты | Постоянно |
| `output/qa/` | QA-чеклисты, Postman | Постоянно |

## GitLab MCP (опционально)

Если настроен при bootstrap — `.mcp.json` с GitLab MCP server + агент `gitlab-manager` + пайплайн `gitlab`:
- Управление Issues, MR, Pipelines, Wiki
- Роутер автоматически направляет запросы типа "создай MR", "задача #42"

## Кастомизация

Вся структура — твоя после генерации.

**Агент:** создай `.claude/agents/{name}.md` по структуре существующих, добавь в CLAUDE.md, подключи в пайплайн.

**Скилл:** `mkdir -p .claude/skills/{name}`, создай `SKILL.md`. Для invocable — frontmatter `user-invocable: true`.

**Пайплайн:** создай `.claude/pipelines/{name}.md` (минимум 2 фазы с Task()), добавь keywords в `skills/pipeline/SKILL.md`, добавь в CLAUDE.md.

**Hook:** создай `.claude/scripts/hooks/{name}.sh`, `chmod +x`, добавь в `settings.json`.

## Версионирование

| Версия | Что нового |
|--------|------------|
| v6.0.0 | Claude Code Plugin — публикация на маркетплейсе, command → skill, английские README/CLAUDE.md, PRIVACY.md |
| v5.4.2 | AskUserQuestion во всём интерактиве, обновление Teams API (natural language вместо TeamCreate/Spawn) |
| v5.4.1 | Версионирование шаблонов — version в frontmatter скиллов и HTML-комментарий в пайплайнах, авто-REGEN при устаревшей версии |
| v5.4.0 | Агент-аналитик — Phase 1 ANALYSIS в new-code/full-feature, формализация ТЗ перед архитектурой |
| v5.3.0 | File-based передача между фазами, секционный CAPTURE, структурированный контекст в роутере, plan mode |
| v5.2.0 | Рефакторинг хуков — 5→3, кросс-платформенность |
| v5.1.0 | Миграция state/ → memory/ |
| v5.0.0 | Adaptive Teams — Teams API с graceful degradation |
| v4.0.0 | Модульная архитектура |
| v3.0.0 | GitLab MCP интеграция |
| v2.0.0 | Pipeline skills, memory system |

## Лицензия

[MIT](LICENSE)
