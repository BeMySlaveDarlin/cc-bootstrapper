# Pipeline: New Code

## Вход
- Описание задачи от пользователя
- Структурированный контекст из роутера: scope, affected_modules
- `.claude/memory/facts.md`

{если ADAPTIVE_TEAMS: включи `templates/includes/capability-detect.md`}

## Phase 1: ARCHITECTURE

Task(.claude/agents/{lang}-architect.md, subagent_type: "general-purpose", mode: "plan"):
  Вход: описание задачи + структурированный контекст + `.claude/skills/architecture/SKILL.md`
  Выход: запиши план в `.claude/output/plans/{task-slug}.md`
  ОГРАНИЧЕНИЕ: агент НЕ СОЗДАЁТ и НЕ ИЗМЕНЯЕТ файлы проекта. Только анализ и план.
  Верни: summary (модули, ключевые решения, путь к плану)

Покажи план пользователю. Жди подтверждения через AskUserQuestion.

## Phase 2: DATABASE

Если задача затрагивает БД:

Task(.claude/agents/db-architect.md, subagent_type: "general-purpose"):
  Вход: прочитай `.claude/output/plans/{task-slug}.md` + `.claude/skills/database/SKILL.md` + `.claude/database/schema.sql`
  Выход: миграции, обновлённая схема
  Верни: summary (таблицы, миграции)

```bash
{MIGRATE_CMD}
```

Если БД не затронута — `[SKIP]`.

## Phase 3: CODE

Task(.claude/agents/{lang}-developer.md, subagent_type: "general-purpose"):
  Вход: прочитай `.claude/output/plans/{task-slug}.md` + `.claude/skills/code-style/SKILL.md`
  Выход: файлы кода
  Верни: summary (созданные файлы, зависимости)

```bash
{SYNTAX_CHECK_CMD}
```

## Phase 4: TESTS

Task(.claude/agents/{lang}-test-developer.md, subagent_type: "general-purpose"):
  Вход: реализованные файлы (из git diff или summary Phase 3) + `.claude/skills/testing/SKILL.md`
  Выход: файлы тестов
  Верни: summary (тесты, покрытие)

```bash
{TEST_CMD}
```

Если тесты fail — исправить (максимум 2 итерации).

## Phase 5: REVIEW

### Режим TEAM (если EXECUTION_MODE=team)

TeamCreate("review-{task}", "Code review: logic + security"):

Spawn("review-{task}", "reviewer-logic", .claude/agents/{lang}-reviewer-logic.md):
  Вход: все изменённые файлы (git diff)
  Выход: запиши в `.claude/output/reviews/{task-slug}-logic.md`
  Верни: summary (verdict, замечания по severity)

Spawn("review-{task}", "reviewer-security", .claude/agents/{lang}-reviewer-security.md):
  Вход: все изменённые файлы (git diff)
  Выход: запиши в `.claude/output/reviews/{task-slug}-security.md`
  Верни: summary (verdict, замечания по severity)

Жди завершения обоих тиммейтов. Собери результаты через TaskList.
Shutdown("review-{task}").

### Режим SEQUENTIAL (если EXECUTION_MODE=sequential)

Запусти одновременно:

Task(.claude/agents/{lang}-reviewer-logic.md, subagent_type: "general-purpose"):
  Вход: все изменённые файлы (git diff)
  Выход: запиши в `.claude/output/reviews/{task-slug}-logic.md`
  Верни: summary (verdict, замечания по severity)

Task(.claude/agents/{lang}-reviewer-security.md, subagent_type: "general-purpose"):
  Вход: все изменённые файлы (git diff)
  Выход: запиши в `.claude/output/reviews/{task-slug}-security.md`
  Верни: summary (verdict, замечания по severity)

### Обработка результатов (оба режима)
- **BLOCK** от любого reviewer → исправить и повторить Phase 5
- **PASS WITH WARNINGS** → исправить WARN, продолжить
- **PASS** → продолжить

## Phase 5.5: CAPTURE

1. Обнови `.claude/memory/facts.md` по секциям:
   - "## Stack" → ЗАМЕНИТЬ секцию целиком (только если стек изменился)
   - "## Key Paths" → МЕРЖИТЬ: добавь новые, удали несуществующие пути
   - "## Active Decisions" → ЗАМЕНИТЬ: только ссылки на файлы из decisions/ (НЕ archive)
   - "## Known Issues" → максимум 10 записей, удали разрешённые
   ПРАВИЛО: перед добавлением проверь — НЕ ДУБЛИРУЙ существующие записи
2. Если были архитектурные решения → `.claude/memory/decisions/{date}-{slug}.md`
3. Обнови `.claude/memory/patterns.md` если выявлены новые паттерны

## Phase 6: FINALIZATION

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
| ARCHITECTURE | План отклонён | Уточнить требования → повторить Phase 1 |
| DATABASE | Миграция fail | Проверить SQL → повторить Phase 2 |
| CODE | Syntax error | Исправить → повторить проверку |
| TESTS | Тесты fail (>2 итераций) | Остановить, показать ошибки пользователю |
| REVIEW | BLOCK | Исправить замечания → повторить Phase 5 |
