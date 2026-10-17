# F-HOME — Сегодня (Home)

**Status:** shipped  
**Primary views:** `HomeView`  
**Related:** [week-plan.md](week-plan.md), [import.md](import.md), [nutrition.md](nutrition.md), [recipes.md](recipes.md)

## Цель

Дневной хаб: питание сегодня, быстрый импорт, слоты еды, мост к недельному плану, рекомендации рецептов.

## Секции экрана

1. **Today nutrition** — expandable карточка прогресса к целям (`NutritionTargetProgressView`).
2. **Import CTA** — открывает `PasteImportSheet`.
3. **Today meals** — слоты `breakfast/lunch/dinner/snack`; тап по пустому → `AddMealSheet`.
4. **Week plan card** — переход/превью к плану.
5. **Recommendations** — сетка рецептов (избранное / каталог), снятие favorite с confirm.

Toolbar: Settings.

## Сервисы

- `WeekPlanService` — текущая неделя / сегодня.
- `RecipeFavoritesService` — избранное.
- `RecipeDiscoveryService` — recipe of the day / random (логика готова; UI на Home может быть partial относительно roadmap).

## Acceptance

- [ ] Прогресс КБЖУ считается по meals сегодняшней даты.
- [ ] Добавление meal с Home обновляет отображение слотов и nutrition.
- [ ] CTA импорта открывает paste-sheet без ухода с вкладки.
- [ ] Settings доступны с Home.
