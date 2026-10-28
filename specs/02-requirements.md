# Requirements

Статусы: **must** — обязательно для текущего продукта; **should** — ожидаемо, может быть partial; **could** — желательно / roadmap.

## Функциональные требования

### Доступ и онбординг

| ID | Требование | Priority | Feature |
| --- | --- | --- | --- |
| FR-01 | До основного UI пользователь проходит онбординг (цель, тело, активность) и получает рассчитанные дневные цели КБЖУ | must | F-ONB |
| FR-02 | После reveal доступно превью «День 1» из генератора; после онбординга без доступа — hard paywall с тем же превью | must | F-ONB, F-SUB |
| FR-03 | Статус доступа Pro сохраняется в `AppSettings` и сверяется с Adapty; Previews — mock-unlock; Debug/sandbox — Continue без покупки | must | F-SUB |
| FR-04 | После успешного unlock при наличии preview snapshot планируется генерация текущей недели (`MealPlanGenerationPending`) | must | F-PLAN, F-SUB |

### Сегодня (Home)

| ID | Требование | Priority | Feature |
| --- | --- | --- | --- |
| FR-10 | Показывать прогресс КБЖУ за сегодня относительно целей | must | F-HOME, F-NUT |
| FR-11 | Показывать слоты приёмов пищи на сегодня и позволять добавить рецепт в слот | must | F-HOME |
| FR-12 | Давать быстрый вход в импорт рецепта | must | F-HOME, F-IMP |
| FR-13 | Показывать рекомендации / избранное из каталога | must | F-HOME, F-REC |
| FR-14 | Рецепт дня / «Surprise me» на Home | must | F-HOME |

### Недельный план

| ID | Требование | Priority | Feature |
| --- | --- | --- | --- |
| FR-20 | Планировать 7 дней недели со слотами: завтрак, обед, ужин, перекус | must | F-PLAN |
| FR-21 | Листать предыдущие и следующие недели | must | F-PLAN |
| FR-22 | При изменении плана синхронизировать список покупок недели | must | F-PLAN, F-SHOP |
| FR-23 | Автогенерация недели под дневные цели КБЖУ из каталога (с прогрессом стадий) | must | F-PLAN |
| FR-24 | Поделиться планом: промежуточный sheet с именем файла и карточкой средних КБЖУ → Share `.foodplan` | must | F-PLAN |
| FR-25 | Импорт плана: выбор целевой недели, режимы replace / fill empty; weekday offsets сохраняются | must | F-PLAN |
| FR-26 | Очистить план: confirmation → удалить meals недели и shopping items | must | F-PLAN |
| FR-27 | Large title + programmatic scroll к сегодняшнему дню через iOS 18 `ScrollPosition` | must | F-PLAN |
| FR-28 | Кнопка «Сегодня» в переключателе недель | could | F-PLAN |

### Список покупок

| ID | Требование | Priority | Feature |
| --- | --- | --- | --- |
| FR-30 | Агрегировать ингредиенты рецептов недели (суммировать одинаковые продукт+единица) | must | F-SHOP |
| FR-31 | Группировать по категориям продуктов; отмечать купленное | must | F-SHOP |
| FR-32 | Добавлять ручные позиции; шарить список | must | F-SHOP |

### Рецепты

| ID | Требование | Priority | Feature |
| --- | --- | --- | --- |
| FR-40 | Разделять каталоговые и пользовательские рецепты в библиотеке | must | F-REC |
| FR-41 | Создавать / редактировать рецепт: фото, ингредиенты из каталога, шаги, порции, время готовки | must | F-REC |
| FR-42 | Карточка рецепта: КБЖУ на порцию, ингредиенты, шаги, микронутриенты | must | F-REC, F-NUT |
| FR-43 | Избранное для каталоговых рецептов | must | F-REC |
| FR-44 | Личный рейтинг рецепта 1…5 на detail | must | F-REC |
| FR-45 | Отображать community like count (локальная «видимость сообщества») | should | F-REC |
| FR-46 | Поиск: сначала по названию; если пусто — отдельная секция «Похожие по ингредиенту» (без шагов готовки) | must | F-REC |
| FR-47 | В библиотеке и discovery дедуплицировать клоны генерации по `catalogRecipeId` | must | F-REC, F-CAT |

