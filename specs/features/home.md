# F-HOME — Сегодня (Home)

**Status:** shipped  
**Primary views:** `HomeView`  
**Related:** [week-plan.md](week-plan.md), [import.md](import.md), [nutrition.md](nutrition.md), [recipes.md](recipes.md)

## Цель

Дневной хаб: питание сегодня, быстрый импорт, слоты еды, рекомендации рецептов.

## Секции экрана

1. **Recipe of the day** — featured + «Surprise me» (`RecipeDiscoveryService`).
2. **Import CTA** — открывает `PasteImportSheet` (form sheet на iPad).
3. **Today nutrition** — expandable карточка прогресса к целям (`NutritionTargetProgressView` / summary).
4. **Today meals** — слоты `breakfast/lunch/dinner/snack`; тап → `AddMealSheet`.
5. **Favorites** — adaptive grid карточек.

Контент в `readableContentWidth` на regular width. Toolbar: Settings.

## Сервисы

- `WeekPlanService` — текущая неделя / сегодня.
- `RecipeFavoritesService` — избранное.
- `RecipeDiscoveryService` — recipe of the day / random.
- `ImportCoordinator` — импорт из paste (progress на root ContentView).

## Acceptance

- [ ] Прогресс КБЖУ считается по meals сегодняшней даты.
- [ ] Добавление meal с Home обновляет отображение слотов и nutrition.
- [ ] CTA импорта открывает paste-sheet без ухода с вкладки.
- [ ] Settings доступны с Home.
- [ ] На iPad контент не растянут на всю ширину; избранное — adaptive columns.
