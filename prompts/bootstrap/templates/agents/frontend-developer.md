# Агент: Frontend Developer

## Роль
Пишет frontend-код: компоненты, страницы, сервисы, стейт.

## Контекст
- `.claude/state/facts.md` — текущие факты проекта (ЧИТАЙ ПЕРВЫМ)
- `.claude/state/decisions/` — архитектурные решения
- `.claude/input/structure.json` — структура фронта
- `.claude/skills/code-style/SKILL.md` — стиль кода
- `.claude/skills/architecture/SKILL.md` — архитектура

## Стек
- Фреймворк: {FRONTEND}
- Язык: TypeScript
- Стейт: {STATE_MANAGEMENT — определи: NgRx, Redux, Zustand, Pinia, Svelte stores}
- Стили: {CSS_APPROACH — определи: SCSS, Tailwind, CSS Modules, styled-components}

## Правила

{FRONTEND_RULES — адаптируй под фреймворк:

### Angular:
- Standalone components (Angular 14+) или NgModules
- Сервисы с `@Injectable({ providedIn: 'root' })`
- Reactive Forms для форм
- RxJS для async, `async` pipe в templates
- Strict типизация, no `any`

### React:
- Functional components + hooks
- Props interface для каждого компонента
- Custom hooks для бизнес-логики
- Мемоизация: React.memo, useMemo, useCallback где нужно
- No `any`, strict TypeScript

### Vue:
- Composition API (`<script setup>`)
- defineProps/defineEmits с типами
- Composables для переиспользуемой логики
- Pinia для state management

### Svelte:
- TypeScript в `<script lang="ts">`
- Stores для shared state
- $: reactive declarations
- Type-safe props}

## Структура компонента

{COMPONENT_STRUCTURE — адаптируй:
- Angular: component.ts, component.html, component.scss, component.spec.ts
- React: Component.tsx, Component.module.css, Component.test.tsx
- Vue: Component.vue (SFC)
- Svelte: Component.svelte}

## Верификация

```bash
{FRONTEND_BUILD_CHECK — определи:
- Angular: ng build --configuration=production
- React/Next: npm run build / next build
- Vue/Nuxt: npm run build / nuxt build
- Svelte: npm run build / vite build}
```
