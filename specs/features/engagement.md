# F-ENG — Вовлечение (уведомления и отзыв)

**Status:** shipped  
**Primary:** `TrialEngagementNotifications`, `ReviewPromptService`, `AppNavigation`, `DeepLinkBridge`, bootstrap transition в `ContentView`  
**Related:** [subscription.md](subscription.md), [recipes.md](recipes.md), [week-plan.md](week-plan.md)

## Цель

Вернуть пользователя к ценности продукта во время free trial и попросить отзыв только после позитивного сигнала — без pushy marketing.

## Bootstrap transition

- Пока `!isSessionReady`: `AppTheme.heroGradient` + `SparklesLoader`.
- При готовности: `.transition(.opacity)` + `motionSafeAnimation` (0.45s easeInOut; Reduce Motion → 0.2s easeOut).
- Без кастомных «наклеечных» / диагональных wipe-анимаций.

## Trial local notifications

Источник окна триала: Adapty `accessLevels[premium]` с `activeIntroductoryOfferType == "free_trial"` (`activatedAt`, `expiresAt`).

| Kind | Когда | Deep link |
| --- | --- | --- |
| D1 | +1 день от activatedAt, 11:00 | `foodplanner://tab/plan` |
| D3 | +3 дня, 11:00 | `foodplanner://tab/shopping` |
| D7 | +7 дней, 11:00 | `foodplanner://tab/plan` |
| renewalMinus2 | expiresAt − 2 дня, 11:00 (если ещё до expires) | `foodplanner://tab/shopping` |

Поведение:

- Запрос authorization при первом sync (alert/sound/badge).
- Перед schedule — cancel старых id того же набора.
- Copy: план / список покупок (ключи `notification.trial.*`), **не** «оформите подписку».
- `interruptionLevel = .active`; category `trial.engagement`.
- Refresh: `ContentView` при появлении доступа / scene active; `AppDelegate.didLoadLatestProfile`.
- Cancel: нет Pro / нет trial window.
- Mock/Debug: `scheduleSyntheticTrial` после Continue на hard paywall при необходимости.

Тап → `UNUserNotificationCenterDelegate` → `DeepLinkBridge` → `AppNavigation.handleURL` → вкладка.

## Запрос отзыва (StoreKit)

Триггер: лайк (favorite on) или установка `userRating` 1…5 (`ReviewPromptService.considerAfterRecipeAppreciation`).

Гейты:

1. `hasFullAccess`.
2. Не первый календарный день (`noteAppOpen` фиксирует first open day; ask только если `today > firstDay`).
3. Не чаще 1 раза на `CFBundleShortVersionString`.
4. Не чаще чем раз в 14 дней.
5. Задержка ~1.2 с перед `requestReview()` (чтобы не рвать жест пользователя).

Системный диалог может не показаться (квота Apple) — это ожидаемо; сервис всё равно пишет lastVersion/lastDate после вызова.

## Acceptance

- [ ] На активном free trial планируются будущие (ещё не прошедшие) точки D1/D3/D7/renewal−2.
- [ ] Тексты уведомлений не содержат CTA оплаты.
- [ ] Тап открывает соответствующую вкладку.
- [ ] После окончания триала / потери доступа pending notifications сняты.
- [ ] Отзыв не запрашивается в календарный день первого открытия.
- [ ] Повторный лайк в той же версии не спамит запросом.
- [ ] Bootstrap → app — только opacity; Reduce Motion ускоряет/упрощает переход.
