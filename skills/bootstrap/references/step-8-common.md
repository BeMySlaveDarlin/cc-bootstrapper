# Шаг 8: Генерация общих артефактов

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.
> Используй ТОЛЬКО переменные из state-файла. НЕ обращайся к результатам других шагов напрямую.

## Вход
- `.bootstrap-cache/state.json` → `config`, `stack`, `registries.agents`, `registries.skills`, `registries.pipelines`
- Путь к шаблонам: `{TEMPLATES_DIR}`

## Директории

```bash
mkdir -p .claude/{agents,skills,pipelines,scripts,memory/{decisions/archive,sessions},output/{contracts,qa,plans,reviews},input/{tasks,plans},database}
touch .claude/memory/decisions/.gitkeep .claude/memory/decisions/archive/.gitkeep
```

Если в `registries.skills` есть custom-скиллы — создай дополнительные директории:
```bash
mkdir -p .claude/skills/{custom_skill_name}
```

Если `config.gitlab_mcp=true`:
```bash
mkdir -p .claude/skills/gitlab
```

---

## 8-common.1 Общие агенты

| Шаблон | Выходной файл | Условие |
|--------|---------------|---------|
| `templates/agents/analyst.md` | `.claude/agents/analyst.md` | всегда |
| `templates/agents/storage-architect.md` | `.claude/agents/storage-architect.md` | `stack.db != none` (реальная БД, не кеш/очередь) |
| `templates/agents/devops.md` | `.claude/agents/devops.md` | всегда |
| `templates/agents/qa-engineer.md` | `.claude/agents/qa-engineer.md` | всегда |

Для каждого агента: прочитай шаблон из `templates/agents/` → подставь переменные из `state.stack` → запиши в `.claude/agents/`.

### Кастомные агенты

Для каждого агента из `registries.agents` с `type: "custom"` сгенерируй файл `.claude/agents/{name}.md`:

```markdown
---
name: "{name}"
description: "{role — краткое описание роли агента, одна строка}"
---

# Агент: {Name}

## Роль
{role — из registry или определи по стеку}

## Контекст
- `.claude/memory/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/memory/decisions/` — архитектурные решения
- Код модуля: {SOURCE_DIR}
- `.claude/skills/code-style/SKILL.md` — стиль кода
- `.claude/skills/architecture/SKILL.md` — архитектура

## Задача
{3-5 шагов на основе роли и стека проекта}

## Правила
{3-5 правил на основе роли, стека и code-style}

## Формат вывода
{определи на основе роли}
```

Адаптируй содержимое под стек проекта (`stack.langs`, `stack.frameworks`, `stack.db`).

### Cleanup легаси (режим `validate`, автоматически)

Обнаружение устаревших агентов. Если найдены — AskUserQuestion:
- question: "Найдены устаревшие агенты: {список}. Сделать backup в .claude/agents/.backup/ перед удалением?"
- header: "Legacy cleanup"
- options:
  - {label: "Backup и удалить", description: "Сохранить копии в .backup/, удалить оригиналы"}
  - {label: "Удалить без backup", description: "Просто удалить устаревшие файлы"}
  - {label: "Оставить", description: "Не трогать устаревшие файлы"}

Таблица устаревших:

| Устаревший файл | Замена в v7 | Действие |
|-----------------|-------------|----------|
| `frontend-developer.md` | (убран, фронтенд через lang-developer) | backup → `.claude/agents/.backup/` |
| `frontend-test-developer.md` | (убран) | backup |
| `frontend-reviewer.md` | (убран) | backup |
| `frontend-contract.md` | (убран) | backup |
| `reviewer-logic.md` / `{lang}-reviewer-logic.md` | `{lang}-reviewer.md` (единый) | backup |
| `reviewer-security.md` / `{lang}-reviewer-security.md` | `{lang}-reviewer.md` (единый) | backup |
| `db-architect.md` | `storage-architect.md` | backup |

```bash
mkdir -p .claude/agents/.backup
mv .claude/agents/{deprecated-file} .claude/agents/.backup/
```

Обнаружение устаревших ссылок в агентах:
- `skills/database/` → заменить на `skills/storage/`
- `skills/routing/` → заменить на `skills/pipeline/`

---

## 8-common.2 Общие скиллы

| Шаблон | Выходной файл |
|--------|---------------|
| `templates/skills/architecture.md` | `.claude/skills/architecture/SKILL.md` |
| `templates/skills/storage.md` | `.claude/skills/storage/SKILL.md` |
| `templates/skills/memory.md` | `.claude/skills/memory/SKILL.md` |
| `templates/skills/pipeline.md` | `.claude/skills/pipeline/SKILL.md` |
| `templates/skills/p.md` | `.claude/skills/p/SKILL.md` |

Для каждого скилла: прочитай шаблон → подставь переменные → запиши в `.claude/skills/{name}/SKILL.md`.

### Валидация скиллов (режим `validate`)

#### Все скиллы (.claude/skills/*/SKILL.md)
- Начинается с YAML frontmatter (`---` блок) с полями `name`, `description`, `version`
- `description` — ОДНА строка (критичное ограничение Claude Code)
- `version` — совпадает с версией шаблона (см. «Версионирование»)
- Для pipeline и p: `user-invocable: true`
- Для остальных: `user-invocable: false`
→ Нет frontmatter → добавить из шаблона → `[FIX] {path}: добавлен frontmatter`
→ Нет `version` или version < шаблона → перегенерировать → `[REGEN] {path}: version outdated`

