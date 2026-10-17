# Domain Model

Персистентность: **SwiftData**. Схема: `FoodPlannerSchema.modelTypes`.

```
AppSettings (singleton "main")
    └── activeWeekPlan → WeekPlan

WeekPlan
    ├── dayPlans[] → DayPlan
    │                  └── meals[] → Meal → Recipe?
    └── shoppingItems[] → ShoppingItem

Recipe
    ├── ingredients[] → Ingredient → FoodProduct?
    └── meals[] (обратная связь)

FoodProduct  (каталог продуктов)
```

## Сущности

### AppSettings

Единственная запись настроек пользователя.

| Поле | Смысл |
| --- | --- |
| `targetCalories/Protein/Fat/Carbs` | Дневные цели макросов |
| `activeWeekPlan` | Текущая активная неделя в UI |
| `favoriteCatalogRecipeIds` | Избранные id каталога |
| `isPro` / `isFree` | Доступ; `hasFullAccess = isPro \|\| isFree` |
| `hasCompletedOnboarding` | Флаг онбординга |
| `profile*` | Пол, возраст, рост, вес, цель веса, активность, цель (lose/maintain/gain), диеты, микро-фокус, привычный источник рецептов |

### FoodProduct

Продукт каталога. Питательность — **на 100 г**.

- Уникальный `catalogKey` (стабильный ключ локализации и матчинга).
- `category: IngredientCategory`, `defaultPieceWeightGrams`.
- Макросы: calories, protein, fat, carbs.
- Микро: fiber, витамины A/B6/B9/B12/C/D3/E/K, Ca, Mg, Zn, Se, Cr, Fe, K, I.

Bundled seed: `food-planner/Resources/food-catalog.json` (~492 продукта).

### Recipe

| Поле | Смысл |
| --- | --- |
| `catalogRecipeId` | Id из системного каталога; `nil` — не каталог |
| `userRecipeId` | Id пользовательского рецепта в `recipes-user.json` |
| `name`, `servings`, `imageData`, `sourceURL` | Базовые атрибуты |
| `steps` / `stepsRichTextData` | Шаги готовки |
| `cookTimeMinutes` | 0 = неизвестно |
| `communityLikeCount` | 0…100, обновляется при заходе |
| `userRating` | 0 = нет оценки; 1…5 |
| `*Per100g` | Макросы рецепта на 100 г (могут дублировать/кэшировать расчёт) |
| `ingredients` | Состав |

Инварианты:

- `isCatalogRecipe` ⇔ `catalogRecipeId != nil`
- `isUserCreated` ⇔ `catalogRecipeId == nil`

Bundled seed: `recipes-catalog.json` (~128 рецептов).

### Ingredient

Связь рецепта с продуктом (или свободное имя).

- `name`, `quantity`, `unit: MeasurementUnit`
- `category`, опционально `foodProduct`
- Расчёт нутриентов через продукт + нормализацию единиц (`UnitConverter` / `UnitNormalizer`)

### MealType

`breakfast` | `lunch` | `dinner` | `snack`

### Meal

Назначение рецепта на дату и тип приёма пищи; принадлежит `DayPlan`.

### DayPlan

Один календарный день внутри `WeekPlan` (`date` + `meals`).

### WeekPlan

Неделя с `weekStartDate` (начало календарной недели).

- `dayPlans` — 7 дней (создаются лениво через `WeekPlanService`).
- `shoppingItems` — материализованный список покупок.
- `aggregatedShoppingList` — вычисляемая агрегация из ингредиентов рецептов (для sync).

### ShoppingItem

Позиция списка: имя, количество, единица, категория, `isPurchased`, `isManual`.

### Enums профиля / расчёта

| Тип | Значения |
| --- | --- |
| `NutritionGoal` | lose, maintain, gain (задают г белка/жира на кг) |
| `DietPreference` | none, vegetarian, vegan, glutenFree, dairyFree, highProtein |
| `RecipeSourceHabit` | instagram, tiktok, blogs, books, improvisation |
| `BiologicalSex` | female, male |
| `ActivityLevel` | sedentary…veryActive (множители TDEE) |
| `MeasurementUnit` | gram, kilogram, milliliter, liter, piece, tablespoon, teaspoon |
| `IngredientCategory` | vegetables, greens, meat, fish, dairy, grains, fruits, nuts, seeds, spices, other |

### ImportedRecipeDraft (не SwiftData)

Временный объект импорта до сохранения: имя, URL, порции, шаги, image, matched ingredients, unresolved ingredients.

## Границы контекстов

| Контекст | Ответственность |
| --- | --- |
| Catalog | Seed, локализация ключей, favorites catalog ids |
| Planning | Week/Day/Meal CRUD, активная неделя |
| Shopping | Sync из плана, manual items, share |
| Nutrition | Calculator, progress, micro focus |
| Import | Instagram/scrape/LLM/match/review |
| Subscription | Adapty placement, paywall, persist access |
