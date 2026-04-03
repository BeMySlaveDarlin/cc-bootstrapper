TEAM MODE: НЕ вызывай AskUserQuestion — он недоступен в team context.
Если нужен пользовательский ввод:
1. Запиши вопрос/данные в `.claude/output/interaction-{task-slug}.json`
2. SendMessage(to=lead): interaction_required + путь к файлу
3. Жди ответ от lead через SendMessage
Твой output не виден пользователю — только lead видит диалог.
