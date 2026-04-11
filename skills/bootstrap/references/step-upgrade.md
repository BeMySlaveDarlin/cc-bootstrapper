# Шаг: Upgrade (полное обновление до v9)

> Modes: upgrade

> Выполняется когда `state.mode = "upgrade"`.
> Заменяет шаги 8-lang, 8-common, 8-infra для upgrade-режима.

## Вход
- `.claude/.cache/state.json` (config, stack, registries)
- Существующая `.claude/` структура (v8.x или legacy)

## Выход
- Полностью перегенерированная `.claude/` структура v9.0.0
- Восстановленные пользовательские файлы
- `.claude/.cache/step-upgrade-log.md`

---

## U.0 Бэкап

```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p .claude/.cache/backups
tar -czf .claude/.cache/backups/backup-${TIMESTAMP}.tar.gz --exclude='.claude/.cache' .claude/ || echo "BACKUP FAILED"
```

Если бэкап уже существует (повторный запуск) — пропустить.

---

## U.1 Инвентаризация

> **КРИТИЧНО:** Ошибка классификации = удаление пользовательских файлов. При сомнениях — файл считается user content.
> **Принцип:** файл можно удалить ТОЛЬКО если выполнены ВСЕ три условия: (1) это known template, (2) hash не менялся, (3) есть v9 шаблон для перегенерации.

### Алгоритм классификации (двухуровневый)

Для каждого файла в `.claude/agents/`, `.claude/skills/`, `.claude/pipelines/`:

#### Шаг 1: Это known template?

**Если есть `.claude/.bootstrap-manifest.json`:**
- `"source": "template"` → known template → шаг 2
- `"source": "user"` → **SAVE**, классификация завершена
- Файл НЕ в manifest → **SAVE**, классификация завершена

**Если manifest нет (legacy / v8.x):**
Прочитать `known-templates.json` (путь к корню плагина передан в prompt оркестратором).
- Для agents: совпадение с `agents[].pattern` (подставить каждый lang из `state.stack.langs` вместо `{lang}`)
- Для skills: совпадение с `skills[].name`
- Для pipelines: совпадение с `pipelines[].name`
- Совпадение → known template → шаг 2
- Нет совпадения → **SAVE**, классификация завершена

#### Шаг 2: Есть v9 шаблон для перегенерации?

Проверить что в `templates/` bootstrapper'а существует шаблон для этого файла:
- agents: `{plugin_root}/templates/agents/{pattern}.md` (с учётом `{lang}` → `lang-*.md`)
- skills: `{plugin_root}/templates/skills/{name}.md`
- pipelines: `{plugin_root}/templates/pipelines/{name}.md`

> `{plugin_root}` — путь к корню плагина, передан в prompt оркестратором.

- Шаблон **не существует** → **SAVE** (нечем перегенерировать)
- Шаблон существует → **DELETE** (будет перегенерирован из v9 шаблона)

### Итого

```
known template? ──NO──→ SAVE
      │YES
v9 template exists? ──NO──→ SAVE
      │YES
      └──→ DELETE
```

### Скрипты
- `scripts/hooks/*.sh` — protected (пользовательские хуки, могут содержать кастомную логику)
- `scripts/verify-bootstrap.sh` — DELETE (перегенерируется)

### Зона "не трогать" (protected paths)
Следующие файлы/директории НЕ удаляются и НЕ модифицируются при upgrade:
- `settings.json`
- `.mcp.json`
- `CLAUDE.md`
- `memory/` — все файлы (данные пользователя)
- `database/` — все файлы
- `input/` — все файлы
- `output/` — все файлы
- `plugins/`
- `logs/`
- `session/`

---

## U.2 Выбор что сохранить

Покажи пользователю:

```
[UPGRADE] Обнаружены пользовательские файлы:

Агенты:
  [ ] agents/custom-agent.md
  [ ] agents/ml-engineer.md

Скиллы:
  [ ] skills/custom-tool/SKILL.md

Пайплайны:
  [ ] pipelines/deploy.md
  [ ] pipelines/migration.md
```

