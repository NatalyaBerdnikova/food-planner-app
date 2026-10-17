# F-REC — Библиотека и карточка рецепта

**Status:** shipped (rating / community likes — partial UI)  
**Primary views:** `RecipeLibraryView`, `RecipeDetailView`, `AddRecipeView`, `RecipeCardView`, `AddIngredientSheet`  
**Related:** [import.md](import.md), [nutrition.md](nutrition.md), [catalogs.md](catalogs.md)

## Цель

Единая библиотека каталоговых и пользовательских рецептов; создание/просмотр с нутриентами.

## Библиотека

- Hero-блок импорта.
- Секция пользовательских рецептов.
- Секция рекомендаций / каталога (grid `RecipeCardView`).
- Toolbar `+` → `AddRecipeView`.
- Favorite / unfavorite каталоговых с confirm.

## Создание / редактирование (`AddRecipeView`)

- PhotosPicker для фото.
- Название, servings, cook time (stepper 0…300, step 5; 0 = unknown).
- Ингредиенты: поиск по каталогу (`AddIngredientSheet`), не длинный Picker.
- Шаги готовки (plain / rich storage).
- Сохранение: SwiftData + запись в user recipes JSON через catalog store.

## Деталь рецепта

- Hero image.
- Nutrition per serving (`NutritionCalculator`).
- Список ингредиентов; масштабирование отображаемых порций (`displayPortions`).
- Локализованные шаги.
- Sheet микронутриентов.
- Мета: cook time (если `hasCookTime`), community likes, user rating (модель готова).

## Карточка (`RecipeCardView`)

Photo-first: изображение, название, meta (время / likes / tags по наличию).

## Acceptance

- [ ] Каталоговые и user recipes визуально разделены.
- [ ] Ингредиент выбирается из каталога по поиску; в UI показывается `displayName`, не сырой `catalogKey`.
- [ ] КБЖУ на порцию согласованы с составом и servings.
- [ ] `cookTimeMinutes = 0` не показывается как «0 мин» (unknown).
- [ ] `userRating` clamp 0…5; `communityLikeCount` clamp 0…100.
