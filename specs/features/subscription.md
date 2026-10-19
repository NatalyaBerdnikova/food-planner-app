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

## Режим тестовых тарифов (TestFlight / pre-release)

Флаг: `AppVars.useSubscriptionMocks` (сейчас `true` для всех конфигураций).

Когда включён:

- `DefaultPaywall` показывает mock-планы (месяц / год с trial / lifetime) без загрузки продуктов StoreKit/Adapty.
- Кнопка подписки / trial → короткий loader → `upgradeToPro` (полный доступ).
- «Восстановить» → тот же unlock без реальных покупок.

Перед релизом в App Store выставить `useSubscriptionMocks = false` и полагаться на Adapty/StoreKit.

## Поведение (production, mocks off)

- Загрузка paywall/products/eligibilities через Adapty.
- Purchase / restore → `PurchaseService.checkAccess` → persist в settings.
- При старте paywall — silent restore, если уже есть доступ.
- Settings: статус active/inactive; кнопка restore при наличии доступа.

## Acceptance

- [ ] Без доступа основной Tab UI скрыт.
- [ ] При `useSubscriptionMocks == true`: mock-тарифы видны; Continue и Restore открывают app без StoreKit.
- [ ] При `useSubscriptionMocks == false`: успешная покупка/restore открывает app без переустановки.
- [ ] `isFree` (если выставлен) обходит paywall так же, как Pro.
- [ ] Ошибки покупки (production) показываются alert'ом сессии.
