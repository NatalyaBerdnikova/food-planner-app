# F-CAT — Каталоги продуктов и рецептов

**Status:** shipped  
**Primary:** `FoodCatalogSeeder`, `RecipeCatalogStore`, Resources JSON, `tools/`  
**Related:** [recipes.md](recipes.md), [import.md](import.md), [nutrition.md](nutrition.md)

## Цель

Локальная база продуктов и стартовых рецептов; расширение контента без backend.

## Продукты

- Файл: `food-planner/Resources/food-catalog.json` (~492).
- Seed в SwiftData при старте, если пусто.
- Локализация имён: ключи `product.*` / `FoodCatalogLocalization` / `Products.xcstrings`.
- Редактор контента: `tools/ingredient-catalog-manager.html` + парсеры health-diet.ru.

## Рецепты

- Системный: `recipes-catalog.json` (~128) → seed с `catalogRecipeId`.
- Пользовательский: Application Support `recipes-user.json` + SwiftData (`userRecipeId`).
- Изображения каталога: `Resources/RecipeImages/<imageId>.jpg`.
- Редактор: `tools/recipe-catalog-manager.html`.
- Поля каталога включают `cookTimeMinutes`, ingredients по `catalogKey`, steps.

## Формат единиц

`gram` | `kilogram` | `milliliter` | `liter` | `piece` | `tablespoon` | `teaspoon` — как `MeasurementUnit`.

## Acceptance

- [ ] Чистая установка получает каталоги без ручного импорта JSON.
- [ ] Новый user recipe переживает перезапуск (SwiftData + user JSON).
- [ ] Каталоговый рецепт идентифицируется стабильным `catalogRecipeId`.
- [ ] Матчинг импорта использует те же `catalogKey`, что в food-catalog.
