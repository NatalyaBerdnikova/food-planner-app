#!/usr/bin/env python3
"""Parse OCR'd ARISE cookbook pages into recipes-catalog-compatible JSON."""

from __future__ import annotations

import json
import re
from pathlib import Path
from collections import OrderedDict

TEXT_DIR = Path("/Users/natalya/Work/food-planner/tools/arise-text")
FOOD_CATALOG = Path("/Users/natalya/Work/food-planner/food-planner/Resources/food-catalog.json")
OUT_RECIPES = Path("/Users/natalya/Work/food-planner/food-planner/Resources/arise-recipes-catalog.json")
OUT_MISSING = Path("/Users/natalya/Work/food-planner/food-planner/Resources/arise-missing-ingredients.json")

# Cookbook / OCR wording -> existing catalogKey (only keys that exist)
ALIASES: dict[str, str] = {
    # dairy / eggs
    "milk": "milk_3_5_fat_sterilized",
    "yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "greek yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "plain yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "high protein plain yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "cottage cheese": "tvorog_5_zhirnosti",
    "egg": "yaytso_kurinoe",
    "eggs": "yaytso_kurinoe",
    "hard boiled eggs": "yaytso_kurinoe",
    "hard boiled egg": "yaytso_kurinoe",
    "egg white": "chicken_egg_white",
    "egg whites": "chicken_egg_white",
    # meat / fish
    "chicken breast": "tsyplyata_produkt_udalen",
    "chicken": "tsyplyata_produkt_udalen",
    "chicken thigh": "chicken_leg",
    "chicken leg": "chicken_leg",
    "beef": "beef_cat_1",
    "steak": "beef_cat_1",
    "sirloin steak": "beef_cat_1",
    "minced beef": "beef_cat_1",
    "ground beef": "beef_cat_1",
    "pork": "pork",
    "butter": "butter_61_5_fat_sandwich",
    "salmon": "losos_atlanticheskiy_semga",
    "salmon fillet": "losos_atlanticheskiy_semga",
    "tuna": "tuna",
    "cod": "treska",
    "shrimp": "far_eastern_shrimp_meat",
    "prawns": "far_eastern_shrimp_meat",
    "jamon": "okorok_vareno_kopchyonyy_produkt_udalen",
    "ofjamon": "okorok_vareno_kopchyonyy_produkt_udalen",
    "ham": "okorok_vareno_kopchyonyy_produkt_udalen",
    # produce
    "tomato": "pomidor_tomat",
    "tomatoes": "pomidor_tomat",
    "cherry tomatoes": "pomidor_tomat",
    "tomato sauce": "tomatnaya_pasta_konservy",
    "onion": "bulb_onion",
    "medium onion": "bulb_onion",
    "red onion": "bulb_onion",
    "garlic": "garlic_clove",
    "banana": "banana",
    "mango": "mango",
    "frozen mango": "mango",
    "orange": "orange",
    "frozen orange": "orange",
    "lemon": "lemon",
    "lemon juice": "lemon_juice",
    "avocado": "avocado",
    "cinnamon": "cinnamon",
    "kiwi": "kiwi",
    "ginger": "ginger",
    "vinegar": "vinegar",
    "olives": "olives",
    "parmesan": "parmesan",
    "corn": "corn",
    "baking powder": "baking_powder",
    "shredded coconut": "shredded_coconut",
    "coconut": "shredded_coconut",
    "cornstarch": "cornstarch",
    "red onion": "redonion",
    "blueberry": "golubika",
    "blueberries": "golubika",
    "strawberry": "strawberries",
    "strawberries": "strawberries",
    "raspberry": "raspberries",
    "raspberries": "raspberries",
    "blackberry": "blackberry",
    "berries": "strawberries",
    "frozen berries": "strawberries",
    "fig": "fig",
    "figs": "fig",
    "apple": "apple",
    "pineapple": "pineapple",
    "watermelon": "watermelon",
    "spinach": "shpinat",
    "mushroom": "shampinony",
    "mushrooms": "shampinony",
    "potato": "potato",
    "potatoes": "potato",
    "baby potatoes": "potato",
    "sweet potato": "batata_sweet_potatoes",
    "carrot": "carrots_product_removed",
    "carrots": "carrots_product_removed",
    "baby carrots": "carrots_product_removed",
    "beetroot": "beetroots",
    "beet": "beetroots",
    "cucumber": "pickled_cucumber",
    "bell pepper": "bell_red",
    "red pepper": "bell_red",
    "green pepper": "green_sweet_pepper",
    "broccoli": "brokkoli",
    "bimi": "brokkoli",
    "grapefruit": "greypfrut",
    # pantry
    "olive oil": "olive_oil",
    "coconut oil": "coconut_oil_liquid",
    "honey": "bee_honey",
    "cocoa": "cocoa_powder",
    "cocoa powder": "cocoa_powder",
    "100 cocoa": "cocoa_powder",
    "100% cocoa": "cocoa_powder",
    "dark chocolate": "shokolad_gorkiy",
    "dark chocolate melted": "shokolad_gorkiy",
    "chocolate": "shokolad_gorkiy",
    "peanut butter": "peanut_butter_liquid",
    "oats": "oatmeal",
    "oatmeal": "oatmeal",
    "rolled oats": "oatmeal",
    "rice": "white_rice_rice_groats",
    "brown rice": "rice_whole_unprocessed_grains",
    "flour": "wheat_flour_premium_grade",
    "almonds": "almonds",
    "walnut": "walnut",
    "walnuts": "walnut",
    "chia seeds": "semena_chia_sushenye",
    "chia": "semena_chia_sushenye",
    "oregano": "oregano_sushenyy",
    "paprika": "paprika_perets_sladkiy_molotyy",
    "dill": "ukrop",
    "water": "water",
    "coffee": "instant_coffee_dry",
    "espresso coffee": "instant_coffee_dry",
    "expresso coffee": "instant_coffee_dry",
    "soy sauce": "miso_pasta_sen_soy",
    "mango": "mango",
    "raspberries or strawberries": "raspberries",
    "raspberries": "raspberries",
    "italian seasoning": "oregano_sushenyy",
}

