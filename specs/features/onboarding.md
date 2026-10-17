# F-ONB — Онбординг

**Status:** shipped  
**Primary views:** `OnboardingFlowView`  
**Related:** [nutrition.md](nutrition.md), [subscription.md](subscription.md)

## Цель

Собрать профиль для расчёта дневных целей КБЖУ и пометить онбординг завершённым.

## Шаги

| Step | Содержание |
| --- | --- |
| welcome | Ценностные буллеты: импорт, макросы, микро |
| goal | `NutritionGoal`: lose / maintain / gain |
| body | пол, возраст, рост, вес, целевой вес |
| activity | `ActivityLevel` |
| reveal | Анимация/показ рассчитанных калорий и БЖУ |

Дополнительно в draft модели (могут задаваться в потоке/профиле): диеты, микро-фокус, `RecipeSourceHabit`.

## Поведение

- Progress header с долей шагов; back кроме welcome.
- Reduce Motion отключает декоративную анимацию шагов.
- По Finish: `AppSettings.apply(onboarding:nutrition:)` → `hasCompletedOnboarding = true`.
- Затем вызывается refresh подписки (переход к paywall или app).

## Acceptance

- [ ] Нельзя попасть в `MainTabView` без `hasCompletedOnboarding`.
- [ ] После finish цели в settings совпадают с `NutritionTargetCalculator.calculate`.
- [ ] Коэффициенты белка/жира зависят от выбранной `NutritionGoal`.
