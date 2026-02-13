Прочитай файл `$ARGUMENTS` и выполни ВСЕ шаги из него последовательно для текущего проекта.

Если аргумент не указан — ищи промпт в таком порядке:
1. `.claude/prompts/meta-prompt-bootstrap.md` в текущем проекте
2. `~/.claude/prompts/meta-prompt-bootstrap.md` (глобальная копия)

Если файл не найден ни там, ни там — сообщи пользователю.

---

## UPGRADE CHECK: Обнаружение обновлений

**ПЕРЕД PRE-CHECK** проверь наличие `.claude/.bootstrap-version`:

### Если `.bootstrap-version` существует:

1. Прочитай файл, извлеки `version`
2. Сравни с `VERSION_CURRENT` из meta-prompt (`2.0.0`)
3. **Если версии совпадают:**
   - Выведи `[CURRENT] Версия актуальна (v{version}). Запускаю PRE-CHECK...`
   - Перейди к PRE-CHECK

4. **Если версия meta-prompt новее:**
   - Покажи CHANGELOG изменений между версиями (из секции CHANGELOG meta-prompt)
   - Предложи режимы обновления:
     - **Полное обновление** — перегенерировать всё кроме кастомных файлов
     - **Только новые** — добавить отсутствующие компоненты
     - **Только хуки** — обновить скрипты
     - **Выборочно** — показать каждый файл с маркерами:
       - `[=]` файл не изменён (hash совпадает) — обновить
       - `[~]` файл кастомизирован (hash отличается) — НЕ перезаписывать
       - `[+]` новый компонент в этой версии — создать

5. **Diff detection:** для каждого файла из `hashes` в `.bootstrap-version`:
   - Вычисли текущий SHA256: `sha256sum .claude/{path} | cut -d' ' -f1`
   - Сравни с сохранённым хешем
   - Если совпадает → файл не менялся, безопасно обновить
   - Если отличается → файл кастомизирован, спроси перед перезаписью

6. После обновления — пересоздай `.bootstrap-version` с новыми хешами

### Если `.bootstrap-version` НЕ существует, но `.claude/` есть (v1 проект):

Это проект bootstrapped v1. Предложи миграцию:

```
[МИГРАЦИЯ v1→v2] Обнаружен bootstrapped проект без version tracking.
```

Предложи варианты:
- **Полная миграция v2** — обновить до v2 (pipeline skill, memory, cleanup)
- **Только version tracking** — создать .bootstrap-version для текущего состояния
- **Пропустить** — продолжить как обычный PRE-CHECK

**При полной миграции v1→v2:**

1. `[МИГРАЦИЯ] Добавить pipeline skill-роутер?` (y/n)
   - Создать `skills/pipeline/SKILL.md` и `skills/p/SKILL.md`
   - Удалить `skills/routing/` если есть
   - Обновить CLAUDE.md: добавить Auto-Pipeline Rule, заменить `by pipeline {name}` на `/pipeline {name}`

2. `[МИГРАЦИЯ] Добавить memory-систему?` (y/n)
   - Создать `state/memory/patterns.md` и `state/memory/issues.md`
   - Обновить `maintain-memory.sh` (добавить ротацию usage.jsonl, архивацию сессий)

3. `[МИГРАЦИЯ] Удалить устаревшие файлы?` (y/n)
   - Удалить `state/session.md` и `state/task-log.md` если есть
   - Убрать ссылки на них из CLAUDE.md

4. `[МИГРАЦИЯ] Добавить verify-bootstrap.sh?` (y/n)
   - Создать `scripts/verify-bootstrap.sh`

5. Сгенерировать `.claude/.bootstrap-version` с текущим состоянием

### Если `.claude/` не существует:

Пропустить UPGRADE CHECK → перейти к PRE-CHECK → fresh install.

---

## PRE-CHECK: Проверка соответствия схеме

