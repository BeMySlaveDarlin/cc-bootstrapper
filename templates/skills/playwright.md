---
name: "playwright"
description: "E2E тестирование и браузерная автоматизация через Playwright MCP"
version: "8.2.0"
user-invocable: false
condition: "plugins.playwright"
---

# Skill: Playwright MCP — Браузерная автоматизация

## Навигация и взаимодействие
| Действие | MCP Tool |
|----------|----------|
| Открыть URL | `mcp__plugin_playwright_playwright__browser_navigate` |
| Назад | `mcp__plugin_playwright_playwright__browser_navigate_back` |
| Клик | `mcp__plugin_playwright_playwright__browser_click` |
| Заполнить форму | `mcp__plugin_playwright_playwright__browser_fill_form` |
| Выбрать option | `mcp__plugin_playwright_playwright__browser_select_option` |
| Нажать клавишу | `mcp__plugin_playwright_playwright__browser_press_key` |
| Ввод текста | `mcp__plugin_playwright_playwright__browser_type` |
| Загрузить файл | `mcp__plugin_playwright_playwright__browser_file_upload` |
| Hover | `mcp__plugin_playwright_playwright__browser_hover` |
| Drag & drop | `mcp__plugin_playwright_playwright__browser_drag` |

## Проверки и диагностика
| Действие | MCP Tool |
|----------|----------|
| Снимок DOM (accessibility tree) | `mcp__plugin_playwright_playwright__browser_snapshot` |
| Скриншот | `mcp__plugin_playwright_playwright__browser_take_screenshot` |
| Console messages | `mcp__plugin_playwright_playwright__browser_console_messages` |
| Network requests | `mcp__plugin_playwright_playwright__browser_network_requests` |
| Ожидание элемента/URL | `mcp__plugin_playwright_playwright__browser_wait_for` |
| Выполнить JS | `mcp__plugin_playwright_playwright__browser_evaluate` |
| Запуск произвольного кода | `mcp__plugin_playwright_playwright__browser_run_code` |

## Управление браузером
| Действие | MCP Tool |
|----------|----------|
| Список вкладок | `mcp__plugin_playwright_playwright__browser_tabs` |
| Resize окна | `mcp__plugin_playwright_playwright__browser_resize` |
| Обработка диалогов (alert, confirm, prompt) | `mcp__plugin_playwright_playwright__browser_handle_dialog` |
| Закрыть браузер | `mcp__plugin_playwright_playwright__browser_close` |

## Типовые сценарии

### E2E тест эндпоинта
1. `browser_navigate` → URL
2. `browser_snapshot` → убедиться что страница загружена
3. `browser_fill_form` → заполнить поля
4. `browser_click` → submit
5. `browser_wait_for` → ожидание результата
6. `browser_snapshot` → проверить результат в DOM

### Отладка UI бага
1. `browser_navigate` → проблемный URL
2. `browser_snapshot` → DOM tree
3. `browser_console_messages` → JS ошибки
4. `browser_network_requests` → failed requests
5. `browser_take_screenshot` → визуальное состояние

### Проверка responsive
1. `browser_resize` → {width: 375, height: 812} (mobile)
2. `browser_snapshot` → проверить layout
3. `browser_resize` → {width: 1920, height: 1080} (desktop)
4. `browser_snapshot` → сравнить

## Правила
- `browser_snapshot` ПЕРЕД взаимодействием — убедиться что элемент существует
- `browser_wait_for` перед проверками — SPA грузится асинхронно
- Скриншоты — при ошибках или по запросу (экономия контекста)
- `browser_close` после завершения сценария
- Не вводить реальные credentials — тестовые данные
- ref-атрибуты из snapshot предпочтительнее CSS-селекторов
