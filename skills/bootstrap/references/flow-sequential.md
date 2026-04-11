# Bootstrap — Sequential Flow

Ты — диспетчер. Вызываешь Agent tool, передаёшь результаты, отслеживаешь прогресс через TaskList.

## Defaults

| Параметр | Значение |
|----------|----------|
| Agent mode | `auto` |
| References dir | `${CLAUDE_SKILL_DIR}/references/` |
| Templates | `${CLAUDE_PLUGIN_ROOT}/templates/` |
| Plugin root | `${CLAUDE_PLUGIN_ROOT}` |
| Cache | `.claude/.cache/` |
| State | `.claude/.cache/state.json` |

### Subagent preamble

Каждый prompt субагента начинается с:

```
ПЕРЕД началом работы: ToolSearch(query: "select:AskUserQuestion", max_results: 1).
Используй AskUserQuestion для вопросов пользователю (параметр questions — массив объектов с полями question, header, options, multiSelect).
```

### Error protocol

| Событие | Действие |
|---------|----------|
| Субагент вернул error | AskUserQuestion: "Ошибка на шаге {name}. Повторить / Пропустить / Остановить" |
| Субагент вернул done | TaskUpdate → completed, следующий шаг |

---

## Resume Detection

Проверь `.claude/.cache/state.json`:

| Состояние | Действие |
|-----------|----------|
| Файл существует, валидный JSON | AskUserQuestion: "Найден незавершённый bootstrap. Продолжить / Заново / Отмена" |
| → Продолжить | Прочитай state.json → первый pending шаг → начни с него |
| → Заново | Удали `.claude/.cache/` → Init |
| → Отмена | Стоп |
| Файл существует, невалидный JSON | Удали `.claude/.cache/` → Init (corrupted state) |
| Файл не существует | Init |

---

## Steps

### Init — Scan + Mode Detection

| Owner | Reference |
|-------|-----------|
| subagent | step-init.md |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-init.md и выполни. Templates: ${CLAUDE_PLUGIN_ROOT}/templates/. Plugin root: ${CLAUDE_PLUGIN_ROOT}.`

После завершения прочитай `.claude/.cache/state.json` → `state.mode`:

| Mode | Действие |
|------|----------|
| empty | Стоп |
| fresh | Создай **Fresh TaskList** → Configure |
| resume | Создай **Fresh TaskList** → первый pending шаг |
| patch | Создай **Patch TaskList** → Patch |
| upgrade | Создай **Upgrade TaskList** → Upgrade (Backup) |

### TaskLists

**Fresh:**

| Subject | Reference |
|---------|-----------|
| Configure (3A) | step-3-configure.md |
| Configure (3B) | orchestrator asks |
| Configure (3C) | step-3-apply.md |
| Settings | step-4-settings.md |
| Plugins (scan) | step-5-plugins.md |
| Plugins (ask) | orchestrator asks |
| Plugins (apply) | step-5-apply.md |
| Preview | step-6-preview.md |
| Analyze | step-7-analyze.md |
| Generate | step-8-lang/common/infra |
| Finalize | step-finalize.md |

**Patch:**

| Subject | Reference |
|---------|-----------|
| Patch | step-patch.md |
| Finalize | step-finalize.md |

**Upgrade:**

| Subject | Reference |
|---------|-----------|
| Backup + Classify | step-upgrade.md (U.0-U.3) |
| Configure (3A-3C) | step-3-configure.md → orchestrator → step-3-apply.md |
| Preview | step-6-preview.md |
| Analyze | step-7-analyze.md |
| Generate | step-8-lang/common/infra |
| Restore | step-upgrade.md (U.5-U.6) |
| Finalize | step-finalize.md |

> Settings и Plugins не запускаются при patch и upgrade.

---

### Configure (3 фазы)

**3A — Сбор вопросов:**

| Owner | Reference |
|-------|-----------|
| subagent | step-3-configure.md |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-3-configure.md и выполни. Plugin root: ${CLAUDE_PLUGIN_ROOT}.`

Субагент возвращает JSON с вопросами или `skip` (если config заполнен).

**3B — Orchestrator задаёт вопросы:**

| Owner | Действие |
|-------|----------|
| orchestrator | Извлечь JSON из 3A → AskUserQuestion → собрать ответы |