**ПЕРЕД выполнением шагов** проверь, полностью ли проект уже соответствует схеме bootstrap. Проверь ВСЕ условия:

1. `.claude/agents/` — содержит `.md` файлы агентов (минимум: `*-architect.md`, `*-developer.md`, `*-test-developer.md`, `*-reviewer-logic.md`, `*-reviewer-security.md`, `db-architect.md`, `devops.md`)
2. `.claude/skills/` — содержит поддиректории с `SKILL.md` (`code-style/`, `architecture/`, `database/`, `testing/`, `memory/`, `pipeline/`, `p/`)
3. `.claude/pipelines/` — содержит все 8 пайплайнов (`new-code.md`, `fix-code.md`, `review.md`, `tests.md`, `api-docs.md`, `qa-docs.md`, `full-feature.md`, `hotfix.md`)
4. `.claude/scripts/hooks/` — содержит `track-agent.sh`, `session-summary.sh`, `update-schema.sh` и `maintain-memory.sh` (все executable)
5. `.claude/scripts/verify-bootstrap.sh` — существует и executable
6. `.claude/settings.json` — существует, валидный JSON
7. `CLAUDE.md` — существует и содержит секции: `## Agents`, `## Skills`, `## Pipelines`, `## Commands`, `## Architecture`
8. `.claude/input/` — существует (директория для задач и планов)
9. `.claude/database/` — существует (если проект использует БД)
10. `.claude/state/facts.md` — существует (файл фактов проекта)
11. `.claude/state/memory/` — содержит `patterns.md` и `issues.md`
12. `.claude/skills/memory/SKILL.md` — существует (скилл системы памяти)
13. `.claude/state/decisions/` — существует (директория архитектурных решений)
14. `.claude/.bootstrap-version` — существует, валидный JSON

**Если ВСЕ условия выполнены:**
- Выведи `[SKIP] Проект уже полностью соответствует схеме bootstrap v2. Изменения не требуются.`
- Покажи краткую сводку: количество агентов, скиллов, пайплайнов, хуков
- **ЗАВЕРШИСЬ. Не выполняй шаги.**

**Если частично выполнены** — выведи список `[OK]` / `[MISS]` по каждому пункту и продолжи выполнение только недостающих шагов.

**Если ничего нет** — выполняй все шаги полностью.

---

## INTERACTIVE: Подтверждение действий с пользователем

Перед выполнением шагов, **если проект не пустой** (уже есть `.claude/` или `CLAUDE.md`), спроси у пользователя:

### 1. Settings

Если `.claude/settings.json` уже существует:
- Покажи текущее содержимое
- Спроси: **Перезаписать `.claude/settings.json`?** (Да / Нет / Merge — добавить недостающие permissions)

Если `.claude/settings.local.json` уже существует:
- Покажи текущее содержимое
- Спроси: **Перезаписать `.claude/settings.local.json`?** (Да / Нет / Merge)

### 2. Очистка устаревшего

Проверь наличие потенциально устаревших файлов и директорий:
- Любые `.md` файлы в `.claude/agents/` которые не соответствуют текущей схеме именования
- `.claude/state/usage.jsonl` — может быть большим, предложить архивировать
- `.claude/skills/routing/` — устаревший routing skill (заменён pipeline skill)
- `.claude/state/session.md` и `.claude/state/task-log.md` — устаревшие файлы v1

Если найдено что-то из списка:
- Покажи список найденного
- Спроси: **Удалить устаревшие файлы?** (Да, все / Выбрать вручную / Нет, оставить)
- При «Выбрать вручную» — показать каждый файл отдельно

**Если проект пустой** — пропускай INTERACTIVE, создавай всё с нуля.

---

Выполняй шаги строго по порядку (Шаг 1 → 2 → 3 → 4 → 5). После каждого шага выводи краткий отчёт. Не пропускай генерацию файлов — создавай все агенты, скиллы, пайплайны, hooks, settings, state.
