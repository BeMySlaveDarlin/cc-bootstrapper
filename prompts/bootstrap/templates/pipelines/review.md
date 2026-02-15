# Pipeline: Review

## Вход
- Файлы для ревью (diff или список путей)
- `.claude/state/facts.md`

## Phase 1: PARALLEL REVIEW

Запусти одновременно:

Task(.claude/agents/{lang}-reviewer-logic.md, subagent_type: "general-purpose"):
  Вход: файлы для ревью + `.claude/skills/code-style/SKILL.md` + `.claude/skills/architecture/SKILL.md`
  Выход: таблица замечаний (severity, файл:строка, проблема, рекомендация)

Task(.claude/agents/{lang}-reviewer-security.md, subagent_type: "general-purpose"):
  Вход: файлы для ревью
  Выход: таблица замечаний (severity, файл:строка, проблема, рекомендация)

## Phase 2: REPORT

### Объединение результатов
1. Собери все замечания из обоих ревью
2. Отсортируй по severity: BLOCK → WARN → INFO
3. Удали дубликаты (один и тот же файл:строка)

### Сводная таблица
| # | Source | Severity | Файл:строка | Проблема | Рекомендация |
|---|--------|----------|-------------|----------|--------------|

### Verdict
- **BLOCK** — есть хотя бы один BLOCK → код требует исправлений
- **PASS WITH WARNINGS** — только WARN/INFO → рекомендовано исправить
- **PASS** — замечаний нет или только INFO

## Phase 3: CAPTURE

1. Добавь recurring issues в `.claude/state/memory/issues.md`
2. Обнови `.claude/state/memory/patterns.md` если выявлены антипаттерны

### Итог
```
[REVIEW COMPLETE]
Logic: {verdict} ({N} замечаний)
Security: {verdict} ({N} замечаний)
Overall: {verdict}
```
