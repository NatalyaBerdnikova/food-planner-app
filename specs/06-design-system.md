# Design System

Канон визуального языка Food Planner. Детальный референс Kitchen Stories — корневой [`design.md`](../design.md); здесь — **что действует в продукте**.

## Позиционирование UI

| Зона приложения | Язык |
| --- | --- |
| Discover / Library / Recipe cards | Photo-first, воздух, секции-рельсы (Kitchen Stories) |
| Week plan / Nutrition / Shopping | Утилитарная ясность planner; карточки блюд внутри слотов — KS-style |
| Onboarding / Paywall | Hero gradient бренда, короткие тексты |

## Бренд-токены (`AppTheme`)

| Token | Значение / роль |
| --- | --- |
| `accent` | Зелёный `#1C5E4A`-диапазон — primary brand |
| `warmFill` | Тёплый оранжево-терракотовый акцент CTA / highlights |
| `heroGradient` | Тёмно-зелёный градиент онбординга / hero блоков |
| `cardRadius` | 16 continuous |
| `sectionSpacing` | 20 |
| `contentPadding` | 16 |
| `canvas` / `elevated` | System grouped / system background |

High contrast: отдельный `accent(for:highContrast:)`.

## Компоненты

| Компонент | Поведение |
| --- | --- |
| `RecipeCardView` | Доминирует фото; title + meta (время, likes) |
| `AppSectionCard` | Elevated surface, radius 16 |
| `AppSectionHeader` | Title + optional glyph в soft circle |
| `NutritionSummaryView` / progress | Макросы без dashboard-шума |
| `PlannedMealSlotView` | Слот приёма пищи в дне |
| Empty states | SF Symbol + short copy + один CTA |

## Правила (must)

1. Первое, что видит глаз на карточке рецепта — **еда**, не chrome.
2. Не вешать floating badges / promo chips поверх hero-фото.
3. Home не превращать в dashboard из виджетов: секции с одной идеей.
4. Один primary accent бренда; не копировать коралл KS буквально.
5. Motion: спокойный fade/slide; `MotionSafeSymbolModifier` чтит Reduce Motion.
6. Шаги готовки — читаемый body (на будущее cook-mode).

## Audit перед UI-мержем

1. Еда или chrome?
2. Можно ли убрать рамку/тень/бейдж без потери смысла?
3. Есть ли понятное время готовки на карточке (если известно)?
4. Не стал ли первый экран dashboard?