Используй AskUserQuestion (multiSelect):
- question: "Какие пользовательские файлы сохранить после upgrade?"
- options: список кандидатов с чекбоксами
  - Каждый с description: краткое описание из frontmatter или первой строки файла

Отмеченные файлы → `state.upgrade.preserve[]`.

Если пользовательских файлов нет — пропустить этот шаг.

---

## U.3 Удаление legacy

> **Safety check перед удалением:** Перед удалением покажи пользователю финальный список файлов на удаление и попроси подтверждение. Формат:
> ```
> [UPGRADE] Будут удалены (template-generated):
>   - agents/php-developer.md
>   - agents/php-architect.md
>   - ...
>
> Будут СОХРАНЕНЫ (user content):
>   - agents/ci-manager.md
>   - skills/gitlab/SKILL.md
>   - ...
>
> Подтвердить удаление?
> ```

Удалить ТОЛЬКО файлы из списка "кандидаты на удаление" (U.1):

```bash
# Агенты (ТОЛЬКО из списка template-generated)
rm -f .claude/agents/{template-agents}.md

# Скиллы (ТОЛЬКО из списка template-generated)
rm -rf .claude/skills/{template-skills}/

# Пайплайны (ТОЛЬКО из списка template-generated)
rm -f .claude/pipelines/{template-pipelines}.md

# Хуки — protected (пользовательские)

# Legacy state (удалять без миграции)
rm -rf .claude/state/

# Legacy version file
rm -f .claude/.bootstrap-version
```

→ `[DELETE] {path}` для каждого удалённого файла.

Не удалять:
- Файлы из `state.upgrade.preserve[]`
- Файлы из protected paths
- `scripts/hooks/*.sh` — пользовательские хуки
- Файлы, не попавшие в список template-generated (U.1)
- **Если файл не в manifest И не в whitelist — НЕ удалять. Это user content.**

---

## U.4 Fresh генерация v9.0.0

> **ЭТОТ ШАГ ВЫПОЛНЯЕТСЯ ОРКЕСТРАТОРОМ** (SKILL.md), не этим субагентом.
> Оркестратор вызывает: configure → preview → analyze → generate. Settings и Plugins пропускаются.
> Перейди к U.5 — он вызывается оркестратором после генерации.

---

## U.5 Восстановление сохранённых файлов

Для каждого файла из `state.upgrade.preserve[]`:
1. Скопировать из бэкапа обратно в `.claude/`
2. Если файл — пайплайн, конвертировать frontmatter v8→v9 (как в step-patch P.2)
3. Если файл — агент/скилл, удалить `version:` из frontmatter (если есть)

→ `[RESTORE] {path}`

Если конвертация frontmatter невозможна (слишком legacy формат) — восстановить as-is и пометить `[RESTORE:RAW] {path}: требует ручной конвертации`.

---

## U.6 Валидация

Проверить что все обязательные файлы на месте:
- Все template-агенты из registries
- Все template-скиллы из registries
- Все 8 пайплайнов (4 per-lang + 4 common, БЕЗ hotfix)
- Все хуки
- `skills/pipeline/SKILL.md` с v9 роутером

Если чего-то не хватает — `[MISS] {path}`, дополнить.

---

## Лог

Перед checkpoint запиши лог в `.claude/.cache/step-upgrade-log.md`:

```markdown
# Step Upgrade: Full upgrade to v9.0.0 — Log

## Выполненные действия
- {что конкретно было сделано, файлы созданные/изменённые}
- Бэкап: .claude/.cache/backups/backup-{timestamp}.tar.gz
- Удалено: {N} legacy файлов
- Сгенерировано: {N} v9 файлов
- Восстановлено: {N} пользовательских файлов

## Пропущенные действия
- {что было пропущено и почему}

## Ошибки
- {ошибки если были, или "нет"}
```

## Checkpoint

После завершения обнови state:
```json
{
  "generation": {
    "checkpoint": "upgrade_done",
    "completed_files": ["...список файлов..."],
    "deleted_files": ["...список удалённых..."],
    "preserved_files": ["...список восстановленных..."]
  }
}
```
