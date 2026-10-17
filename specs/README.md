# Specs — Food Planner

Пакет спецификаций по принципам **Spec-Driven Development (SDD)**: поведение и ограничения продукта зафиксированы до (и независимо от) деталей реализации. Код — следствие спецификации; при расхождении правится либо код, либо спека (с явной фиксацией решения).

## Как пользоваться

| Задача | Документ |
| --- | --- |
| Зачем продукт и для кого | [01-product-vision.md](01-product-vision.md) |
| Что должно уметь приложение | [02-requirements.md](02-requirements.md) |
| Сущности и связи | [03-domain-model.md](03-domain-model.md) |
| Как устроена система | [04-architecture.md](04-architecture.md) |
| Сквозные сценарии | [05-user-journeys.md](05-user-journeys.md) |
| Поведение фич (acceptance) | [features/](features/) |
| Визуальный язык | [06-design-system.md](06-design-system.md) |
| Планируемые изменения | [07-roadmap.md](07-roadmap.md) |

## Правила SDD в этом репозитории

1. **Спека первична.** Новая фича начинается с обновления `features/*.md` (или requirements), затем код.
2. **Acceptance criteria** — проверяемые утверждения («Given / When / Then» или чеклист), не пожелания.
3. **Один источник правды.** Дубли с `design.md` / `todo.md` в корне: корневые файлы — рабочие черновики; `specs/` — канон для агентов и разработки.
4. **Статусы фич:** `shipped` (в продукте), `partial` (модель/UI частично), `planned` (только roadmap).
5. **Язык:** русский; идентификаторы кода и ключи локализации — как в репозитории.

## Карта фич

| ID | Фича | Статус | Файл |
| --- | --- | --- | --- |
| F-ONB | Онбординг и профиль питания | shipped | [features/onboarding.md](features/onboarding.md) |
| F-HOME | Сегодня / Home | shipped | [features/home.md](features/home.md) |
| F-PLAN | Недельный план | shipped | [features/week-plan.md](features/week-plan.md) |
| F-SHOP | Список покупок | shipped | [features/shopping.md](features/shopping.md) |
| F-REC | Библиотека и карточка рецепта | shipped | [features/recipes.md](features/recipes.md) |
| F-IMP | Импорт рецептов (Instagram / paste / share) | shipped | [features/import.md](features/import.md) |
| F-NUT | КБЖУ, микронутриенты, цели | shipped | [features/nutrition.md](features/nutrition.md) |
| F-SUB | Подписка (Adapty / StoreKit) | shipped | [features/subscription.md](features/subscription.md) |
| F-SET | Настройки | shipped | [features/settings.md](features/settings.md) |
| F-CAT | Каталоги продуктов и рецептов | shipped | [features/catalogs.md](features/catalogs.md) |

## Источники (снимок на момент сборки)

- Код: `food-planner/`, `FoodPlannerShareExtension/`, `Shared/`, `tools/`
- Дизайн-референс: корневой `design.md` (Kitchen Stories)
- Рабочий бэклог: корневой `todo.md`
