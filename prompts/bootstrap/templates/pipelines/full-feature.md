<!-- version: 7.2.1 -->
# Pipeline: Full Feature

## Вход
- Полное описание фичи
- Структурированный контекст из роутера: scope, affected_modules
- `.claude/memory/facts.md`

## Phase 1: NEW CODE

Выполни pipeline `.claude/pipelines/new-code.md` полностью (все 7 фаз + Phase 6.5 CAPTURE).

## Phase 2: API DOCS

Выполни pipeline `.claude/pipelines/api-docs.md` для созданного модуля.

Если фича не содержит API-эндпоинтов — `[SKIP]`.

## Phase 3: QA DOCS

Выполни pipeline `.claude/pipelines/qa-docs.md` для созданного модуля.

Если фича не содержит API-эндпоинтов — `[SKIP]`.

## Phase 4: CAPTURE

1. Обнови `.claude/memory/facts.md` по секциям:
   - "## Stack" → ЗАМЕНИТЬ секцию целиком (только если стек изменился)
   - "## Key Paths" → МЕРЖИТЬ: добавь новые, удали несуществующие пути
   - "## Active Decisions" → ЗАМЕНИТЬ: только ссылки на файлы из decisions/ (НЕ archive)
   - "## Known Issues" → максимум 10 записей, удали разрешённые
   ПРАВИЛО: перед добавлением проверь — НЕ ДУБЛИРУЙ существующие записи
2. Запиши решение в `.claude/memory/decisions/{date}-{slug}.md`
3. Обнови `.claude/memory/patterns.md`

## Phase 5: FINALIZATION

### Итог
```
[FULL-FEATURE COMPLETE]
Фича: {name}
Код: {N} файлов, тесты {pass}/{total}, review {verdict}
API Docs: {status}
QA Docs: {status}
```
