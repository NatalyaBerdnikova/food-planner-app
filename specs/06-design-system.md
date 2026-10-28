# Design System

Канон визуального языка Food Planner. Детальный референс Kitchen Stories — корневой [`design.md`](../design.md); здесь — **что действует в продукте**.

## Позиционирование UI

| Зона приложения | Язык |
| --- | --- |
| Discover / Library / Recipe cards | Photo-first, воздух, секции-рельсы (Kitchen Stories) |
| Week plan / Nutrition / Shopping | Утилитарная ясность planner; карточки блюд внутри слотов — KS-style |
| Onboarding / Paywall / Bootstrap | Hero gradient бренда, короткие тексты; loader → opacity crossfade |

## Бренд-токены (`AppTheme`)

| Token | Значение / роль |
| --- | --- |
| `accent` | Оранжевый brand tint (high-contrast вариант через `accent(for:highContrast:)`) |
| `accentSoft` | Мягкая заливка чипов / CTA |
| `warmFill` | Тёплый акцент highlights |
| `heroGradient` | Градиент онбординга / hero / bootstrap |
| `cardRadius` | 16 continuous |
| `sectionSpacing` | 24 |
| `contentPadding` | 16 |
| `minTapTarget` | 44 |
| `canvas` / `elevated` / `nestedFill` | System grouped surfaces |
| `readableContentWidth` | 720 — колонка контента на regular width |
| `formContentWidth` | 560 — onboarding / paywall / import progress |
| `wideContentWidth` | 1100 — библиотека / план |

High contrast: `accent(for:highContrast:)`.

## Адаптив (iPad / multitasking)

- Решения по `horizontalSizeClass`, не по idiom устройства (`layout.md` HIG).
- `appReadableWidth` / `appWideReadableWidth` / `appFormWidth` — центрирование и cap ширины.
- Рецептные сетки: `recipeGridColumns` (adaptive min width).
- План: `dayPlanColumns` — 1 колонка compact, 2 regular.
- Sheets: `appFormSheetPresentation()` → `presentationSizing(.form)`.
- Tabs: `.sidebarAdaptable`.

## Компоненты

| Компонент | Поведение |
| --- | --- |
| `RecipeCardView` | Доминирует фото; title + meta (время, likes) |
| `AppSectionCard` | Elevated surface, radius 16 |
| `AppSectionHeader` | Title + optional glyph в soft circle |
| `NutritionSummaryView` / progress | Макросы без dashboard-шума |
| `MealPlanTargetsCard` | Карточка целей / средних КБЖУ (генерация, экспорт, импорт) |
| `PlannedMealSlotView` | Слот приёма пищи в дне |
| `IngredientTagSearchField` | Поиск + clear (`×`) при непустом тексте |
| `WeekRangeSwitcher` | Общий переключатель недель (план / покупки / импорт плана) |
| Hints card (import paste) | Одна nested-карточка с 3 hint-rows в едином стиле |
| Empty states | SF Symbol + short copy + один CTA |
| `SparklesLoader` | Bootstrap; переход на app — только opacity (HIG motion) |

## Правила (must)

1. Первое, что видит глаз на карточке рецепта — **еда**, не chrome.
2. Не вешать floating badges / promo chips поверх hero-фото.
3. Home не превращать в dashboard из виджетов: секции с одной идеей.
4. Один primary accent бренда.
5. Motion: спокойный fade/slide; `MotionSafeSymbolModifier` / `motionSafeAnimation` чтят Reduce Motion.
6. Материалы поверх контента — solid overlays (`contentOverlayFill`), не glass на еде.
7. Hit targets ≥ 44pt.
8. На wide layout не растягивать текстовые формы на всю ширину экрана.
9. Modal sheets с формой: `.scrollBounceBehavior(.basedOnSize)` + `.presentationContentInteraction(.scrolls)` — без rubber-band «двойного» скролла.
10. Trial notifications и review copy — без pushy marketing / dark patterns.

## Audit перед UI-мержем

1. Еда или chrome?
2. Можно ли убрать рамку/тень/бейдж без потери смысла?
3. Есть ли понятное время готовки на карточке (если известно)?
4. Не стал ли первый экран dashboard?
5. Regular width: колонка читаемая? Сетка использует место? Sheet — form?
