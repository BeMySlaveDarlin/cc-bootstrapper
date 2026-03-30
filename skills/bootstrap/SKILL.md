---
description: Генерирует полную .claude/ структуру автоматизации для любого проекта — агенты, пайплайны, скиллы, memory, hooks, settings. Автоопределение режима fresh/validate.
argument-hint: "[meta-prompt-file]"
---

Прочитай файл `$ARGUMENTS` и выполни ВСЕ шаги из него для текущего проекта.

Если аргумент не указан — читай промпт:
`${CLAUDE_SKILL_DIR}/../../prompts/meta-prompt-bootstrap.md`

Если файл не найден — сообщи пользователю.

---

## Определи BOOTSTRAP_MODE

- `.claude/` не существует → `BOOTSTRAP_MODE = "fresh"` → `[MODE] fresh — полная генерация`
- `.claude/` существует → `BOOTSTRAP_MODE = "validate"` → `[MODE] validate — проверка и починка`

Передай BOOTSTRAP_MODE в контексте выполнения шагов.
Выполняй шаги строго по порядку (Шаг 1 → 2 → 3 → 4 → 5).
Если возможно внутри шага что-то выполнять параллельно, запускай параллельных агентов.
