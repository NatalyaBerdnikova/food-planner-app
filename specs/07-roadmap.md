# Roadmap / Backlog

Источник идей: корневой `todo.md` + gaps относительно specs.  
Статусы: `planned` | `in-model` | `partial-ui` | `done`.

## Недавно закрыто (спека ↔ код)

| Item | Notes |
| --- | --- |
| Share Extension auto-open + cold-start import | App Group + `?url=`; sheets на root ContentView |
| Матчинг ингредиентов | Stemming, одноязычный каталог в LLM, amount parser |
| iPad layout | Readable widths, adaptive grids, 2-col week, form sheets |
| Генерация недельного плана | `MealPlanGenerator` + preview в онбординге/paywall + pending |
| Обмен планом `.foodplan` | Export sheet (имя + avg КБЖУ), import modes, openURL |
| Очистка плана | Confirmation → meals + shopping |
| Trial engagement notifications | D1/D3/D7 + renewal−2d; deep links вкладок |
| Запрос отзыва | Favorite / rating; не day 1; 14 дней / 1× версия |
| Поиск рецептов | Название → иначе «Похожие по ингредиенту» |
| Дедуп клонов каталога | `deduplicatedCatalogRecipes` |
| Bootstrap transition | Opacity crossfade по HIG |
| Week plan scroll | iOS 18 `ScrollPosition` + large title |
| Micronutrient focus limit UX | Alert при попытке выбрать 6-й |
| Paste import hints | Единая карточка: текст / privacy / Share из Instagram |
| Production paywall | `useSubscriptionMocks = false` (кроме Previews); Debug Continue |

## Ближайший бэклог

| ID | Item | Status | Notes |
| --- | --- | --- | --- |
| R-01 | Рецепт дня / Surprise me на Home | done | |
| R-02 | Случайный рецепт | done | CTA на Home |
| R-03 | Надиктовка рецепта | planned | Voice → тот же import/parse pipeline |
| R-04 | Генерация картинки для рецепта | planned | Для user recipes без фото |
| R-05 | Обновить дизайн: Kitchen Stories × текущий бренд | partial-ui | Токены и карточки; audit по [06-design-system.md](06-design-system.md) |
| R-06 | Лайки / community visibility | partial-ui | Рандом 0…100; добить отображение везде |
| R-07 | Личный рейтинг рецептов | done | UI на detail + review trigger |
| R-08 | Время готовки на всех карточках | partial | Поле есть; единый meta |
| R-09 | Кнопка «Сегодня» в week switcher | planned | |
| R-10 | Reverse-engineering паттернов Kitchen Stories | planned | Исследование UX |
| R-11 | Аналитика (Firebase / Google) | partial | Фасад `AppAnalytics` + wiring v1; локальный plist есть. Осталось: Resolve Firebase SPM, DebugView (`-FIRDebugEnabled`). Спека: [ANALYTICS_EVENTS.md](ANALYTICS_EVENTS.md) |
| R-12 | Обновить базу ингредиентов и рецептов | planned | Из `todo.md` |
| R-13 | Качество импорта Instagram | planned | Сопоставление unresolved, парсинг |
| R-14 | Свайп под рецептом «подобрать похожие» | planned | Спорное в `todo.md` |
| R-15 | Ручной ввод целевого веса (не только slider) | planned | Фидбек Нади |
| R-16 | Фильтр рецептов по типу приёма в AddMeal | partial | Есть UI; проверить качество фильтра |
| R-17 | Авторасчёт КБЖУ для своего рецепта из ингредиентов в форме создания | partial | Считается на detail из каталога; UX ввода улучшить |

## Принцип приоритизации

1. **R-11** аналитика — измерить воронку до правок каталога/импорта.
2. **R-12 / R-13** контент и качество импорта — основной friction.
3. Закрыть **partial** UX (cook time meta, фильтр приёма, вес вручную).
4. Затем voice / image gen / swipe discovery.

## Definition of Done для roadmap-item

- Обновлена feature-спека в `specs/features/`.
- Acceptance criteria зелёные.
- Локализация en/ru для новых строк.
- Не нарушены gating онбординга/подписки и offline-ядро плана.
