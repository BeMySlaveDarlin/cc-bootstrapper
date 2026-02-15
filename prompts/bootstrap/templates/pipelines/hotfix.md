# Pipeline: Hotfix

## Вход
- Описание критичной проблемы
- `.claude/state/facts.md`

## Phase 1: FIX

Выполни pipeline `.claude/pipelines/fix-code.md` полностью (все 5 фаз).

## Phase 2: REVIEW

Выполни pipeline `.claude/pipelines/review.md` для всех изменённых файлов.

Если review вернул BLOCK — вернись к Phase 1 для исправления.

## Phase 3: CAPTURE

1. Обнови `.claude/state/facts.md` — зафиксируй hotfix
2. Добавь в `.claude/state/memory/issues.md`
3. Обнови `.claude/state/memory/patterns.md` если выявлен антипаттерн

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
