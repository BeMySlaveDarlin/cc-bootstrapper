# Pipeline: API Docs

## Вход
- Модуль / эндпоинты для документирования
- `.claude/state/facts.md`

## Phase 1: SCAN

1. Прочитай `.claude/state/facts.md`
2. Найди все эндпоинты целевого модуля (routes, controllers, handlers)
3. Определи request/response структуры (DTOs, schemas, models)
4. Собери middleware, guards, валидацию

### Вывод
```
[API SCAN]
Модуль: {name}
Эндпоинтов: {N}
```

## Phase 2: GENERATE

Task(.claude/agents/{lang}-developer.md, subagent_type: "general-purpose"):
  Вход: результаты сканирования + исходный код эндпоинтов
  Выход: контракт API в markdown-формате

### Формат контракта
Для каждого эндпоинта:
- Method + URL
- Headers
- Request body (JSON schema)
- Response 2xx (JSON schema)
- Response 4xx/5xx
- Пример запроса/ответа

## Phase 3: SAVE

Сохрани в `.claude/output/contracts/{module}.md`

### Итог
```
[API-DOCS COMPLETE]
Модуль: {name}
Эндпоинтов: {N}
Файл: .claude/output/contracts/{module}.md
```