UNIT_TO_GRAMS = {
    "g": 1.0, "gr": 1.0, "gram": 1.0, "grams": 1.0,
    "kg": 1000.0, "ml": 1.0, "l": 1000.0,
    "tsp": 5.0, "teaspoon": 5.0, "teaspoons": 5.0,
    "tbsp": 15.0, "tablespoon": 15.0, "tablespoons": 15.0,
    "cup": 240.0, "cups": 240.0,
}

PIECE_WEIGHTS = {
    "egg": 50, "eggs": 50, "avocado": 150, "tomato": 100, "kiwi": 75,
    "banana": 100, "onion": 100, "lemon": 60, "lime": 50, "orange": 130,
    "grapefruit": 200, "bagel": 90, "tortilla": 50, "wrap": 50, "wraps": 50,
    "mushroom": 15, "mushrooms": 15, "garlic": 5, "clove": 5, "fig": 40,
    "figs": 40, "raspberry": 5, "raspberries": 5, "apple": 150, "naan": 90, "slice": 30, "slices": 30,
}


def normalize(s: str) -> str:
    s = s.lower()
    s = s.replace("½", "1/2").replace("¼", "1/4").replace("¾", "3/4")
    s = s.replace("vz", "1/2").replace("v2", "1/2")
    s = re.sub(r"[^a-z0-9/%.\-]+", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def parse_fraction(token: str) -> float | None:
    token = token.strip().lower().replace(",", ".")
    token = re.sub(r"(?<=\d)o(?=\d)", "0", token)  # 1o0 -> 100
    token = re.sub(r"^o+(?=\d)", "", token)
    m = re.fullmatch(r"(\d+)\s*/\s*(\d+)", token)
    if m:
        den = float(m.group(2))
        return float(m.group(1)) / den if den else None
    try:
        return float(token)
    except ValueError:
        return None


def load_catalog() -> tuple[dict[str, str], set[str]]:
    with open(FOOD_CATALOG) as f:
        data = json.load(f)
    index: dict[str, str] = {}
    keys: set[str] = set()
    for p in data["products"]:
        key = p["catalogKey"]
        keys.add(key)
        names = [key.replace("_", " "), p.get("displayName", "")]
        tr = p.get("translations") or {}
        names.extend([tr.get("en", ""), tr.get("ru", "")])
        for n in names:
            if not n:
                continue
            norm = normalize(n)
            # Prefer first; don't overwrite shorter/cleaner later with junk
            if norm and norm not in index:
                index[norm] = key
    # Drop aliases that point to missing keys
    return index, keys


def match_ingredient(name: str, index: dict[str, str], keys: set[str]) -> str | None:
    n = normalize(name)
    n = re.sub(
        r"\b(fresh|raw|frozen|dried|chopped|sliced|diced|medium|large|small|"
        r"to taste|optional|of|the|a|an)\b",
        " ",
        n,
    )
    n = re.sub(r"\s+", " ", n).strip()
    n = re.sub(r"^\d+\s*%?\s*", "", n).strip()  # drop leading 100%
    if not n or len(n) < 2:
        return None

    # exact alias / index first
    if n in ALIASES and ALIASES[n] in keys:
        return ALIASES[n]
    if n in index:
        return index[n]

    # Prefer alias that covers the START of the name (first ingredient word),
    # then longer matches — avoids "mango orange" -> orange
    best_alias = None
    best_score = (-1, -1)  # (starts_at_0, length)
    for alias, key in ALIASES.items():
        if key not in keys:
            continue
        m = re.search(rf"\b{re.escape(alias)}\b", n)
        if not m:
            continue
        score = (1 if m.start() == 0 else 0, len(alias))
        if score > best_score:
            best_score = score
            best_alias = key
    if best_alias:
        return best_alias

    # index contains (prefer longer, prefer match at start)
    best = None
    best_score = (-1, -1)
    for ename, key in index.items():
        if len(ename) < 4:
            continue
        m = re.search(rf"\b{re.escape(ename)}\b", n)
        if not m:
            continue
        score = (1 if m.start() == 0 else 0, len(ename))
        if score > best_score:
            best_score = score
            best = key
    return best


INSTRUCTION_WORDS = {
    "add", "mix", "blend", "cook", "heat", "bake", "fry", "slice", "chop", "cut",
    "place", "pour", "spread", "toast", "saute", "sauté", "remove", "start",
    "after", "preheat", "season", "serve", "melt", "put", "make", "brush",
    "until", "then", "everything", "minutes", "ready", "flip", "onto",
}


def looks_like_instruction(text: str) -> bool:
    words = set(normalize(text).split())
    return len(words & INSTRUCTION_WORDS) >= 2


def extract_ingredient_line(page_text: str) -> str:
    """Find the densest quantity-bearing line (true ingredients list)."""
    # Fix common OCR glitches first
    text = page_text
    text = re.sub(r"\b1[oO0]{2}ml\b", "100ml", text, flags=re.I)
    text = re.sub(r"\b1[oO0]{2}g\b", "100g", text, flags=re.I)
    text = re.sub(r"(\d)o(\d)", r"\1\2", text, flags=re.I)  # 1o0 -> 100 inside numbers
    text = text.replace("Vz", "1/2").replace("vz", "1/2")
    text = text.replace("ofjamon", "of jamon").replace("saltand", "salt and")
    text = text.replace("theegg", "the egg").replace("sunnyside", "sunny side")
    text = text.replace("1kiwi", "1 kiwi").replace("1tomato", "1 tomato")
    text = text.replace("1tbsp", "1 tbsp").replace("1tsp", "1 tsp")
    text = text.replace("1/4of", "1/4 of").replace("1/2cup", "1/2 cup")
    text = text.replace("2og", "20g").replace("drops of water", "5ml of water")
    text = re.sub(r"(\d)(g|ml|tsp|tbsp)of\b", r"\1\2 of ", text, flags=re.I)  # 15gof -> 15g of
    text = re.sub(r"\([^)]*\)", " ", text)  # drop (frozen) etc so names parse

    # Prefer content after INGREDIENTS
    low = text.lower()
    idx = low.find("ingredients")
    chunk = text[idx + len("ingredients") :] if idx >= 0 else text
    for stop in ("arrise cookbook", "arise cookbook", "nicolina"):
        si = chunk.lower().find(stop)
        if si > 0:
            chunk = chunk[:si]

    # Score lines / sentences by quantity density
    candidates = re.split(r"[\n;]+", chunk)
    # also whole chunk as one candidate
    candidates.append(re.sub(r"\s+", " ", chunk))

    best, best_score = "", 0
    qty_pat = re.compile(
        r"\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?\s*(?:g|gr|grams?|kg|ml|l|tsp|tbsp|cups?|cup)\b|"
        r"\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?\s+(?:of\s+)?[a-z]",
        re.I,
    )
    for c in candidates:
        c = c.strip()
        if len(c) < 8:
            continue
        if looks_like_instruction(c) and qty_pat.findall(c).__len__() < 2:
            continue
        score = len(qty_pat.findall(c))
        # bonus for "g of"
        score += len(re.findall(r"\bg\s+of\b", c, re.I)) * 2
        if score > best_score:
            best, best_score = c, score
    return best


ITEM_RE = re.compile(
    r"(?P<qty>\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?)\s*"
    r"(?P<unit>g|gr|grams?|kg|ml|l|tsp|tbsp|teaspoons?|tablespoons?|cups?|cup)?\s*"
    r"(?:of\s+)?"
    r"(?:(?P<pct>\d+)\s*%\s*)?"  # e.g. 100% cocoa
    r"(?P<name>[a-zA-Z][a-zA-Z0-9 %/\-']{1,40}?)"
    r"(?=(?:\s+\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?\s*(?:g|gr|grams?|kg|ml|l|tsp|tbsp|cups?|cup)?\b)|"
    r"(?:\s+\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?\s+[a-zA-Z])|$)",
    re.I,
)


def parse_ingredients(line: str) -> list[dict]:
    if not line:
        return []
    items = []
    seen = set()
    for m in ITEM_RE.finditer(line):
        qty = parse_fraction(m.group("qty"))
        if qty is None or qty <= 0 or qty > 5000:
            continue
        unit = (m.group("unit") or "").lower()
        name = m.group("name").strip(" ,.;:")
        if m.groupdict().get("pct"):
            # keep percent cue for alias "100% cocoa"
            name = f"{m.group('pct')}% {name}"
        name = re.sub(r"\b(to taste|optional|and)\b", "", name, flags=re.I).strip()
        name_l = normalize(name)
        if len(name_l) < 2:
            continue
        if looks_like_instruction(name):
            continue
        # skip garbage
        if name_l in {"of", "a", "the", "and", "or", "with", "on", "to", "for", "in"}:
            continue
        if any(x in name_l for x in ("minute", "ready", "plate", "bowl", "smooth", "everything")):
            continue

        if unit:
            grams = qty * UNIT_TO_GRAMS.get(unit, 1.0)
        else:
            base = name_l.split()[0]
            pw = PIECE_WEIGHTS.get(base) or PIECE_WEIGHTS.get(name_l)
            grams = qty * (pw if pw else 30)

        key = (name_l, round(grams, 1))
        if key in seen:
            continue
        seen.add(key)
        items.append({"name": name, "quantity": round(grams, 1), "unit": "gram"})
    return items


def extract_steps(page_text: str) -> str:
    text = page_text
    # gather instructional sentences
    lines = []
    for raw in re.split(r"[\n.]+", text):
        s = raw.strip(" ;,")
        if len(s) < 12:
            continue
        low = s.lower()
        if low in ("instructions", "ingredients") or "arise" in low or "nicolina" in low:
            continue
        # skip ingredient-dense lines
        if len(re.findall(r"\d+\s*(?:g|ml|tsp|tbsp)\b", low)) >= 3:
            continue
        if looks_like_instruction(s) or any(
            low.startswith(w) for w in ("add", "mix", "blend", "cook", "heat", "slice", "chop", "cut", "toast", "spread", "preheat", "start", "after", "in a", "ina ", "place", "pour", "melt", "season", "serve", "brush", "fry", "bake")
        ):
            # capitalize
            s = s[0].upper() + s[1:] if s else s
            lines.append(s)
    # dedupe preserving order
    out = []
    seen = set()
    for ln in lines:
        k = normalize(ln)
        if k in seen:
            continue
        seen.add(k)
        out.append(ln if ln.endswith(".") else ln + ".")
    return "\n".join(out)


TITLE_BAD = re.compile(
    r"(?i)kcal|difficulty|calories|total time|easy|medium|hard|arise|nicolina|"
    r"^\d+\s*[pcf]\b|^\d+\s*$|protein coffee$"  # keep protein coffee actually OK
)


_OCR_DIGIT = str.maketrans({"O": "0", "o": "0", "l": "1", "I": "1", "z": "2", "Z": "2", "S": "5", "B": "8"})

BAD_TITLE_NAMES = {
    "minutes", "minute", "min", "easy", "medium", "hard", "calories", "difficulty",
    "total time", "kcal", "time",
}


def extract_title(text: str) -> tuple[str | None, str | None]:
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    for ln in lines[:8]:
        low = ln.lower()
        if any(x in low for x in ("difficulty", "calories", "total time", "arise", "nicolina", "kcal")):
            continue
        if re.fullmatch(r"easy|medium|hard|\d+", low):
            continue
        # OCR: "Oz. summer..." / "O4.berry..." / "01 protein..."
        m = re.match(r"(?i)^([O0-9IlZSBz]{1,3})\s*[.\-]?\s*(.+)$", ln)
        if not m:
            continue
        raw_num = m.group(1).translate(_OCR_DIGIT)
        raw_num = re.sub(r"\D", "", raw_num)
        if not raw_num:
            continue
        num = str(int(raw_num))
        name = m.group(2).strip(" .,:")
        name = re.sub(r"\s+", " ", name)
        name = re.sub(r"^[,:.\-]+\s*", "", name)
        if re.search(r"\bbow$", name, re.I):
            name = re.sub(r"bow$", "bowl", name, flags=re.I)
        if len(name) < 3 or normalize(name) in BAD_TITLE_NAMES:
            continue
        if re.search(r"(?i)kcal|\d+\s*[PCF]\b", name):
            continue
        if normalize(name) in {"minutes", "miniutes"}:
            continue
        return num, name
    return None, None


def extract_time(text: str) -> int | None:
    m = re.search(r"(\d+)\s*(?:minutes|minute|min|miniutes)", text, re.I)
    return int(m.group(1)) if m else None


def is_title_page(text: str) -> bool:
    t = text.lower()
    return (
        ("difficulty" in t or "calories" in t or "total time" in t)
        and "ingredients" not in t
        and "instructions" not in t
    )


def is_ingredient_page(text: str) -> bool:
    t = text.lower()
    return "ingredients" in t or "instructions" in t


def build_recipes() -> tuple[list[dict], list[dict]]:
    index, keys = load_catalog()
    # validate aliases
    global ALIASES
    ALIASES = {k: v for k, v in ALIASES.items() if v in keys}

    pages = {int(p.stem): p.read_text(encoding="utf-8", errors="replace") for p in TEXT_DIR.glob("*.txt")}

    titles: list[tuple[int, str, str, int | None]] = []
    for pg, text in sorted(pages.items()):
        if not is_title_page(text):
            continue
        num, name = extract_title(text)
        if not name or not num:
            continue
        titles.append((pg, num, name, extract_time(text)))

    # dedupe by recipe number (keep first)
    seen_nums = set()
    uniq = []
    for t in titles:
        if t[1] in seen_nums:
            continue
        seen_nums.add(t[1])
        uniq.append(t)
    titles = uniq

    recipes = []
    missing_acc: OrderedDict[str, dict] = OrderedDict()

    for i, (pg, num, name, cook_time) in enumerate(titles):
        next_title = titles[i + 1][0] if i + 1 < len(titles) else pg + 3
        # Ingredient page lies strictly between this title and the next
        between = [
            adj
            for adj in range(min(pg, next_title) + 1, max(pg, next_title))
            if adj in pages and is_ingredient_page(pages[adj])
        ]
        if not between:
            # fallback: nearest adjacent ingredient page
            for adj in (pg + 1, pg - 1, pg + 2, pg - 2):
                if adj in pages and is_ingredient_page(pages[adj]):
                    between = [adj]
                    break
        # Prefer densest ingredient line
        def dens(pgs: int) -> int:
            return len(re.findall(r"\d+\s*(?:g|ml|tsp|tbsp)\b", pages[pgs], re.I))

        ing_page = max(between, key=dens) if between else None
        ing_text = pages[ing_page] if ing_page else ""

        line = extract_ingredient_line(ing_text) if ing_text else ""
        raw_ings = parse_ingredients(line)
        steps = extract_steps(ing_text) if ing_text else ""

        mapped = []
        for ing in raw_ings:
            catalog_key = match_ingredient(ing["name"], index, keys)
            if catalog_key and catalog_key in keys:
                mapped.append({"catalogKey": catalog_key, "quantity": ing["quantity"], "unit": "gram"})
            else:
                miss_key = re.sub(r"[^a-z0-9]+", "_", normalize(ing["name"])).strip("_")
                if not miss_key:
                    continue
                if miss_key not in missing_acc:
                    missing_acc[miss_key] = {
                        "name": ing["name"].strip(),
                        "suggestedKey": miss_key,
                        "exampleQuantityGrams": ing["quantity"],
                        "seenInRecipes": [],
                        "rawExamples": [],
                    }
                entry = missing_acc[miss_key]
                if name not in entry["seenInRecipes"]:
                    entry["seenInRecipes"].append(name)
                raw = f"{ing['quantity']}g {ing['name']}"
                if raw not in entry["rawExamples"]:
                    entry["rawExamples"].append(raw)
                # Keep placeholder in recipe so structure is ready once catalog is updated
                mapped.append({
                    "catalogKey": miss_key,
                    "quantity": ing["quantity"],
                    "unit": "gram",
                })

        merged: OrderedDict[str, dict] = OrderedDict()
        for m in mapped:
            k = m["catalogKey"]
            if k in merged:
                merged[k]["quantity"] = round(merged[k]["quantity"] + m["quantity"], 1)
            else:
                merged[k] = m

        recipes.append({
            "id": f"arise_{int(num):03d}",
            "servings": 1,
            "imageId": str(pg),
            "sourcePage": pg,
            "translations": {
                "ru": {"name": name, "steps": steps},
                "en": {"name": name, "steps": steps},
            },
            "ingredients": list(merged.values()),
            "cookTimeMinutes": cook_time or 15,
        })

    return recipes, list(missing_acc.values())


def main():
    recipes, missing = build_recipes()
    out = {
        "version": 2,
        "source": "ARISE COOKBOOK — Nicolina Nunes",
        "recipes": recipes,
    }
    OUT_RECIPES.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    OUT_MISSING.write_text(
        json.dumps(
            {
                "description": "Ingredients from ARISE COOKBOOK not found in food-catalog.json. Add these products to the catalog, then re-run tools/parse_arise_recipes.py.",
                "count": len(missing),
                "ingredients": missing,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"recipes: {len(recipes)}")
    print(f"missing ingredients: {len(missing)}")
    for r in recipes[:5]:
        print(f"  {r['id']}: {r['translations']['en']['name']} ({len(r['ingredients'])} ings)")
        for ing in r["ingredients"]:
            print(f"      {ing['catalogKey']} {ing['quantity']}g")


if __name__ == "__main__":
    main()
