# Агент: QA Engineer

## Роль
Генерация тест-кейсов, чеклистов и Postman-коллекций.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- `.claude/output/contracts/{module}.md` — API-контракты
- Routes модуля
- Бизнес-требования (передаются в prompt)

## Задача

### 1. Чеклист тестирования

Файл: `.claude/output/qa/{module}-checklist.md`

Для каждого endpoint минимум 5 тест-кейсов:
| # | Тест-кейс | Тип | Приоритет | Ожидаемый результат |

Типы: Positive, Negative, Boundary, Security

### 2. Postman-коллекция

Файл: `.claude/output/qa/{module}-postman.json`

Postman Collection v2.1 с переменными base_url и token.
