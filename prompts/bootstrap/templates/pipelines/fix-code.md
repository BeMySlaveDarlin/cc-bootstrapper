# Pipeline: Fix Code

## Вход
- Описание бага / ошибки
- Структурированный контекст из роутера: type, affected_modules
- `.claude/memory/facts.md`

## Phase 1: DIAGNOSIS

1. Прочитай `.claude/memory/facts.md` → секции: Stack, Key Paths
2. Прочитай `.claude/memory/issues.md`
3. Локализуй проблему: файл, строка, причина
4. Определи root cause
5. Проверь `.claude/memory/decisions/` на релевантные ограничения
6. Запиши диагностику в `.claude/output/plans/{task-slug}.md`

### Вывод диагностики
```
[DIAGNOSIS]
Файл: {path}
Root cause: {описание}
Затронутые модули: {список}
```

Покажи диагностику пользователю.

AskUserQuestion:
  question: "План исправления:"
  options:
    - {label: "Подтвердить", description: "Приступить к исправлению"}
    - {label: "Уточнить", description: "Скорректировать план"}
    - {label: "Отменить", description: "Не исправлять"}

## Phase 2: FIX

Task(.claude/agents/{lang}-developer.md, subagent_type: "general-purpose"):
  Вход: прочитай `.claude/output/plans/{task-slug}.md` + `.claude/skills/code-style/SKILL.md`
  Выход: исправленные файлы
  Верни: summary (изменённые файлы, что исправлено)

```bash
{SYNTAX_CHECK_CMD}
```

## Phase 3: TESTS

Task(.claude/agents/{lang}-test-developer.md, subagent_type: "general-purpose"):
  Вход: исправленные файлы (из git diff или summary Phase 2) + описание бага
  Выход: regression test, подтверждающий исправление
  Верни: summary (тесты, результат)

```bash
{TEST_CMD}
```

Если тесты fail — исправить (максимум 2 итерации).

## Phase 4: REVIEW

Task(.claude/agents/{lang}-reviewer-logic.md, subagent_type: "general-purpose"):
  Вход: все изменённые файлы (git diff)
  Выход: запиши в `.claude/output/reviews/{task-slug}-logic.md`
  Верни: summary (verdict, замечания по severity)

### Обработка результатов
- **BLOCK** → исправить и повторить Phase 4
- **PASS WITH WARNINGS** → исправить WARN, продолжить
- **PASS** → продолжить

## Phase 5: CAPTURE

1. Обнови `.claude/memory/facts.md` по секциям:
   - "## Key Paths" → МЕРЖИТЬ: добавь новые, удали несуществующие пути
   - "## Known Issues" → максимум 10 записей, удали разрешённые
   ПРАВИЛО: перед добавлением проверь — НЕ ДУБЛИРУЙ существующие записи
2. Добавь в `.claude/memory/issues.md` описание бага и решения
3. Обнови `.claude/memory/patterns.md` если выявлен антипаттерн

### Итог
```
[FIX-CODE COMPLETE]
Root cause: {описание}
Исправлено файлов: {N}
Regression test: {pass/fail}
Review: {verdict}
```
