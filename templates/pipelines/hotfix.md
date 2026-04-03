---
name: "hotfix"
description: "Срочное исправление критичной проблемы"
version: "8.0.0"
phases: 4
capture: "partial"
user_prompts: false
parallel_per_lang: false
error_matrix: true
chains: ["fix-code", "review"]
triggers:
  - срочно
  - hotfix
  - prod
error_routing:
  fix_fail: stop_and_report
  review_block: retry_from:1
---

# Pipeline: Hotfix

## Вход
- Описание критичной проблемы
- Структурированный контекст из роутера: type, affected_modules
- `.claude/memory/facts.md`

## Phase 1: FIX

Выполни pipeline `.claude/pipelines/fix-code.md` полностью (все 5 фаз).

## Phase 2: REVIEW

Выполни pipeline `.claude/pipelines/review.md` для всех изменённых файлов.

Если review вернул BLOCK — вернись к Phase 1 для исправления.

## Phase 3: CAPTURE

{CAPTURE:partial}

## Phase 4: FINALIZATION

### Итог
```
[HOTFIX COMPLETE]
Проблема: {описание}
Root cause: {причина}
Исправлено: {N} файлов
Regression test: {pass/fail}
Review: {verdict}
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| FIX | Pipeline fix-code завершился с ошибкой | Остановить, показать ошибки пользователю |
| REVIEW | BLOCK | Вернуться к Phase 1 для исправления |
| CAPTURE | Запись в memory не удалась | Предупредить, продолжить |
