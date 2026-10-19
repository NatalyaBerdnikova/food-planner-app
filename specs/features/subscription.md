# F-SUB — Подписка

**Status:** shipped  
**Primary:** `HardPaywallView`, `DefaultPaywall`, `PurchaseService`, `SubscriptionSession`, Adapty  
**Related:** [onboarding.md](onboarding.md), [settings.md](settings.md)

## Цель

Ограничить полный доступ приложения подпиской Pro; дать restore и отображение статуса.

## Модель доступа

- Adapty access level: `premium`.
- Placement: `basic_placement`.
- Локально: `AppSettings.isPro` / `isFree`; `hasFullAccess = isPro || isFree`.
- `SubscriptionSession` — runtime state + alerts + loader overlay.

## Gating

После онбординга без `hasFullAccess` → только `HardPaywallView` (не tabs).

Paywall копирайт фич (маркетинг): AI-импорт, insights, plan — см. localization keys `home.proOffer.feature.*`.

## Поведение

- Загрузка paywall/products/eligibilities через Adapty.
- Purchase / restore → `PurchaseService.checkAccess` → persist в settings.
- Settings: статус active/inactive; кнопка restore при наличии доступа.

## Acceptance

- [ ] Без доступа основной Tab UI скрыт.
- [ ] Успешная покупка/restore открывает app без переустановки.
- [ ] `isFree` (если выставлен) обходит paywall так же, как Pro.
- [ ] Ошибки покупки показываются alert'ом сессии.
