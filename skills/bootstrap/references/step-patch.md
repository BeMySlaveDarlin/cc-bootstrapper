# Шаг: Patch (mini-upgrade v8→v9)

> Modes: patch

> Выполняется когда `state.mode = "patch"`.
> Заменяет шаги 8-lang, 8-common, 8-infra для patch-режима.

## Вход
- `.claude/.cache/state.json` (config, stack, registries)
- Существующая `.claude/` структура (v8.x или v9.x)

## Выход
- Обновлённые файлы в `.claude/` с v9 frontmatter
- `.claude/.cache/step-patch-log.md`
- Diff preview для пользователя

---

## P.0 Бэкап

```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p .claude/.cache/backups
tar -czf .claude/.cache/backups/backup-${TIMESTAMP}.tar.gz --exclude='.claude/.cache' .claude/ || echo "BACKUP FAILED"
```

Если бэкап уже существует (повторный запуск) — пропустить.

---

## P.1 Cleanup deprecated includes

Реестр паттернов удаления (10 паттернов). Применять ко ВСЕМ `.md` файлам в `.claude/pipelines/` и `.claude/agents/`:

| # | Паттерн | Действие |
|---|---------|----------|
| 1 | `{CAPABILITY_DETECT}` | удалить строку |
| 2 | `{PIPELINE_STATE_INIT}` | удалить строку |
| 3 | `{PIPELINE_STATE_UPDATE}` | удалить строку |
| 4 | `{PEER_REVIEW}` | удалить строку |
| 5 | `{TEAM_SHUTDOWN}` | удалить строку |
| 6 | `{PARALLEL_PER_LANG}` | удалить строку |
| 7 | `## Phase 0` / `### Phase 0` (CAPABILITY DETECT) | удалить секцию до следующего `##` / `###` |
| 8 | `### Peer Review` / `## Peer Review` | удалить секцию до следующего `###` / `##` |
| 9 | `## Матрица ошибок` | удалить секцию до следующего `##` |
| 10 | `{если SKIP_*}` / `{if SKIP_*}` | удалить строку |

Для каждого файла: прочитать → применить паттерны → записать если изменился → `[CLEAN] {path}: удалено {N} паттернов`.

---

## P.1.5 Deprecated agent migration

Прочитай `state.deprecated_files[]` (заполняется в step-init 2.3).

Для каждого deprecated файла:

| Deprecated | Target | Действие |
|------------|--------|----------|
| `frontend-developer.md` | `{lang}-developer.md` (lang=js/ts) | Если target существует → удалить deprecated. Если нет → переименовать |
| `frontend-reviewer.md` | `{lang}-reviewer.md` | Аналогично |
| `frontend-test-developer.md` | `{lang}-test-developer.md` | Аналогично |
| `frontend-contract.md` | — | Удалить (нет замены) |
| `{lang}-reviewer-logic.md` | `{lang}-reviewer.md` | Если target существует → удалить deprecated |
| `{lang}-reviewer-security.md` | `{lang}-reviewer.md` | Если target существует → удалить deprecated |
| `db-architect.md` | `storage-architect.md` | Если target существует → удалить deprecated. Если нет → переименовать |

Перед удалением — backup в `.claude/agents/.backup/`.

Если `state.deprecated_files` пуст — пропустить.

→ `[MIGRATE] {old} → {new}` или `[DELETE:DEPRECATED] {old}`

---

## P.2 Конвертация frontmatter v8→v9

Для каждого `.claude/pipelines/*.md`:

1. Прочитать YAML frontmatter
2. Проверить формат: если `phases` уже массив (Array) — пропустить этот файл → `[SKIP] {path}: already v9`
3. Конвертировать (только если frontmatter v8):

