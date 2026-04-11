# Шаг 8: Генерация общих артефактов

> Modes: fresh, upgrade

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.
> Используй ТОЛЬКО переменные из state-файла. НЕ обращайся к результатам других шагов напрямую.

## Вход
- `.claude/.cache/state.json` → `config`, `stack`, `registries.agents`, `registries.skills`, `registries.pipelines`
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

**Поле `mode` в frontmatter агентов:**
- `analyst` → `mode: "plan"`
- `storage-architect` → `mode: "plan"`
- `devops` → `mode: "plan"`
- `qa-engineer` → `mode: "plan"`

### Кастомные агенты

Для каждого агента из `registries.agents` с `type: "custom"` сгенерируй файл `.claude/agents/{name}.md`:

```markdown
---
name: "{name}"
description: "{role — краткое описание роли агента, одна строка}"
mode: "plan"
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

### Cleanup легаси (режим `patch`/`upgrade`, автоматически)

Обнаружение устаревших агентов. Если найдены — **автоматический backup + удаление** (без вопроса):

```bash
mkdir -p .claude/agents/.backup
mv .claude/agents/{deprecated-file} .claude/agents/.backup/
```

Вывести: `[LEGACY] {file} → backup в .claude/agents/.backup/`

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

### Сборка мульти-язычных скиллов (code-style, testing)

step-8-lang записывает per-lang фрагменты в `.claude/.cache/skills/`:
- `code-style-{lang}.md` — для каждого языка
- `testing-{lang}.md` — для каждого языка

Собери финальные файлы:

1. Прочитай шаблон `templates/skills/code-style.md` → frontmatter + общая часть
2. Для каждого `code-style-{lang}.md` в `.claude/.cache/skills/` → append содержимое как секцию
3. Запиши `.claude/skills/code-style/SKILL.md`
4. Аналогично для testing

Если фрагментов нет (single-lang или step-8-lang не создал) → генерируй из шаблона напрямую, подставляя единственный lang.

### Валидация скиллов (режим `patch`)

#### Все скиллы (.claude/skills/*/SKILL.md)
- Начинается с YAML frontmatter (`---` блок) с полями `name`, `description`
- `description` — ОДНА строка (критичное ограничение Claude Code)
- Для pipeline и p: `user-invocable: true`
- Для остальных: `user-invocable: false`
→ Нет frontmatter → добавить из шаблона → `[FIX] {path}: добавлен frontmatter`

#### skills/pipeline/SKILL.md
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

## 8-common.3 Общие пайплайны (language-agnostic)

Сгенерировать все 4 файла из таблицы ниже.

| Шаблон | Выходной файл | Тип |
|--------|---------------|-----|
| `templates/pipelines/full-feature.md` | `.claude/pipelines/full-feature.md` | standalone (8 inline фаз) |
| `templates/pipelines/api-docs.md` | `.claude/pipelines/api-docs.md` | standalone, modes: [sequential] |
| `templates/pipelines/qa-docs.md` | `.claude/pipelines/qa-docs.md` | standalone, modes: [sequential] |
| `templates/pipelines/brainstorm.md` | `.claude/pipelines/brainstorm.md` | standalone, modes: [sequential, team] |

**Удалён:** `hotfix.md` — в v9 не генерируется (8 pipelines суммарно: 4 per-lang + 4 common).

full-feature = standalone pipeline с 8 inline фазами (НЕ orchestrator, НЕ chains). Все фазы описаны прямо в файле.

Для api-docs, qa-docs, brainstorm — Task() pseudo-syntax в `### [sequential]` секции.

### Формат пайплайнов v9

Все пайплайны имеют YAML frontmatter v9:
```yaml
---
name: "pipeline-name"
description: "..."
triggers: [...]
modes: [sequential, team]  # или [sequential] only
capture: "full|partial|review|none"
user_prompts: true
error_routing:
  test_fail: retry_current
  review_block: stop
  agent_error: {max_retries: 2, action: stop}
  timeout: skip
phases:
  - id: 1
    name: PHASE_NAME
    agent: agent-name       # или agent: lead
    inputs: [...]
    output: path
    gate: review|confirm|silent
agents:
  agent-name:
    on_block: {action: stop}
---
```

**Убрано из v8:** `parallel_per_lang`, `error_matrix`, `chains`, `adaptive_teams`, `peer_validation`
**Добавлено в v9:** `modes`, `phases` (array), `agents` (секция с `on_block`), structured `error_routing`

### Include-подстановки

