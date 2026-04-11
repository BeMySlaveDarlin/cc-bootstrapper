---
name: "github"
description: "Интеграция с GitHub: issues, PR, actions, releases через gh CLI"
user-invocable: false
condition: "config.github_mcp"
---

# Skill: GitHub — Маппинг операций

## Pull Requests
| Операция | Команда |
|----------|---------|
| Создать PR | `gh pr create --title "..." --body "..."` |
| Получить PR | `gh pr view N` |
| Список PR | `gh pr list` |
| Мои PR | `gh pr list --author @me` |
| Approve PR | `gh pr review N --approve` |
| Merge PR | `gh pr merge N --squash` |
| Diff PR | `gh pr diff N` |
| Комментарий к PR | `gh pr comment N --body "..."` |
| Checks PR | `gh pr checks N` |

## Issues
| Операция | Команда |
|----------|---------|
| Создать issue | `gh issue create --title "..." --body "..."` |
| Получить issue | `gh issue view N` |
| Список issues | `gh issue list` |
| Мои issues | `gh issue list --assignee @me` |
| Закрыть issue | `gh issue close N` |
| Комментарий | `gh issue comment N --body "..."` |

## Actions / CI
| Операция | Команда |
|----------|---------|
| Список запусков | `gh run list` |
| Статус запуска | `gh run view RUN_ID` |
| Лог ошибок | `gh run view RUN_ID --log-failed` |
| Перезапуск | `gh run rerun RUN_ID` |
| Watch | `gh run watch RUN_ID` |

## Releases
| Операция | Команда |
|----------|---------|
| Создать release | `gh release create TAG --title "..." --notes "..."` |
| Список releases | `gh release list` |
| Получить release | `gh release view TAG` |

## API (для сложных запросов)
| Операция | Команда |
|----------|---------|
| Комментарии PR | `gh api repos/{owner}/{repo}/pulls/N/comments` |
| Labels | `gh api repos/{owner}/{repo}/labels` |
| Произвольный endpoint | `gh api <endpoint>` |

## Типовые сценарии

### Создание PR с ревью
1. `gh pr create --title "..." --body "..."` → получить URL
2. `gh pr checks N` → дождаться CI
3. Если CI green → сообщить, если fail → `gh run view --log-failed`

### Работа с issue
1. `gh issue view N` → прочитать контекст
2. Реализовать → код/тесты
3. `gh issue close N` → закрыть с комментарием

## Обработка ошибок

| Ошибка | Причина | Действие |
|--------|---------|----------|
| `gh auth status` fail | Не авторизован | Предложить `gh auth login` |
| 404 | Неверный repo/number | Проверить параметры |
| 422 | Невалидные данные | Показать причину валидации |

## Правила
- Деструктивные операции (delete, close, merge) — требуют подтверждения пользователя
- PR merge — только после проверки CI статуса
- Формат PR body — Markdown с ## Summary и ## Test plan
