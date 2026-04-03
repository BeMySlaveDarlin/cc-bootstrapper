---
name: "tests"
description: "Генерация тестов для существующего кода"
version: "8.0.0"
phases: 4
capture: "none"
user_prompts: true
parallel_per_lang: true
error_matrix: true
adaptive_teams: true
chains: []
triggers:
  - тесты
  - покрытие
  - unit test
  - coverage
error_routing:
  plan_rejected: retry_current
  test_fail: {max_retries: 2, action: stop_and_report}
  review_block: retry_from:4
  team_spawn_fail: fallback_sequential
---

# Pipeline: Tests

## Phase 0: CAPABILITY DETECT

{CAPABILITY_DETECT}

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

## Phase 2+3+4: GENERATE → VERIFY → REVIEW

### Режим TEAM

Для КАЖДОГО затронутого `{lang}`:

```python
TeamCreate(team_name="tests-{lang}")

Agent(name="{lang}-test-developer", team_name="tests-{lang}", prompt="""
Прочитай .claude/agents/{lang}-test-developer.md — выполняй workflow.
{TEAM_AGENT_RULES}
ЗАДАНИЕ: напиши тесты по плану `.claude/output/plans/{task-slug}.md` + целевые файлы {lang} + `.claude/skills/testing/SKILL.md`.
После записи: {TEST_CMD}. Если fail — исправь (макс. 2 итерации). {SYNTAX_CHECK_CMD}.
Отчёт запиши в `.claude/output/plans/{task-slug}-tests-{lang}.md`.
SendMessage(to="{lang}-reviewer"): done + путь к отчёту.
""")

Agent(name="{lang}-reviewer", team_name="tests-{lang}", prompt="""
Прочитай .claude/agents/{lang}-reviewer.md — выполняй workflow.
{TEAM_AGENT_RULES}
Жди сообщение от {lang}-test-developer (done).
ЗАДАНИЕ: ревью тестов (git diff).
Запиши ревью в `.claude/output/reviews/{task-slug}-tests-{lang}.md`.
BLOCK → SendMessage(to="{lang}-test-developer"): реестр правок. Жди исправление. Макс. 2 цикла.
PASS → SendMessage(to=lead): verdict + путь к ревью.
""")
```

### Flow
```
{lang}-test-developer → {lang}-reviewer
                              ↓ BLOCK
                        {lang}-test-developer (fix) → ... (макс. 2 цикла)
                              ↓ PASS
                             lead
```

Если затронуто несколько языков — команды per-lang ПАРАЛЛЕЛЬНО (отдельный TeamCreate на каждый lang).

{TEAM_SHUTDOWN}

### Режим SEQUENTIAL

{PARALLEL_PER_LANG}

Task(.claude/agents/{lang}-test-developer.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/plans/{task-slug}.md` + целевые файлы {lang} + `.claude/skills/testing/SKILL.md`
  Выход: файлы тестов
  Ограничение: project-write
  Верни: summary (файлы тестов, количество кейсов)

```bash
{TEST_CMD}
```

Если тесты fail — исправить (максимум 2 итерации).

```bash
{SYNTAX_CHECK_CMD}
```

Task(.claude/agents/{lang}-reviewer.md, subagent_type: "general-purpose"):
  Вход: файлы тестов (git diff)
  Выход: `.claude/output/reviews/{task-slug}-tests.md`
  Ограничение: read-only
  Верни: summary (verdict, качество тестов)

### Обработка результатов (оба режима)
- **BLOCK** → исправить и повторить review
- **PASS WITH WARNINGS** → исправить WARN, продолжить
- **PASS** → продолжить

### Итог
```
[TESTS COMPLETE]
Режим: {TEAM | SEQUENTIAL}
Создано тестов: {N}
Результат: {pass}/{total}
Review: {verdict}
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| CAPABILITY DETECT | Teams недоступны | Fallback → SEQUENTIAL |
| ANALYZE | План отклонён | Уточнить → повторить Phase 1 |
| GENERATE+VERIFY (TEAM) | Spawn fail | Fallback → SEQUENTIAL |
| VERIFY | Тесты fail (>2 итераций) | Остановить, показать ошибки пользователю |
| REVIEW | BLOCK (>2 циклов) | Остановить, показать замечания пользователю |
