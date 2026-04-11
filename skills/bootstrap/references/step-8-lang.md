# Шаг 8: Генерация per-language ({lang})

> Modes: fresh, upgrade

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.
> Используй ТОЛЬКО переменные из state-файла. НЕ обращайся к результатам других шагов напрямую.

**Вызывается ОДИН РАЗ НА КАЖДЫЙ ЯЗЫК.** Оркестратор передаёт `{lang}` как параметр.

## Вход
- `.claude/.cache/state.json` → `config`, `stack`, `registries.agents`, `registries.skills`, `registries.pipelines`
- `{lang}` — текущий язык (например `php`, `node`, `go`)
- `.claude/.cache/deep/{lang}-patterns.md` — паттерны кода (если есть, из step 7)

## Директории

```bash
mkdir -p .claude/{agents,skills,pipelines}
```

Безопасно при повторных вызовах — `mkdir -p` не падает если директория уже есть.

---

## 8-lang.1 Агенты

### Источники данных
1. **State:** `stack.langs`, `stack.frameworks`, `stack.test_frameworks`, `stack.test_cmds`, `stack.lint_cmds`
2. **Cache:** `.claude/.cache/deep/{lang}-patterns.md` → naming conventions, error handling → вставить в секцию `## Правила` агента
3. **Registry:** `registries.agents[]` — для проверки [USER] файлов

### Генерация

Для текущего `{lang}` прочитай шаблон → подставь переменные → запиши файл:

| Шаблон | Выходной файл |
|--------|---------------|
| `templates/agents/lang-architect.md` | `.claude/agents/{lang}-architect.md` |
| `templates/agents/lang-developer.md` | `.claude/agents/{lang}-developer.md` |
| `templates/agents/lang-test-developer.md` | `.claude/agents/{lang}-test-developer.md` |
| `templates/agents/lang-reviewer.md` | `.claude/agents/{lang}-reviewer.md` |

Подстановки в каждом шаблоне (включая YAML frontmatter):
- `{lang}` → `php`, `node`, etc.
- `{LANG}` → `PHP`, `Node.js`, etc.
- `{Lang}` → `Php`, `Node`, etc. (Title case, для заголовков)
- `{FRAMEWORK}` → из `stack.frameworks[lang]`
- `{TEST_FRAMEWORK}` → из `stack.test_frameworks[lang]`
- `{TEST_CMD}` → из `stack.test_cmds[lang]`
- `{LINT_CMD}` → из `stack.lint_cmds[lang]`
- `{SOURCE_DIR}` → определить по стеку (src/, app/, lib/)

**Поле `mode` в frontmatter агентов:**
- `lang-architect` → `mode: "plan"` (read-only, генерирует план)
- `lang-developer` → `mode: "implement"` (пишет код в проект)
- `lang-test-developer` → `mode: "implement"` (пишет тесты)
- `lang-reviewer` → `mode: "plan"` (read-only, генерирует ревью)

### Стек-специфичные адаптации

Прочитай `templates/includes/stack-adaptations.md` — используй ТОЛЬКО для текущего `{lang}`.

---

## 8-lang.2 Скиллы (per-lang фрагменты)

Генерируй per-lang фрагменты для code-style и testing. Финальная сборка — в step-8-common.

| Что | Выходной файл |
|-----|---------------|
| Code-style фрагмент для `{lang}` | `.claude/.cache/skills/code-style-{lang}.md` |
| Testing фрагмент для `{lang}` | `.claude/.cache/skills/testing-{lang}.md` |

Если есть `.claude/.cache/deep/{lang}-patterns.md` → обогатить code-style фрагмент паттернами из проекта (naming conventions, error handling, структура).

Шаблоны: `templates/skills/code-style.md` и `templates/skills/testing.md` — используй как reference для формата секции. Каждый фрагмент = секция `## {Lang}` с правилами для конкретного языка.

### Валидация (режим `patch`)
- Начинается с YAML frontmatter (`---` блок) с полями `name`, `description`
- `description` — ОДНА строка (критичное ограничение Claude Code)
- `user-invocable: false`
→ Нет frontmatter → добавить из шаблона → `[FIX] {path}: добавлен frontmatter`

---

## 8-lang.3 Пайплайны (per-lang)

Генерируй пайплайны, подставляя переменные в шаблоны.

| Шаблон | Выходной файл |
|--------|---------------|
| `templates/pipelines/new-code.md` | `.claude/pipelines/new-code.md` |
| `templates/pipelines/fix-code.md` | `.claude/pipelines/fix-code.md` |
| `templates/pipelines/review.md` | `.claude/pipelines/review.md` |
| `templates/pipelines/tests.md` | `.claude/pipelines/tests.md` |

### Формат пайплайнов v9

Пайплайны имеют YAML frontmatter v9 (phases[] = array, agents{} секция):
```yaml
---
name: "new-code"
description: "..."
triggers: [...]
modes: [sequential, team]
capture: "full"
user_prompts: true
error_routing:
  test_fail: retry_current
  review_block: stop
  agent_error: {max_retries: 2, action: stop}
  timeout: skip
phases:
  - id: 1
    name: ANALYSIS
    agent: "{lang}-architect"
    inputs: ["task description", "memory/facts.md"]
    output: ".claude/output/plans/{task-slug}-analysis.md"
    gate: review
    artifact: ".claude/output/plans/{task-slug}-analysis.md"
  - id: 2
    name: CODE
    agent: "{lang}-developer"
    inputs: ["plan from phase 1"]
    output: "project source"
    gate: silent
agents:
  "{lang}-architect":
    on_block: {action: stop, message: "Architect blocked"}
  "{lang}-developer":
    on_block: {action: retry_current, max_retries: 2}
---
```

