## Phase 0: CAPABILITY DETECT

Определи режим выполнения:

1. Проверь свой список доступных инструментов (tools):
   - Если `TeamCreate` присутствует в списке → `EXECUTION_MODE=team`
   - Если `TeamCreate` отсутствует → `EXECUTION_MODE=sequential`

2. Сообщи пользователю:
   - `[MODE: TEAM]` — параллельное выполнение через Teams API
   - `[MODE: SEQUENTIAL]` — последовательное выполнение через Task()

3. Fallback: если TeamCreate доступен, но вызов завершился ошибкой → переключись на `EXECUTION_MODE=sequential` и сообщи `[MODE: FALLBACK → SEQUENTIAL]`

> Все последующие фазы с пометкой "Режим TEAM / Режим SEQUENTIAL" выполняй ТОЛЬКО соответствующую ветку.
