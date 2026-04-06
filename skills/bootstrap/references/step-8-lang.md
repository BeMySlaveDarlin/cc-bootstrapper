# Шаг 8: Генерация per-language ({lang})

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.
> Используй ТОЛЬКО переменные из state-файла. НЕ обращайся к результатам других шагов напрямую.

**Вызывается ОДИН РАЗ НА КАЖДЫЙ ЯЗЫК.** Оркестратор передаёт `{lang}` как параметр.

## Вход
- `.bootstrap-cache/state.json` → `config`, `stack`, `registries.agents`, `registries.skills`, `registries.pipelines`
- `{lang}` — текущий язык (например `php`, `node`, `go`)
- `.bootstrap-cache/deep/{lang}-patterns.md` — паттерны кода (если есть, из step 7)

## Директории

```bash
mkdir -p .claude/{agents,skills,pipelines}
```

Безопасно при повторных вызовах — `mkdir -p` не падает если директория уже есть.

---

## 8-lang.1 Агенты

### Источники данных
1. **State:** `stack.langs`, `stack.frameworks`, `stack.test_frameworks`, `stack.test_cmds`, `stack.lint_cmds`
2. **Cache:** `.bootstrap-cache/deep/{lang}-patterns.md` → naming conventions, error handling → вставить в секцию `## Правила` агента
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

## 8-lang.2 Скиллы (per-lang)

Генерируй code-style и testing, адаптированные под `{lang}`.

| Шаблон | Выходной файл |
|--------|---------------|
| `templates/skills/code-style.md` | `.claude/skills/code-style/SKILL.md` |
| `templates/skills/testing.md` | `.claude/skills/testing/SKILL.md` |

Если есть `.bootstrap-cache/deep/{lang}-patterns.md` → обогатить code-style паттернами из проекта (naming conventions, error handling, структура).

**Мульти-язычные проекты:** При повторном вызове для второго `{lang}` — ДОПОЛНЯЙ существующие скиллы секциями для нового языка, НЕ перезаписывай целиком.

### Версионирование
- Поле `version` в YAML frontmatter (например `version: "8.1.0"`)
- При `validate`: нет версии или version < `7.2.0` → `[REGEN]`

### Валидация (режим `validate`)
- Начинается с YAML frontmatter (`---` блок) с полями `name`, `description`, `version`
- `description` — ОДНА строка (критичное ограничение Claude Code)
- `version` — совпадает с версией шаблона
- `user-invocable: false`
→ Нет frontmatter → добавить из шаблона → `[FIX] {path}: добавлен frontmatter`
→ Нет `version` или version < шаблона → перегенерировать → `[REGEN] {path}: version outdated`

---

## 8-lang.3 Пайплайны (per-lang)

Генерируй пайплайны, подставляя переменные в шаблоны.

| Шаблон | Выходной файл |
|--------|---------------|
| `templates/pipelines/new-code.md` | `.claude/pipelines/new-code.md` |
| `templates/pipelines/fix-code.md` | `.claude/pipelines/fix-code.md` |
| `templates/pipelines/review.md` | `.claude/pipelines/review.md` |
| `templates/pipelines/tests.md` | `.claude/pipelines/tests.md` |

### Формат пайплайнов v8

Пайплайны имеют YAML frontmatter (вместо HTML-комментария `<!-- version -->`):
```yaml
---
name: "new-code"
description: "..."
version: "8.1.0"
phases: 7
capture: "full"
user_prompts: true
parallel_per_lang: true
error_matrix: true
chains: []
triggers: [...]
error_routing: {...}
---
```

### Include-подстановки

Шаблоны содержат include-плейсхолдеры. Генератор ОБЯЗАН подставить содержимое из `templates/includes/`:
- `{CAPTURE:full}` → содержимое `templates/includes/capture-full.md`
- `{CAPTURE:partial}` → содержимое `templates/includes/capture-partial.md`
- `{CAPTURE:review}` → содержимое `templates/includes/capture-review.md`
- `{PARALLEL_PER_LANG}` → содержимое `templates/includes/parallel-per-lang.md`

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

**Мульти-язычные проекты:** При повторном вызове для второго `{lang}` — пайплайны уже существуют. Task()-синтаксис использует `{lang}-developer` и т.д., где `{lang}` подставляется динамически в runtime. НЕ перезаписывай пайплайны — они language-agnostic.

