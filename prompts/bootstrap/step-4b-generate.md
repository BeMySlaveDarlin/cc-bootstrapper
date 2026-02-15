# Шаг 4b: Генерация (Скиллы + Пайплайны)

> Продолжение шага 4. Правила записи файлов и стек-адаптации — см. `step-4-generate.md`.

## Правила записи (краткое напоминание)
- `fresh`: записывать без проверок
- `validate`: файл есть → валидация → `[OK]`/`[FIX]`/`[REGEN]`; файла нет → `[NEW]`

---

## 4.3 Скиллы

### Валидация (режим `validate`)

#### skills/pipeline/SKILL.md (CRITICAL)
- Файл расположен в `skills/pipeline/` (НЕ `skills/routing/`)
- Содержит frontmatter с `user-invocable: true`
- Содержит `name: pipeline` в frontmatter
- Содержит таблицу Intent → Триггеры
- Содержит Шаг 4 — Диспатч с ссылкой на `.claude/pipelines/`
→ `skills/routing/` → переместить в `skills/pipeline/` → `[FIX] routing/ → pipeline/`
→ Нет frontmatter → добавить → `[FIX] добавлен frontmatter`
→ Нет таблицы → перегенерировать из шаблона → `[REGEN] pipeline/SKILL.md`

#### skills/p/SKILL.md
- Содержит frontmatter с `user-invocable: true`
- Ссылается на `/pipeline`
→ Нет → создать из шаблона → `[NEW] skills/p/SKILL.md`

---

### Генерация

Для каждого скилла прочитай шаблон из `templates/skills/` → подставь переменные → запиши в `.claude/skills/{name}/SKILL.md`:

  `templates/skills/code-style.md` → `.claude/skills/code-style/SKILL.md`
  `templates/skills/architecture.md` → `.claude/skills/architecture/SKILL.md`
  `templates/skills/database.md` → `.claude/skills/database/SKILL.md`
  `templates/skills/testing.md` → `.claude/skills/testing/SKILL.md`
  `templates/skills/pipeline.md` → `.claude/skills/pipeline/SKILL.md`
  `templates/skills/p.md` → `.claude/skills/p/SKILL.md`
  `templates/skills/memory.md` → `.claude/skills/memory/SKILL.md`

### 4.3.1 Кастомные скиллы

Для каждого скилла из CUSTOM_SKILLS сгенерируй файл `.claude/skills/{name}/SKILL.md` по шаблону:

```markdown
# Skill: {Name} — {DESCRIPTION}

## Паттерны
{Сгенерируй на основе назначения скилла и стека проекта}

## Антипаттерны
{Типичные ошибки}

## Примеры
{Конкретные примеры для стека}
```

---

## 4.4 Пайплайны

### Валидация (режим `validate`)

#### Пайплайны (.claude/pipelines/*.md)
- Содержит Task() pseudo-syntax для вызова агентов
- НЕ содержит устаревших текстовых инструкций типа "Прочитай .claude/agents/X.md"
- Параллельные агенты помечены "Запусти одновременно:"
→ Нет Task() → перегенерировать из шаблона → `[REGEN] {path}`
  (при перегенерации сохранять кастомные секции, специфичные для проекта)

### Cleanup легаси
- Пайплайны без Task() syntax → перегенерировать с сохранением проектной специфики → `[REGEN] {path}`

---

### Генерация

**Правило выбора языка в мульти-язычных проектах:**
- `{lang}` в пайплайне = язык, релевантный текущей задаче
- Если задача затрагивает конкретный модуль — определи язык по модулю
- Если неоднозначно — используй `PRIMARY_LANG`
- Для задач, затрагивающих несколько языков — фазы CODE, TESTS, REVIEW повторяются для каждого затронутого языка с соответствующими агентами

Для каждого пайплайна прочитай шаблон из `templates/pipelines/` → подставь переменные → запиши в `.claude/pipelines/{name}.md`:

  `templates/pipelines/new-code.md` → `.claude/pipelines/new-code.md`
  `templates/pipelines/fix-code.md` → `.claude/pipelines/fix-code.md`
  `templates/pipelines/review.md` → `.claude/pipelines/review.md`
  `templates/pipelines/tests.md` → `.claude/pipelines/tests.md`
  `templates/pipelines/api-docs.md` → `.claude/pipelines/api-docs.md`
  `templates/pipelines/qa-docs.md` → `.claude/pipelines/qa-docs.md`
  `templates/pipelines/full-feature.md` → `.claude/pipelines/full-feature.md`
  `templates/pipelines/hotfix.md` → `.claude/pipelines/hotfix.md`

### 4.4.1 Кастомные пайплайны

Для каждого пайплайна из CUSTOM_PIPELINES сгенерируй файл `.claude/pipelines/{name}.md` по шаблону:

```markdown
# Pipeline: {Name}

## Фазы

{Сгенерируй фазы на основе описания и указанных агентов. Минимум 2 фазы, максимум 5.
Используй Task() pseudo-syntax для вызова агентов.}

## Матрица ошибок

| Проблема | Действие | Откат |
|----------|----------|-------|
```
