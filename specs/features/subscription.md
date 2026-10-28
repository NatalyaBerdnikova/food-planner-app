# F-SUB — Подписка

**Status:** shipped  
**Primary:** `HardPaywallView`, `DefaultPaywall`, `PurchaseService`, `SubscriptionSession`, Adapty  
**Related:** [onboarding.md](onboarding.md), [settings.md](settings.md), [engagement.md](engagement.md), [week-plan.md](week-plan.md)

## Цель

Ограничить полный доступ приложения подпиской Pro; дать restore и отображение статуса; после unlock — опционально продолжить генерацию недели из превью.

## Модель доступа

- Adapty access level: `premium`.
- Placement: `basic_placement`.
- Локально: `AppSettings.isPro` / `isFree`; `hasFullAccess = isPro || isFree`.
- `SubscriptionSession` — runtime state + alerts + loader overlay.

## Gating

После онбординга без `hasFullAccess` → только `HardPaywallView` (не tabs).

Paywall показывает превью «День 1» (`OnboardingDayPreviewStep`) и маркетинговые фичи (AI-импорт, insights, plan) — ключи `home.proOffer.feature.*`.

Успешный unlock / Continue:

- `MealPlanGenerationPending.markNeedsGeneration()` — чтобы после входа в tabs достроить неделю.
- При free trial (Adapty) — `TrialEngagementNotifications.refreshFromAdapty` (см. [engagement.md](engagement.md)).

## Режимы разблокировки

| Режим | Флаг / условие | Поведение |
| --- | --- | --- |
| Production | `useSubscriptionMocks == false` (default) | Реальные продукты Adapty/StoreKit |
| Xcode Previews | `useSubscriptionMocks == true` | Mock-тарифы; Continue/Restore → Pro без StoreKit |
| Debug / TestFlight sandbox | `allowsContinueWithoutSubscription` | CTA Continue без покупки; synthetic trial schedule при необходимости |

Перед App Store релизом убедиться: mocks только в Previews; sandbox Continue не попадает в App Store build без sandbox receipt.

## Поведение (production)

- Загрузка paywall/products/eligibilities через Adapty.
- Purchase / restore → `PurchaseService.checkAccess` → persist в settings.
- При старте paywall — silent restore, если уже есть доступ.
- Settings: статус active/inactive; кнопка restore при наличии доступа.
- Profile updates через `AppDelegate` / `AdaptyDelegate` → session + trial notifications sync.

## Acceptance

- [ ] Без доступа основной Tab UI скрыт.
- [ ] При `useSubscriptionMocks == true` (Previews): mock-тарифы; Continue и Restore открывают app без StoreKit.
- [ ] При production: успешная покупка/restore открывает app без переустановки.
- [ ] `isFree` (если выставлен) обходит paywall так же, как Pro.
- [ ] Ошибки покупки (production) показываются alert'ом сессии.
- [ ] После unlock с preview snapshot планируется генерация текущей недели.
- [ ] Активный free trial приводит к schedule engagement notifications.
