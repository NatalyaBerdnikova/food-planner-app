# F-SHOP — Список покупок

**Status:** shipped  
**Primary views:** `ShoppingListView`  
**Related:** [week-plan.md](week-plan.md), [catalogs.md](catalogs.md), [engagement.md](engagement.md)

## Цель

Чеклист продуктов на выбранную неделю: из рецептов плана + ручные позиции. Можно переключиться на следующую неделю и закупиться заранее. Trial-пуши D3 / renewal−2 ведут на эту вкладку.

## Поведение

- Источник: `WeekPlan.shoppingItems` выбранной недели (`WeekRangeSwitcher` + `WeekPlanService.weekPlan(..., setAsActive: false)`).
- Sync: агрегация ингредиентов всех meals недели по ключу `name|unit`, сумма quantity, категория продукта.
- UI: переключатель недели как в плане; секции по `IngredientCategory.shoppingListOrder`; купленные ниже некупленных внутри сортировки.
- Toggle purchased на row.
- `+` — ручной item через `AddIngredientSheet` (form sheet на iPad; clear в поиске); swipe delete только для manual.
- Share sheet — текстовый экспорт списка.
- Очистка плана на вкладке План удаляет и shopping items той недели.

## Empty state

Нет items → `ContentUnavailableView` с подсказкой заполнить план (или сгенерировать).

## Acceptance

- [ ] Два одинаковых продукта из разных рецептов сливаются в одну строку с суммой.
- [ ] Отметка «куплено» сохраняется в SwiftData.
- [ ] Ручная позиция не исчезает при следующем sync авто-агрегации (политика sync должна сохранять purchased/manual — проверять в `WeekPlanService.syncShoppingItems`).
- [ ] Share доступен при непустом списке.
- [ ] Переключатель недели меняет список без смены active week plan.
- [ ] Deep link `foodplanner://tab/shopping` открывает эту вкладку.
