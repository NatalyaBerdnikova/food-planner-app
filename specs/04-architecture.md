# Architecture

## Стек

| Слой | Технология |
| --- | --- |
| UI | SwiftUI (`TabView` + `NavigationStack`) |
| Данные | SwiftData + локальный store (`LocalPersistence`) |
| Подписка | Adapty + StoreKit-обвязка (`PurchaseService`, `SubscriptionSession`); mocks только Previews |
| Импорт рецептов | Share Extension → App Group + deep link → main app; ScrapeCreators; LLM HTTP; матчер каталога |
| Обмен планом | Codable `.foodplan` + `fileImporter` / ShareLink / `onOpenURL` |
| Уведомления | `UNUserNotificationCenter` (локальные trial reminders) |
| Аналитика | Firebase Analytics через фасад `AppAnalytics` (no-op без `GoogleService-Info.plist`) |
| Отзыв | StoreKit `RequestReviewAction` через `ReviewPromptService` |
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
Core/           подписка, AppDelegate, session, AppVars, DeepLinkBridge
Localization/   язык, L10n helpers
Resources/      JSON-каталоги, изображения рецептов
```

## Bootstrap и gating

Порядок в `ContentView`:

1. Seed `FoodCatalogSeeder` + `RecipeCatalogStore`.
2. Загрузка `AppSettings` / `SubscriptionSession`.
3. Пока `!isSessionReady` — hero gradient + `SparklesLoader`.
4. Готовность → opacity crossfade (0.45s easeInOut; Reduce Motion → 0.2s easeOut).
5. Если `!hasCompletedOnboarding` → `OnboardingFlowView`.
6. Иначе если `!hasFullAccess` → `HardPaywallView`.
7. Иначе `MainTabView` + attach coordinators; optional `startPendingGenerationIfNeeded`.

Импорт рецептов и обмен планом (sheets) живут на **корне** `ContentView`.

Старт Instagram-импорта только при `canPresentImport` (bootstrap + onboarding + full access); иначе URL/pending ждут.

## Навигация (IA)

Нижние вкладки (`MainTabView` + `AppNavigation`):

| Tab | View | Роль |
| --- | --- | --- |
| Сегодня | `HomeView` | Питание дня, слоты, импорт CTA, рекомендации |
| План | `WeekPlanView` | Дни недели / генерация / обмен / очистка |
| Покупки | `ShoppingListView` | Чеклист активной недели |
| Рецепты | `RecipeLibraryView` | Библиотека + создание |

Настройки — из Home (toolbar).  
`TabView` style: `.sidebarAdaptable` (на iPad — sidebar).

### Deep links (`foodplanner://`)

| URL | Действие |
| --- | --- |
| `foodplanner://import?url=` | Instagram import (App Group fallback) |
| `foodplanner://tab/plan` | Вкладка План (`AppNavigation`) |
| `foodplanner://tab/shopping` | Вкладка Покупки |
| `foodplanner://tab/today` | Вкладка Сегодня |
| `foodplanner://tab/recipes` | Вкладка Рецепты |
| file URL `.foodplan` | `WeekPlanTransferCoordinator.importFromFile` |

Тап по trial-уведомлению → `DeepLinkBridge` → `AppNavigation.handleURL`.

### Адаптив (iPad / regular width)

- Контентные колонки: `appReadableWidth` / `appWideReadableWidth` / `appFormWidth` (`AppTheme`).
- Сетки рецептов: `GridItem.adaptive` по `horizontalSizeClass`.
- План недели: 2 колонки дней на regular width.
- Sheets: `presentationSizing(.form)` через `appFormSheetPresentation()`.

## Ключевые сервисы

| Сервис | Назначение |
| --- | --- |
| `WeekPlanService` | Создание/поиск недели, day plans, clear, sync shopping |
| `MealPlanGenerator` | Автоподбор рецептов под цели; клоны для meals; preview day |
| `WeekPlanGenerationCoordinator` | UI-состояние генерации + pending после paywall |
| `WeekPlanTransferService` | Serialize/deserialize `.foodplan`, apply modes |
| `WeekPlanTransferCoordinator` | Export sheet → share file; import preview/apply |
| `AppSettingsService` | Singleton settings |
| `RecipeCatalogStore` | Seed каталога / user JSON |
| `FoodCatalogSeeder` | Seed продуктов |
| `RecipeFavoritesService` / `RecipeCollections` | Избранное + дедуп каталога |
| `RecipeDiscoveryService` | Recipe of the day / random |
| `CommunitySocialStatsService` | Рандом like counts при заходе |
| `NutritionCalculator` | Нутриенты рецепта / дня |
| `NutritionTargetCalculator` | Цели из профиля |
| `ImportCoordinator` | Оркестрация UI-состояния импорта рецептов |
| `InstagramImportService` | Fetch + parse + match |
| `LLMRecipeParser` | Структурирование caption/transcript |
| `IngredientAmountParser` | Вырезка quantity/unit из rawName |
| `IngredientNameStemmer` | Лёгкий стемминг RU/EN |
| `IngredientCatalogMatcher` | Сопоставление с `FoodProduct` |
| `PurchaseService` | Adapty paywall / purchase / restore |
| `AppNavigation` | Selected tab + tab deep links |
| `TrialEngagementNotifications` | Schedule/cancel trial locals |
| `ReviewPromptService` | Gating `requestReview` |
| `AppAnalytics` | Firebase events / user properties; activation once |

## Поток импорта рецепта

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

## Поток генерации плана

```
Toolbar sparkles / post-paywall pending
        ↓
GenerateWeekPlanSheet (targets card) → WeekPlanGenerationCoordinator.startGeneration
        ↓
MealPlanGenerator: picking → filling → macros → saving
        ↓
Клоны Recipe в DayPlan.meals + syncShoppingItems
```

Превью онбординга/paywall пишет `MealPlanGenerationPending.previewSnapshot`; после unlock сегодня может быть pinned.

## Поток обмена планом

```
Export: WeekPlan → FoodPlanDocument → ExportWeekPlanSheet (имя + avg КБЖУ) → temp .foodplan → Share
Import: fileImporter / onOpenURL → ImportWeekPlanSheet (неделя + mode + avg) → apply → sync shopping
```

## Данные на диске

- SwiftData store URL — `LocalPersistence.storeURL`.
- User recipes — Application Support / `food-planner` / `recipes-user.json`.
- App Group UserDefaults — pending import URL (`ImportAppGroup`).
- UserDefaults — review gating, meal-plan pending snapshot, first open day.

## Внешние зависимости (runtime)

- **Adapty** — paywall placement `basic_placement`, access level `premium`.
- **ScrapeCreators / LLM API** — через `ImportAPIConfig` (пример в `ImportAPIConfig.example.swift`).

## Инструменты (вне приложения)

См. `tools/README.md`: менеджеры каталогов HTML, парсеры health-diet.ru, remap ингредиентов. Не входят в app binary; питают JSON в `Resources/`.

## Тестирование

- `food-plannerTests`, `food-plannerUITests` — каркас Xcode.
- Preview: in-memory `FoodPlannerSchema.previewContainer` + `PreviewSampleData`; `useSubscriptionMocks == true` в Previews.
- Debug / TestFlight sandbox: `allowsContinueWithoutSubscription` — Continue без StoreKit.
