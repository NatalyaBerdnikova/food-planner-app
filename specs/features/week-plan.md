# F-PLAN — Недельный план

**Status:** shipped  
**Primary views:** `WeekPlanView`, `WeekDayCarousel`, `DayPlanCardView`, `PlannedMealSlotView`, `AddMealSheet`, `GenerateWeekPlanSheet`, `WeekPlanGenerationProgressView`, `ExportWeekPlanSheet`, `ImportWeekPlanSheet`  
**Related:** [shopping.md](shopping.md), [home.md](home.md), [nutrition.md](nutrition.md), [onboarding.md](onboarding.md)

## Цель

Разложить рецепты по дням и приёмам пищи на произвольную календарную неделю; уметь сгенерировать план под цели, очистить его и обменяться файлом `.foodplan`.

## Планирование вручную

- Переключатель недель: `WeekRangeSwitcher` (общий с покупками / импортом).
- `WeekPlanService.weekPlan(forWeekStarting:)` создаёт неделю и 7 `DayPlan`, если нет.
- Активная неделя пишется в `AppSettings.activeWeekPlan`.
- Дни: `WeekDayCarousel` — 1 колонка на compact, **2 колонки** на regular width; expandable `DayPlanCardView`.
- Пустой слот → `AddMealSheet` (form sheet) с preferred type.
- Поиск в sheet: сначала `matchesNameSearch`; если пусто — секция «Похожие по ингредиенту» (`matchesIngredientSearch`, без шагов готовки).
- После добавления meal — `syncShoppingItems` для displayed week.
- Контент ограничен `wideContentWidth` на больших экранах.
- Large navigation title; scroll к сегодняшнему дню через iOS 18+ `.scrollPosition($scrollPosition)` + `ScrollPosition` (Reduce Motion — без анимации).

## Генерация плана

- Toolbar sparkles → `GenerateWeekPlanSheet` с `MealPlanTargetsCard` (цели + микро-фокус).
- `WeekPlanGenerationCoordinator` → `MealPlanGenerator.generateWeek`:
  - стадии: pickingRecipes → fillingDays → checkingMacros → saving → ready;
  - подбор из видимых каталоговых рецептов под `targetNutrition` (soft band coverage);
  - клоны `Recipe` с тем же `catalogRecipeId` для meals;
  - variety: избегает повторов id across week.
- Progress sheet: `WeekPlanGenerationProgressView`.
- После paywall unlock: `MealPlanGenerationPending` может запустить генерацию с pinned today из preview snapshot (`replaceExisting: false` для остальных заполненных дней).

## Поделиться планом (экспорт)

1. Menu → «Поделиться планом» → `WeekPlanTransferCoordinator.beginExport`.
2. `ExportWeekPlanSheet`: summary (дни/meals), карточка **средних** дневных КБЖУ, поле имени файла + `.foodplan`.
3. Confirm → temp file → system Share (`WeekPlanSharePresentation`).
4. Документ: `FoodPlanDocument` (targets опционально, days по `dayOffset` 0…6, вложенные рецепты/ингредиенты).

## Импорт плана

1. Menu → fileImporter (`.foodplan` / json / data) или `onOpenURL` файла.
2. `ImportWeekPlanSheet`: выбор целевой недели (`WeekRangeSwitcher`), summary, avg КБЖУ / targets из файла, режим:
   - `replaceWeek` — заменить meals недели;
   - `fillEmptyDaysOnly` — только пустые дни.
3. Weekday из файла ложится на тот же weekday целевой недели (преимущество: любая календарная неделя без сдвига дней).
4. Apply → `WeekPlanTransferService.apply` + sync shopping.

## Очистить план

- Menu → destructive «Очистить план» (disabled, если нет meals и shopping items).
- Alert confirmation → `WeekPlanService.clearPlan` (все meals дней + все shopping items).

## Out of scope (planned)

- Кнопка «Сегодня» в switcher (см. roadmap R-09).

## Acceptance

- [ ] Можно спланировать будущие недели и листать назад.
- [ ] У каждого дня есть 4 концептуальных слота meal types (UI).
- [ ] Изменение состава meals обновляет shopping list той же недели.
- [ ] Повторный вход на ту же неделю не дублирует day plans.
- [ ] На iPad (regular) дни отображаются в две колонки.
- [ ] Генерация заполняет неделю и обновляет shopping.
- [ ] Экспорт предлагает имя файла и показывает avg КБЖУ до Share.
- [ ] Импорт с `fillEmptyDaysOnly` не затирает уже заполненные дни.
- [ ] Clear удаляет и meals, и shopping items после confirm.
- [ ] Large title корректно компактится при скролле (ScrollPosition path).
