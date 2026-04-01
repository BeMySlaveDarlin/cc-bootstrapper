<!-- version: 7.2.0 -->
# Pipeline: New Code

## Вход
- Описание задачи от пользователя
- Структурированный контекст из роутера: scope, affected_modules
- `.claude/memory/facts.md`

## Phase 1: ANALYSIS

{если SKIP_ANALYSIS: пропустить Phase 1, перейти к Phase 2}

Task(.claude/agents/analyst.md, subagent_type: "general-purpose"):
  Вход: описание задачи, {SOURCE_DIR}, memory/facts.md, memory/decisions/, database/schema.sql
  Выход: ОБЯЗАТЕЛЬНО запиши ТЗ в `.claude/output/plans/{task-slug}-spec.md` через Write tool ПЕРЕД возвратом
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

## Phase 2: ARCHITECTURE

Task(.claude/agents/{lang}-architect.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/plans/{task-slug}-spec.md` + `.claude/skills/architecture/SKILL.md`
  Выход: ОБЯЗАТЕЛЬНО запиши план в `.claude/output/plans/{task-slug}.md` через Write tool
  ОГРАНИЧЕНИЕ: агент НЕ СОЗДАЁТ и НЕ ИЗМЕНЯЕТ файлы ПРОЕКТА (src/, app/, etc.). Но ОБЯЗАН записать план в .claude/output/.
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

## Phase 3: STORAGE

Если задача затрагивает БД:

Task(.claude/agents/storage-architect.md, subagent_type: "general-purpose"):
  Вход: прочитай `.claude/output/plans/{task-slug}.md` + `.claude/skills/storage/SKILL.md` + `.claude/database/schema.sql`
  Выход: миграции, обновлённая схема
  Верни: summary (таблицы, миграции)

```bash
{MIGRATE_CMD}
```

Если БД не затронута — `[SKIP]`.

## Phase 4+5: CODE + TESTS (ПАРАЛЛЕЛЬНО)

Если проект мультиязычный — запусти per-lang ПАРАЛЛЕЛЬНО.
Developer и test-developer для одного языка — ПОСЛЕДОВАТЕЛЬНО (тесты зависят от кода).

Для КАЖДОГО затронутого `{lang}`:

Task(.claude/agents/{lang}-developer.md, subagent_type: "general-purpose"):
  Вход: прочитай `.claude/output/plans/{task-slug}.md` + `.claude/skills/code-style/SKILL.md`
  Выход: файлы кода
  Верни: summary (созданные файлы, зависимости)

```bash
{SYNTAX_CHECK_CMD}
```

Task(.claude/agents/{lang}-test-developer.md, subagent_type: "general-purpose"):
  Вход: реализованные файлы (из git diff или summary выше) + `.claude/skills/testing/SKILL.md`
  Выход: файлы тестов
  Верни: summary (тесты, покрытие)

```bash
{TEST_CMD}
```

Если тесты fail — исправить (максимум 2 итерации).

## Phase 6: REVIEW (per-lang ПАРАЛЛЕЛЬНО)

Если проект мультиязычный — запусти reviewer для каждого `{lang}` ПАРАЛЛЕЛЬНО.

Для КАЖДОГО затронутого `{lang}`:

Task(.claude/agents/{lang}-reviewer.md, subagent_type: "general-purpose"):
  Вход: изменённые файлы {lang} (git diff --name-only | grep расширение) + `.claude/skills/code-style/SKILL.md` + `.claude/skills/architecture/SKILL.md`
  Выход: запиши в `.claude/output/reviews/{task-slug}-{lang}.md`
  Верни: summary (verdict, замечания по severity)

### Обработка результатов
- **BLOCK** → исправить и повторить Phase 6
- **PASS WITH WARNINGS** → исправить WARN, продолжить
- **PASS** → продолжить

## Phase 6.5: CAPTURE

1. Обнови `.claude/memory/facts.md` по секциям:
   - "## Stack" → ЗАМЕНИТЬ секцию целиком (только если стек изменился)
   - "## Key Paths" → МЕРЖИТЬ: добавь новые, удали несуществующие пути
   - "## Active Decisions" → ЗАМЕНИТЬ: только ссылки на файлы из decisions/ (НЕ archive)
   - "## Known Issues" → максимум 10 записей, удали разрешённые
   ПРАВИЛО: перед добавлением проверь — НЕ ДУБЛИРУЙ существующие записи
2. Если были архитектурные решения → `.claude/memory/decisions/{date}-{slug}.md`
3. Обнови `.claude/memory/patterns.md` если выявлены новые паттерны

## Phase 7: FINALIZATION

### Итог
```
[NEW-CODE COMPLETE]
Создано файлов: {N}
Тесты: {pass}/{total}
Review: {verdict}
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| ANALYSIS | ТЗ отклонено | Уточнить требования → повторить Phase 1 |
| ARCHITECTURE | План отклонён | Уточнить требования → повторить Phase 2 |
| DATABASE | Миграция fail | Проверить SQL → повторить Phase 3 |
| CODE | Syntax error | Исправить → повторить проверку |
| TESTS | Тесты fail (>2 итераций) | Остановить, показать ошибки пользователю |
| REVIEW | BLOCK | Исправить замечания → повторить Phase 6 |
