# Шаг 4: Генерация (Агенты)

## Вход
- BOOTSTRAP_MODE: fresh | validate
- LANGS: список языков
- PRIMARY_LANG: основной язык
- FRAMEWORK_{lang}: фреймворки
- TEST_FRAMEWORK_{lang}: тест-фреймворки
- FRONTEND, DB, CONTAINER
- CUSTOM_AGENTS: список кастомных агентов
- ADAPTIVE_TEAMS: true | false

## Выход
Верни результат:
- Список созданных/обновлённых агентов с статусами [OK]/[FIX]/[NEW]/[REGEN]
- Список созданных директорий

## Правила записи файлов

### Режим `fresh`
Записывать все файлы без проверок.

### Режим `validate`
**Всё автоматически, без AskUserQuestion.** Для КАЖДОГО файла:

1. **Файл НЕ существует** → создать из шаблона → `[NEW] {path}`
2. **Файл существует** → провести ВАЛИДАЦИЮ содержимого:

#### Валидация агентов (.claude/agents/*.md)
- Начинается с YAML frontmatter (`---` блок) с полями `name` и `description`
- `name` — kebab-case, совпадает с именем файла (без `.md`)
- `description` — одна строка, описание роли агента
- Содержит секцию `## Контекст` с ссылкой на `facts.md`
- Содержит ссылки на skills (`skills/code-style/SKILL.md`, etc.)
- НЕ содержит устаревших ссылок на `skills/routing/`
→ Нет frontmatter → добавить из шаблона → `[FIX] {path}: добавлен frontmatter`
→ Проблемы найдены → исправить IN-PLACE → `[FIX] {path}: {что исправлено}`
→ Файл ОК → `[OK] {path}`

#### Валидация CLAUDE.md
- Содержит ЖЁСТКОЕ ПРАВИЛО routing первым в Rules
- Содержит `/pipeline` ссылку
- Содержит таблицы Agents, Skills, Pipelines
- НЕ содержит устаревшей секции "Auto-Pipeline Rule"
- Таблица Agents соответствует реальным файлам в .claude/agents/
- Таблица Skills соответствует реальным директориям в .claude/skills/
→ Проблемы → исправить IN-PLACE → `[FIX] CLAUDE.md: {что}`

## Cleanup легаси (автоматически, без вопросов)

В режиме `validate` выполняется автоматически:
- `skills/routing/` существует → переименовать в `skills/pipeline/`, обновить содержимое → `[FIX] routing/ → pipeline/`
- `CLAUDE.md` содержит "Auto-Pipeline Rule" → заменить на ЖЁСТКОЕ ПРАВИЛО → `[FIX] CLAUDE.md`
- Агенты без ссылок на skills → добавить ссылки → `[FIX] {path}`
- Устаревшие файлы (`state/session.md`, `state/task-log.md`) → предупредить → `[WARN] Устаревший: {path}`

---

## 4.1 Директории

```bash
mkdir -p .claude/{agents,skills/{code-style,architecture,database,testing,memory,pipeline,p},pipelines,scripts/hooks,memory/{decisions,decisions/archive,sessions,sessions/archive},output/{contracts,qa,plans,reviews},input/{tasks,plans},database}
touch .claude/memory/decisions/.gitkeep .claude/memory/decisions/archive/.gitkeep
```

Если CUSTOM_SKILLS не пуст — создай дополнительные директории:
```bash
mkdir -p .claude/skills/{custom_skill_1,custom_skill_2,...}
```

Если GITLAB_MCP=true:
```bash
mkdir -p .claude/skills/gitlab
```

## 4.2 Агенты

**Мульти-языковая генерация:** Шаблоны генерируй для КАЖДОГО языка из `LANGS`. Для каждого языка подставляй соответствующие `FRAMEWORK_{lang}`, `TEST_FRAMEWORK_{lang}`, `TEST_CMD_{lang}`, `LINT_CMD_{lang}`.

Общие агенты (DB Architect, DevOps, Frontend*, QA Engineer) — генерируются в одном экземпляре.

**ВАЖНО:** Каждый шаблон агента содержит YAML frontmatter с placeholder-переменными (`{lang}`, `{LANG}`). При генерации подставляй реальные значения в frontmatter так же, как и в теле файла.

Для каждого `{lang}` из LANGS:
  Прочитай шаблон `templates/agents/lang-architect.md` → подставь переменные (включая frontmatter) → запиши в `.claude/agents/{lang}-architect.md`
  Прочитай шаблон `templates/agents/lang-developer.md` → подставь переменные → запиши в `.claude/agents/{lang}-developer.md`
  Прочитай шаблон `templates/agents/lang-test-developer.md` → подставь переменные → запиши в `.claude/agents/{lang}-test-developer.md`
  Прочитай шаблон `templates/agents/lang-reviewer-logic.md` → подставь переменные → запиши в `.claude/agents/{lang}-reviewer-logic.md`
  Прочитай шаблон `templates/agents/lang-reviewer-security.md` → подставь переменные → запиши в `.claude/agents/{lang}-reviewer-security.md`

Общие агенты (по условиям):
  Прочитай шаблон `templates/agents/db-architect.md` → подставь переменные → запиши в `.claude/agents/db-architect.md` (если есть БД)
  Прочитай шаблон `templates/agents/devops.md` → подставь переменные → запиши в `.claude/agents/devops.md`
  Прочитай шаблон `templates/agents/frontend-developer.md` → подставь переменные → запиши в `.claude/agents/frontend-developer.md` (если FRONTEND != none)
  Прочитай шаблон `templates/agents/frontend-test-developer.md` → подставь переменные → запиши в `.claude/agents/frontend-test-developer.md` (если FRONTEND != none)
  Прочитай шаблон `templates/agents/frontend-reviewer.md` → подставь переменные → запиши в `.claude/agents/frontend-reviewer.md` (если FRONTEND != none)
  Прочитай шаблон `templates/agents/qa-engineer.md` → подставь переменные → запиши в `.claude/agents/qa-engineer.md`

Условные агенты (создавай если есть соответствующий стек):
  Если FRONTEND != none: `frontend-contract` — API-контракты (`.claude/agents/frontend-contract.md`)
  Если есть CI (.gitlab-ci.yml, .github/workflows/): `ci-manager` — CI/CD (`.claude/agents/ci-manager.md`)

Для frontend-contract и ci-manager агентов используй универсальный шаблон ниже.

### 4.2.1 Кастомные агенты

Для каждого агента из CUSTOM_AGENTS, а также для frontend-contract и ci-manager, сгенерируй файл `.claude/agents/{name}.md` по универсальному шаблону:

```markdown
---
name: "{name}"
description: "{ROLE — краткое описание роли агента, одна строка}"
---

# Агент: {Name}

## Роль
{ROLE — из ответа пользователя или определи по стеку}

## Контекст
- `.claude/memory/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/memory/decisions/` — архитектурные решения
- Код модуля: {SOURCE_DIR}
- `.claude/skills/code-style/SKILL.md` — стиль кода
- `.claude/skills/architecture/SKILL.md` — архитектура

## Задача
{Сгенерируй 3-5 шагов на основе роли и стека проекта}

## Правила
{Сгенерируй 3-5 правил на основе роли, стека и code-style}

## Формат вывода
{Определи на основе роли}
```

Адаптируй содержимое под стек проекта (LANG, FRAMEWORK, DB).

---

## СТЕК-СПЕЦИФИЧНЫЕ АДАПТАЦИИ

Прочитай `templates/includes/stack-adaptations.md` — используй ТОЛЬКО для языков из LANGS.
