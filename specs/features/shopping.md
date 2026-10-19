# F-SHOP — Список покупок

**Status:** shipped  
**Primary views:** `ShoppingListView`  
**Related:** [week-plan.md](week-plan.md), [catalogs.md](catalogs.md)

## Цель

Чеклист продуктов на выбранную неделю: из рецептов плана + ручные позиции. Можно переключиться на следующую неделю и закупиться заранее.

## Поведение

- Источник: `WeekPlan.shoppingItems` выбранной недели (`WeekRangeSwitcher` + `WeekPlanService.weekPlan(..., setAsActive: false)`).
- Sync: агрегация ингредиентов всех meals недели по ключу `name|unit`, сумма quantity, категория продукта.
- UI: переключатель недели как в плане; секции по `IngredientCategory.shoppingListOrder`; купленные ниже некупленных внутри сортировки.
- Toggle purchased на row.
- `+` — ручной item (`isManual`); swipe delete только для manual.
- Share sheet — текстовый экспорт списка.

## Empty state

Нет items → `ContentUnavailableView` с подсказкой заполнить план.

## Acceptance

- [ ] Два одинаковых продукта из разных рецептов сливаются в одну строку с суммой.
- [ ] Отметка «куплено» сохраняется в SwiftData.
- [ ] Ручная позиция не исчезает при следующем sync авто-агрегации (политика sync должна сохранять purchased/manual — проверять в `WeekPlanService.syncShoppingItems`).
- [ ] Share доступен при непустом списке.
- [ ] Переключатель недели меняет список без смены active week plan.
