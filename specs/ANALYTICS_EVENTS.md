# События Firebase Analytics / Google Analytics (GA4)

Приложение: планирование питания, жёсткий paywall, триал 14 дней.

Именование: `snake_case`, ≤40 символов. Где возможно — [рекомендуемые события Firebase](https://firebase.google.com/docs/analytics/measure-inapp-purchases); остальное — custom.

Параметры: ≤40 символов, значения-строки ≤100. Не передавать PII (имя, email, точный вес как идентификатор).

---

## 1. Онбординг

| Событие | Тип | Когда слать | Параметры |
|---------|-----|-------------|-----------|
| `tutorial_begin` | recommended | Старт онбординга | `source` (`first_open` / `reinstall`) |
| `onboarding_step_view` | custom | Показ шага | `step_name`, `step_index` (1–3) |
| `onboarding_step_complete` | custom | Шаг успешно пройден | `step_name`, `step_index` |
| `onboarding_goal_set` | custom | Цель сохранена | `goal_type` (`lose` / `maintain` / `gain`), `pace` (если есть) |
| `onboarding_targets_ready` | custom | Макросы рассчитаны | `calories`, `protein_g`, `fat_g`, `carbs_g` |
| `tutorial_complete` | recommended | Анкета завершена, до превью/paywall | `steps_completed` |

`step_name` примеры: `weight`, `goal`, `activity`.

---

## 2. Превью плана (до paywall)

| Событие | Тип | Когда слать | Параметры |
|---------|-----|-------------|-----------|
| `plan_preview_view` | custom | Показ «День 1» | `calories`, `meals_count` |
| `plan_preview_meal_open` | custom | Тап по приёму пищи | `meal_type` (`breakfast` / `lunch` / `dinner` / `snack`) |
| `plan_preview_cta_tap` | custom | Тап «Открыть неделю» / дальше на paywall | `cta_name` |

---

## 3. Paywall и подписка

| Событие | Тип | Когда слать | Параметры |
|---------|-----|-------------|-----------|
| `paywall_view` | custom | Показ paywall | `trigger` (`onboarding` / `feature_gate` / `settings`), `default_plan` |
| `paywall_plan_select` | custom | Выбор тарифа | `plan_id` (`monthly` / `yearly` / `lifetime`), `has_trial` (bool) |
| `paywall_cta_tap` | custom | Тап основной кнопки | `plan_id`, `cta_text` |
| `paywall_restore_tap` | custom | Тап «Восстановить» | — |
| `paywall_link_tap` | custom | Terms / Privacy | `link_type` |
| `paywall_dismiss` | custom | Закрытие, если появится | `plan_id` |
| `begin_checkout` | recommended | Старт StoreKit purchase sheet | `item_id`, `value`, `currency` |
| `purchase` | recommended | Успешная покупка / старт подписки | `item_id`, `value`, `currency`, `transaction_id` |
| `trial_start` | custom | Старт introductory offer / free trial | `plan_id`, `trial_days` (`14`) |
| `purchase_error` | custom | Ошибка / отмена sheet | `plan_id`, `error_code`, `is_user_cancelled` (bool) |
| `restore_result` | custom | Результат restore | `success` (bool), `has_active_entitlement` (bool) |

`plan_id` держать стабильным и тем же, что в StoreKit product id mapping.

Для подписок дополнительно включить **Firebase/GA4 in-app purchase & subscription reporting** (App Store Server Notifications / RevenueCat и т.п., если используете) — дублировать вручную только то, чего нет в автосборе.

---

## 4. Активация продукта

| Событие | Тип | Когда слать | Параметры |
|---------|-----|-------------|-----------|
| `plan_week_view` | custom | Открыта неделя | `source` (`home` / `onboarding` / `push`) |
| `plan_day_view` | custom | Открыт день | `day_index`, `is_today` (bool) |
| `meal_open` | custom | Открыт приём пищи / рецепт | `meal_type`, `source` |
| `plan_edit` | custom | Замена блюда / правка плана | `edit_type` (`swap` / `remove` / `add`) |
| `plan_save` | custom | План сохранён | `days_count` |
| `shopping_list_open` | custom | Открыт список покупок | `items_count` |
| `shopping_list_item_check` | custom | Отметил продукт | `checked` (bool) |
| `shopping_list_share` | custom | Шаринг списка | `method` (если известно) |
| `share` | recommended | Системный share | `content_type` (`shopping_list` / `meal` / `plan`) |
| `instagram_import_start` | custom | Старт импорта | `source` |
| `instagram_import_success` | custom | Успешный импорт | `items_count` (если есть) |
| `instagram_import_error` | custom | Ошибка импорта | `error_code` |
| `micronutrients_view` | custom | Экран микронутриентов | — |

### Activation (для аудиторий / BigQuery)

Считайте activated, если за D0–D1 было ≥1 из:
- `plan_save`
- `shopping_list_open`
- `instagram_import_success`
- `plan_edit`

Опционально дублируйте одним событием:

| Событие | Когда | Параметры |
|---------|-------|-----------|
| `user_activated` | Первый раз сработала активация | `activation_type`, `hours_since_trial_start` |

---

## 5. Вовлечение и триал

| Событие | Тип | Когда слать | Параметры |
|---------|-----|-------------|-----------|
| `app_open` | automatic | Обычно уже есть | — |
| `session_start` | automatic | Обычно уже есть | — |
| `trial_reminder_scheduled` | custom | Запланировали локальный пуш | `day` (`1` / `3` / `7` / `12`) |
| `notification_receive` | custom* | Пуш получен | `campaign_id`, `day` |
| `notification_open` | custom* | Тап по пушу | `campaign_id`, `day` |
| `trial_ending_view` | custom | Экран «триал скоро закончится» | `days_left` |
| `subscription_cancel_intent` | custom | Ушёл в управление подпиской из приложения (если трекаете) | `plan_id` |

\* Для iOS push лучше связывать с FCM / своим `campaign_id`. Не путать с reserved-именами, если конфликт — префикс `push_`.

---

## 6. Отзывы и рейтинг

| Событие | Тип | Когда слать | Параметры |
|---------|-----|-------------|-----------|
| `rate_prompt_view` | custom | Показали системный/свой запрос | `trigger` (`plan_save` / `shopping_list`) |
| `rate_prompt_result` | custom | Результат | `action` (`rated` / `dismissed` / `feedback`) |

---

## 7. Ошибки и техника

| Событие | Тип | Когда слать | Параметры |
|---------|-----|-------------|-----------|
| `app_exception` | recommended / crashlytics | Через Crashlytics | — |
| `plan_generate_error` | custom | Не удалось собрать план | `error_code`, `stage` |
| `entitlement_check` | custom | Проверка доступа к фиче | `feature`, `allowed` (bool) |

---

## User properties (раз в изменении)

| Property | Значения | Зачем |
|----------|----------|--------|
| `subscription_status` | `none` / `trial` / `active` / `expired` / `lifetime` | Сегменты |
| `plan_id` | `monthly` / `yearly` / `lifetime` / `none` | Тариф |
| `goal_type` | `lose` / `maintain` / `gain` | Контент |
| `activated` | `true` / `false` | Качество трафика |
| `onboarding_completed` | `true` / `false` | Воронка |
| `app_language` | `ru` / `en` | Локаль |

Не класть в properties вес, возраст как точный идентификатор, имя.

---

## Воронки в GA4 (собрать из событий)

1. **Онбординг → триал**  
   `tutorial_begin` → `tutorial_complete` → `plan_preview_view` → `paywall_view` → `trial_start`

2. **Активация в триале**  
   `trial_start` → (`plan_week_view` | `shopping_list_open` | `instagram_import_success`) → `user_activated`

3. **Триал → оплата**  
   `trial_start` → `purchase` (с `plan_id`, без trial)

---

## Минимальный набор на релиз (v1)

Онбординг: `tutorial_begin`, `onboarding_step_complete`, `tutorial_complete`, `onboarding_targets_ready`  
Paywall: `paywall_view`, `paywall_plan_select`, `paywall_cta_tap`, `trial_start`, `purchase`, `purchase_error`, `restore_result`  
Продукт: `plan_preview_view`, `plan_week_view`, `plan_save`, `shopping_list_open`, `instagram_import_start`, `instagram_import_success`, `instagram_import_error`  
Свойства: `subscription_status`, `plan_id`, `activated`, `onboarding_completed`

Остальное — второй итерацией.

---

## Debug

- Включить DebugView в Firebase (Xcode argument: `-FIRDebugEnabled`).
- Проверить, что `purchase` / подписки не двоятся с RevenueCat/StoreKit2 collector.
- Имена событий не менять после запуска воронок — только добавлять новые.
