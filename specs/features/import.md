# F-IMP — Импорт рецептов

**Status:** shipped  
**Primary:** `ImportCoordinator`, `InstagramImportService`, `PasteImportSheet`, `ImportProgressView`, `ImportedRecipeReviewView`, Share Extension  
**Related:** [recipes.md](recipes.md), [catalogs.md](catalogs.md)

## Цель

Превратить Instagram-пост (или текст/JSON) в редактируемый draft рецепта с ингредиентами, привязанными к каталогу.

## Точки входа

| Вход | Механизм |
| --- | --- |
| Share Extension | URL → App Group `pendingImportURL` → `foodplanner://import` |
| Paste in-app | `PasteImportSheet` → `startImport(urlString:)` |
| Deep link | `onOpenURL` / query `url=` |
| Файл (сервис) | `RecipeImportService.importFromFile` (JSON / plain text) |

Share Extension принимает только URL/текст с `instagram.com`.

## Стадии (`ImportStage`)

1. `fetchingPost` — ScrapeCreators post info  
2. `readingContent` — caption + optional transcript  
3. `parsingRecipe` — LLM (`LLMRecipeParser`) или fallback caption parser  
4. `matchingIngredients` — `IngredientCatalogMatcher`  
5. `ready` — draft для review  

UI: `ImportProgressView` sheet; ошибки → failed + retry.

## Review

`ImportedRecipeReviewView`: правка имени, шагов, matched/unresolved ingredients, сохранение в библиотеку.

## Ошибки

`RecipeImportError`: unreadable, invalid, network, instagramUnavailable, transcriptionFailed, parsingFailed, apiQuotaExceeded, apiUnauthorized.

## Конфиг

Ключи API — `ImportAPIConfig` (не в git; пример `ImportAPIConfig.example.swift`).

## Acceptance

- [ ] Pending URL из App Group обрабатывается один раз (`consume`).
- [ ] Пользователь видит стадии прогресса до review.
- [ ] Unresolved ingredients не блокируют открытие review (пользователь может дозаполнить).
- [ ] Успешный save создаёт user recipe с `sourceURL`.
- [ ] Не-Instagram URL из extension не сохраняется как pending.
