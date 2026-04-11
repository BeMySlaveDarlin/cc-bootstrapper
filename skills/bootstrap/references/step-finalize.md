# Шаг 9-10: Финализация (CLAUDE.md + manifest)

> Modes: fresh, patch, upgrade

> **SUBAGENT ISOLATION:** Этот шаг выполняется как изолированный субагент.
> Объединяет генерацию CLAUDE.md и финальную верификацию/cleanup в один вызов.
>
> Выполняется ПОСЛЕ step 8 (генерации). Зависит от финальных таблиц agents/skills/pipelines.

## Вход
- `.claude/.cache/state.json` → `stack`, `config`, `registries`, `generation results`, `errors`
- `.claude/.cache/gen-report-8-*.json` (только fresh/upgrade) → фактически созданные файлы. В patch mode gen-reports нет — таблицы строятся по файловой системе
- `.claude/.cache/deep/` → паттерны (если есть, для секции Rules)

## Выход
- `CLAUDE.md` в корне проекта
- `.claude/.bootstrap-manifest.json` создан
- `.claude/.bootstrap-version` удалён (legacy, заменён manifest)
- `.claude/.cache/state.json` и `.claude/.cache/` удалены
- Результат верификации: все [OK] или список проблем
- Финальный баннер

---

## ЧАСТЬ 1: Генерация CLAUDE.md

Если Write CLAUDE.md отклонён — верни error.

### 9.1 Режим `fresh`

Сгенерировать CLAUDE.md с секциями:

#### Структура файла

```markdown
# CLAUDE.md

## Project Overview
{краткое описание проекта из stack-анализа: язык, фреймворк, назначение}

## Rules

### ЖЁСТКОЕ ПРАВИЛО: Pipeline Routing
**ВСЕ операции с кодом** (написание, исправление, ревью, тесты, документация) выполняются ТОЛЬКО через пайплайны.
Используй `/pipeline` или `/p` для маршрутизации задачи в нужный пайплайн.
Все кодовые задачи — через pipeline.

### Code Style
{из deep-анализа если есть, иначе базовые правила по стеку}

### Project Conventions
{из deep-анализа если есть, иначе пропустить}

## Agents

| Агент | Файл | Описание |
|-------|------|----------|
{строка для каждого агента из gen-report-8-{lang} и gen-report-8-common, по факту созданных файлов}

## Skills

| Скилл | Директория | Описание |
|-------|-----------|----------|
{строка для каждого скилла из gen-report-8-{lang} и gen-report-8-common}

## Pipelines

| Пайплайн | Файл | Описание |
|----------|------|----------|
{строка для каждого пайплайна из gen-report-8-{lang} и gen-report-8-common}

## Key Paths
- Source: {SOURCE_DIR}
- Tests: {TEST_DIR}
- Database: {MIGRATIONS_DIR}
- Memory: `.claude/memory/`
- Pipelines: `.claude/pipelines/`
```

Таблицы agents/skills/pipelines: в fresh/upgrade — из gen-report-8-*.json (фактически созданные файлы). В patch — scan файловой системы (gen-reports не существуют).

### 9.2 Режим `patch`

#### Шаг 1: Чтение и парсинг

1. Прочитай существующий `CLAUDE.md`
2. Определи секции:
   - **Шаблонные** — секции из нашего шаблона (Project Overview, Rules, Agents, Skills, Pipelines, Key Paths)
   - **Пользовательские** — всё остальное (секции, которых нет в шаблоне)

#### Шаг 2: Извлечение пользовательского контента

Для каждой секции, которая НЕ входит в шаблонные:
- Запомнить заголовок, содержимое и позицию (после какой секции стоит)

Для шаблонных секций:
- Проверить есть ли пользовательские дополнения ВНУТРИ секции (текст после шаблонного контента)
- Если есть — извлечь и сохранить отдельно

#### Шаг 3: Регенерация шаблонных секций

- **Project Overview** — обновить из `stack` (если стек изменился)
- **Rules** — проверить наличие ЖЁСТКОГО ПРАВИЛА routing, обновить code-style из deep-анализа
- **Agents/Skills/Pipelines таблицы** — перестроить по фактическим файлам на диске (scan `.claude/agents/*.md`, `.claude/skills/*/SKILL.md`, `.claude/pipelines/*.md`). В patch mode gen-report-* не существуют — строить только по файловой системе
- **Key Paths** — обновить

#### Шаг 4: Сборка

