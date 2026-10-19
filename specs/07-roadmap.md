# Roadmap / Backlog

Источник идей: корневой `todo.md` + gaps относительно specs.  
Статусы: `planned` | `in-model` | `partial-ui` | `done`.

## Недавно закрыто (спека ↔ код)

| Item | Notes |
| --- | --- |
| Share Extension auto-open + cold-start import | App Group + `?url=`; sheets на root ContentView |
| Матчинг ингредиентов | Stemming, одноязычный каталог в LLM, amount parser |
| iPad layout | Readable widths, adaptive grids, 2-col week, form sheets |
| TestFlight paywall mocks | `AppVars.useSubscriptionMocks` |

## Ближайший бэклог

| ID | Item | Status | Notes |
| --- | --- | --- | --- |
| R-01 | Рецепт дня / Surprise me на Home | done / polish | UI есть; следить за copy/a11y |
| R-02 | Случайный рецепт | done | CTA на Home |
| R-03 | Надиктовка рецепта | planned | Voice → тот же import/parse pipeline |
| R-04 | Генерация картинки для рецепта | planned | Для user recipes без фото |
| R-05 | Обновить дизайн: Kitchen Stories × текущий бренд | partial-ui | Токены и карточки; audit по [06-design-system.md](06-design-system.md) |
| R-06 | Лайки / community visibility | partial-ui | Рандом 0…100; добить отображение везде |
| R-07 | Личный рейтинг рецептов | in-model | `Recipe.userRating` 1…5; UI на detail/card |
| R-08 | Время готовки на всех карточках | partial | Поле есть; единый meta |
| R-09 | Кнопка «Сегодня» в week switcher | planned | |
| R-10 | Reverse-engineering паттернов Kitchen Stories | planned | Исследование UX |
| R-11 | Выключить mock-тарифы перед App Store | planned | `AppVars.useSubscriptionMocks = false` + реальные Adapty products |
| R-12 | Аналитика (Firebase / Google) | planned | Из `todo.md` |
| R-13 | Качество импорта (больше ключей каталога / курица и т.п.) | planned | Gaps в food-catalog |

## Принцип приоритизации

1. Закрыть **partial** (рейтинг, cook time на карточках) — высокий ROI.
2. Перед релизом: **R-11** (убрать mocks).
3. Дизайн-проход Library/Home; затем voice / image gen.

## Definition of Done для roadmap-item

- Обновлена feature-спека в `specs/features/`.
- Acceptance criteria зелёные.
- Локализация en/ru для новых строк.
- Не нарушены gating онбординга/подписки и offline-ядро плана.
