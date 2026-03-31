Прочитай и выполни все шаги из `~/.claude/prompts/meta-prompt-bootstrap.md` для текущего проекта.

## Определи BOOTSTRAP_MODE

- `.claude/` не существует → `BOOTSTRAP_MODE = "fresh"` → `[MODE] fresh — полная генерация`
- `.claude/` существует → `BOOTSTRAP_MODE = "validate"` → `[MODE] validate — проверка и починка`

Передай BOOTSTRAP_MODE в контексте выполнения шагов.
Выполняй шаги строго по порядку (Шаг 1 → 2 → 3 → 4 → 5).
