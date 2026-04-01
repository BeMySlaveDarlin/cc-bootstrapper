# Шаг 10: Финализация

## Вход
- `.bootstrap-cache/state.json` (generation results, registries, config, errors)
- gen-report-8-{lang}.json, gen-report-8-common.json, gen-report-8-infra.json

## Выход
- Результат верификации: все [OK] или список проблем
- `.claude/.bootstrap-version` создан
- `.bootstrap-cache/state.json` и `.bootstrap-cache/` удалены
- Финальный баннер

## 10.1 Запуск верификации

Прочитай шаблон `templates/verify-bootstrap.sh` и запиши в `.claude/scripts/verify-bootstrap.sh` (если ещё не создан на шаге 8).

Запусти:

```bash
bash .claude/scripts/verify-bootstrap.sh
```

Дополнительно проверь вручную:

### Директории

Все обязательные директории существуют:
- `.claude/agents/`
- `.claude/skills/`
- `.claude/pipelines/`
- `.claude/scripts/hooks/`
- `.claude/memory/`
- `.claude/input/`
- `.claude/output/`

### Файлы

Сверь каждый файл из `state.registries` (agents, skills, pipelines) с файловой системой.
Для каждого файла выведи статус:

| Статус | Значение |
|--------|----------|
| `[OK]` | Файл существует, не пустой |
| `[MISS]` | Ожидаемый файл отсутствует |
| `[EMPTY]` | Файл существует, но пустой |

### Синтаксис .sh

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

### YAML frontmatter

Проверь наличие YAML frontmatter (`---` в начале файла) у:
- Всех агентов `.claude/agents/*.md`
- Всех скиллов `.claude/skills/*/SKILL.md`

Если frontmatter отсутствует — `[WARN]`.

### Версионные комментарии пайплайнов

Проверь что каждый файл `.claude/pipelines/*.md` содержит комментарий с версией (например `<!-- v7.2.0 -->`).

Если отсутствует — `[WARN]`.

## 10.2 Version Tracking

Сгенерируй `.claude/.bootstrap-version`:

```bash
HASHES="{}"
for f in .claude/agents/*.md .claude/skills/*/SKILL.md .claude/pipelines/*.md .claude/scripts/hooks/*.sh .claude/scripts/verify-bootstrap.sh .claude/settings.json; do
    [ -f "$f" ] || continue
    REL=$(echo "$f" | sed 's|^.claude/||')
    HASH=$(sha256sum "$f" | cut -d' ' -f1)
    HASHES=$(echo "$HASHES" | jq --arg k "$REL" --arg v "sha256:$HASH" '. + {($k): $v}')
done

jq -n \
    --arg version "7.3.1" \
    --arg generated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson hashes "$HASHES" \
    '{
        version: $version,
        generated: $generated,
        hashes: $hashes
    }' > .claude/.bootstrap-version
```

Поле `version` — версия бутстрапера. Используется при `validate` для сравнения с версиями в шаблонах.

## 10.3 Проверка stale state

Проверь что в корне проекта нет устаревших артефактов:
- `.bootstrap-cache/state.json` — если содержит `errors[]` — сначала отобрази их, затем удали cache
- `state/` — легаси директория, не должна существовать

Если найден `state/` — `[WARN] Обнаружена легаси директория state/. Рекомендуется удалить.`

## 10.4 Метрики

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

## 10.5 Cleanup

```bash
rm -rf .bootstrap-cache/
rm -f .bootstrap-cache/state.json
```

Проверь что оба паттерна есть в `.gitignore`:

```bash
for pattern in ".bootstrap-cache/state.json" ".bootstrap-cache/"; do
    if ! grep -qF "$pattern" .gitignore 2>/dev/null; then
        echo "[WARN] $pattern не найден в .gitignore"
    fi
done
```

Если `.gitignore` не содержит эти паттерны — добавь (маловероятно, step 1 должен был добавить, но на всякий случай).

## 10.6 Финальный баннер

```
╔══════════════════════════════════════════╗
║  Bootstrap Complete — v7.2.0             ║
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
`MODE` — значение `state.mode` (`fresh` / `validate`).

**НЕ добавляй никаких рекомендаций после баннера. Никаких git commit, никаких плагинов, никаких "следующих шагов". Баннер — это финал.**

## Лог

**ОБЯЗАТЕЛЬНО** перед checkpoint запиши лог в `.bootstrap-cache/step-10-log.md`:

```markdown
# Step 10: Финализация — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

Записать лог ПЕРЕД checkpoint.

## Checkpoint

Обнови `.bootstrap-cache/state.json` перед удалением:
- `steps.10.status` → `"completed"`
- `steps.10.completed_at` → `"{ISO8601}"`
- `status` → `"completed"`
- `updated_at` → `"{ISO8601}"`

Затем выполни cleanup (9.5).
