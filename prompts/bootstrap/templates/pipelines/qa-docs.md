# Pipeline: QA Docs

## Вход
- Модуль / фича для QA-документации
- `.claude/state/facts.md`

## Phase 1: INPUT

1. Прочитай `.claude/state/facts.md`
2. Найди контракт API: `.claude/output/contracts/{module}.md`
3. Изучи бизнес-логику модуля (сервисы, валидация, edge cases)
4. Если контракта нет — сначала запусти pipeline API Docs

## Phase 2: CHECKLIST

Task(.claude/agents/qa-engineer.md, subagent_type: "general-purpose"):
  Вход: контракт API + исходный код модуля
  Выход: чеклист тестирования

### Формат чеклиста
Для каждого эндпоинта:
- Позитивные сценарии
- Негативные сценарии (невалидные данные, 401, 403, 404)
- Граничные случаи
- Интеграционные проверки (зависимости между модулями)

## Phase 3: POSTMAN

Task(.claude/agents/qa-engineer.md, subagent_type: "general-purpose"):
  Вход: контракт API + чеклист
  Выход: Postman-коллекция (JSON)

### Содержание коллекции
- Папки по эндпоинтам
- Pre-request scripts (auth, переменные)
- Tests (assertions на status, body, headers)
- Environment variables

## Phase 4: SAVE

1. Сохрани чеклист в `.claude/output/qa/{module}-checklist.md`
2. Сохрани коллекцию в `.claude/output/qa/{module}-postman.json`

### Итог
```
[QA-DOCS COMPLETE]
Модуль: {name}
Сценариев: {N}
Файлы:
  - .claude/output/qa/{module}-checklist.md
  - .claude/output/qa/{module}-postman.json
```
