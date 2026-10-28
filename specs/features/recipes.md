# F-REC — Библиотека и карточка рецепта

**Status:** shipped  
**Primary views:** `RecipeLibraryView`, `RecipeDetailView`, `AddRecipeView`, `RecipeCardView`, `AddIngredientSheet`  
**Related:** [import.md](import.md), [nutrition.md](nutrition.md), [catalogs.md](catalogs.md), [engagement.md](engagement.md)

## Цель

Единая библиотека каталоговых и пользовательских рецептов; создание/просмотр с нутриентами; позитивные сигналы (лайк/оценка) для запроса отзыва.

## Библиотека

- Поиск двухступенчатый:
  1. `matchesNameSearch` по локализованному названию;
  2. если пусто — отдельная секция «Похожие по ингредиенту» (`matchesIngredientSearch` по именам ингредиентов, **не** по шагам готовки).
- Quick filters: тип приёма, избранное, «мои», advanced filters.
- Advanced: ингредиенты-теги; режим «хотя бы один» / «все» (`matchAnyIngredient`).
- Источник списка: `RecipeCollections.libraryRecipes` / `catalogRecipes` — **дедуп** клонов генерации по `catalogRecipeId` (предпочтение инстансу без meals).
- Grid: adaptive columns по size class; wide readable width на iPad.
- Toolbar: Instagram-import CTA + `+` → `AddRecipeView`.
- Favorite / unfavorite каталоговых с confirm; после favorite on → `ReviewPromptService`.
- Empty state с Reset filters (bordered + accent).

## Создание / редактирование (`AddRecipeView`)

- PhotosPicker для фото.
- Название, servings, cook time (stepper 0…300, step 5; 0 = unknown).
- Ингредиенты: поиск по каталогу (`AddIngredientSheet` / `IngredientTagSearchField`), не длинный Picker.
- Поиск: кнопка clear при непустом тексте.
- Шаги готовки (plain / rich storage).
- Сохранение: SwiftData + запись в user recipes JSON через catalog store.
- КБЖУ на detail считаются из сопоставленных продуктов; отдельного ручного поля «калории» в форме нет (roadmap: улучшить UX авторасчёта в редакторе).

## Деталь рецепта

- Hero image; контент в readable-колонке на wide layout.
- Nutrition per serving (`NutritionCalculator`).
- Список ингредиентов; масштабирование отображаемых порций (`displayPortions`).
- Локализованные шаги.
- Sheet микронутриентов.
- Мета: cook time (если `hasCookTime`), community likes.
- Личный рейтинг 1…5; изменение → `ReviewPromptService` (см. [engagement.md](engagement.md)).

## Карточка (`RecipeCardView`)

Photo-first: изображение, название, meta (время / likes / tags по наличию).

## Acceptance

- [ ] Каталоговые и user recipes визуально разделены (фильтр «мои»).
- [ ] Ингредиент выбирается из каталога по поиску; в UI показывается `displayName`, не сырой `catalogKey`.
- [ ] Clear в поле поиска сбрасывает текст и возвращает фокус.
- [ ] При непустом name-match секция ингредиентов не показывается.
- [ ] При пустом name-match и ненулевом ingredient-match видна секция `search.byIngredient.*`.
- [ ] Клоны генерации с одним `catalogRecipeId` не троят карточку в библиотеке.
- [ ] КБЖУ на порцию согласованы с составом и servings.
- [ ] `cookTimeMinutes = 0` не показывается как «0 мин» (unknown).
- [ ] `userRating` clamp 0…5; `communityLikeCount` clamp 0…100.
- [ ] На regular width сетка использует >2 колонок при достаточной ширине.
