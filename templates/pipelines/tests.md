<!-- version: 7.3.1 -->
# Pipeline: Tests

## Вход
- Файлы / модули для покрытия тестами
- Структурированный контекст из роутера: type, affected_modules
- `.claude/memory/facts.md`

## Phase 1: ANALYZE

1. Прочитай `.claude/memory/facts.md` → секции: Stack, Key Paths
2. Определи целевые файлы и их public API
3. Проверь существующие тесты — не дублировать
4. Составь план тестирования: класс → методы → сценарии
5. Запиши план в `.claude/output/plans/{task-slug}.md`

### Вывод
```
[TEST PLAN]
Целевые файлы: {список}
Сценариев: {N}
Существующих тестов: {M}
```

AskUserQuestion:
  question: "План тестирования:"
  options:
    - {label: "Подтвердить", description: "Начать генерацию тестов"}
    - {label: "Уточнить", description: "Скорректировать план"}
    - {label: "Отменить", description: "Не генерировать"}

## Phase 2: GENERATE (per-lang ПАРАЛЛЕЛЬНО)

Если затронуто несколько языков — запусти per-lang ПАРАЛЛЕЛЬНО.

Для КАЖДОГО затронутого `{lang}`:

Task(.claude/agents/{lang}-test-developer.md, subagent_type: "general-purpose"):
  Вход: прочитай `.claude/output/plans/{task-slug}.md` + целевые файлы {lang} + `.claude/skills/testing/SKILL.md`
  Выход: файлы тестов
  Верни: summary (файлы тестов, количество кейсов)

## Phase 3: VERIFY

```bash
{TEST_CMD}
```

Если тесты fail — исправить (максимум 2 итерации).

```bash
{SYNTAX_CHECK_CMD}
```

## Phase 4: REVIEW

Task(.claude/agents/{lang}-reviewer.md, subagent_type: "general-purpose"):
  Вход: файлы тестов (git diff)
  Выход: запиши в `.claude/output/reviews/{task-slug}-tests.md`
  Верни: summary (verdict, качество тестов)

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
