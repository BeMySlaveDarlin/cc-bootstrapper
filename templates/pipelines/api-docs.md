---
name: "api-docs"
description: "Генерация API-контрактов"
version: "8.2.0"
phases: 3
capture: "none"
user_prompts: false
parallel_per_lang: false
error_matrix: true
chains: []
triggers:
  - документация
  - api docs
  - контракт
error_routing:
  scan_empty: stop_and_report
  generate_fail: retry_current
---

# Pipeline: API Docs

{PIPELINE_STATE_INIT}

## Вход
- Модуль / эндпоинты для документирования
- `.claude/memory/facts.md`

## Phase 1: SCAN

1. Прочитай `.claude/memory/facts.md`
2. Найди все эндпоинты целевого модуля (routes, controllers, handlers)
3. Определи request/response структуры (DTOs, schemas, models)
4. Собери middleware, guards, валидацию

### Вывод
```
[API SCAN]
Модуль: {name}
Эндпоинтов: {N}
```

{PIPELINE_STATE_UPDATE}

## Phase 2: GENERATE

Task(.claude/agents/{lang}-developer.md, subagent_type: "general-purpose"):
  Вход: результаты сканирования + исходный код эндпоинтов
  Выход: `.claude/output/contracts/{module}.md`
  Ограничение: read-only
  Верни: summary (эндпоинты, формат)

### Формат контракта
Для каждого эндпоинта:
- Method + URL
- Headers
- Request body (JSON schema)
- Response 2xx (JSON schema)
- Response 4xx/5xx
- Пример запроса/ответа

{PIPELINE_STATE_UPDATE}

## Phase 3: SAVE

Сохрани в `.claude/output/contracts/{module}.md`

### Итог
```
[API-DOCS COMPLETE]
Модуль: {name}
Эндпоинтов: {N}
Файл: .claude/output/contracts/{module}.md
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| SCAN | Эндпоинтов не найдено | Остановить, сообщить пользователю |
| GENERATE | Агент не вернул контракт | Повторить Phase 2 |
