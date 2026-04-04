---
name: "fix-code"
description: "Диагностика и исправление бага"
version: "8.1.0"
phases: 5
capture: "partial"
user_prompts: true
parallel_per_lang: true
error_matrix: true
adaptive_teams: true
chains: []
triggers:
  - баг
  - ошибка
  - fix
  - не работает
  - сломалось
  - regression
error_routing:
  diagnosis_rejected: retry_current
  syntax_error: retry_current
  test_fail: {max_retries: 2, action: stop_and_report}
  review_block: retry_from:4
  team_spawn_fail: fallback_sequential
---

# Pipeline: Fix Code

## Phase 0: CAPABILITY DETECT

{CAPABILITY_DETECT}

{PIPELINE_STATE_INIT}

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
6. **ОБЯЗАТЕЛЬНО** запиши диагностику в `.claude/output/plans/{task-slug}.md` через Write tool ПЕРЕД возвратом

**После субагента** — прочитай `.claude/output/plans/{task-slug}.md` и покажи пользователю.

AskUserQuestion:
  question: "Диагностика готова. Подтвердить план исправления?"
  options:
    - {label: "Подтвердить", description: "Приступить к исправлению"}
    - {label: "Уточнить", description: "Скорректировать диагностику"}
    - {label: "Отменить", description: "Не исправлять"}

→ "Уточнить":
  AskUserQuestion:
    question: "Что скорректировать?"
    header: "Поправки"
    options:
      - {label: "Root cause", description: "Другая причина проблемы"}
      - {label: "Scope", description: "Другие затронутые модули"}
      - {label: "Подход", description: "Другой способ исправления"}
  Перезапусти диагностику с поправками. Повтори AskUserQuestion.

{PIPELINE_STATE_UPDATE}

## Phase 2+3+4: FIX → TESTS → REVIEW

### Режим TEAM

Для КАЖДОГО затронутого `{lang}`:

```python
TeamCreate(team_name="fix-code-{lang}")

Agent(name="{lang}-developer", team_name="fix-code-{lang}", prompt="""
Прочитай .claude/agents/{lang}-developer.md — выполняй workflow.
{TEAM_AGENT_RULES}
ЗАДАНИЕ: исправь код по диагностике `.claude/output/plans/{task-slug}.md` + `.claude/skills/code-style/SKILL.md`.
После записи: {SYNTAX_CHECK_CMD}.
Отчёт запиши в `.claude/output/plans/{task-slug}-fix-{lang}.md`.
SendMessage(to="{lang}-test-developer"): done + путь к отчёту.
""")

Agent(name="{lang}-test-developer", team_name="fix-code-{lang}", prompt="""
Прочитай .claude/agents/{lang}-test-developer.md — выполняй workflow.
{TEAM_AGENT_RULES}
Жди сообщение от {lang}-developer (done).
ЗАДАНИЕ: напиши regression test по описанию бага + исправленным файлам.
После записи: {TEST_CMD}. Если fail — исправь (макс. 2 итерации).
Отчёт запиши в `.claude/output/plans/{task-slug}-tests-{lang}.md`.
SendMessage(to="{lang}-reviewer"): done + путь к отчёту.
""")

Agent(name="{lang}-reviewer", team_name="fix-code-{lang}", prompt="""
Прочитай .claude/agents/{lang}-reviewer.md — выполняй workflow.
{TEAM_AGENT_RULES}
Жди сообщение от {lang}-test-developer (done).
ЗАДАНИЕ: ревью изменённых файлов (git diff).
Запиши ревью в `.claude/output/reviews/{task-slug}-{lang}.md`.
BLOCK → SendMessage(to="{lang}-developer"): реестр правок. Жди исправление. Макс. 2 цикла.
PASS → SendMessage(to=lead): verdict + путь к ревью.
""")
```

### Flow
```
{lang}-developer → {lang}-test-developer → {lang}-reviewer
                                                 ↓ BLOCK
                                           {lang}-developer (fix) → ... (макс. 2 цикла)
                                                 ↓ PASS
                                                lead
```

Если затронуто несколько языков — команды per-lang ПАРАЛЛЕЛЬНО (отдельный TeamCreate на каждый lang).

{TEAM_SHUTDOWN}

### Режим SEQUENTIAL

Task(.claude/agents/{lang}-developer.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/plans/{task-slug}.md` + `.claude/skills/code-style/SKILL.md`
  Выход: исправленные файлы
  Ограничение: project-write
  Верни: summary (изменённые файлы, что исправлено)

```bash
{SYNTAX_CHECK_CMD}
```

Task(.claude/agents/{lang}-test-developer.md, subagent_type: "general-purpose"):
  Вход: исправленные файлы (из git diff или summary Phase 2) + описание бага
  Выход: regression test, подтверждающий исправление
  Ограничение: project-write
  Верни: summary (тесты, результат)

```bash
{TEST_CMD}
```

Если тесты fail — исправить (максимум 2 итерации).

{PARALLEL_PER_LANG}

Task(.claude/agents/{lang}-reviewer.md, subagent_type: "general-purpose"):
  Вход: изменённые файлы {lang} (git diff)
  Выход: `.claude/output/reviews/{task-slug}-{lang}.md`
  Ограничение: read-only
  Верни: summary (verdict, замечания по severity)

### Обработка результатов (оба режима)
- **BLOCK** → исправить и повторить review
- **PASS WITH WARNINGS** → исправить WARN, продолжить
- **PASS** → продолжить

{PIPELINE_STATE_UPDATE}

## Phase 5: CAPTURE

{CAPTURE:partial}

### Итог
```
[FIX-CODE COMPLETE]
Режим: {TEAM | SEQUENTIAL}
Root cause: {описание}
Исправлено файлов: {N}
Regression test: {pass/fail}
Review: {verdict}
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| CAPABILITY DETECT | Teams недоступны | Fallback → SEQUENTIAL |
| DIAGNOSIS | Диагностика отклонена | Уточнить → повторить Phase 1 |
| FIX+TESTS (TEAM) | Spawn fail | Fallback → SEQUENTIAL |
| FIX | Syntax error | Исправить → повторить проверку |
| TESTS | Тесты fail (>2 итераций) | Остановить, показать ошибки пользователю |
| REVIEW | BLOCK (>2 циклов) | Остановить, показать замечания пользователю |
