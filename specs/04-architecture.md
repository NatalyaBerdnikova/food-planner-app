# Architecture

## Стек

| Слой | Технология |
| --- | --- |
| UI | SwiftUI (`TabView` + `NavigationStack`) |
| Данные | SwiftData + локальный store (`LocalPersistence`) |
| Подписка | Adapty + StoreKit-обвязка (`PurchaseService`, `SubscriptionSession`); опционально mocks через `AppVars.useSubscriptionMocks` |
| Импорт | Share Extension → App Group + deep link → main app; ScrapeCreators; LLM HTTP; матчер каталога |
| Контент | Bundled JSON + Application Support (`recipes-user.json`) |
| Инструменты контента | `tools/*.html`, Python-парсеры (вне runtime приложения) |

## Targets

```
food-planner (main app)
FoodPlannerShareExtension (UIViewController, auto-share без compose)
Shared/ImportAppGroup.swift (App Group + URL scheme + deep link builder)
```

## Слои кода (main app)

```
Views/          экраны и UI-компоненты
Models/         SwiftData-модели и value-types
Helpers/        сервисы предметной логики (не UI)
Core/           подписка, AppDelegate, session, AppVars
Localization/   язык, L10n helpers
Resources/      JSON-каталоги, изображения рецептов
```

## Bootstrap и gating

Порядок в `ContentView`:

1. Seed `FoodCatalogSeeder` + `RecipeCatalogStore`.
2. Загрузка `AppSettings` / `SubscriptionSession`.
3. Если `!hasCompletedOnboarding` → `OnboardingFlowView`.
4. Иначе если `!hasFullAccess` → `HardPaywallView`.
5. Иначе `MainTabView` + attach `ImportCoordinator`.

Импорт (deep link / App Group / sheet прогресса и review):

- `onOpenURL`, `scenePhase`, sheet `ImportProgressView` / `ImportedRecipeReviewView` — на **корне** `ContentView`.
- Старт импорта только при `canPresentImport` (bootstrap + onboarding + full access); иначе URL/pending ждут.

## Навигация (IA)

Нижние вкладки (`MainTabView`):

| Tab | View | Роль |
| --- | --- | --- |
| Сегодня | `HomeView` | Питание дня, слоты, импорт CTA, рекомендации |
| План | `WeekPlanView` | Дни недели / слоты |
| Покупки | `ShoppingListView` | Чеклист активной недели |
| Рецепты | `RecipeLibraryView` | Библиотека + создание |

Настройки — из Home (toolbar).  
`TabView` style: `.sidebarAdaptable` (на iPad — sidebar).

### Адаптив (iPad / regular width)

- Контентные колонки: `appReadableWidth` / `appWideReadableWidth` / `appFormWidth` (`AppTheme`).
- Сетки рецептов: `GridItem.adaptive` по `horizontalSizeClass`.
- План недели: 2 колонки дней на regular width.
- Sheets: `presentationSizing(.form)` через `appFormSheetPresentation()`.

## Ключевые сервисы

| Сервис | Назначение |
| --- | --- |
| `WeekPlanService` | Создание/поиск недели, day plans, sync shopping |
| `AppSettingsService` | Singleton settings |
| `RecipeCatalogStore` | Seed каталога / user JSON |
| `FoodCatalogSeeder` | Seed продуктов |
| `RecipeFavoritesService` | Избранное каталога |
| `RecipeDiscoveryService` | Recipe of the day / random |
| `CommunitySocialStatsService` | Рандом like counts при заходе |
| `NutritionCalculator` | Нутриенты рецепта / дня |
| `NutritionTargetCalculator` | Цели из профиля |
| `ImportCoordinator` | Оркестрация UI-состояния импорта |
| `InstagramImportService` | Fetch + parse + match |
| `LLMRecipeParser` | Структурирование caption/transcript; каталог в промпте на языке UI |
| `IngredientAmountParser` | Вырезка quantity/unit из rawName |
| `IngredientNameStemmer` | Лёгкий стемминг RU/EN |
| `IngredientCatalogMatcher` | Сопоставление с `FoodProduct` |
| `IngredientCatalogPrompt` | Компактный каталог для LLM (один язык) |
| `PurchaseService` | Adapty paywall / purchase / restore |

## Поток импорта

```
[Instagram Share] → App Group pendingURL + foodplanner://import?url=
        ↓
ContentView.onOpenURL / checkPendingImport (после canPresentImport)
        ↓
ImportCoordinator.startImport
        ↓
ScrapeCreatorsClient (post + optional transcript)
        ↓
LLMRecipeParser / CaptionFallbackParser
        ↓
IngredientAmountParser.normalize → IngredientCatalogMatcher
        ↓
ImportProgressView → ImportedRecipeReviewView → Recipe в SwiftData (+ user JSON)
```

In-app: `PasteImportSheet` → тот же coordinator.

## Данные на диске

- SwiftData store URL — `LocalPersistence.storeURL`.
- User recipes — Application Support / `food-planner` / `recipes-user.json`.
- App Group UserDefaults — pending import URL (`ImportAppGroup`).

## Внешние зависимости (runtime)

- **Adapty** — paywall placement `basic_placement`, access level `premium` (если mocks выключены).
- **ScrapeCreators / LLM API** — через `ImportAPIConfig` (пример в `ImportAPIConfig.example.swift`).

## Инструменты (вне приложения)

См. `tools/README.md`: менеджеры каталогов HTML, парсеры health-diet.ru, remap ингредиентов. Не входят в app binary; питают JSON в `Resources/`.

## Тестирование

- `food-plannerTests`, `food-plannerUITests` — каркас Xcode.
- Preview: in-memory `FoodPlannerSchema.previewContainer` + `PreviewSampleData`.
- TestFlight paywall: `AppVars.useSubscriptionMocks` — mock-тарифы + Continue/Restore без StoreKit.
