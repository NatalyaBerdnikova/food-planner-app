# F-PLAN — Недельный план

**Status:** shipped  
**Primary views:** `WeekPlanView`, `WeekDayCarousel`, `DayPlanCardView`, `PlannedMealSlotView`, `AddMealSheet`  
**Related:** [shopping.md](shopping.md), [home.md](home.md)

## Цель

Разложить рецепты по дням и приёмам пищи на произвольную календарную неделю.

## Поведение

- Переключатель недель: `WeekRangeSwitcher` (общий с покупками).
- `WeekPlanService.weekPlan(forWeekStarting:)` создаёт неделю и 7 `DayPlan`, если нет.
- Активная неделя пишется в `AppSettings.activeWeekPlan`.
- Дни: `WeekDayCarousel` — 1 колонка на compact, **2 колонки** на regular width; expandable `DayPlanCardView`.
- Пустой слот → `AddMealSheet` (form sheet на iPad) с preferred type.
- Фильтр рецептов в sheet: все / по типу приёма (`RecipeFilterTab`).
- После добавления meal — `syncShoppingItems` для displayed week.
- Контент ограничен `wideContentWidth` на больших экранах.

## Out of scope (planned)

- Кнопка «Сегодня» в switcher (см. roadmap).

## Acceptance

- [ ] Можно спланировать будущие недели и листать назад.
- [ ] У каждого дня есть 4 концептуальных слота meal types (UI).
- [ ] Изменение состава meals обновляет shopping list той же недели.
- [ ] Повторный вход на ту же неделю не дублирует day plans.
- [ ] На iPad (regular) дни отображаются в две колонки.
