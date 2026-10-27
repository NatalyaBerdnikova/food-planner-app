#!/usr/bin/env python3
"""Remap legacy recipe catalogKeys to food-catalog keys and flag macros-only products."""

from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "food-planner/Resources/food-catalog.json"
RECIPES_PATH = ROOT / "food-planner/Resources/recipes-catalog.json"
MISSING_PATH = ROOT / "tools/import-missing-ingredients.txt"
DUMP_PATH = Path("/Users/natalya/Downloads/10_0_0_129.json")

# Legacy placeholder keys from early recipes-catalog import -> current food-catalog keys
LEGACY_KEY_MAP = {
    "egg": "yaytso_kurinoe",
    "milk": "milk_3_5_fat_sterilized",
    "butter": "butter_61_5_fat_sandwich",
    "onion": "bulb_onion",
    "yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "cheese": "syr_korol_syrov_syrobogatov",
    "chicken_breast": "tsyplyata_produkt_udalen",
    "rice": "white_rice_rice_groats",
    "tomato": "pomidor_tomat_produkt_udalen",
    "pasta": "makarony_tselnozernovye_s_zarodyshami_i_kletchat",
    "apple": "yabloko",
    "spinach": "shpinat",
    "bell_pepper": "bell_red",
    "bread": "bread_pshenichnyy_produkt_udalen",
    "honey": "bee_honey",
    "carrot": "carrots_product_removed",
    "cucumber": "ogurets_gruntovyy",
    "lentils": "chechevitsa_zerno",
    "broccoli": "brokkoli",
    "avocado": "avocado",
    "garlic": "garlic_clove",
    "salmon": "losos_atlanticheskiy_semga",
    "lemon": "lemon",
    "beef": "beef_cat_1",
}

MICRO_FIELDS = [
    "fiberPer100g",
    "vitaminD3Per100g",
    "calciumPer100g",
    "magnesiumPer100g",
    "zincPer100g",
    "vitaminKPer100g",
    "vitaminCPer100g",
    "vitaminEPer100g",
    "vitaminAPer100g",
    "vitaminB6Per100g",
    "vitaminB9Per100g",
    "vitaminB12Per100g",
    "seleniumPer100g",
    "chromiumPer100g",
    "ironPer100g",
    "potassiumPer100g",
    "iodinePer100g",
]

MACRO_FIELDS = ["caloriesPer100g", "proteinPer100g", "fatPer100g", "carbsPer100g"]


def clean_brand(name: str) -> str:
    return re.sub(r"\s*\[.*?\]\s*", " ", name or "").strip()