1. Извлечь JSON из результата 3A (между ```json fences)
2. Подставить `estimates.standard` / `estimates.deep` в описания
3. `questions_main.questions` → AskUserQuestion
4. Если выбраны custom agents/skills/pipelines → follow-up из `questions_followup`
5. Собрать ответы в JSON

Analysis_depth normalization (Other-input):

| Input | Normalized |
|-------|------------|
| standart, стандарт, стандартный, средний | standard |
| глубокий, полный, full, максимальный | deep |
| лёгкий, легкий, быстрый, fast, lite | light |
| (unrecognized) | standard |

**3C — Применение:**

| Owner | Reference |
|-------|-----------|
| subagent | step-3-apply.md |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-3-apply.md и выполни. Ответы пользователя: {JSON из 3B}. Plugin root: ${CLAUDE_PLUGIN_ROOT}.`

Verify: `state.json` → `config` непустой. Пустой → повторить 3A-3C.

---

### Settings

| Owner | Reference | Modes |
|-------|-----------|-------|
| subagent | step-4-settings.md | fresh only |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-4-settings.md и выполни.`

---

### Plugins (3 фазы)

**5A — Scan:**

| Owner | Reference | Modes |
|-------|-----------|-------|
| subagent | step-5-plugins.md | fresh only |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-5-plugins.md и выполни. Plugin root: ${CLAUDE_PLUGIN_ROOT}.`

Субагент возвращает JSON с результатами сканирования.

**5B — Orchestrator задаёт вопросы:**

| Owner | Действие |
|-------|----------|
| orchestrator | Извлечь JSON из 5A → AskUserQuestion → собрать ответы |

1. Извлечь JSON из результата 5A
2. `auto` — уже установленные плагины, передать в apply
3. Если `questions` не пустой → AskUserQuestion пачками по 4
4. Gate-вопросы (`_type: "mcp_gate"`) → conditional follow-ups
5. Собрать ответы в JSON

**5C — Apply:**

| Owner | Reference |
|-------|-----------|
| subagent | step-5-apply.md |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-5-apply.md и выполни. Данные: {JSON из 5B}. Plugin root: ${CLAUDE_PLUGIN_ROOT}.`

---

### Preview

| Owner | Reference |
|-------|-----------|
| subagent | step-6-preview.md |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-6-preview.md и выполни. Templates: ${CLAUDE_PLUGIN_ROOT}/templates/.`

| Результат | Действие |
|-----------|----------|
| done | Следующий шаг |
| pause | Стоп |
| change | Вернуться к Configure (3A) |

---

### Analyze

| Owner | Reference |
|-------|-----------|
| subagent | step-7-analyze.md |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-7-analyze.md и выполни.`

---

### Generate

Перед генерацией — создать директории (orchestrator, Bash):
```bash
mkdir -p .claude/{agents,skills,pipelines,scripts/hooks,memory/{decisions/archive,sessions},output/{contracts,qa,plans,reviews,state},input/{tasks,plans},database}
```

| Sub-step | Owner | Reference | Sequential after |
|----------|-------|-----------|-----------------|
| per lang | subagent | step-8-lang.md | mkdir (по одному для каждого lang из `state.config.langs`) |
| common | subagent | step-8-common.md | все lang завершены |
| infra | subagent | step-8-infra.md | common |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/{reference} и выполни для языка {lang}. Templates: ${CLAUDE_PLUGIN_ROOT}/templates/. Plugin root: ${CLAUDE_PLUGIN_ROOT}.`

**Partial failure:** прочитать gen-report-8-*.json → если failed → AskUserQuestion: "N файлов не записано. Повторить / Пропустить / Остановить".

---

### Patch

| Owner | Reference | Modes |
|-------|-----------|-------|
| subagent | step-patch.md | patch only |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-patch.md и выполни. Templates: ${CLAUDE_PLUGIN_ROOT}/templates/. Plugin root: ${CLAUDE_PLUGIN_ROOT}.`

---

### Upgrade (Backup + Classify)

| Owner | Reference | Modes |
|-------|-----------|-------|
| subagent | step-upgrade.md (U.0-U.3) | upgrade only |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-upgrade.md и выполни шаги U.0-U.3. Templates: ${CLAUDE_PLUGIN_ROOT}/templates/. Plugin root: ${CLAUDE_PLUGIN_ROOT}. Known templates: ${CLAUDE_PLUGIN_ROOT}/known-templates.json.`

После U.3 → Configure (3A-3C) → Preview → Analyze → Generate (без Settings и Plugins).

### Upgrade (Restore)

| Owner | Reference |
|-------|-----------|
| subagent | step-upgrade.md (U.5-U.6) |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-upgrade.md и выполни шаги U.5-U.6. Templates: ${CLAUDE_PLUGIN_ROOT}/templates/.`

---

### Finalize

| Owner | Reference |
|-------|-----------|
| subagent | step-finalize.md |

Prompt: `Прочитай ${CLAUDE_SKILL_DIR}/references/step-finalize.md и выполни. Plugin root: ${CLAUDE_PLUGIN_ROOT}.`
