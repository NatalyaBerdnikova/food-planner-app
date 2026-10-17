# Roadmap / Backlog

Источник идей: корневой `todo.md` + gaps относительно specs.  
Статусы: `planned` | `in-model` | `partial-ui` | `done`.

## Ближайший бэклог

| ID | Item | Status | Notes |
| --- | --- | --- | --- |
| R-01 | Рецепт дня на главной | planned / in-model | `RecipeDiscoveryService.recipeOfTheDay` есть; нужна явная секция на Home |
| R-02 | Случайный рецепт | planned / in-model | `randomRecipe` есть; нужен UI CTA |
| R-03 | Надиктовка рецепта | planned | Voice → тот же import/parse pipeline |
| R-04 | Генерация картинки для рецепта | planned | Для user recipes без фото |
| R-05 | Обновить дизайн: Kitchen Stories × текущий бренд | partial-ui | Токены и карточки частично; полный audit по [06-design-system.md](06-design-system.md) |
| R-06 | Лайки / community visibility | partial-ui | `CommunitySocialStatsService` рандом 0…100 при заходе в tabs; добить отображение везде |
| R-07 | Личный рейтинг рецептов | in-model | `Recipe.userRating` 1…5; нужен UI на detail/card |
| R-08 | Время готовки | partial | Поле + AddRecipe + catalog; единый meta на всех карточках |
| R-09 | Кнопка «Сегодня» в week switcher | planned | Из memory.md |
| R-10 | Reverse-engineering паттернов Kitchen Stories | planned | Исследование UX; не код |

## Принцип приоритизации

1. Закрыть **partial** (рейтинг, cook time на карточках, recipe of the day) — высокий ROI, модель уже есть.
2. Дизайн-проход Library/Home под KS без ломки planner.
3. Новые входы контента (voice, image gen).

## Definition of Done для roadmap-item

- Обновлена feature-спека в `specs/features/`.
- Acceptance criteria зелёные.
- Локализация en/ru для новых строк.
- Не нарушены gating онбординга/подписки и offline-ядро плана.