**Убрано из v8 frontmatter:** `adaptive_teams`, `parallel_per_lang`, `error_matrix`, `chains`, `peer_validation`
**Добавлено в v9:** `modes`, `phases` (array), `agents` (секция с `on_block`), structured `error_routing`
**Фаза без агента:** `agent: lead` — special value, означает что фазу выполняет сам роутер

### Include-подстановки

Шаблоны содержат include-плейсхолдеры. Генератор ОБЯЗАН подставить содержимое из `templates/includes/`:
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

### Task() формат

Все Task()-вызовы в пайплайнах используют стандартный формат (см. `templates/includes/task-syntax.md`):
```
Task(<agent-path>, subagent_type: "general-purpose"):
  Вход: <входные данные>
  Выход: <выходной файл>
  Ограничение: read-only | project-write
  Верни: summary (...)
```

### Правило выбора языка в мульти-языковых проектах
- `{lang}` в пайплайне = язык, релевантный текущей задаче
- Если задача затрагивает конкретный модуль — определи язык по модулю
- Если неоднозначно — используй `stack.primary_lang`
- Для задач, затрагивающих несколько языков — фазы CODE, TESTS, REVIEW повторяются для каждого затронутого языка

**Мульти-язычные проекты:** При повторном вызове для второго `{lang}` — пайплайны уже существуют. Task()-синтаксис использует `{lang}-developer` и т.д., где `{lang}` подставляется динамически в runtime. Пайплайны language-agnostic: если файл существует — пропусти, если нет — создай.

### Pipeline body — dual sections

Пайплайны содержат две секции в body:
- `### [sequential]` — Task()-вызовы по task-syntax.md (тупой диспетчер)
- `### [team]` — structured shorthand (TeamCreate, Agent, SendMessage)

Генератору НЕ нужно добавлять team-секции вручную — они уже в шаблонах. `modes:` в frontmatter определяет доступные режимы выполнения.

Пайплайны с `modes: [sequential]` (review, api-docs, qa-docs) — содержат только `### [sequential]`.

### Миграция
- **МИГРАЦИЯ:** Если первая строка содержит `<!-- version: X.Y.Z -->` (старый формат) → `[REGEN]`
- **МИГРАЦИЯ v8→v9:** phases: int → phases: array, adaptive_teams → modes, добавить agents{}, убрать deprecated fields → `[REGEN]`

### Валидация (режим `patch`)

**Приоритет 1 — формат:**
- Содержит YAML frontmatter с полями `name`, `triggers`, `phases` (array), `modes`
- Если старый формат (HTML-комментарий или phases: int) → `[REGEN]`

**Приоритет 2 — структура:**
- Содержат `### [sequential]` с Task() pseudo-syntax
- НЕ содержат deprecated includes (`{CAPABILITY_DETECT}`, `{PIPELINE_STATE_*}`, `{PEER_REVIEW}`, `{PARALLEL_PER_LANG}`, `{TEAM_SHUTDOWN}`)
- НЕ содержат `## Матрица ошибок` (заменена structured error_routing)
→ Проблемы найдены → `[REGEN] {path}`

**Сохранение пользовательского контента:**
При `[REGEN]` — обнаружить non-template контент (кастомные фазы, комментарии пользователя).
Сохранить в конце файла как `## Кастомные дополнения` (перенести из оригинала).

---

## Правила записи файлов

### Режим `fresh`
Записывать все файлы без проверок.

### Режим `patch`
**Всё автоматически, без AskUserQuestion.** Для КАЖДОГО файла:

1. **Файл НЕ существует** → создать из шаблона → `[NEW] {path}`
2. **Файл существует** → провести ВАЛИДАЦИЮ содержимого:

#### Валидация агентов (.claude/agents/*.md)
- Начинается с YAML frontmatter (`---` блок) с полями `name`, `description`, `mode`
- `name` — kebab-case, совпадает с именем файла (без `.md`)
- `description` — одна строка, описание роли агента
- `mode` — `"plan"` или `"implement"`. Только `{lang}-developer` и `{lang}-test-developer` = `"implement"`, остальные = `"plan"`
- Содержит секцию `## Контекст` с ссылкой на `facts.md`
- Содержит ссылки на skills (`skills/code-style/SKILL.md`, etc.)
- НЕ содержит устаревших ссылок на `skills/routing/`, `skills/database/`
→ Нет frontmatter → добавить из шаблона → `[FIX] {path}: добавлен frontmatter`
→ Нет `mode` → добавить → `[FIX] {path}: добавлен mode`
→ Проблемы найдены → исправить IN-PLACE → `[FIX] {path}: {что исправлено}`
→ Файл ОК → `[OK] {path}`

#### Маркер [USER]
Файлы в `.claude/agents/`, `.claude/skills/`, `.claude/pipelines/`, которых НЕТ в соответствующих registries — пользовательские.
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

В финальном gen-report **обязательно** заполни `written[]` и `failed[]`.

---

## Выход
- `.claude/.cache/gen-report-8-{lang}.json`

Единый формат gen-report:
```json
{
  "step": "8-lang-{lang}",
  "generated_at": "ISO8601",
  "files": [
    {"path": "agents/{lang}-architect.md", "type": "agent", "status": "created", "source": "template"},
    {"path": "agents/{lang}-developer.md", "type": "agent", "status": "created", "source": "template"}
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

Перед checkpoint запиши лог в `.claude/.cache/step-8-lang-log.md`:

```markdown
# Step 8: Генерация per-language — Log

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

Запиши отчёт в `.claude/.cache/gen-report-8-{lang}.json` — это ЕДИНСТВЕННЫЙ выходной файл.