### Импорт рецептов

| ID | Требование | Priority | Feature |
| --- | --- | --- | --- |
| FR-50 | Импорт по URL Instagram (in-app paste и Share Extension без compose) | must | F-IMP |
| FR-51 | Пайплайн: fetch post → caption/transcript → LLM parse → amount normalize → match каталога → review draft | must | F-IMP |
| FR-52 | Пользователь может править draft перед сохранением в библиотеку | must | F-IMP |
| FR-53 | Deep link `foodplanner://import?url=` и App Group pending переживают cold start / bootstrap | must | F-IMP |
| FR-54 | LLM-каталог в промпте на языке UI (ru\|en); матчинг со стеммингом; quantity/unit из названия подставляются при ручном сопоставлении | must | F-IMP |
| FR-55 | Paste sheet: единая карточка подсказок (текст/privacy/Share → Food Planner из Instagram) | must | F-IMP |

### Питание

| ID | Требование | Priority | Feature |
| --- | --- | --- | --- |
| FR-60 | Расчёт целей: BMR Mifflin–St Jeor × activity → TDEE; белок/жир от целевого веса; углеводы — остаток | must | F-NUT |
| FR-61 | Ручная правка целей КБЖУ в настройках | must | F-SET |
| FR-62 | Фокус до 5 микронутриентов; при попытке включить 6-й — alert с просьбой снять другой | must | F-NUT, F-SET |

### Вовлечение

| ID | Требование | Priority | Feature |
| --- | --- | --- | --- |
| FR-80 | На free trial: локальные уведомления D1, D3, D7 и за 2 дня до expiresAt (11:00); тексты про план/покупки, не про оплату | must | F-ENG |
| FR-81 | Тап по уведомлению открывает вкладку через `foodplanner://tab/…` | must | F-ENG |
| FR-82 | Системный запрос отзыва после лайка или оценки рецепта; не в первый календарный день использования; ≤1 раз на версию и ≥14 дней между | must | F-ENG |
| FR-83 | Плавный opacity crossfade bootstrap loader → gated UI (уважение Reduce Motion) | must | F-ENG |

### Каталоги и локализация

| ID | Требование | Priority | Feature |
| --- | --- | --- | --- |
| FR-70 | Seed каталога продуктов и рецептов из bundled JSON при первом запуске | must | F-CAT |
| FR-71 | Пользовательские рецепты персистятся в SwiftData и `recipes-user.json` | must | F-CAT |
| FR-72 | UI-язык: system / en / ru; названия продуктов и каталоговых рецептов локализуются | must | F-SET, F-CAT |

## Нефункциональные требования

| ID | Требование | Priority |
| --- | --- | --- |
| NFR-01 | Основной UX работает offline (план, библиотека, shopping, nutrition из локальных данных) | must |
| NFR-02 | Сеть: импорт Instagram, LLM, Adapty; ошибки импорта показываются с retry | must |
| NFR-03 | Accessibility: VoiceOver labels на ключевых контролах; уважение Reduce Motion; hit targets ≥ 44pt | should |
| NFR-04 | Контраст и Dynamic Type через системные стили SwiftUI где применимо | should |
| NFR-05 | При битой локальной БД — recovery reset store (DEBUG-лог) и пересоздание контейнера | must |
| NFR-06 | Секреты API импорта не коммитятся (`ImportAPIConfig.example.swift`) | must |
| NFR-07 | Preview на симуляторе без обязательной подписи development team | should |
| NFR-08 | Layout адаптируется по size class (readable columns, adaptive grids, form sheets на iPad) | must |
| NFR-09 | Экспорт `.foodplan` — документированный Codable JSON; UTType зарегистрирован в приложении | must |

## Ограничения

- Нет обязательного backend Food Planner: источник правды — устройство (+ файловый обмен планом).
- Community likes — случайные 0…100 при заходе (не серверная социальная граф).
- Натрий из внешних парсеров каталога не хранится в `FoodProduct`.
- Генерация плана клонирует рецепты под meals; библиотека показывает один ряд на `catalogRecipeId`.
