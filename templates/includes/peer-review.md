### Peer Review: {PEER_VALIDATOR} валидирует результат {PEER_AUTHOR}

Task(.claude/agents/{PEER_VALIDATOR}.md, subagent_type: "general-purpose"):
  Вход: `.claude/output/{PEER_ARTIFACT}`, контекст задачи, `.claude/memory/facts.md`
  Выход: `.claude/output/reviews/{task-slug}-peer-{PEER_PHASE}.md`
  Ограничение: read-only
  Инструкция: ты — валидатор. Проверь результат на:
    - Полноту (все ли аспекты задачи учтены)
    - Соответствие описанию задачи / спецификации
    - Пропущенные edge cases
    - Overengineering / underengineering
    - Конфликты с существующей архитектурой (`.claude/memory/facts.md`, `.claude/memory/decisions/`)
  Верни: verdict (APPROVE | REVISE) + замечания (если REVISE — конкретный пронумерованный список)

→ APPROVE: продолжить к следующему шагу.

→ REVISE (итерация {I}/{PEER_MAX_ITERATIONS}):
  Передай замечания автору:
  Task(.claude/agents/{PEER_AUTHOR}.md, subagent_type: "general-purpose"):
    Вход: `.claude/output/{PEER_ARTIFACT}` + замечания из `.claude/output/reviews/{task-slug}-peer-{PEER_PHASE}.md`
    Выход: обновлённый `.claude/output/{PEER_ARTIFACT}`
    Инструкция: исправь результат по замечаниям валидатора. Обнови файл. Не добавляй ничего сверх замечаний.
    Верни: summary (что исправлено, пункт → решение)
  Повтори peer review (макс. {PEER_MAX_ITERATIONS} итераций).

→ После {PEER_MAX_ITERATIONS} итераций, если verdict всё ещё REVISE:
  Прочитай нерешённые замечания из последнего `.claude/output/reviews/{task-slug}-peer-{PEER_PHASE}.md`.
  Покажи пользователю результат **вместе с нерешёнными замечаниями** — пусть решает сам.
