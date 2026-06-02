# Инструменты food-planner

## ingredient-catalog-manager.html

Локальная HTML-страница для управления каталогом продуктов (поля модели `FoodProduct`, значения **на 100 г**).

### Запуск

Откройте файл в браузере:

```bash
open tools/ingredient-catalog-manager.html
```

### Возможности

- Ручное добавление и редактирование: название, `catalogKey`, категория, КБЖУ и микронутриенты
- Загрузка JSON (`{ "version": 1, "products": [...] }` или массив)
- Экспорт изменённого `food-catalog.json`
- Парсинг таблицы с [health-diet.ru](https://health-diet.ru/base_of_food/sostav/39.php): по URL (через прокси) или вставкой HTML

### Без прокси (локальный парсер)

Если прокси в браузере не работает (timeout/403), используйте локальный скрипт — он скачивает страницу напрямую (server-side запрос, без CORS):

```bash
python3 tools/parse_health_diet.py "https://health-diet.ru/base_of_food/sostav/39.php" --out /tmp/product.json
```

Дальше откройте `ingredient-catalog-manager.html` и импортируйте полученный JSON (`/tmp/product.json`).

Массовый сбор диапазона id (с паузами между запросами, без добавления страниц с «Запрашиваемая страница не найдена!»):

```bash
python3 tools/parse_health_diet_range.py --start 19 --end 510 --delay 1.3 --timeout 10 --insecure-ssl --out food-planner/Resources/food-catalog.json
```

### Соответствие полей приложению

| JSON / форма | Модель Swift |
|--------------|--------------|
| `caloriesPer100g` … `carbsPer100g` | макросы |
| `vitaminAPer100g`, `vitaminB6Per100g`, `vitaminB12Per100g`, `vitaminCPer100g`, `vitaminD3Per100g`, `vitaminEPer100g`, `vitaminKPer100g` | витамины |
| `potassiumPer100g`, `calciumPer100g`, `magnesiumPer100g`, `ironPer100g`, `seleniumPer100g`, `zincPer100g`, `iodinePer100g` | минералы |
| `chromiumPer100g` | хром (в БД нет поля «фтор») |
| `fiberPer100g`, `vitaminB9Per100g` | также в модели |

Натрий с health-diet.ru в JSON **не экспортируется** — в `FoodProduct` нет поля натрия.

## recipe-catalog-manager.html

Страница для сборки базы рецептов под приложение.

### Запуск

```bash
open tools/recipe-catalog-manager.html
```

### Рабочий процесс

1. Загрузите JSON каталога из `ingredient-catalog-manager` (продукты с `catalogKey`).
2. Создайте или отредактируйте рецепты: название, `id`, `imageId`, ингредиенты, шаги (по строке).
3. Опционально загрузите фото — в экспорте можно включить `imageBase64` или положить файлы в `food-planner/Resources/RecipeImages/<imageId>.jpg`.
4. Скачайте `recipes-catalog.json` и поместите в `food-planner/Resources/recipes-catalog.json`.

При каждом запуске `RecipeCatalogSeeder.syncCatalog` синхронизирует рецепты из JSON (они всегда в блоке «Рекомендации» на главной). Избранные каталоговые рецепты дополнительно показываются на вкладке «Рецепты».

### Формат JSON

```json
{
  "version": 1,
  "recipes": [
    {
      "id": "oatmeal_berries",
      "name": "Овсянка с ягодами",
      "imageId": "oatmeal_berries",
      "steps": ["Залить овсянку молоком", "Добавить ягоды"],
      "ingredients": [
        { "catalogKey": "oatmeal", "quantity": 50, "unit": "gram" }
      ]
    }
  ]
}
```

Единицы: `gram`, `kilogram`, `milliliter`, `liter`, `piece`, `tablespoon`, `teaspoon` — как `MeasurementUnit` в приложении.
