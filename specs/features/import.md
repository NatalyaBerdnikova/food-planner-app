# F-IMP — Импорт рецептов

**Status:** shipped  
**Primary:** `ImportCoordinator`, `InstagramImportService`, `PasteImportSheet`, `ImportProgressView`, `ImportedRecipeReviewView`, Share Extension (`ShareViewController`)  
**Related:** [recipes.md](recipes.md), [catalogs.md](catalogs.md)

## Цель

Превратить Instagram-пост (или текст/JSON) в редактируемый draft рецепта с ингредиентами, привязанными к каталогу.

## Точки входа

| Вход | Механизм |
| --- | --- |
| Share Extension | Без compose UI: извлечь Instagram URL → App Group `pendingImportURL` + deep link `foodplanner://import?url=` → прогресс на root `ContentView` |
| Paste in-app | `PasteImportSheet` → `startImport(urlString:)` |
| Deep link | `onOpenURL` на `ContentView` (до/после bootstrap); query `url=` или consume App Group |
| Файл (сервис) | `RecipeImportService.importFromFile` (JSON / plain text) |

Share Extension: `UIViewController` + spinner (не `SLComposeServiceViewController`). Принимает URL/plain text с `instagram.com` / `instagr.am`. Extension завершается после `open` host app.

### Холодный старт / race

- Sheet прогресса и `onOpenURL` живут на корневом `ContentView`, не только на `mainApp`.
- Pending обрабатывается когда `canPresentImport` (bootstrap + onboarding + full access).
- Повтор при `scenePhase == .active`.
- App Group: `synchronize()` после save/consume; deep link с `url=` — запасной путь, если UserDefaults ещё не видны.

## Стадии (`ImportStage`)

1. `fetchingPost` — ScrapeCreators post info  
2. `readingContent` — caption + optional transcript  
3. `parsingRecipe` — LLM (`LLMRecipeParser`) или `CaptionFallbackParser`  
4. `matchingIngredients` — нормализация количества + `IngredientCatalogMatcher` (copy: «Подбираем ингредиенты»)  
5. `ready` — draft для review  

UI: `ImportProgressView` sheet (на iPad — form sizing); ошибки → failed + retry.

## Парсинг и матчинг

### LLM

- В промпт уходит каталог **на языке приложения** (`L10n.currentLanguageCode`): строки `catalogKey | localizedName` (ru или en), без обрезки критичной части списка.
- `rawName` в ответе — на том же языке; `catalogKey` только из списка или `null`.

### Количество в названии (`IngredientAmountParser`)

Перед матчингом из `rawName` вырезаются хвосты вида `50г`, `100 мл`, `2 стика`, `20`:

- очищенное имя → матчинг и UI «Нужно сопоставить»;
- quantity/unit → `suggestedQuantity` / `suggestedUnit` (и в matched draft);
- инструкции («примерно в 3 раза…», КБЖУ-комментарии) не режутся.

### Fuzzy match (`IngredientCatalogMatcher` + `IngredientNameStemmer`)

- Приоритет: валидный `catalogKey` из LLM → продукт в SwiftData.
- Иначе стемминг (RU/EN) + score по токенам (порог ≥ 70); короткие токены только exact; производные («рисовая мука» при запросе «рис») штрафуются.
- Unresolved: `rawName` (без единиц) + suggested amount.

## Review

`ImportedRecipeReviewView`:

- правка имени, шагов, matched ingredients;
- секция unresolved → tap → `AddIngredientSheet` с `initialSearchText` = очищенное имя и предзаполненными quantity/unit;
- в поиске продукта — кнопка clear (`×`), чтобы быстро стереть префилл и ввести своё;
- сохранение в библиотеку (`sourceURL` сохраняется).

## Ошибки

`RecipeImportError`: unreadable, invalid, network, instagramUnavailable, transcriptionFailed, parsingFailed, apiQuotaExceeded, apiUnauthorized.

## Конфиг

Ключи API — `ImportAPIConfig` (не в git; пример `ImportAPIConfig.example.swift`).

## Acceptance

- [ ] Pending URL из App Group обрабатывается один раз (`consume`); deep link с `url=` тоже стартует импорт.
- [ ] После Share приложение открывается и показывает progress sheet (в т.ч. cold start после bootstrap/paywall).
- [ ] Пользователь видит стадии прогресса до review.
- [ ] «Молоко 100 мл» в unresolved → имя «Молоко», справа «100 мл»; при ручном выборе те же значения в sheet.
- [ ] Unresolved не блокируют review (дозаполнение вручную).
- [ ] Успешный save создаёт user recipe с `sourceURL`.
- [ ] Не-Instagram URL из extension не сохраняется как pending.
