#!/usr/bin/env python3

import json
import re
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "food-planner/Resources"
RECIPES_PATH = RESOURCES / "recipes-catalog.json"
FOOD_PATH = RESOURCES / "food-catalog.json"
STRINGS_PATH = ROOT / "food-planner/Localizable.xcstrings"
IMAGES_PATH = RESOURCES / "RecipeImages"
CYRILLIC = re.compile(r"[А-Яа-яЁё]")
LATIN = re.compile(r"[A-Za-z]")
NAME_ENDING_PUNCTUATION = ".,;:"
UNIT_KEYS = {
    "unit.gram",
    "unit.kilogram",
    "unit.milliliter",
    "unit.liter",
    "unit.piece",
    "unit.tablespoon",
    "unit.teaspoon",
}
UNIT_VALUES = {key.removeprefix("unit.") for key in UNIT_KEYS}
MEAL_TYPE_VALUES = {"breakfast", "lunch", "dinner", "snack"}


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def normalized_name(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value.casefold())
    clean = "".join(
        character
        for character in decomposed
        if character.isalnum() or character.isspace()
    )
    return " ".join(clean.split())


def validate_text(
    errors: list[str],
    owner: str,
    field: str,
    locale: str,
    value: object,
    *,
    is_name: bool = False,
) -> None:
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{owner}: missing {locale}.{field}")
        return
    if value != value.strip():
        errors.append(f"{owner}: surrounding whitespace in {locale}.{field}")
    if "\u200b" in value:
        errors.append(f"{owner}: zero-width space in {locale}.{field}")
    if value.count("<p>") != value.count("</p>"):
        errors.append(f"{owner}: unbalanced paragraph tags in {locale}.{field}")
    if locale == "en" and CYRILLIC.search(value):
        errors.append(f"{owner}: Cyrillic text in en.{field}")
    if locale == "ru" and not CYRILLIC.search(value):
        errors.append(f"{owner}: Russian text missing from ru.{field}")
    if is_name:
        first_letter = next((character for character in value if character.isalpha()), "")
        if first_letter and not first_letter.isupper():
            errors.append(f"{owner}: {locale}.{field} must start with uppercase")
        if value.endswith(tuple(NAME_ENDING_PUNCTUATION)):
            errors.append(f"{owner}: trailing punctuation in {locale}.{field}")


