<!-- version: 7.3.0 -->
# Pipeline: Review

## Вход
- Файлы для ревью (diff или список путей)
- `.claude/memory/facts.md`

## Phase 1: REVIEW (per-lang ПАРАЛЛЕЛЬНО)

Определи какие языки затронуты в файлах для ревью.
Если мультиязычный diff — запусти reviewer для каждого `{lang}` ПАРАЛЛЕЛЬНО.

Для КАЖДОГО затронутого `{lang}`:

Task(.claude/agents/{lang}-reviewer.md, subagent_type: "general-purpose"):
  Вход: файлы {lang} для ревью + `.claude/skills/code-style/SKILL.md` + `.claude/skills/architecture/SKILL.md`
  Выход: запиши в `.claude/output/reviews/{task-slug}-{lang}.md`
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

1. Обнови `.claude/memory/facts.md` по секциям:
   - "## Known Issues" → максимум 10 записей, удали разрешённые
   ПРАВИЛО: перед добавлением проверь — НЕ ДУБЛИРУЙ существующие записи
2. Добавь recurring issues в `.claude/memory/issues.md`
3. Обнови `.claude/memory/patterns.md` если выявлены антипаттерны

### Итог
```
[REVIEW COMPLETE]
Review: {verdict} ({N} замечаний)
```
