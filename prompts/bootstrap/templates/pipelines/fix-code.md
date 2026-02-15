# Pipeline: Fix Code

## Вход
- Описание бага / ошибки
- `.claude/state/facts.md`

## Phase 1: DIAGNOSIS

1. Прочитай `.claude/state/facts.md` и `.claude/state/memory/issues.md`
2. Локализуй проблему: файл, строка, причина
3. Определи root cause
4. Проверь `.claude/state/decisions/` на релевантные ограничения

### Вывод диагностики
```
[DIAGNOSIS]
Файл: {path}
Root cause: {описание}
Затронутые модули: {список}
```

## Phase 2: FIX

Task(.claude/agents/{lang}-developer.md, subagent_type: "general-purpose"):
  Вход: диагностика + `.claude/skills/code-style/SKILL.md`
  Выход: исправленные файлы с полным содержимым

```bash
{SYNTAX_CHECK_CMD}
```

## Phase 3: TESTS

Task(.claude/agents/{lang}-test-developer.md, subagent_type: "general-purpose"):
  Вход: исправленные файлы + описание бага
  Выход: regression test, подтверждающий исправление

```bash
{TEST_CMD}
```

Если тесты fail — исправить (максимум 2 итерации).

## Phase 4: REVIEW

Task(.claude/agents/{lang}-reviewer-logic.md, subagent_type: "general-purpose"):
  Вход: diff изменённых файлов
  Выход: таблица замечаний

### Обработка результатов
- **BLOCK** → исправить и повторить Phase 4
- **PASS WITH WARNINGS** → исправить WARN, продолжить
- **PASS** → продолжить

## Phase 5: CAPTURE

1. Обнови `.claude/state/facts.md` — зафиксируй исправление
2. Добавь в `.claude/state/memory/issues.md` описание бага и решения
3. Обнови `.claude/state/memory/patterns.md` если выявлен антипаттерн

### Итог
```
[FIX-CODE COMPLETE]
Root cause: {описание}
Исправлено файлов: {N}
Regression test: {pass/fail}
Review: {verdict}
```
