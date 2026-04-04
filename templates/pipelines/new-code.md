---
name: "new-code"
description: "Полный цикл создания нового кода"
version: "8.1.0"
phases: 7
capture: "full"
user_prompts: true
parallel_per_lang: true
error_matrix: true
adaptive_teams: true
chains: []
triggers:
  - новый
  - добавь
  - создай
  - фича
  - модуль
  - эндпоинт
error_routing:
  analysis_rejected: retry_current
  architecture_rejected: retry_current
  migration_fail: retry_current
  syntax_error: retry_current
  test_fail: {max_retries: 2, action: stop_and_report}
  review_block: retry_from:6
  team_spawn_fail: fallback_sequential
---

# Pipeline: New Code

## Phase 0: CAPABILITY DETECT

{CAPABILITY_DETECT}

{PIPELINE_STATE_INIT}

## Вход
- Описание задачи от пользователя
- Структурированный контекст из роутера: scope, affected_modules
- `.claude/memory/facts.md`

## Phase 1: ANALYSIS

{если SKIP_ANALYSIS: пропустить Phase 1, перейти к Phase 2}

Task(.claude/agents/analyst.md, subagent_type: "general-purpose"):
  Вход: описание задачи, {SOURCE_DIR}, memory/facts.md, memory/decisions/, database/schema.sql
  Выход: `.claude/output/plans/{task-slug}-spec.md`
  Ограничение: read-only
  Верни: summary (scope + затронутые модули + acceptance criteria)

**После субагента** — прочитай `.claude/output/plans/{task-slug}-spec.md` и покажи пользователю.

AskUserQuestion:
  question: "ТЗ готово. Подтвердить?"
  options:
    - {label: "Подтвердить", description: "Передать ТЗ архитектору"}
    - {label: "Уточнить", description: "Ввести поправки"}
    - {label: "Отменить", description: "Прервать pipeline"}

→ "Уточнить":
  AskUserQuestion:
    question: "Что скорректировать в ТЗ?"
    header: "Поправки"
    options:
      - {label: "Scope", description: "Изменить что входит/не входит"}
      - {label: "Требования", description: "Изменить acceptance criteria"}
      - {label: "Модули", description: "Изменить затронутые модули"}
  Запусти аналитика заново с поправками. Повтори AskUserQuestion.
→ "Подтвердить": передай ТЗ в Phase 2

{PIPELINE_STATE_UPDATE}

## Phase 2: ARCHITECTURE

