# Шаг 5: Верификация

## 5.1 Запуск верификации

Прочитай шаблон `templates/verify-bootstrap.sh` → запиши в `.claude/scripts/verify-bootstrap.sh` (если ещё не создан на шаге 4).

Запусти скрипт верификации одной командой:

```bash
bash .claude/scripts/verify-bootstrap.sh
```

## 5.2 Version Tracking

Сгенерируй файл `.claude/.bootstrap-version`:

```bash
HASHES="{}"
for f in .claude/agents/*.md .claude/skills/*/SKILL.md .claude/pipelines/*.md .claude/scripts/hooks/*.sh .claude/scripts/verify-bootstrap.sh; do
    [ -f "$f" ] || continue
    REL=$(echo "$f" | sed 's|^.claude/||')
    HASH=$(sha256sum "$f" | cut -d' ' -f1)
    HASHES=$(echo "$HASHES" | jq --arg k "$REL" --arg v "sha256:$HASH" '. + {($k): $v}')
done

jq -n \
    --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson hashes "$HASHES" \
    '{
        generated: $date,
        hashes: $hashes
    }' > .claude/.bootstrap-version
```

Без поля `version`. Хеши нужны только для определения кастомизированных файлов.

## 5.3 Итоговый отчёт

Покажи:
- Количество агентов, скиллов, пайплайнов
- Стек проекта
- Что было вычленено из CLAUDE.md (если было)
- Список всех созданных файлов
- Результат верификации (все [OK] или есть [MISS]/[ERR])

## ФИНАЛ

После завершения всех шагов выведи:

```
╔══════════════════════════════════════════════╗
║  Claude Code Automation — Bootstrap Complete ║
╠══════════════════════════════════════════════╣
║  Project: {PROJECT_NAME}                     ║
║  Stack: {LANGS} + {FRONTEND}                  ║
║  DB: {DB}                                    ║
║                                              ║
║  Agents: {N_BASE + N_CUSTOM}                 ║
║  Skills: {7 + N_CUSTOM_SKILLS}               ║
║  Pipelines: {8 + N_CUSTOM_PIPELINES}         ║
║  Hooks: 5                                    ║
║  Memory: facts + patterns + issues + decisions║
║  MCP: {gitlab | none}                        ║
║  Quick start:                                ║
║  /pipeline new-code  или  /p new-code        ║
╚══════════════════════════════════════════════╝
```