def validate() -> list[str]:
    errors: list[str] = []
    recipes = load_json(RECIPES_PATH).get("recipes", [])
    products = load_json(FOOD_PATH).get("products", [])
    strings = load_json(STRINGS_PATH).get("strings", {})

    recipe_ids = [recipe.get("id") for recipe in recipes]
    if any(not isinstance(recipe_id, str) or not recipe_id for recipe_id in recipe_ids):
        errors.append("recipe with missing id")
    duplicate_recipe_ids = sorted(
        recipe_id
        for recipe_id, count in Counter(recipe_ids).items()
        if isinstance(recipe_id, str) and count > 1
    )
    if duplicate_recipe_ids:
        errors.append(f"duplicate recipe ids: {duplicate_recipe_ids}")

    product_keys = [product.get("catalogKey") for product in products]
    if any(not isinstance(key, str) or not key for key in product_keys):
        errors.append("product with missing catalogKey")
    duplicate_product_keys = sorted(
        product_key
        for product_key, count in Counter(product_keys).items()
        if isinstance(product_key, str) and count > 1
    )
    if duplicate_product_keys:
        errors.append(f"duplicate product keys: {duplicate_product_keys}")
    known_product_keys = set(product_keys)

    names_by_locale: dict[str, dict[str, list[str]]] = {
        "en": defaultdict(list),
        "ru": defaultdict(list),
    }
    for product in products:
        key = product.get("catalogKey", "<missing-key>")
        translations = product.get("translations") or {}
        for locale in ("en", "ru"):
            name = translations.get(locale)
            validate_text(
                errors,
                f"product {key}",
                "name",
                locale,
                name,
                is_name=True,
            )
            if isinstance(name, str) and name.strip():
                names_by_locale[locale][normalized_name(name)].append(key)
        russian_name = translations.get("ru")
        if product.get("displayName") != russian_name:
            errors.append(f"product {key}: displayName must match translations.ru")

    for locale, localized_names in names_by_locale.items():
        for name, keys in localized_names.items():
            if len(keys) > 1:
                errors.append(
                    f"duplicate {locale} product name {name!r}: {sorted(keys)}"
                )

    image_ids: list[str] = []
    for recipe in recipes:
        recipe_id = recipe.get("id", "<missing-id>")
        if recipe_id.startswith("arise_") and recipe.get("sourceDescription") != (
            "ARISE COOKBOOK — Nicolina Nunes"
        ):
            errors.append(f"recipe {recipe_id}: missing ARISE source attribution")
        translations = recipe.get("translations") or {}
        for locale in ("en", "ru"):
            translation = translations.get(locale) or {}
            validate_text(
                errors,
                f"recipe {recipe_id}",
                "name",
                locale,
                translation.get("name"),
                is_name=True,
            )
            validate_text(
                errors,
                f"recipe {recipe_id}",
                "steps",
                locale,
                translation.get("steps"),
            )
        servings = recipe.get("servings")
        if not isinstance(servings, int) or servings < 1:
            errors.append(f"recipe {recipe_id}: invalid servings {servings!r}")
        cook_time = recipe.get("cookTimeMinutes")
        if not isinstance(cook_time, int) or cook_time < 1:
            errors.append(f"recipe {recipe_id}: invalid cookTimeMinutes {cook_time!r}")
        meal_types = recipe.get("mealTypes")
        if not isinstance(meal_types, list) or not meal_types:
            errors.append(f"recipe {recipe_id}: missing mealTypes")
        else:
            invalid_meal_types = [
                meal_type
                for meal_type in meal_types
                if meal_type not in MEAL_TYPE_VALUES
            ]
            if invalid_meal_types:
                errors.append(
                    f"recipe {recipe_id}: unknown mealTypes {invalid_meal_types!r}"
                )
            if len(meal_types) != len(set(meal_types)):
                errors.append(f"recipe {recipe_id}: duplicate mealTypes {meal_types!r}")
        ingredients = recipe.get("ingredients") or []
        if not ingredients:
            errors.append(f"recipe {recipe_id}: missing ingredients")
        ingredient_pairs = []
        for ingredient in ingredients:
            key = ingredient.get("catalogKey")
            if key not in known_product_keys:
                errors.append(f"recipe {recipe_id}: unknown catalogKey {key!r}")
            unit = ingredient.get("unit")
            if unit not in UNIT_VALUES:
                errors.append(f"recipe {recipe_id}: unknown unit {unit!r}")
            quantity = ingredient.get("quantity")
            if not isinstance(quantity, (int, float)) or quantity <= 0:
                errors.append(
                    f"recipe {recipe_id}: invalid quantity {quantity!r} for {key!r}"
                )
            ingredient_pairs.append((key, unit))
        duplicate_ingredients = sorted(
            pair
            for pair, count in Counter(ingredient_pairs).items()
            if count > 1
        )
        if duplicate_ingredients:
            errors.append(
                f"recipe {recipe_id}: duplicate ingredients {duplicate_ingredients}"
            )
        image_id = recipe.get("imageId")
        if not image_id:
            errors.append(f"recipe {recipe_id}: missing imageId")
        else:
            image_ids.append(image_id)
            if not any(
                (IMAGES_PATH / f"{image_id}{extension}").is_file()
                for extension in (".jpg", ".jpeg", ".png", ".heic", ".webp")
            ):
                errors.append(f"recipe {recipe_id}: missing image file for {image_id}")

    duplicate_image_ids = sorted(
        image_id
        for image_id, count in Counter(image_ids).items()
        if count > 1
    )
    if duplicate_image_ids:
        errors.append(f"duplicate image ids: {duplicate_image_ids}")

    referenced_image_ids = set(image_ids)
    unused_images = sorted(
        path.name
        for path in IMAGES_PATH.iterdir()
        if path.is_file()
        and not path.name.startswith(".")
        and path.stem not in referenced_image_ids
    )
    if unused_images:
        errors.append(f"unused recipe image files: {unused_images}")

    for key in UNIT_KEYS:
        entry = strings.get(key) or {}
        localizations = entry.get("localizations") or {}
        for locale in ("en", "ru"):
            value = (
                (localizations.get(locale) or {})
                .get("stringUnit", {})
                .get("value")
            )
            validate_text(errors, f"string {key}", "value", locale, value)
            if locale == "en" and isinstance(value, str) and not LATIN.search(value):
                errors.append(f"string {key}: en.value must contain Latin text")

    return errors


def main() -> int:
    errors = validate()
    if errors:
        for error in errors:
            print(error)
        print(f"{len(errors)} localization errors")
        return 1
    print("Localization validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
