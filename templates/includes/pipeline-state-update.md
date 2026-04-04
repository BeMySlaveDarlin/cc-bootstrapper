Обнови `.claude/output/state/{task-slug}.json`:
  - `phases.{N}.status` = `"completed"`
  - `phases.{N}.completed_at` = `"{ISO 8601}"`
Если ВСЕ фазы `"completed"` — удали файл state (pipeline завершён, state больше не нужен).