### Adaptive Teams

Пайплайны **new-code**, **fix-code**, **tests**, **review** содержат dual execution modes прямо в шаблонах:
- `{CAPABILITY_DETECT}` — Phase 0, подставляется из `templates/includes/capability-detect.md`
- "Режим TEAM" — агенты запускаются как команда, общаются через файлы в `.claude/output/`
- "Режим SEQUENTIAL" — последовательные Task()-вызовы (fallback)
- `adaptive_teams: true` в YAML frontmatter

Генератору **НЕ НУЖНО** добавлять adaptive-секции — они уже в шаблонах. Нужно только подставить `{CAPABILITY_DETECT}` как обычный include-плейсхолдер.

**Валидация adaptive (режим `validate`):**
- Пайплайны с `adaptive_teams: true` в frontmatter должны содержать Phase 0: CAPABILITY DETECT
- Каждая adaptive-фаза содержит ОБА режима (TEAM + SEQUENTIAL)
- Секции "Режим TEAM" используют Teammate-синтаксис (НЕ устаревший TeamCreate/Spawn/Shutdown)
- Task() только в секциях "Режим SEQUENTIAL"
→ Нет Phase 0 при `adaptive_teams: true` → `[FIX] {path}: добавлен CAPABILITY DETECT`

### Версионирование
- Версия в YAML frontmatter поле `version` (например `version: "8.1.0"`)
- При `validate`: нет version или version < `8.0.0` → `[REGEN]`
- **МИГРАЦИЯ:** Если первая строка содержит `<!-- version: X.Y.Z -->` (старый формат) → `[REGEN]` в новый формат с frontmatter

### Валидация (режим `validate`)

**Приоритет 1 — формат:**
- Содержит YAML frontmatter с полями `name`, `version`, `triggers`
- Если старый формат (HTML-комментарий) → `[REGEN]`

**Приоритет 2 — версия:**
- `version` в frontmatter < `8.0.0` → `[REGEN] {path}: version outdated`

**Приоритет 3 — структура (только если версия совпала):**
- Содержат Task() pseudo-syntax с 4 полями (Вход, Выход, Ограничение, Верни)
- Содержат `## Матрица ошибок`
- НЕ содержат устаревших текстовых инструкций
→ Task()-пайплайн без Task() → `[REGEN] {path}`

**Сохранение пользовательского контента:**
При `[REGEN]` — обнаружить non-template контент (кастомные фазы, комментарии пользователя).
Сохранить в конце файла как `## Кастомные дополнения` (перенести из оригинала).

---

## Правила записи файлов

### Режим `fresh`
Записывать все файлы без проверок.

### Режим `validate`
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
→ `[USER] {path}` — НЕ ТРОГАТЬ, НЕ УДАЛЯТЬ, НЕ МОДИФИЦИРОВАТЬ

### Паттерн "Write first"
ОБЯЗАТЕЛЬНО Write файл ПЕРЕД возвратом результата. Не возвращай содержимое без записи на диск.

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
- `.bootstrap-cache/gen-report-8-{lang}.json`

Формат отчёта:
```json
{
  "step": "8-lang",
  "lang": "{lang}",
  "agents": [
    {"name": "{lang}-architect", "path": ".claude/agents/{lang}-architect.md", "status": "[NEW]"},
    {"name": "{lang}-developer", "path": ".claude/agents/{lang}-developer.md", "status": "[NEW]"}
  ],
  "skills": [
    {"name": "code-style", "path": ".claude/skills/code-style/SKILL.md", "status": "[NEW]"}
  ],
  "pipelines": [
    {"name": "new-code", "path": ".claude/pipelines/new-code.md", "status": "[NEW]"}
  ],
  "written": [".claude/agents/{lang}-architect.md", ".claude/agents/{lang}-developer.md", "..."],
  "failed": [],
  "errors": []
}
```

**Важно:** `failed` содержит объекты `{"path", "error", "status"}`. `errors` — строки для backward compat. Если `failed` не пуст — оркестратор обработает partial failure.

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-8-lang-log.md`:

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

После завершения обнови state:
```json
{
  "generation": {
    "checkpoint": "8-lang_{lang}_done",
    "completed_files": ["...список созданных файлов..."]
  }
}
```

Запиши отчёт в `.bootstrap-cache/gen-report-8-{lang}.json`.
