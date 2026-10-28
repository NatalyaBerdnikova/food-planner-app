# F-CAT — Каталоги продуктов и рецептов

**Status:** shipped  
**Primary:** `FoodCatalogSeeder`, `RecipeCatalogStore`, `RecipeCollections`, Resources JSON, `tools/`  
**Related:** [recipes.md](recipes.md), [import.md](import.md), [nutrition.md](nutrition.md), [week-plan.md](week-plan.md)

## Цель

Локальная база продуктов и стартовых рецептов; расширение контента без backend; стабильные id для генерации плана и дедупа в UI.

## Продукты

- Файл: `food-planner/Resources/food-catalog.json` (~492).
- Seed в SwiftData при старте, если пусто.
- Локализация имён: `FoodCatalogLocalization` / translations en+ru в JSON.
- Для LLM-импорта: `IngredientCatalogPrompt.compactCatalogForPrompt(languageCode:)` — **один** язык UI (`catalogKey | name`), чтобы весь каталог помещался в лимит промпта.
- Редактор контента: `tools/ingredient-catalog-manager.html` + парсеры health-diet.ru.

## Рецепты

- Системный: `recipes-catalog.json` (~128) → seed с `catalogRecipeId`.
- Пользовательский: Application Support `recipes-user.json` + SwiftData (`userRecipeId`).
- Изображения каталога: `Resources/RecipeImages/<imageId>.jpg`.
- Редактор: `tools/recipe-catalog-manager.html`.
- Поля каталога включают `cookTimeMinutes`, ingredients по `catalogKey`, steps.
- Генерация плана создаёт клоны с тем же `catalogRecipeId`; библиотека/discovery используют `RecipeCollections.deduplicatedCatalogRecipes` (предпочтение «канонического» инстанса без meals).

## Формат единиц

`gram` | `kilogram` | `milliliter` | `liter` | `piece` | `tablespoon` | `teaspoon` — как `MeasurementUnit`.  
Нормализация сырых строк (г, мл, стик, ст.л, …) — `UnitNormalizer`.

## Acceptance

- [ ] Чистая установка получает каталоги без ручного импорта JSON.
- [ ] Новый user recipe переживает перезапуск (SwiftData + user JSON).
- [ ] Каталоговый рецепт идентифицируется стабильным `catalogRecipeId`.
- [ ] Матчинг импорта использует те же `catalogKey`, что в food-catalog.
- [ ] Промпт импорта на ru/en содержит полный (или почти полный) одноязычный список без критичной обрезки базовых продуктов.
- [ ] После генерации недели библиотека не показывает несколько карточек одного catalog id.
