---
name: "full-feature"
description: "Полный цикл фичи: код + API docs + QA docs"
version: "8.0.1"
phases: 5
capture: "full"
user_prompts: false
parallel_per_lang: false
error_matrix: true
chains: ["new-code", "api-docs", "qa-docs"]
triggers:
  - полный цикл
  - feature
  - от начала до конца
error_routing:
  new_code_fail: stop_and_report
  api_docs_fail: skip_and_continue
  qa_docs_fail: skip_and_continue
---

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

{CAPTURE:full}

## Phase 5: FINALIZATION

### Итог
```
[FULL-FEATURE COMPLETE]
Фича: {name}
Код: {N} файлов, тесты {pass}/{total}, review {verdict}
API Docs: {status}
QA Docs: {status}
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| NEW CODE | Pipeline new-code завершился с ошибкой | Остановить, показать ошибки пользователю |
| API DOCS | Генерация провалилась | Пропустить, продолжить (non-critical) |
| QA DOCS | Генерация провалилась | Пропустить, продолжить (non-critical) |
| CAPTURE | Запись в memory не удалась | Предупредить, продолжить |