1. Собрать обновлённый CLAUDE.md:
   - Шаблонные секции — обновлённые
   - Пользовательские секции — на своих оригинальных позициях
   - Пользовательские дополнения внутри шаблонных секций — сохранить после обновлённого контента
2. Показать diff пользователю (что изменилось)
3. AskUserQuestion:
   ```
   question: "Принять обновления CLAUDE.md?"
   options:
     - {label: "Да", description: "Применить обновления"}
     - {label: "Показать diff", description: "Показать полный diff перед применением"}
     - {label: "Нет", description: "Оставить CLAUDE.md без изменений"}
   ```

#### Cleanup легаси
- Секция "Auto-Pipeline Rule" → заменить на ЖЁСТКОЕ ПРАВИЛО → `[FIX]`
- Устаревшие агенты в таблице (frontend-*, db-architect, reviewer-logic/security) → убрать
- Ссылки на `skills/database/` → заменить на `skills/storage/`
- Ссылки на `skills/routing/` → заменить на `skills/pipeline/`

---

## ЧАСТЬ 2: Manifest и верификация

### 10.1 Запуск верификации

Прочитай шаблон `templates/verify-bootstrap.sh` и запиши в `.claude/scripts/verify-bootstrap.sh` (если ещё не создан на шаге 8).

Запусти:

```bash
bash .claude/scripts/verify-bootstrap.sh
```

Дополнительно проверь вручную:

#### Директории

Все обязательные директории существуют:
- `.claude/agents/`
- `.claude/skills/`
- `.claude/pipelines/`
- `.claude/scripts/hooks/`
- `.claude/memory/`
- `.claude/input/`
- `.claude/output/`

#### Файлы

Сверь каждый файл из `state.registries` (agents, skills, pipelines) с файловой системой.
Для каждого файла выведи статус:

| Статус | Значение |
|--------|----------|
| `[OK]` | Файл существует, не пустой |
| `[MISS]` | Ожидаемый файл отсутствует |
| `[EMPTY]` | Файл существует, но пустой |

#### Синтаксис .sh

```bash
for f in .claude/scripts/hooks/*.sh .claude/scripts/*.sh; do
    [ -f "$f" ] || continue
    if bash -n "$f" 2>/dev/null; then
        echo "[OK] $f"
    else
        echo "[ERR] $f"
        bash -n "$f" 2>&1
    fi
done
```

#### YAML frontmatter

Проверь наличие YAML frontmatter (`---` в начале файла) у:
- Всех агентов `.claude/agents/*.md`
- Всех скиллов `.claude/skills/*/SKILL.md`

Если frontmatter отсутствует — `[WARN]`.

#### Frontmatter пайплайнов

Проверь что каждый `.claude/pipelines/*.md` содержит YAML frontmatter с полями `name`, `phases` (array), `modes`. HTML-комментарий `<!-- version -->` — устаревший формат → `[WARN]`. Поле `version` в frontmatter — legacy, версионирование через manifest.

### 10.2 Version Tracking

#### Записать `.claude/.bootstrap-manifest.json`

Manifest ОБЯЗАН правильно классифицировать файлы. **Ошибка классификации приведёт к удалению пользовательских файлов при upgrade.**

**Алгоритм классификации:**
1. Прочитать `state.registries` из `.claude/.cache/state.json`
2. Собрать множество template-путей:
   - `registries.agents[]` где `type != "custom"` → `agents/{name}.md`
   - `registries.skills[]` где `type != "custom"` → `skills/{name}/SKILL.md`
   - `registries.pipelines[]` где `type != "custom"` → `pipelines/{name}.md`
   - `scripts/verify-bootstrap.sh` — всегда template
   - `scripts/hooks/*.sh` — **НЕ включать в manifest** (пользовательские, protected)
3. Для каждого файла: если путь в множестве template-путей → `"source": "template"`, иначе → `"source": "user"`