#### skills/pipeline/SKILL.md (CRITICAL)
- Файл расположен в `skills/pipeline/` (НЕ `skills/routing/`)
- Содержит frontmatter с `user-invocable: true`
- Содержит `name: pipeline` в frontmatter
- Содержит таблицу Intent → Триггеры
- Содержит Шаг 4 — Диспатч с ссылкой на `.claude/pipelines/`
→ `skills/routing/` → переместить в `skills/pipeline/` → `[FIX] routing/ → pipeline/`
→ Нет таблицы → перегенерировать → `[REGEN] pipeline/SKILL.md`

#### skills/p/SKILL.md
- Содержит frontmatter с `user-invocable: true`
- Ссылается на `/pipeline`
→ Нет → создать из шаблона → `[NEW] skills/p/SKILL.md`

### Кастомные скиллы

Для каждого скилла из `registries.skills` с `type: "custom"` сгенерируй файл `.claude/skills/{name}/SKILL.md`:

```markdown
---
name: "{name}"
description: "{description — краткое описание, одна строка}"
version: "7.3.0"
user-invocable: false
---

# Skill: {Name} — {description}

## Паттерны
{на основе назначения скилла и стека проекта}

## Антипаттерны
{типичные ошибки}

## Примеры
{конкретные примеры для стека}
```

### Cleanup легаси
- `skills/database/` → переименовать в `skills/storage/` → `[FIX] database/ → storage/`
- `skills/routing/` → переименовать в `skills/pipeline/` → `[FIX] routing/ → pipeline/`

---

## 8-common.3 Композитные пайплайны

| Шаблон | Выходной файл |
|--------|---------------|
| `templates/pipelines/full-feature.md` | `.claude/pipelines/full-feature.md` |
| `templates/pipelines/hotfix.md` | `.claude/pipelines/hotfix.md` |
| `templates/pipelines/api-docs.md` | `.claude/pipelines/api-docs.md` |
| `templates/pipelines/qa-docs.md` | `.claude/pipelines/qa-docs.md` |

Композитные пайплайны (full-feature, hotfix) ссылаются на другие пайплайны через «Выполни pipeline». Task() НЕ требуется.

Для api-docs, qa-docs — Task() pseudo-syntax используется.

### Версионирование
- HTML-комментарий в первой строке: `<!-- version: 7.3.0 -->`
- При `validate`: нет version или version < `7.2.0` → `[REGEN]`

### Валидация (режим `validate`)

**Приоритет 1 — версия (проверяй ПЕРВЫМ):**
- Первая строка содержит `<!-- version: X.Y.Z -->` — сравнить с `7.2.0`
- Нет version или version < `7.2.0` → `[REGEN] {path}: version outdated`

**Приоритет 2 — структура (только если версия совпала):**
- НЕ содержит устаревших текстовых инструкций типа "Прочитай .claude/agents/X.md"
- Параллельные агенты помечены "Запусти одновременно:"
→ Проблемы найдены → `[REGEN] {path}`

**Сохранение пользовательского контента:**
При `[REGEN]` — обнаружить non-template контент (кастомные фазы, комментарии пользователя).
Сохранить в конце файла как `## Кастомные дополнения` (перенести из оригинала).

### Кастомные пайплайны

Для каждого пайплайна из `registries.pipelines` с `type: "custom"` сгенерируй файл `.claude/pipelines/{name}.md`:

```markdown
<!-- version: 7.3.0 -->
# Pipeline: {Name}

## Фазы

{2-5 фаз на основе описания и указанных агентов.
Используй Task() pseudo-syntax для вызова агентов.}

## Матрица ошибок

| Проблема | Действие | Откат |
|----------|----------|-------|
```

---

## Правила записи файлов

### Режим `fresh`
Записывать все файлы без проверок.

### Режим `validate`
**Всё автоматически, без AskUserQuestion** (кроме legacy cleanup агентов). Для КАЖДОГО файла:

1. **Файл НЕ существует** → создать из шаблона → `[NEW] {path}`
2. **Файл существует** → провести ВАЛИДАЦИЮ → `[OK]`/`[FIX]`/`[REGEN]`

#### Маркер [USER]
Файлы, которых НЕТ в соответствующих registries — пользовательские.
→ `[USER] {path}` — НЕ ТРОГАТЬ, НЕ УДАЛЯТЬ, НЕ МОДИФИЦИРОВАТЬ

### Паттерн "Write first"
ОБЯЗАТЕЛЬНО Write файл ПЕРЕД возвратом результата. Не возвращай содержимое без записи на диск.

---

## Выход
- `.bootstrap-cache/gen-report-8-common.json`

Формат отчёта:
```json
{
  "step": "8-common",
  "agents": [
    {"name": "analyst", "path": ".claude/agents/analyst.md", "status": "[NEW]"},
    {"name": "devops", "path": ".claude/agents/devops.md", "status": "[NEW]"}
  ],
  "skills": [
    {"name": "architecture", "path": ".claude/skills/architecture/SKILL.md", "status": "[NEW]"},
    {"name": "pipeline", "path": ".claude/skills/pipeline/SKILL.md", "status": "[NEW]"}
  ],
  "pipelines": [
    {"name": "full-feature", "path": ".claude/pipelines/full-feature.md", "status": "[NEW]"},
    {"name": "hotfix", "path": ".claude/pipelines/hotfix.md", "status": "[NEW]"}
  ],
  "directories_created": [".claude/agents/", ".claude/skills/", ".claude/memory/", "..."],
  "errors": []
}
```

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-8-common-log.md`:

```markdown
# Step 8: Генерация общих артефактов — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

Записать лог ПЕРЕД checkpoint.

## Checkpoint

После завершения обнови state:
```json
{
  "generation": {
    "checkpoint": "8-common_done",
    "completed_files": ["...список созданных файлов..."]
  }
}
```

Запиши отчёт в `.bootstrap-cache/gen-report-8-common.json`.
