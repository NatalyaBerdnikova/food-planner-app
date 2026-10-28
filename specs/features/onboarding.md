# F-ONB — Онбординг

**Status:** shipped  
**Primary views:** `OnboardingFlowView`, `OnboardingDayPreviewStep`  
**Related:** [nutrition.md](nutrition.md), [subscription.md](subscription.md), [week-plan.md](week-plan.md)

## Цель

Собрать профиль для расчёта дневных целей КБЖУ, показать ценность через превью дня и пометить онбординг завершённым.

## Шаги

| Step | Содержание |
| --- | --- |
| welcome | Ценностные буллеты: импорт, макросы, микро |
| goal | `NutritionGoal`: lose / maintain / gain |
| body | пол, возраст, рост, вес, целевой вес |
| activity | `ActivityLevel` |
| reveal | Анимация/показ рассчитанных калорий и БЖУ; CTA открыть превью дня |

Дополнительно в draft модели (могут задаваться в потоке/профиле): диеты, микро-фокус (дефолт fiber / D3 / iron), `RecipeSourceHabit`.

## Превью дня

- `OnboardingDayPreviewFactory` → `MealPlanGenerator.makePreviewDayPlan` под рассчитанные targets.
- Sheet `OnboardingDayPreviewStep`: слоты дня + nutrition vs target + микро chips.
- Snapshot пишется в `MealPlanGenerationPending.previewSnapshot` для post-paywall генерации недели.
- На dismiss — `discardPreviewDayPlan` (временный DayPlan убирается из контекста).

То же превью переиспользуется на `HardPaywallView`.

## Поведение

- Progress header с долей шагов; back кроме welcome.
- Контент шагов в `formContentWidth` (читаемо на iPad).
- Reduce Motion отключает декоративную анимацию шагов.
- По Finish: `AppSettings.apply(onboarding:nutrition:)` → `hasCompletedOnboarding = true`.
- Затем refresh подписки → Hard Paywall или app.

## Acceptance

- [ ] Нельзя попасть в `MainTabView` без `hasCompletedOnboarding`.
- [ ] После finish цели в settings совпадают с `NutritionTargetCalculator.calculate`.
- [ ] Коэффициенты белка/жира зависят от выбранной `NutritionGoal`.
- [ ] На iPad текст онбординга не растянут на всю ширину.
- [ ] Превью дня строится из каталога под цели; snapshot доступен для генерации после unlock.
