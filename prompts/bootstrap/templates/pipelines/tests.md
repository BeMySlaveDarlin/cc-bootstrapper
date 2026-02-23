# Pipeline: Tests

## Вход
- Файлы / модули для покрытия тестами
- `.claude/memory/facts.md`

## Phase 1: ANALYZE

1. Прочитай `.claude/memory/facts.md`
2. Определи целевые файлы и их public API
3. Проверь существующие тесты — не дублировать
4. Составь план тестирования: класс → методы → сценарии

### Вывод
```
[TEST PLAN]
Целевые файлы: {список}
Сценариев: {N}
Существующих тестов: {M}
```

## Phase 2: GENERATE

Task(.claude/agents/{lang}-test-developer.md, subagent_type: "general-purpose"):
  Вход: целевые файлы + план тестирования + `.claude/skills/testing/SKILL.md`
  Выход: файлы тестов, каждый с полным содержимым

## Phase 3: VERIFY

```bash
{TEST_CMD}
```

Если тесты fail — исправить (максимум 2 итерации).

```bash
{SYNTAX_CHECK_CMD}
```

## Phase 4: REVIEW

Task(.claude/agents/{lang}-reviewer-logic.md, subagent_type: "general-purpose"):
  Вход: файлы тестов
  Выход: качество тестов (покрытие сценариев, моки, assertions)

### Обработка результатов
- **BLOCK** → исправить и повторить Phase 4
- **PASS WITH WARNINGS** → исправить WARN, продолжить
- **PASS** → продолжить

### Итог
```
[TESTS COMPLETE]
Создано тестов: {N}
Результат: {pass}/{total}
Review: {verdict}
```
