# Pipeline: Full Feature

## Вход
- Полное описание фичи
- `.claude/state/facts.md`

## Phase 1: NEW CODE

Выполни pipeline `.claude/pipelines/new-code.md` полностью (все 6 фаз + Phase 5.5 CAPTURE).

## Phase 2: API DOCS

Выполни pipeline `.claude/pipelines/api-docs.md` для созданного модуля.

Если фича не содержит API-эндпоинтов — `[SKIP]`.

## Phase 3: QA DOCS

Выполни pipeline `.claude/pipelines/qa-docs.md` для созданного модуля.

Если фича не содержит API-эндпоинтов — `[SKIP]`.

## Phase 4: CAPTURE

1. Обнови `.claude/state/facts.md` — добавь фичу в Active Features
2. Запиши решение в `.claude/state/decisions/{date}-{slug}.md`
3. Обнови `.claude/state/memory/patterns.md`

## Phase 5: FINALIZATION

### Итог
```
[FULL-FEATURE COMPLETE]
Фича: {name}
Код: {N} файлов, тесты {pass}/{total}, review {verdict}
API Docs: {status}
QA Docs: {status}
```