Генератор ОБЯЗАН подставить include-плейсхолдеры из `templates/includes/`:
- `{CAPTURE:full}` → содержимое `templates/includes/capture-full.md`
- `{CAPTURE:partial}` → содержимое `templates/includes/capture-partial.md`
- `{CAPTURE:review}` → содержимое `templates/includes/capture-review.md`
- `{TEAM_AGENT_RULES}` → содержимое `templates/includes/team-agent-rules.md`
- `{AGENT_BASE_CONTEXT}` → содержимое `templates/includes/agent-base-context.md`
- `{MCP_SKILLS_CONTEXT}` → содержимое `templates/includes/mcp-skills-context.md`

**УДАЛЁННЫЕ includes (НЕ подставлять):**
- ~~`{CAPABILITY_DETECT}`~~ — удалён
- ~~`{PIPELINE_STATE_INIT}`~~ — удалён
- ~~`{PIPELINE_STATE_UPDATE}`~~ — удалён
- ~~`{PEER_REVIEW}`~~ — удалён
- ~~`{PARALLEL_PER_LANG}`~~ — удалён
- ~~`{TEAM_SHUTDOWN}`~~ — удалён

### Миграция
- **МИГРАЦИЯ:** Если первая строка содержит `<!-- version: X.Y.Z -->` (старый формат) → `[REGEN]`

### Валидация (режим `patch`)

**Приоритет 1 — формат:**
- Содержит YAML frontmatter с полями `name`, `phases` (array), `modes`
- Если старый формат (HTML-комментарий или phases: int) → `[REGEN]`

**Приоритет 2 — структура:**
- НЕ содержит deprecated includes
- НЕ содержит `## Матрица ошибок` (заменена structured error_routing)
→ Проблемы найдены → `[REGEN] {path}`

**Сохранение пользовательского контента:**
При `[REGEN]` — обнаружить non-template контент (кастомные фазы, комментарии пользователя).
Сохранить в конце файла как `## Кастомные дополнения` (перенести из оригинала).

### Кастомные пайплайны

Для каждого пайплайна из `registries.pipelines` с `type: "custom"` сгенерируй файл `.claude/pipelines/{name}.md`:

```markdown
---
name: "{name}"
description: "{description}"
triggers: [{keywords}]
modes: [sequential]
capture: "none"
user_prompts: false
error_routing:
  agent_error: stop
  timeout: skip
phases:
  - id: 1
    name: PHASE_NAME
    agent: agent-name
    inputs: [...]
    output: path
    gate: silent
agents:
  agent-name:
    on_block: {action: stop}
---

# Pipeline: {Name}

### [sequential]

{2-5 фаз на основе описания и указанных агентов.
Используй Task() pseudo-syntax с 4 обязательными полями (Вход, Выход, Ограничение, Верни).}
```

---

## Правила записи файлов

### Режим `fresh`
Записывать все файлы без проверок.

### Режим `patch`
**Всё автоматически, без AskUserQuestion** (кроме legacy cleanup агентов). Для КАЖДОГО файла:

1. **Файл НЕ существует** → создать из шаблона → `[NEW] {path}`
2. **Файл существует** → провести ВАЛИДАЦИЮ → `[OK]`/`[FIX]`/`[REGEN]`

#### Маркер [USER]
Файлы, которых НЕТ в соответствующих registries — пользовательские.
→ `[USER] {path}` — user content, skip

### Паттерн "Write first"
Записывай файл перед возвратом результата.

### Error tracking

Для КАЖДОЙ операции Write:
1. Выполни Write
2. Если Write вернул ошибку или был отклонён пользователем:
   - Добавь в массив failed: `{"path": "{file_path}", "error": "{error_text}", "status": "[WRITE_FAIL]"}`
   - **ПРОДОЛЖАЙ** со следующим файлом — НЕ останавливайся
3. Если Write успешен — добавь путь в массив written[]

---

## Выход
- `.claude/.cache/gen-report-8-common.json`

Единый формат gen-report:
```json
{
  "step": "8-common",
  "generated_at": "ISO8601",
  "files": [
    {"path": "agents/analyst.md", "type": "agent", "status": "created", "source": "template"},
    {"path": "skills/architecture/SKILL.md", "type": "skill", "status": "created", "source": "template"},
    {"path": "pipelines/full-feature.md", "type": "pipeline", "status": "created", "source": "template"}
  ],
  "errors": []
}
```

| Поле files[] | Описание |
|--------------|----------|
| path | Относительно .claude/ |
| type | agent, skill, pipeline, hook, script, memory, config |
| status | created, skipped, error, user_exists |
| source | template, custom |

`errors[]` — объекты `{"path", "error"}`. Если не пуст — оркестратор обработает partial failure.

## Лог

Перед checkpoint запиши лог в `.claude/.cache/step-8-common-log.md`:

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

> **НЕ пиши в state.json** — при параллельном выполнении это вызывает race condition.
> Оркестратор обновит state после сбора всех gen-reports.

Запиши отчёт в `.claude/.cache/gen-report-8-common.json`.