```bash
# Собрать template-пути из registries
TEMPLATE_PATHS=$(jq -r '
  ([.registries.agents[] | select(.type != "custom") | "agents/\(.name).md"] +
   [.registries.skills[] | select(.type != "custom") | "skills/\(.name)/SKILL.md"] +
   [.registries.pipelines[] | select(.type != "custom") | "pipelines/\(.name).md"])[]
' .claude/.cache/state.json)

FILES="{}"
HASHES="{}"
for f in .claude/agents/*.md .claude/skills/*/SKILL.md .claude/pipelines/*.md .claude/scripts/verify-bootstrap.sh; do
    [ -f "$f" ] || continue
    REL=$(echo "$f" | sed 's|^.claude/||')
    HASH=$(sha256sum "$f" | cut -d' ' -f1)
    HASHES=$(echo "$HASHES" | jq --arg k "$REL" --arg v "sha256:$HASH" '. + {($k): $v}')

    # verify-bootstrap.sh — template; agents/skills/pipelines — по registries
    SOURCE="user"
    case "$REL" in
        scripts/verify-bootstrap.sh) SOURCE="template" ;;
        *) echo "$TEMPLATE_PATHS" | grep -qxF "$REL" && SOURCE="template" ;;
    esac

    FILES=$(echo "$FILES" | jq --arg k "$REL" --arg s "$SOURCE" '. + {($k): {"source": $s}}')
done

jq -n \
    --arg version "9.0.0" \
    --arg generated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson files "$FILES" \
    --argjson hashes "$HASHES" \
    '{
        version: $version,
        generated: $generated,
        files: $files,
        hashes: $hashes
    }' > .claude/.bootstrap-manifest.json
```

**НЕ включать в manifest:** settings.json, CLAUDE.md, .mcp.json (protected paths).
**КРИТИЧНО:** Если registries недоступны — НЕ записывать manifest. Лучше без manifest, чем с неправильной классификацией.

Поле `version` — версия бутстрапера. Используется при `patch`/`upgrade` для сравнения с версиями в шаблонах.

#### Удалить legacy `.claude/.bootstrap-version`

```bash
rm -f .claude/.bootstrap-version
```

Файл `.bootstrap-version` заменён на `.bootstrap-manifest.json` начиная с v9.0.0. При следующем запуске step-init будет искать manifest первым.

### 10.3 Проверка stale state

Проверь что в корне проекта нет устаревших артефактов:
- `.claude/.cache/state.json` — если содержит `errors[]` — сначала отобрази их, затем удали cache
- `state/` — легаси директория, не должна существовать

Если найден `state/` — `[WARN] Обнаружена легаси директория state/. Рекомендуется удалить.`

### 10.4 Метрики

Собери из `state`:

| Метрика | Источник |
|---------|----------|
| Всего файлов | `state.generation.completed_files.length` |
| Агентов | `state.registries.agents.length` |
| Скиллов | `state.registries.skills.length` |
| Пайплайнов | `state.registries.pipelines.length` |
| Хуков | количество `.sh` в `scripts/hooks/` |
| Memory файлов | количество `.md` в `memory/` |
| Прочих | остаток (settings.json, verify-bootstrap.sh, CLAUDE.md, .mcp.json и т.д.) |
| Длительность | `state.started_at` → текущее время |
| Ошибки | `state.errors[]` — если есть, вывести список |

Покажи таблицу:

```
Файлы: {total}
  Агенты:    {N}
  Скиллы:    {N}
  Пайплайны: {N}
  Хуки:      {N}
  Memory:    {N}
  Прочее:    {N}

Время: {duration}
Ошибки: {count} (или "нет")
```

Если есть ошибки — выведи каждую с шагом и описанием.

### 10.5 Cleanup

```bash
rm -rf .claude/.cache/
rm -f .claude/.cache/state.json
```

### 10.6 Финальный баннер

```
╔══════════════════════════════════════════╗
║  Bootstrap Complete — v9.0.0             ║
╠══════════════════════════════════════════╣
║  Project: {PROJECT_NAME}                 ║
║  Mode: {MODE}                            ║
║  Agents: {N}  Skills: {N}               ║
║  Pipelines: {N}  Hooks: {N}             ║
║                                          ║
║  Quick start: /pipeline {описание}       ║
║  Short alias: /p {описание}              ║
╚══════════════════════════════════════════╝
```

`PROJECT_NAME` — имя директории проекта (`basename $CLAUDE_PROJECT_DIR`).
`MODE` — значение `state.mode` (`fresh` / `patch` / `upgrade`).

**НЕ добавляй никаких рекомендаций после баннера. Никаких git commit, никаких плагинов, никаких "следующих шагов". Баннер — это финал.**

---

## Лог

Перед checkpoint запиши лог в `.claude/.cache/step-finalize-log.md`:

```markdown
# Step 9-10: Финализация (CLAUDE.md + manifest) — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

Записать лог ПЕРЕД checkpoint.

## Checkpoint

Обнови `.claude/.cache/state.json` перед удалением:
- `steps.finalize.status` → `"completed"`
- `steps.finalize.completed_at` → `"{ISO8601}"`
- `status` → `"completed"`
- `updated_at` → `"{ISO8601}"`
- `generation.checkpoint` → `"finalize_done"`

Затем выполни cleanup (10.5).
