# Architecture

## Стек

| Слой | Технология |
| --- | --- |
| UI | SwiftUI (`TabView` + `NavigationStack`) |
| Данные | SwiftData + локальный store (`LocalPersistence`) |
| Подписка | Adapty + StoreKit-обвязка (`PurchaseService`, `SubscriptionSession`) |
| Импорт | Share Extension → App Group → main app; ScrapeCreators; LLM HTTP; каталог-матчер |
| Контент | Bundled JSON + Application Support (`recipes-user.json`) |
| Инструменты контента | `tools/*.html`, Python-парсеры (вне runtime приложения) |

## Targets

```
food-planner (main app)
FoodPlannerShareExtension (SLComposeServiceViewController)
Shared/ImportAppGroup.swift (App Group + URL scheme)
```

## Слои кода (main app)

```
Views/          экраны и UI-компоненты
Models/         SwiftData-модели и value-types
Helpers/        сервисы предметной логики (не UI)
Core/           подписка, AppDelegate, session
Localization/   язык, L10n helpers
Resources/      JSON-каталоги, изображения рецептов
```

## Bootstrap и gating

Порядок в `ContentView`:

1. Seed `FoodCatalogSeeder` + `RecipeCatalogStore`.
2. Загрузка `AppSettings` / `SubscriptionSession`.
3. Если `!hasCompletedOnboarding` → `OnboardingFlowView`.
4. Иначе если `!hasFullAccess` → `HardPaywallView`.
5. Иначе `MainTabView` + attach `ImportCoordinator`, проверка pending import.

## Навигация (IA)

Нижние вкладки (`MainTabView`):

| Tab | View | Роль |
| --- | --- | --- |
| Сегодня | `HomeView` | Питание дня, слоты, импорт CTA, рекомендации |
| План | `WeekPlanView` | Карусель дней / слоты недели |
| Покупки | `ShoppingListView` | Чеклист активной недели |
| Рецепты | `RecipeLibraryView` | Библиотека + создание |

Настройки — из Home (toolbar).  
`TabView` style: `.sidebarAdaptable` (iPad-friendly).

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
| `LLMRecipeParser` | Структурирование caption/transcript |
| `IngredientCatalogMatcher` | Сопоставление с `FoodProduct` |
| `PurchaseService` | Adapty paywall / purchase / restore |

## Поток импорта

```
[Instagram Share] → App Group pendingURL → foodplanner://import
        ↓
ImportCoordinator.startImport
        ↓
ScrapeCreatorsClient (post + optional transcript)
        ↓
LLMRecipeParser / CaptionFallbackParser
        ↓
IngredientCatalogMatcher
        ↓
ImportedRecipeReviewView → Recipe в SwiftData (+ user JSON)
```

In-app: `PasteImportSheet` → тот же coordinator.

## Данные на диске

- SwiftData store URL — `LocalPersistence.storeURL`.
- User recipes — Application Support / `food-planner` / `recipes-user.json`.
- App Group UserDefaults — только pending import URL.

## Внешние зависимости (runtime)

- **Adapty** — paywall placement `basic_placement`, access level `premium`.
- **ScrapeCreators / LLM API** — через `ImportAPIConfig` (пример в `ImportAPIConfig.example.swift`).

## Инструменты (вне приложения)

См. `tools/README.md`: менеджеры каталогов HTML, парсеры health-diet.ru, remap ингредиентов. Не входят в app binary; питают JSON в `Resources/`.

## Тестирование

- `food-plannerTests`, `food-plannerUITests` — каркас Xcode.
- Preview: in-memory `FoodPlannerSchema.previewContainer` + `PreviewSampleData`.
