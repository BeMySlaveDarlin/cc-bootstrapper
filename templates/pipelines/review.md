---
name: "review"
description: "Ревью кода"
version: "8.0.0"
phases: 3
capture: "review"
user_prompts: false
parallel_per_lang: true
error_matrix: true
adaptive_teams: true
chains: []
triggers:
  - ревью
  - проверь
  - review
  - посмотри код
error_routing:
  review_block: report_to_user
  team_spawn_fail: fallback_sequential
---

# Pipeline: Review

## Phase 0: CAPABILITY DETECT

{CAPABILITY_DETECT}

## Вход
- Файлы для ревью (diff или список путей)
- `.claude/memory/facts.md`

## Phase 1: REVIEW

### Режим TEAM

Определи какие языки затронуты. Все reviewers работают ПАРАЛЛЕЛЬНО:

```python
TeamCreate(team_name="review-{task-slug}")

# Для КАЖДОГО затронутого {lang}:
Agent(name="{lang}-reviewer", team_name="review-{task-slug}", prompt="""
Прочитай .claude/agents/{lang}-reviewer.md — выполняй workflow.
{TEAM_AGENT_RULES}
ЗАДАНИЕ (сразу): ревью файлов {lang} + `.claude/skills/code-style/SKILL.md` + `.claude/skills/architecture/SKILL.md`.
Запиши ревью в `.claude/output/reviews/{task-slug}-{lang}.md`.
SendMessage(to=lead): verdict (BLOCK | PASS WITH WARNINGS | PASS) + путь к ревью.
""")
```

### Flow
```
{lang-1}-reviewer (∥) {lang-2}-reviewer (∥) ... → lead: собирает verdicts
```

{TEAM_SHUTDOWN}

### Режим SEQUENTIAL

{PARALLEL_PER_LANG}

Task(.claude/agents/{lang}-reviewer.md, subagent_type: "general-purpose"):
  Вход: файлы {lang} для ревью + `.claude/skills/code-style/SKILL.md` + `.claude/skills/architecture/SKILL.md`
  Выход: `.claude/output/reviews/{task-slug}-{lang}.md`
  Ограничение: read-only
  Верни: summary (verdict, замечания по severity)

## Phase 2: REPORT

Объедини результаты всех per-lang ревью в общий отчёт.

### Сводная таблица
| # | Severity | Файл:строка | Проблема | Рекомендация |
|---|----------|-------------|----------|--------------|

### Verdict
- **BLOCK** — есть хотя бы один BLOCK → код требует исправлений
- **PASS WITH WARNINGS** — только WARN/INFO → рекомендовано исправить
- **PASS** — замечаний нет или только INFO

## Phase 3: CAPTURE

{CAPTURE:review}

### Итог
```
[REVIEW COMPLETE]
Режим: {TEAM | SEQUENTIAL}
Review: {verdict} ({N} замечаний)
```

## Матрица ошибок

| Фаза | Ошибка | Действие |
|------|--------|----------|
| CAPABILITY DETECT | Teams недоступны | Fallback → SEQUENTIAL |
| REVIEW (TEAM) | Spawn fail | Fallback → SEQUENTIAL |
| REVIEW | Агент не вернул verdict | Повторить для языка |
| REPORT | Конфликт verdicts между языками | Принять наихудший verdict |
