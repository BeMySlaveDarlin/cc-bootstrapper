---
name: bootstrap
description: Генерирует полную .claude/ структуру автоматизации для любого проекта — агенты, пайплайны, скиллы, memory, hooks, settings. Автоопределение режима fresh/patch/upgrade/resume.
user-invocable: true
argument-hint: "[meta-prompt-file]"
---

# Bootstrap — Router

## 1. Определи режим выполнения

ToolSearch(query: "select:TeamCreate", max_results: 1)

| Результат | Действие |
|-----------|----------|
| TeamCreate найден | Прочитай `${CLAUDE_SKILL_DIR}/references/flow-team.md` и выполни |
| TeamCreate не найден | Прочитай `${CLAUDE_SKILL_DIR}/references/flow-sequential.md` и выполни |

## 2. Контекст для flow-файлов

| Переменная | Значение |
|------------|----------|
| Skill dir | `${CLAUDE_SKILL_DIR}` |
| Plugin root | `${CLAUDE_PLUGIN_ROOT}` |
| Templates | `${CLAUDE_PLUGIN_ROOT}/templates/` |
| Known templates | `${CLAUDE_PLUGIN_ROOT}/known-templates.json` |
| Cache | `.claude/.cache/` |
| Backup | `.claude/.cache/backups/` |
| State | `.claude/.cache/state.json` |
