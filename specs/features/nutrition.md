# F-NUT — Питание (КБЖУ и микро)

**Status:** shipped  
**Primary:** `NutritionTargetCalculator`, `NutritionCalculator`, `NutritionTargetProgressView`, `NutritionSummaryView`, `MicronutrientDetailSheet`  
**Related:** [onboarding.md](onboarding.md), [settings.md](settings.md), [home.md](home.md)

## Цель

Считать персональные дневные цели и фактическое питание из плана/рецептов; показывать микронутриенты.

## Расчёт целей

1. **BMR** — Mifflin–St Jeor (пол, вес, рост, возраст).
2. **TDEE** — BMR × `ActivityLevel.factor`.
3. **Белок / жир** — г на кг *целевого* веса; диапазоны 1…3 и 0.8…1.5; пресеты от `NutritionGoal`.
4. **Углеводы** — остаток калорий после белка и жира (4/9/4 ккал/г).

UI пересчёта: `NutritionTargetCalculatorSheet` из Settings.

## Фактическое питание

- Рецепт: сумма нутриентов ингредиентов (через `FoodProduct` + единицы) → на порцию / на 100 г.
- День: сумма nutrition meals дня.
- Progress: actual vs `AppSettings.targetNutrition`; статусы через `NutritionTargetStatus`.

## Микронутриенты

- Виды: `MicronutrientKind` (fiber, витамины, минералы — см. domain model).
- Фокус профиля: до **5** видов в Settings.
- Детализация по рецепту — sheet с рядами прогресса (`MicronutrientProgressRow`).

## Acceptance

- [ ] Изменение meals сегодня меняет Home progress.
- [ ] Пересчёт калькулятора обновляет target* в settings.
- [ ] Ручной ввод targets в Settings переопределяет рассчитанные значения.
- [ ] Нельзя выбрать больше 5 микро в фокусе.
