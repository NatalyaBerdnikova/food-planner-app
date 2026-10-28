# F-SET — Настройки

**Status:** shipped  
**Primary views:** `SettingsView`, `NutritionTargetCalculatorSheet`  
**Related:** [nutrition.md](nutrition.md), [subscription.md](subscription.md), [onboarding.md](onboarding.md)

## Цель

Управление подпиской, профилем (read-only сводка), микро-фокусом, языком, дневными целями; опасные действия с данными (если есть в UI).

## Секции

1. **Subscription** — статус, restore.
2. **Profile** — goal, age, weight, target weight (из онбординга).
3. **Micronutrient focus** — toggles до 5 видов; при попытке включить 6-й — alert `settings.micros.limit.*` без изменения selection.
4. **Language** — system / en / ru (`AppLanguage`, `@AppStorage`); также влияет на язык каталога в LLM-импорте.
5. **Targets** — калькулятор (form sheet) + ручные поля calories/protein/fat/carbs.

## Acceptance

- [ ] Смена языка сразу влияет на UI (`applyAppLanguage`).
- [ ] Сохранение targets пишет в `AppSettings` и отражается на Home.
- [ ] Микро-фокус персистится в `profileMicronutrientFocusStorage`.
- [ ] Нельзя держать больше 5 микро включёнными.
- [ ] Restore подписки в Settings работает (при Previews mocks — как unlock, если доступен путь).