Task(.claude/agents/{lang}-architect.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/plans/{task-slug}-spec.md` + `.claude/skills/architecture/SKILL.md`
  Выход: `.claude/output/plans/{task-slug}.md`
  Ограничение: read-only
  Верни: summary (модули, ключевые решения, путь к плану)

**После субагента** — прочитай `.claude/output/plans/{task-slug}.md` и покажи пользователю.

AskUserQuestion:
  question: "Архитектурный план готов. Подтвердить?"
  options:
    - {label: "Подтвердить", description: "Приступить к реализации"}
    - {label: "Уточнить", description: "Ввести поправки"}
    - {label: "Отменить", description: "Прервать pipeline"}

→ "Уточнить":
  AskUserQuestion:
    question: "Что скорректировать в плане?"
    header: "Поправки"
    options:
      - {label: "Scope", description: "Изменить набор модулей/компонентов"}
      - {label: "Подход", description: "Изменить архитектурный подход"}
      - {label: "Детализация", description: "Нужно больше деталей"}
  Запусти архитектора заново с дополнительным контекстом (поправки пользователя).
  Повтори AskUserQuestion "Подтвердить?"

{PIPELINE_STATE_UPDATE}

## Phase 3: STORAGE

Если задача затрагивает БД:

Task(.claude/agents/storage-architect.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/plans/{task-slug}.md` + `.claude/skills/storage/SKILL.md` + `.claude/database/schema.sql`
  Выход: миграции, обновлённая схема
  Ограничение: project-write
  Верни: summary (таблицы, миграции)

```bash
{MIGRATE_CMD}
```

Если БД не затронута — `[SKIP]`.

{PIPELINE_STATE_UPDATE}

## Phase 4+5+6: CODE → TESTS → REVIEW

### Режим TEAM

Для КАЖДОГО затронутого `{lang}`:

```python
TeamCreate(team_name="new-code-{lang}")

Agent(name="{lang}-developer", team_name="new-code-{lang}", prompt="""
Прочитай .claude/agents/{lang}-developer.md — выполняй workflow.
{TEAM_AGENT_RULES}
ЗАДАНИЕ: реализуй код по плану `.claude/output/plans/{task-slug}.md` + `.claude/skills/code-style/SKILL.md`.
После записи кода: {SYNTAX_CHECK_CMD}.
Отчёт запиши в `.claude/output/plans/{task-slug}-impl-{lang}.md`.
SendMessage(to="{lang}-test-developer"): done + путь к отчёту.
""")

Agent(name="{lang}-test-developer", team_name="new-code-{lang}", prompt="""
Прочитай .claude/agents/{lang}-test-developer.md — выполняй workflow.
{TEAM_AGENT_RULES}
Жди сообщение от {lang}-developer (done).
ЗАДАНИЕ: напиши тесты для реализованных файлов + `.claude/skills/testing/SKILL.md`.
После записи тестов: {TEST_CMD}. Если fail — исправь (макс. 2 итерации).
Отчёт запиши в `.claude/output/plans/{task-slug}-tests-{lang}.md`.
SendMessage(to="{lang}-reviewer"): done + путь к отчёту.
""")

Agent(name="{lang}-reviewer", team_name="new-code-{lang}", prompt="""
Прочитай .claude/agents/{lang}-reviewer.md — выполняй workflow.
{TEAM_AGENT_RULES}
Жди сообщение от {lang}-test-developer (done).
ЗАДАНИЕ: ревью кода (git diff) + `.claude/skills/code-style/SKILL.md` + `.claude/skills/architecture/SKILL.md`.
Запиши ревью в `.claude/output/reviews/{task-slug}-{lang}.md`.
BLOCK → SendMessage(to="{lang}-developer"): реестр правок. Жди исправление. Макс. 2 цикла.
PASS → SendMessage(to=lead): verdict + путь к ревью.
""")
```

### Flow
```
{lang}-developer → {lang}-test-developer → {lang}-reviewer
                                                 ↓ BLOCK
                                           {lang}-developer (fix) → ... (макс. 2 цикла)
                                                 ↓ PASS
                                                lead
```

Если проект мультиязычный — запусти команды per-lang ПАРАЛЛЕЛЬНО (отдельный TeamCreate на каждый lang).

{TEAM_SHUTDOWN}

### Режим SEQUENTIAL

{PARALLEL_PER_LANG}

Task(.claude/agents/{lang}-developer.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/plans/{task-slug}.md` + `.claude/skills/code-style/SKILL.md`
  Выход: файлы кода
  Ограничение: project-write
  Верни: summary (созданные файлы, зависимости)

```bash
{SYNTAX_CHECK_CMD}
```

Task(.claude/agents/{lang}-test-developer.md, subagent_type: "general-purpose"):
  Вход: реализованные файлы (из git diff или summary выше) + `.claude/skills/testing/SKILL.md`
  Выход: файлы тестов
  Ограничение: project-write
  Верни: summary (тесты, покрытие)

```bash
{TEST_CMD}
```

Если тесты fail — исправить (максимум 2 итерации).

Task(.claude/agents/{lang}-reviewer.md, subagent_type: "general-purpose"):
  Вход: изменённые файлы {lang} (git diff --name-only | grep расширение) + `.claude/skills/code-style/SKILL.md` + `.claude/skills/architecture/SKILL.md`
  Выход: `.claude/output/reviews/{task-slug}-{lang}.md`
  Ограничение: read-only
  Верни: summary (verdict, замечания по severity)

### Обработка результатов (оба режима)
- **BLOCK** → исправить и повторить review
- **PASS WITH WARNINGS** → исправить WARN, продолжить
- **PASS** → продолжить

{PIPELINE_STATE_UPDATE}

## Phase 6.5: CAPTURE

{CAPTURE:full}

{PIPELINE_STATE_UPDATE}

## Phase 7: FINALIZATION

### Итог
```
[NEW-CODE COMPLETE]
Режим: {TEAM | SEQUENTIAL}
Создано файлов: {N}
Тесты: {pass}/{total}
Review: {verdict}
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| CAPABILITY DETECT | Teams недоступны | Fallback → SEQUENTIAL |
| ANALYSIS | ТЗ отклонено | Уточнить требования → повторить Phase 1 |
| ARCHITECTURE | План отклонён | Уточнить требования → повторить Phase 2 |
| DATABASE | Миграция fail | Проверить SQL → повторить Phase 3 |
| CODE+TESTS (TEAM) | Spawn fail | Fallback → SEQUENTIAL |
| CODE+TESTS (TEAM) | Агент не отвечает | Исключить, продолжить остальными |
| CODE | Syntax error | Исправить → повторить проверку |
| TESTS | Тесты fail (>2 итераций) | Остановить, показать ошибки пользователю |
| REVIEW | BLOCK (>2 циклов) | Остановить, показать замечания пользователю |
