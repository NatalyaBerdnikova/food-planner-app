# F-PLAN — Недельный план

**Status:** shipped  
**Primary views:** `WeekPlanView`, `WeekDayCarousel`, `DayPlanCardView`, `PlannedMealSlotView`, `AddMealSheet`  
**Related:** [shopping.md](shopping.md), [home.md](home.md)

## Цель

Разложить рецепты по дням и приёмам пищи на произвольную календарную неделю.

## Поведение

- Переключатель недель: стрелки ←/→; в заголовке диапазон дат.
- `WeekPlanService.weekPlan(forWeekStarting:)` создаёт неделю и 7 `DayPlan`, если нет.
- Активная неделя пишется в `AppSettings.activeWeekPlan`.
- Карусель дней: слоты meal types; пустой слот → `AddMealSheet` с preferred type.
- Фильтр рецептов в sheet: все / по типу приёма (`RecipeFilterTab`).
- После добавления meal — `syncShoppingItems` для displayed week.

## Out of scope (planned)

- Кнопка «Сегодня» в switcher (см. roadmap).

## Acceptance

- [ ] Можно спланировать будущие недели и листать назад.
- [ ] У каждого дня есть 4 концептуальных слота meal types (UI).
- [ ] Изменение состава meals обновляет shopping list той же недели.
- [ ] Повторный вход на ту же неделю не дублирует day plans.
