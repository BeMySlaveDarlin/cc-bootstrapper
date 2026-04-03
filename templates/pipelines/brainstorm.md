---
name: "brainstorm"
description: "Мозговой штурм: анализ идеи с нескольких ракурсов"
version: "8.0.1"
phases: 4
capture: "partial"
user_prompts: true
parallel_per_lang: false
error_matrix: true
chains: []
adaptive_teams: true
triggers:
  - обсудим
  - идея
  - brainstorm
  - брейншторм
  - побрейнштормим
  - как лучше
  - варианты
  - подход
  - архитектурно
  - продумать
  - предложи
error_routing:
  frame_rejected: retry_current
  no_decision: skip_capture
  team_spawn_fail: fallback_sequential
---

# Pipeline: Brainstorm

## Вход
- Описание идеи / проблемы / вопроса
- `.claude/memory/facts.md`

## Phase 0: CAPABILITY DETECT

{CAPABILITY_DETECT}

## Phase 1: FRAME

Task(.claude/agents/analyst.md, subagent_type: "general-purpose"):
  Вход: описание идеи, `.claude/memory/facts.md`, `.claude/memory/decisions/`, `.claude/database/schema.sql`
  Выход: `.claude/output/plans/{task-slug}-frame.md`
  Ограничение: read-only
  Верни: summary (проблема, ограничения, критерии выбора)

**После субагента** — прочитай `.claude/output/plans/{task-slug}-frame.md` и покажи пользователю.

AskUserQuestion:
  question: "Проблема сформулирована верно?"
  options:
    - {label: "Да", description: "Перейти к вариантам"}
    - {label: "Уточнить", description: "Скорректировать формулировку"}
    - {label: "Отменить", description: "Прервать"}

→ "Уточнить":
  Перезапусти analyst с поправками. Повтори AskUserQuestion.

## Phase 2: PERSPECTIVES

### Режим TEAM

```python
TeamCreate(team_name="brainstorm-{task-slug}")

Agent(name="{lang}-architect", team_name="brainstorm-{task-slug}", prompt="""
Прочитай .claude/agents/{lang}-architect.md — выполняй workflow.
{TEAM_AGENT_RULES}
РОЛЬ: ведущий мозгового штурма. Координируй обсуждение.
Контекст: `.claude/output/plans/{task-slug}-frame.md`.
Жди перспективы от analyst, storage-architect, devops (через SendMessage).
Собери 2-3 варианта решения с trade-offs.
Итог запиши в `.claude/output/plans/{task-slug}-options.md`.
SendMessage(to=lead): done + путь к итогу.
""")

Agent(name="analyst", team_name="brainstorm-{task-slug}", prompt="""
Прочитай .claude/agents/analyst.md — выполняй workflow.
{TEAM_AGENT_RULES}
ЗАДАНИЕ (сразу): проанализируй `.claude/output/plans/{task-slug}-frame.md` с бизнес-перспективы.
Scope, acceptance criteria, риски, ограничения.
SendMessage(to="{lang}-architect"): бизнес-перспектива + ключевые ограничения.
""")

Agent(name="storage-architect", team_name="brainstorm-{task-slug}", prompt="""
Прочитай .claude/agents/storage-architect.md — выполняй workflow.
{TEAM_AGENT_RULES}
ЗАДАНИЕ (сразу): проанализируй `.claude/output/plans/{task-slug}-frame.md` с позиции хранилищ данных.
Варианты хранения, миграции, производительность запросов.
SendMessage(to="{lang}-architect"): storage-перспектива + trade-offs.
""")

Agent(name="devops", team_name="brainstorm-{task-slug}", prompt="""
Прочитай .claude/agents/devops.md — выполняй workflow.
{TEAM_AGENT_RULES}
ЗАДАНИЕ (сразу): проанализируй `.claude/output/plans/{task-slug}-frame.md` с позиции инфраструктуры.
Деплой, CI/CD, мониторинг, масштабирование.
SendMessage(to="{lang}-architect"): infra-перспектива + trade-offs.
""")
```

### Flow
```
analyst (∥) storage-architect (∥) devops → {lang}-architect (собирает итог) → lead
```

{TEAM_SHUTDOWN}

### Режим SEQUENTIAL

Последовательный сбор перспектив от каждого агента.

Task(.claude/agents/analyst.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/plans/{task-slug}-frame.md`
  Выход: `.claude/output/plans/{task-slug}-perspective-analyst.md`
  Ограничение: read-only
  Верни: summary (бизнес-перспектива, риски, ограничения)

Task(.claude/agents/{lang}-architect.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/plans/{task-slug}-frame.md` + `.claude/output/plans/{task-slug}-perspective-analyst.md` + `.claude/skills/architecture/SKILL.md`
  Выход: `.claude/output/plans/{task-slug}-options.md`
  Ограничение: read-only
  Верни: summary (варианты с trade-offs)

Если задача затрагивает данные:

Task(.claude/agents/storage-architect.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/plans/{task-slug}-options.md` + `.claude/skills/storage/SKILL.md` + `.claude/database/schema.sql`
  Выход: дополни `.claude/output/plans/{task-slug}-options.md` секцией "Storage perspective"
  Ограничение: read-only
  Верни: summary (оценка вариантов с позиции хранилищ)

### После Phase 2 (оба режима)

**Прочитай** `.claude/output/plans/{task-slug}-options.md` и покажи пользователю.

Формат вариантов:
```
## Вариант A: {название}
- Плюсы: ...
- Минусы: ...
- Сложность: low / medium / high
- Риски: ...

## Вариант B: {название}
...
```

AskUserQuestion:
  question: "Какой вариант выбираем?"
  options: {динамически из вариантов + "Нужно больше вариантов" + "Комбинировать" + "Отложить решение"}

→ "Нужно больше вариантов":
  Перезапусти Phase 2 с инструкцией добавить альтернативы. Повтори AskUserQuestion.
→ "Комбинировать":
  AskUserQuestion:
    question: "Что взять из каждого варианта?"
  Запусти architect с инструкцией скомбинировать. Повтори AskUserQuestion.
→ "Отложить решение":
  Перейти к FINALIZATION без CAPTURE.

## Phase 3: CAPTURE

{CAPTURE:partial}

Дополнительно:
- Запиши решение в `.claude/memory/decisions/{date}-{slug}.md` с обоснованием выбора и отвергнутыми вариантами

### Итог
```
[BRAINSTORM COMPLETE]
Режим: {TEAM | SEQUENTIAL}
Проблема: {формулировка}
Участники: {список агентов}
Вариантов рассмотрено: {N}
Решение: {выбранный вариант или "отложено"}
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| CAPABILITY DETECT | Teams недоступны | Fallback → SEQUENTIAL |
| FRAME | Формулировка отклонена | Уточнить → повторить Phase 1 |
| PERSPECTIVES (TEAM) | Spawn fail | Fallback → SEQUENTIAL |
| PERSPECTIVES (TEAM) | Агент не отвечает | Исключить из команды, продолжить |
| PERSPECTIVES | Architect не вернул варианты | Повторить Phase 2 |
| PERSPECTIVES | Пользователь отложил решение | Пропустить CAPTURE, завершить |