| v8 поле | v9 поле | Преобразование |
|---------|---------|----------------|
| `phases: {int}` | `phases: [{array}]` | Парсить body, создать массив объектов `{id, name, agent, inputs, output, gate}` |
| `adaptive_teams: true` | `modes: [sequential, team]` | — |
| `adaptive_teams: false` (или нет) | `modes: [sequential]` | — |
| `parallel_per_lang: true` | удалить | — |
| `error_matrix: true` | удалить | — |
| `chains: [...]` | удалить | — |
| `peer_validation: {...}` | удалить | — |
| `error_routing: {...}` | `error_routing: {structured}` | Конвертировать в enum формат: `test_fail\|review_block\|agent_error\|timeout` → `stop\|retry_current\|skip\|{max_retries, action}` |
| — | `agents: {}` | Создать секцию из агентов, упомянутых в phases. `on_block: {action: stop}` по умолчанию |
| `version: "8.x.x"` | удалить | Версионирование через manifest |

3. Записать обновлённый frontmatter

→ `[CONVERT] {path}: frontmatter v8→v9`

### Конвертация phases: int → phases: array

Парсить body пайплайна, найти все `## Phase {N}: {NAME}` или `## Фаза {N}: {NAME}`:
```yaml
phases:
  - id: 1
    name: ANALYSIS
    agent: "{определить из Task() в body}"
    inputs: ["{из Вход: в Task()}"]
    output: "{из Выход: в Task()}"
    gate: silent  # default, review если есть AskUserQuestion после фазы
```

Если body слишком сложный для автоматического парсинга — создать минимальный phases array с `agent: lead` и пометить `[CONVERT:PARTIAL] {path}: phases требуют ручной доработки`.

---

## P.3 Генерация v9 роутера

Перегенерировать `skills/pipeline/SKILL.md` с:
- ROUTER_PROTOCOLS (секвенциальный + team dispatch)
- Обновлённой таблицей triggers из frontmatter всех pipeline-файлов
- TaskList creation logic (из phases[] frontmatter)

→ `[REGEN] skills/pipeline/SKILL.md: v9 router`

---

## P.4 Удаление legacy файлов

Удалить если существуют:
- `.claude/pipelines/hotfix.md` — удалён в v9
- `.claude/state/` — legacy state directory

→ `[DELETE] {path}`

---

## P.5 Diff preview

Перед финальной записью — показать пользователю сводку изменений:

```
[PATCH PREVIEW]

Файлы изменены:
  [CLEAN]   pipelines/new-code.md: удалено 4 паттерна
  [CONVERT] pipelines/new-code.md: frontmatter v8→v9
  [CONVERT] pipelines/fix-code.md: frontmatter v8→v9
  [REGEN]   skills/pipeline/SKILL.md: v9 router
  [DELETE]  pipelines/hotfix.md

Файлы без изменений:
  [OK] agents/analyst.md
  [OK] skills/architecture/SKILL.md
```

Используй AskUserQuestion:
- question: "Применить изменения?"
- options:
  - {label: "Применить все", description: "Записать все изменения на диск"}
  - {label: "Отмена", description: "Откатить (бэкап сохранён)"}

Если "Отмена" → `[PATCH CANCELLED]`, бэкап остаётся на диске.

---

## Зона "не трогать"

НЕ модифицировать при patch:
- `settings.json`
- `.mcp.json`
- `CLAUDE.md`
- `memory/` (все файлы)
- `database/`
- `input/`
- `output/`
- `plugins/`
- Файлы с маркером `[USER]` (не в registries)

---

## Лог

Перед checkpoint запиши лог в `.claude/.cache/step-patch-log.md`:

```markdown
# Step Patch: Mini-upgrade — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

## Checkpoint

После завершения обнови state:
```json
{
  "steps": {
    "patch": {"status": "completed", "completed_at": "{ISO8601}"}
  },
  "generation": {
    "checkpoint": "patch_done",
    "completed_files": ["...список изменённых файлов..."]
  },
  "status": "completed",
  "updated_at": "{ISO8601}"
}
```
