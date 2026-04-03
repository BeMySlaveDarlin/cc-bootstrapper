---
name: "qa-docs"
description: "QA-чеклисты, Postman-коллекции, E2E stubs"
version: "8.0.0"
phases: 4
capture: "none"
user_prompts: false
parallel_per_lang: false
error_matrix: true
chains: []
triggers:
  - чеклист
  - QA
  - postman
error_routing:
  no_contract: prerequisite:api-docs
  generate_fail: retry_current
---

# Pipeline: QA Docs

## Вход
- Модуль / фича для QA-документации
- `.claude/memory/facts.md`

## Phase 1: INPUT

1. Прочитай `.claude/memory/facts.md`
2. Найди контракт API: `.claude/output/contracts/{module}.md`
3. Изучи бизнес-логику модуля (сервисы, валидация, edge cases)
4. Если контракта нет — сначала запусти pipeline API Docs

## Phase 2: CHECKLIST

Task(.claude/agents/qa-engineer.md, subagent_type: "general-purpose"):
  Вход: контракт API + исходный код модуля
  Выход: `.claude/output/qa/{module}-checklist.md`
  Ограничение: read-only
  Верни: summary (сценарии, покрытие)

### Формат чеклиста
Для каждого эндпоинта:
- Позитивные сценарии
- Негативные сценарии (невалидные данные, 401, 403, 404)
- Граничные случаи
- Интеграционные проверки (зависимости между модулями)

## Phase 3: AUTOMATION

Task(.claude/agents/qa-engineer.md, subagent_type: "general-purpose"):
  Вход: контракт API + чеклист
  Выход: `.claude/output/qa/{module}-postman.json` + `.claude/output/qa/{module}-e2e.spec.ts` (опционально)
  Ограничение: read-only
  Верни: summary (коллекция, E2E stubs)

### Postman-коллекция
- Папки по эндпоинтам
- Pre-request scripts (auth, переменные)
- Tests (assertions на status, body, headers)
- Environment variables

### Playwright E2E stubs (опционально, если есть UI)
- Базовые сценарии: навигация, формы, CRUD-операции
- Page Object заготовки
- Файл: `{module}-e2e.spec.ts`

## Phase 4: SAVE

1. Сохрани чеклист в `.claude/output/qa/{module}-checklist.md`
2. Сохрани коллекцию в `.claude/output/qa/{module}-postman.json`
3. Сохрани E2E stubs в `.claude/output/qa/{module}-e2e.spec.ts` (если сгенерированы)

### Итог
```
[QA-DOCS COMPLETE]
Модуль: {name}
Сценариев: {N}
Файлы:
  - .claude/output/qa/{module}-checklist.md
  - .claude/output/qa/{module}-postman.json
  - .claude/output/qa/{module}-e2e.spec.ts (если есть UI)
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| INPUT | Контракт API не найден | Запустить pipeline api-docs сначала |
| CHECKLIST | Агент не вернул чеклист | Повторить Phase 2 |
| AUTOMATION | Генерация Postman провалилась | Повторить Phase 3 |