def norm(s: str) -> str:
    s = clean_brand(s).lower().replace("ё", "е")
    s = re.sub(r"\(.*?\)", " ", s)
    s = re.sub(r"[^a-zа-я0-9\s]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def build_name_index(products: list[dict]) -> dict[str, str]:
    by_norm: dict[str, str] = {}
    for p in products:
        names = [p.get("displayName"), p.get("catalogKey")]
        tr = p.get("translations") or {}
        if isinstance(tr, dict):
            names.extend(str(v) for v in tr.values() if v)
        for name in names:
            if isinstance(name, str) and name.strip():
                by_norm[norm(name)] = p["catalogKey"]
    return by_norm


def dump_name_to_catalog_key(dump_ingredient_name: str, by_norm: dict[str, str]) -> str | None:
    n = norm(dump_ingredient_name)
    if n in by_norm:
        return by_norm[n]
    for alt in (re.sub(r"\s*\(.*?\)\s*", " ", n).strip(), n.replace(",", "")):
        if alt in by_norm:
            return by_norm[alt]
    return None


def load_dump_maps() -> tuple[dict[int, str], dict[str, list[tuple[str, float]]]]:
    """recipe dump name -> [(ingredient dump name, amount)]"""
    if not DUMP_PATH.exists():
        return {}, {}
    dump = json.loads(DUMP_PATH.read_text(encoding="utf-8"))
    tables = {item["name"]: item for item in dump if item.get("type") == "table"}
    ingredients = {int(r["id"]): r["name"] for r in tables["recipes_ingredient"]["data"]}
    recipes = {int(r["id"]): r["name"] for r in tables["recipes_recipe"]["data"]}
    recipe_ings: dict[str, list[tuple[str, float]]] = defaultdict(list)
    for row in tables["recipes_recipeingredient"]["data"]:
        rid = int(row["recipe_id"])
        iid = int(row["ingredient_id"])
        amount = float(row["amount"])
        rname = recipes.get(rid)
        iname = ingredients.get(iid)
        if rname and iname:
            recipe_ings[rname].append((iname, amount))
    return ingredients, recipe_ings


def is_macros_only(product: dict) -> bool:
    has_macro = any(float(product.get(k) or 0) > 0 for k in MACRO_FIELDS)
    if not has_macro:
        return False
    return all(float(product.get(k) or 0) == 0 for k in MICRO_FIELDS)


def main() -> None:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    recipes_file = json.loads(RECIPES_PATH.read_text(encoding="utf-8"))
    products = catalog["products"]
    catalog_keys = {p["catalogKey"] for p in products}
    by_norm = build_name_index(products)

    # Extend map from dump ingredient names when unique
    _, dump_recipe_ings = load_dump_maps()
    dump_to_key: dict[str, str] = {}
    for ing_name in {n for pairs in dump_recipe_ings.values() for n, _ in pairs}:
        key = dump_name_to_catalog_key(ing_name, by_norm)
        if key:
            dump_to_key[clean_brand(ing_name)] = key

    remapped = 0
    for recipe in recipes_file["recipes"]:
        ru_name = (recipe.get("translations") or {}).get("ru", {}).get("name", "")
        dump_pairs = dump_recipe_ings.get(ru_name, [])
        dump_names = [clean_brand(n) for n, _ in dump_pairs]

        for idx, ing in enumerate(recipe.get("ingredients") or []):
            old = ing["catalogKey"]
            new = old

            if old not in catalog_keys:
                if old in LEGACY_KEY_MAP and LEGACY_KEY_MAP[old] in catalog_keys:
                    new = LEGACY_KEY_MAP[old]
                elif idx < len(dump_names):
                    dump_key = dump_to_key.get(dump_names[idx])
                    if dump_key and dump_key in catalog_keys:
                        new = dump_key
                elif clean_brand(old) in dump_to_key:
                    new = dump_to_key[clean_brand(old)]

            if new != old:
                ing["catalogKey"] = new
                remapped += 1

    # Flag macros-only products
    flagged = 0
    cleared = 0
    for product in products:
        if is_macros_only(product):
            if product.get("macrosOnly") is not True:
                product["macrosOnly"] = True
                flagged += 1
        elif product.get("macrosOnly"):
            del product["macrosOnly"]
            cleared += 1

    # Missing report
    missing_usage: dict[str, list[str]] = defaultdict(list)
    for recipe in recipes_file["recipes"]:
        rname = (recipe.get("translations") or {}).get("ru", {}).get("name") or recipe["id"]
        for ing in recipe.get("ingredients") or []:
            key = ing["catalogKey"]
            if key not in catalog_keys:
                missing_usage[key].append(rname)

    RECIPES_PATH.write_text(
        json.dumps(recipes_file, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    CATALOG_PATH.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    lines = [
        "Missing ingredients for recipes-catalog.json",
        f"Total recipes: {len(recipes_file['recipes'])}",
        f"Unique missing keys: {len(missing_usage)}",
        "",
    ]
    for key in sorted(missing_usage, key=lambda k: (-len(set(missing_usage[k])), k)):
        recipes = sorted(set(missing_usage[key]))
        lines.append(f"- {key} ({len(recipes)} recipes)")
        for name in recipes[:8]:
            lines.append(f"    · {name}")
        if len(recipes) > 8:
            lines.append(f"    · … +{len(recipes) - 8} more")
        lines.append("")

    MISSING_PATH.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

    print(f"Remapped ingredient refs: {remapped}")
    print(f"macrosOnly flagged: {flagged}, cleared: {cleared}")
    print(f"Still missing keys: {len(missing_usage)}")
    for key in sorted(missing_usage, key=lambda k: -len(set(missing_usage[k]))):
        print(f"  {key}: {len(set(missing_usage[key]))} recipes")


if __name__ == "__main__":
    main()
