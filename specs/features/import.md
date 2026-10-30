# F-IMP — Импорт рецептов

**Status:** shipped  
**Primary:** `ImportCoordinator`, `InstagramImportService`, `PasteImportSheet`, `ImportProgressView`, `ImportedRecipeReviewView`, Share Extension (`ShareViewController`)  
**Related:** [recipes.md](recipes.md), [catalogs.md](catalogs.md)  
**Не путать с** импортом **плана** (`.foodplan`) — см. [week-plan.md](week-plan.md).

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

### PasteImportSheet UX

- URL field + paste from clipboard.
- Единая nested-карточка подсказок (3 ряда):
  - общий footer copy;
  - privacy / server processing;
  - как шарить из Instagram (Share → Food Planner).
- Кнопка открыть сохранённые в Instagram (`InstagramAppLauncher.openSaved`).
- Sheet: `.scrollBounceBehavior(.basedOnSize)` + `.presentationContentInteraction(.scrolls)` — без «двойного» скролла контента.

### Холодный старт / race

- Sheet прогресса и `onOpenURL` живут на корневом `ContentView`, не только на `mainApp`.
- Pending обрабатывается когда `canPresentImport` (bootstrap + onboarding + full access).
- Повтор при `scenePhase == .active`.
- App Group: `synchronize()` после save/consume; deep link с `url=` — запасной путь, если UserDefaults ещё не видны.

## Стадии (`ImportStage`)

1. `fetchingPost` — ScrapeCreators post info (caption + thumbnail)  
2. `readingContent` — transcript (только если `IMPORT_FETCH_TRANSCRIPT=true`; по умолчанию выключено)  
3. `parsingRecipe` — LLM (`LLMRecipeParser`) или `CaptionFallbackParser`  
4. `matchingIngredients` — нормализация количества + `IngredientCatalogMatcher` (copy: «Подбираем ингредиенты»)  
5. `ready` — draft для review  

UI: `ImportProgressView` sheet (на iPad — form sizing); ошибки → failed + retry.

## Парсинг и матчинг

### LLM (только структура рецепта)

- Промпт **без** food-catalog: extraction-engine + few-shot (messy IG caption → JSON).
- Поля: name (не hook первой строки), servings/cookTime (null если нет), stepsIntro, steps, ingredients (`rawName`+qty+unit).
- `response_format: json_object`; temperature ~0.2; пост-очистка имени/emoji/маркеров шагов.
- Язык `rawName`/шагов — язык UI (ru|en).
- Сопоставление с каталогом — только локальный matcher.

### Количество в названии (`IngredientAmountParser`)

Перед матчингом из `rawName` вырезаются хвосты вида `50г`, `100 мл`, `2 стика`, `20`:

- очищенное имя → матчинг и UI «Нужно сопоставить»;
- quantity/unit → `suggestedQuantity` / `suggestedUnit` (и в matched draft);
- инструкции («примерно в 3 раза…», КБЖУ-комментарии) не режутся.

### Fuzzy match (`IngredientCatalogMatcher` + `IngredientNameStemmer`)

Отдельная стадия после LLM/fallback:

- Стемминг (RU/EN) + score по токенам (порог ≥ 70); короткие токены только exact; производные («рисовая мука» при запросе «рис») штрафуются.
- Unresolved: `rawName` (без единиц) + suggested amount.

Известный gap (roadmap): ручное сопоставление unresolved всё ещё friction; качество caption/transcript нестабильно.

## Review

`ImportedRecipeReviewView`:

- правка имени, шагов, matched ingredients;
- секция unresolved → tap → `AddIngredientSheet` с `initialSearchText` = очищенное имя и предзаполненными quantity/unit;
- в поиске продукта — кнопка clear (`×`);
- сохранение в библиотеку (`sourceURL` сохраняется).

## Ошибки

`RecipeImportError`: unreadable, invalid, network, instagramUnavailable, transcriptionFailed, parsingFailed, apiQuotaExceeded, apiUnauthorized.

## Конфиг

Ключи API — `ImportSecrets.plist` (gitignored; шаблон `ImportSecrets.example.plist`). `ImportAPIConfig` читает plist / env.

## Acceptance

- [ ] Pending URL из App Group обрабатывается один раз (`consume`); deep link с `url=` тоже стартует импорт.
- [ ] После Share приложение открывается и показывает progress sheet (в т.ч. cold start после bootstrap/paywall).
- [ ] Пользователь видит стадии прогресса до review.
- [ ] Paste sheet показывает три подсказки в одной карточке, включая Share из Instagram.
- [ ] «Молоко 100 мл» в unresolved → имя «Молоко», справа «100 мл»; при ручном выборе те же значения в sheet.
- [ ] Unresolved не блокируют review (дозаполнение вручную).
- [ ] Успешный save создаёт user recipe с `sourceURL`.
- [ ] Не-Instagram URL из extension не сохраняется как pending.
