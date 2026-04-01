## Phase 0: CAPABILITY DETECT

Определи режим выполнения:

1. Проверь env-переменную `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`:
   - Если `= 1` → `EXECUTION_MODE=team`
   - Иначе → `EXECUTION_MODE=sequential`

2. Сообщи пользователю:
   - `[MODE: TEAM]` — параллельное выполнение через Agent Teams
   - `[MODE: SEQUENTIAL]` — последовательное выполнение через Task()

3. Fallback: если teams включены, но spawn завершился ошибкой → переключись на `EXECUTION_MODE=sequential` и сообщи `[MODE: FALLBACK → SEQUENTIAL]`

> Все последующие фазы с пометкой "Режим TEAM / Режим SEQUENTIAL" выполняй ТОЛЬКО соответствующую ветку.
