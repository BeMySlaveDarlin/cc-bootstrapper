## Phase 0.5: STATE CHECK

Прочитай `.claude/output/state/{task-slug}.json`.

### Файл существует (resume)

1. Покажи прогресс:
   ```
   [RESUME] Pipeline: {pipeline}, task: {task-slug}
   Завершено фаз: {completed}/{total}
   Последняя завершённая: Phase {N} ({name})
   ```
2. Найди первую фазу со `status != "completed"`
3. Перейди к ней — пропусти завершённые фазы

### Файл не существует (новый запуск)

Создай `.claude/output/state/{task-slug}.json`:
```json
{
  "pipeline": "{TYPE}",
  "task": "{task-slug}",
  "started_at": "{ISO 8601}",
  "phases": {
    "1": {"name": "{Phase 1 name}", "status": "pending"},
    "2": {"name": "{Phase 2 name}", "status": "pending"}
  }
}
```

Фазы заполняй из frontmatter текущего pipeline (phases count + имена из заголовков).
Phase 0 (CAPABILITY DETECT) не включай — она stateless.
