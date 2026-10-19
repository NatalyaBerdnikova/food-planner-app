# User Journeys

## J1 — Первый запуск

**Цель:** получить персональные цели и войти в приложение.

1. Пользователь открывает приложение → splash/bootstrap (seed каталогов).
2. Онбординг: welcome → цель (lose/maintain/gain) → параметры тела → активность → reveal рассчитанных КБЖУ.
3. Профиль и цели пишутся в `AppSettings`, `hasCompletedOnboarding = true`.
4. Если нет Pro/Free → Hard Paywall.
5. Доступ:
   - **TestFlight / mocks on:** выбор mock-тарифа → Continue или Restore → Pro.
   - **Production / mocks off:** покупка Adapty/StoreKit или restore.
6. Успех → `MainTabView` (Сегодня).

**Acceptance:** без завершённого онбординга основной UI недоступен; после — только paywall или tabs; при mocks Continue и Restore разблокируют app.

## J2 — Импорт рецепта из Instagram

**Цель:** сохранить рецепт из Reels/поста в библиотеку.

### Из Share Sheet

1. В Instagram: Share → Food Planner.
2. Extension без ввода текста: URL → App Group + `foodplanner://import?url=` → открытие host app.
3. После готовности app (`canPresentImport`): `ImportCoordinator` поднимает progress sheet на root (fetch → read → parse → «Подбираем ингредиенты» → ready).
4. Review: matched / unresolved; у unresolved количество уже вынесено из названия; tap → поиск продукта (clear в инпуте) с подставленными unit/qty.
5. Сохранение → рецепт в «Мои рецепты».

### Из приложения

1. Home или Recipes → CTA импорта → `PasteImportSheet` (вставка URL).
2. Тот же пайплайн, что выше.

**Failure:** сеть / quota / пустой caption → `ImportState.failed` + retry.  
**Cold start:** deep link / pending не теряются во время bootstrap и paywall.

## J3 — Спланировать неделю и купить продукты

**Цель:** закрыть вопрос «что есть» и «что купить».

1. Вкладка План → выбрать день и слот (завтрак/обед/ужин/перекус). На iPad дни могут идти в 2 колонки.
2. `AddMealSheet`: выбрать рецепт (фильтр по типу / все).
3. `WeekPlanService.syncShoppingItems` обновляет список.
4. Вкладка Покупки: чеклист по категориям, отметка купленного, опционально share / manual item.

**Acceptance:** одинаковые ингредиенты суммируются; купленные уходят вниз списка.

## J4 — Контроль питания за день

**Цель:** понять, насколько день закрывает цели.

1. Вкладка Сегодня → прогресс КБЖУ (expandable); на wide layout контент в readable-колонке.
2. Слоты сегодняшних meals отражают план.
3. Добавление meal с Home обновляет прогресс.
4. В Settings можно пересчитать или вручную задать цели; выбрать до 5 микро для фокуса.

## J5 — Создать рецепт вручную

**Цель:** добавить свой рецепт без импорта.

1. Recipes → `+` → `AddRecipeView`.
2. Фото (PhotosPicker), название, порции, cook time, ингредиенты через поиск каталога (`AddIngredientSheet` + clear в поиске), шаги.
3. Сохранение в SwiftData + user catalog JSON.
4. Карточка показывает КБЖУ на порцию и микро по кнопке деталей.

## J6 — Вернуться к избранному каталогу

1. В рекомендациях / библиотеке пользователь ставит favorite на каталоговый рецепт.
2. Id пишется в `AppSettings.favoriteCatalogRecipeIds`.
3. Снятие избранного — с confirmation alert.

## Сквозные инварианты

- Offline: J3–J6 без сети (кроме картинок из сети при импорте).
- Импорт и подписка — единственные обязательные online-пути для полного happy path J1/J2 (кроме mock-разблокировки в TestFlight).
- Layout: size class, не device idiom; sheets form-sized на iPad.
