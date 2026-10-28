# User Journeys

## J1 — Первый запуск

**Цель:** получить персональные цели и войти в приложение.

1. Пользователь открывает приложение → splash/bootstrap (seed каталогов) → плавный opacity-переход на gated UI.
2. Онбординг: welcome → цель (lose/maintain/gain) → параметры тела → активность → reveal рассчитанных КБЖУ.
3. Опционально: превью «День 1» (`OnboardingDayPreviewStep`) из `MealPlanGenerator`.
4. Профиль и цели пишутся в `AppSettings`, `hasCompletedOnboarding = true`.
5. Если нет Pro/Free → Hard Paywall (то же превью дня + CTA).
6. Доступ:
   - **Production:** покупка Adapty/StoreKit или restore; trial → schedule engagement notifications.
   - **Debug / TestFlight sandbox:** Continue without subscription (и synthetic trial schedule при mocks-пути).
   - **Previews:** `useSubscriptionMocks` unlock.
7. Успех → `MainTabView` (Сегодня); если был preview snapshot — генерация текущей недели (today pinned).

**Acceptance:** без завершённого онбординга основной UI недоступен; после — только paywall или tabs.

## J2 — Импорт рецепта из Instagram

**Цель:** сохранить рецепт из Reels/поста в библиотеку.

### Из Share Sheet

1. В Instagram: Share → Food Planner.
2. Extension без ввода текста: URL → App Group + `foodplanner://import?url=` → открытие host app.
3. После готовности app (`canPresentImport`): `ImportCoordinator` поднимает progress sheet на root.
4. Review: matched / unresolved; у unresolved количество уже вынесено из названия; tap → поиск продукта.
5. Сохранение → рецепт в «Мои рецепты».

### Из приложения

1. Home или Recipes → CTA импорта → `PasteImportSheet` (URL + единая карточка подсказок, в т.ч. Share из Instagram).
2. Тот же пайплайн, что выше.

**Failure:** сеть / quota / пустой caption → `ImportState.failed` + retry.  
**Cold start:** deep link / pending не теряются во время bootstrap и paywall.

## J3 — Спланировать неделю и купить продукты

**Цель:** закрыть вопрос «что есть» и «что купить».

1. Вкладка План → выбрать день и слот (завтрак/обед/ужин/перекус). На iPad дни могут идти в 2 колонки.
2. `AddMealSheet`: поиск по названию; если пусто — секция «Похожие по ингредиенту».
3. `WeekPlanService.syncShoppingItems` обновляет список.
4. Вкладка Покупки: чеклист по категориям, отметка купленного, опционально share / manual item.

**Acceptance:** одинаковые ингредиенты суммируются; купленные уходят вниз списка.

## J3b — Сгенерировать неделю

**Цель:** заполнить неделю под цели без ручного подбора.

1. Toolbar sparkles → `GenerateWeekPlanSheet` (карточка целей).
2. Прогресс стадий → meals на 7 дней + shopping sync.
3. Альтернатива: после paywall unlock с preview — автостарт с pinned today.

## J3c — Поделиться / импортировать / очистить план

**Цель:** передать план тренеру или сбросить неделю.

1. **Поделиться планом:** menu → промежуточный sheet (имя файла + средние КБЖУ) → Share `.foodplan`.
2. **Импорт плана:** fileImporter / open file → выбор недели и режима (заменить / только пустые дни) → apply; день недели из файла ложится на тот же weekday целевой недели.
3. **Очистить план:** confirmation → meals + shopping items недели удалены.

## J4 — Контроль питания за день

**Цель:** понять, насколько день закрывает цели.

1. Вкладка Сегодня → прогресс КБЖУ (expandable); на wide layout контент в readable-колонке.
2. Слоты сегодняшних meals отражают план.
3. Добавление meal с Home обновляет прогресс.
4. В Settings можно пересчитать или вручную задать цели; выбрать до 5 микро; 6-й — alert.

## J5 — Создать рецепт вручную

**Цель:** добавить свой рецепт без импорта.

1. Recipes → `+` → `AddRecipeView`.
2. Фото (PhotosPicker), название, порции, cook time, ингредиенты через поиск каталога, шаги.
3. Сохранение в SwiftData + user catalog JSON.
4. Карточка показывает КБЖУ на порцию и микро по кнопке деталей.

## J6 — Избранное и отзыв

1. В рекомендациях / библиотеке / detail пользователь ставит favorite или ranking 1…5.
2. Favorite id пишется в `AppSettings.favoriteCatalogRecipeIds`; unfavorite — с confirmation.
3. Если не первый календарный день использования и пройдены гейты версии/14 дней → системный `requestReview` (через ~1.2 с).

## J7 — Trial-напоминание

1. Активный Adapty free trial → schedule locals на D1/D3/D7 и renewal−2d (11:00).
2. Тап → deep link вкладки План или Покупки.
3. Отмена триала / нет доступа → cancel pending notifications.

## Сквозные инварианты

- Offline: J3–J6 без сети (кроме картинок из сети при импорте).
- Импорт рецептов и подписка — обязательные online-пути для полного happy path J1/J2 (кроме Debug Continue).
- Layout: size class, не device idiom; sheets form-sized на iPad.
- Клоны генерации не размножают карточки в библиотеке.
