#!/usr/bin/env python3
"""
Rebuild arise-recipes-catalog.json from tools/arise-cookbook-full.txt
(OCR text dump of ARISE COOKBOOK). Keeps every parsed ingredient in recipes;
unmatched catalog keys also go to arise-missing-ingredients.json.
"""

from __future__ import annotations

import json
import re
from collections import OrderedDict
from pathlib import Path

ROOT = Path("/Users/natalya/Work/food-planner")
FULL_TEXT = ROOT / "tools/arise-cookbook-full.txt"
TEXT_DIR = ROOT / "tools/arise-text"
FOOD_CATALOG = ROOT / "food-planner/Resources/food-catalog.json"
OUT_RECIPES = ROOT / "food-planner/Resources/arise-recipes-catalog.json"
OUT_MISSING = ROOT / "food-planner/Resources/arise-missing-ingredients.json"
OUT_FULL = ROOT / "tools/arise-cookbook-full.txt"

ALIASES: dict[str, str] = {
    "milk": "milk_3_5_fat_sterilized",
    "yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "greek yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "plain yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "high protein plain yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "high protein yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "protein yogurt": "yogurt_grecheskiy_1_9_zhirnosti_naturalnyy",
    "cottage cheese": "tvorog_5_zhirnosti",
    "egg": "yaytso_kurinoe",
    "eggs": "yaytso_kurinoe",
    "hard boiled eggs": "yaytso_kurinoe",
    "hard boiled egg": "yaytso_kurinoe",
    "egg white": "chicken_egg_white",
    "egg whites": "chicken_egg_white",
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
    "shrimps": "far_eastern_shrimp_meat",
    "prawns": "far_eastern_shrimp_meat",
    "jamon": "okorok_vareno_kopchyonyy_produkt_udalen",
    "ham": "okorok_vareno_kopchyonyy_produkt_udalen",
    "tomato": "pomidor_tomat",
    "tomatoes": "pomidor_tomat",
    "cherry tomatoes": "pomidor_tomat",
    "tomato sauce": "tomatnaya_pasta_konservy",
    "onion": "bulb_onion",
    "medium onion": "bulb_onion",
    "red onion": "bulb_onion",
    "garlic": "garlic_clove",
    "garlic clove": "garlic_clove",
    "banana": "banana",
    "mango": "mango",
    "orange": "orange",
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
    "corn starch": "cornstarch",
    "red onion": "redonion",
    "redonion": "redonion",
    "blueberry": "golubika",
    "blueberries": "golubika",
    "strawberry": "strawberries",
    "strawberries": "strawberries",
    "raspberry": "raspberries",
    "raspberries": "raspberries",
    "berries": "strawberries",
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
    "sweet potato": "batata_sweet_potatoes",
    "carrot": "carrots_product_removed",
    "carrots": "carrots_product_removed",
    "beetroot": "beetroots",
    "cucumber": "pickled_cucumber",
    "bell pepper": "bell_red",
    "broccoli": "brokkoli",
    "bimi": "brokkoli",
    "grapefruit": "greypfrut",
    "peach": "peach",
    "olive oil": "olive_oil",
    "coconut oil": "coconut_oil_liquid",
    "honey": "bee_honey",
    "cocoa": "cocoa_powder",
    "cocoa powder": "cocoa_powder",
    "100 cocoa": "cocoa_powder",
    "100% cocoa": "cocoa_powder",
    "dark chocolate": "shokolad_gorkiy",
    "chocolate": "shokolad_gorkiy",
    "peanut butter": "peanut_butter_liquid",
    "oats": "oatmeal",
    "oatmeal": "oatmeal",
    "rolled oats": "oatmeal",
    "rice": "white_rice_rice_groats",
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
    "italian seasoning": "oregano_sushenyy",
    "bell pepper red": "bell_red",
    "red bell pepper": "bell_red",
}

# Prefer missing over wrong catalog match for spices without good keys
FORCE_MISSING = {"black pepper", "pepper", "salt and pepper", "parsley"}

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
    "figs": 40, "apple": 150, "naan": 90, "slice": 30, "slices": 30,
    "raspberry": 5, "raspberries": 5, "blueberry": 2, "blueberries": 2,
    "strawberry": 12, "strawberries": 12, "leaf": 1, "cloves": 5,
}


def normalize(s: str) -> str:
    s = s.lower()
    s = s.replace("½", "1/2").replace("¼", "1/4").replace("¾", "3/4")
    s = s.replace("vz", "1/2").replace("v2", "1/2")
    s = re.sub(r"[^a-z0-9/%.\-]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def parse_fraction(token: str) -> float | None:
    token = token.strip().lower().replace(",", ".")
    token = re.sub(r"(?<=\d)o(?=\d)", "0", token)
    m = re.fullmatch(r"(\d+)\s*/\s*(\d+)", token)
    if m:
        den = float(m.group(2))
        return float(m.group(1)) / den if den else None
    try:
        return float(token)
    except ValueError:
        return None


def suggested_key(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", normalize(name)).strip("_") or "unknown"


def load_pages() -> dict[int, str]:
    """Prefer per-page OCR files; rebuild full text dump."""
    pages: dict[int, str] = {}
    if TEXT_DIR.exists():
        for p in TEXT_DIR.glob("*.txt"):
            pages[int(p.stem)] = p.read_text(encoding="utf-8", errors="replace")
    # Write / refresh full dump
    parts = []
    for n in sorted(pages):
        parts.append(f"\n\n===== PAGE {n} =====\n\n{pages[n].strip()}")
    OUT_FULL.write_text("".join(parts) + "\n", encoding="utf-8")
    return pages


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
            if norm and norm not in index:
                index[norm] = key
    return index, keys


def match_ingredient(name: str, index: dict[str, str], keys: set[str]) -> str | None:
    n = normalize(name)
    n = re.sub(
        r"\b(fresh|raw|frozen|dried|chopped|sliced|diced|medium|large|small|"
        r"to taste|optional|melted|cooked|boiled|grated|crushed)\b",
        " ",
        n,
    )
    n = re.sub(r"\s+", " ", n).strip()
    n = re.sub(r"^\d+\s*%?\s*", "", n).strip()
    if not n or len(n) < 2:
        return None
    if n in FORCE_MISSING or any(n == x or n.endswith(" " + x) for x in FORCE_MISSING):
        if n in ("salt",) and "salt" in ALIASES and ALIASES["salt"] in keys:
            return ALIASES["salt"]
        if n in FORCE_MISSING and n != "salt":
            return None

    if n in ALIASES and ALIASES[n] in keys:
        return ALIASES[n]
    if n in index:
        return index[n]

    best_alias = None
    best_score = (-1, -1)
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


def fix_ocr(text: str) -> str:
    t = text
    t = t.replace("½", "1/2").replace("¼", "1/4").replace("¾", "3/4")
    t = t.replace("Vz", "1/2").replace("vz", "1/2").replace("V2", "1/2")
    t = re.sub(r"\bV[/\\]?4(?=\s|[a-zA-Z]|$)", "1/4 ", t)
    t = re.sub(r"\b1[oO0]{2}ml\b", "100ml", t, flags=re.I)
    t = re.sub(r"\b1[oO0]{2}g\b", "100g", t, flags=re.I)
    t = re.sub(r"\b2[oO0]g\b", "20g", t, flags=re.I)
    t = re.sub(r"\b2[oO0]{2}g\b", "200g", t, flags=re.I)
    t = re.sub(r"\bz[oO0]{2}g\b", "200g", t, flags=re.I)  # zo0g / zoog
    t = re.sub(r"\b25[oO]ml\b", "250ml", t)
    t = re.sub(r"\b(\d{2})[oO]ml\b", r"\g<1>0ml", t)  # 15oml -> 150ml
    t = re.sub(r"(\d)o(\d)", r"\1\2", t, flags=re.I)
    t = re.sub(r"(\d)\s*(g|ml|tsp|tbsp)of\b", r"\1\2 of ", t, flags=re.I)
    t = re.sub(r"(\d)(g|ml|tsp|tbsp)of\b", r"\1\2 of ", t, flags=re.I)
    # bare tbsp/tsp of -> 1 tbsp/tsp of
    t = re.sub(r"(?<![\d/])\b(tbsp|tsp)\s+of\b", r"1 \1 of", t, flags=re.I)
    replacements = [
        ("ofjamon", "of jamon"),
        ("thejamon", "the jamon"),
        ("saltand", "salt and"),
        ("theegg", "the egg"),
        ("ofegg", "of egg"),
        ("eggsare", "eggs are"),
        ("eggsonapan", "eggs on a pan"),
        ("sunnyside", "sunny side"),
        ("hummusand", "hummus and"),
        ("1kiwi", "1 kiwi"),
        ("1tomato", "1 tomato"),
        ("1onion", "1 onion"),
        ("1egg", "1 egg"),
        ("1banana", "1 banana"),
        ("1zucchini", "1 zucchini"),
        ("1zuchinni", "1 zucchini"),
        ("1tbsp", "1 tbsp"),
        ("1tsp", "1 tsp"),
        ("2tbsp", "2 tbsp"),
        ("2tsp", "2 tsp"),
        ("1/4of", "1/4 of"),
        ("1/2cup", "1/2 cup"),
        ("1/4cup", "1/4 cup"),
        ("1cup", "1 cup"),
        ("2cups", "2 cups"),
        ("1/2medium", "1/2 medium"),
        ("1/4medium", "1/4 medium"),
        ("drops of water", "5 ml of water"),
        ("boiledeggs", "boiled eggs"),
        ("slicesof", "slices of"),
        ("ofitalian", "of italian"),
        ("Addthe", "Add the"),
        ("ina ", "in a "),
        ("inabowl", "in a bowl"),
        ("shereded", "shredded"),
        ("expresso", "espresso"),
        ("arrise cookbook", "arise cookbook"),
        ("drise cookbook", "arise cookbook"),
        ("O% sugar", "0% sugar"),
        ("0% sugar syrup", "sugar syrup"),
        ("olive il", "olive oil"),
        ("spirulin a", "spirulina"),
    ]
    for a, b in replacements:
        t = t.replace(a, b)
    t = re.sub(r"(\d+)(g|ml)\s*of", r"\1\2 of", t, flags=re.I)
    # medium tomatoes without qty
    t = re.sub(r"(?<![\d/])\bmedium tomatoes\b", "2 tomatoes", t, flags=re.I)
    return t


INSTRUCTION_START = re.compile(
    r"^\s*(add|mix|blend|cook|heat|bake|fry|slice|chop|cut|place|pour|spread|"
    r"toast|saute|sauté|remove|start|after|preheat|season|serve|melt|put|make|"
    r"brush|until|then|in a|ina |on a|a non-stick|heat the|after the)\b",
    re.I,
)


def extract_ingredient_blob(page_text: str) -> str:
    text = fix_ocr(page_text)
    low = text.lower()
    idx = low.find("ingredients")
    chunk = text[idx + len("ingredients") :] if idx >= 0 else text
    for stop in ("arise cookbook", "nicolina", "arrise cookbook"):
        si = chunk.lower().find(stop)
        if si > 0:
            chunk = chunk[:si]

    # Prefer the line with most quantity markers; also keep short "to taste" bits
    lines = [ln.strip() for ln in re.split(r"[\n;]+", chunk) if ln.strip()]
    qty_re = re.compile(
        r"\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?\s*(?:g|gr|grams?|kg|ml|l|tsp|tbsp|cups?|cup)\b|"
        r"\b\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?\s+(?:of\s+)?[a-z]",
        re.I,
    )

    scored = []
    for ln in lines:
        if INSTRUCTION_START.match(ln) and len(qty_re.findall(ln)) < 2:
            continue
        score = len(qty_re.findall(ln)) + 3 * len(re.findall(r"\bg\s+of\b", ln, re.I))
        if "to taste" in ln.lower():
            score += 1
        scored.append((score, ln))

    # Also whole chunk collapsed
    flat = re.sub(r"\s+", " ", chunk).strip()
    scored.append((len(qty_re.findall(flat)) + 3 * len(re.findall(r"\bg\s+of\b", flat, re.I)), flat))
    scored.sort(key=lambda x: -x[0])
    best = scored[0][1] if scored else flat

    # Strip leading instruction sentences glued before quantities
    m = re.search(
        r"(?:\d+(?:[.,]\d+)?(?:\s*/\s*\d+)?\s*(?:g|ml|tsp|tbsp|cup)|\b\d+\s+[a-z]|\bbagel\b|\btortilla\b)",
        best,
        re.I,
    )
    if m and m.start() > 0:
        # keep from first qty-like token, but if bagel/tortilla at start of leftover OK
        prefix = best[: m.start()]
        if len(prefix) > 40 and INSTRUCTION_START.match(prefix.strip()):
            best = best[m.start() :]
    return best


# Quantity token that starts a new ingredient (must not split inside "25g", "1/2", or "100%")
QTY_TOKEN = (
    r"(?<![\d./])(?:\d+\s*/\s*\d+|\d+(?:[.,]\d+)?)(?!%)\s*"
    r"(?:g|gr|grams?|kg|ml|l|tsp|tbsp|teaspoons?|tablespoons?|cups?|cup)?\b"
)

SPLIT_RE = re.compile(rf"(?=({QTY_TOKEN}))", re.I)

ITEM_RE = re.compile(
    r"^(?P<qty>\d+\s*/\s*\d+|\d+(?:[.,]\d+)?)\s*"
    r"(?P<unit>g|gr|grams?|kg|ml|l|tsp|tbsp|teaspoons?|tablespoons?|cups?|cup)?\s*"
    r"(?:of\s+)?"
    r"(?:(?P<pct>\d+)\s*%\s*)?"
    r"(?P<name>.+)$",
    re.I,
)

# leading bare item without qty: "bagel", "salt and pepper"
BARE_LEAD = re.compile(
    r"^(?P<name>bagel|naan(?:\s+bread)?|tortilla(?:\s+wraps?)?|pita|wraps?|"
    r"salt(?:\s+and\s+pepper)?|pepper|parsley|oregano|basil|cilantro|dill|"
    r"cherry\s+tomatoes(?:\s+chopped)?)\b",
    re.I,
)


def clean_name(name: str) -> str:
    name = name.strip(" ,.;:")
    name = re.sub(r"\([^)]*\)", " ", name)
    # cut trailing instruction / garnish fragments early
    name = re.split(
        r"\b(qb|to garnish|to garish|garnish|add salt|bake for|season with|finish|"
        r"until|cook for|place the|spread|in a|ina |add the|mix|blend|cut the|"
        r"put it|melt the|after|heat the|let it|saute|recipe n)\b",
        name,
        maxsplit=1,
        flags=re.I,
    )[0]
    name = re.sub(
        r"\b(to taste|optional|and|or|with|chopped|sliced|diced|melted|frozen|cooked|"
        r"peeled|grilled|medium)\b",
        " ",
        name,
        flags=re.I,
    )
    name = re.sub(r"\s+", " ", name).strip(" ,.;:?")
    # drop trailing seasoning leftovers stuck on name
    name = re.sub(
        r"\b(salt|black pepper|pepper|parsley|oregano|basil|cilantro|dill)\s*$",
        "",
        name,
        flags=re.I,
    ).strip(" ,.;:")
    # normalize "bell pepper red" / "pepper red"
    name = re.sub(r"\bbell\s+pepper\s+red\b", "red bell pepper", name, flags=re.I)
    name = re.sub(r"\bpepper\s+red\b", "red bell pepper", name, flags=re.I)
    return name


def grams_for(qty: float, unit: str, name: str) -> float:
    unit = (unit or "").lower()
    if unit:
        return qty * UNIT_TO_GRAMS.get(unit, 1.0)
    base = normalize(name).split()[0] if name else ""
    pw = PIECE_WEIGHTS.get(base) or PIECE_WEIGHTS.get(normalize(name))
    return qty * (pw if pw else 30.0)


def parse_ingredients(blob: str) -> list[dict]:
    if not blob:
        return []
    blob = fix_ocr(blob)
    blob = re.sub(r"\s+", " ", blob).strip()

    items: list[dict] = []
    seen: set[tuple[str, float]] = set()

    def add(name: str, qty: float, unit: str, raw: str):
        name = clean_name(name)
        if not name or len(normalize(name)) < 2:
            return
        nl = normalize(name)
        # skip instruction-ish leftovers
        if any(w in nl for w in ("minute", "ready", "plate", "everything", "smooth until", "freezer")):
            return
        if nl in {"of", "a", "the", "and", "or", "with", "on", "to", "for", "in", "some"}:
            return
        g = round(grams_for(qty, unit, name), 1)
        if g <= 0 or g > 8000:
            return
        key = (nl, g)
        if key in seen:
            return
        # merge same name different rounding
        for sn, sg in list(seen):
            if sn == nl:
                return
        seen.add(key)
        items.append({"name": name, "quantity": g, "unit": "gram", "raw": raw.strip()})

    rest = blob

    # Leading bare ingredient (bagel / tortilla...)
    while True:
        m = BARE_LEAD.match(rest)
        if not m:
            break
        add(m.group("name"), 1.0, "", m.group("name"))
        rest = rest[m.end():].lstrip(" ,;")

    # Normalize "1/2avocado" -> "1/2 avocado"
    rest = re.sub(
        r"(\d+\s*/\s*\d+|\d+(?:[.,]\d+)?)([a-zA-Z])",
        r"\1 \2",
        rest,
    )

    # Find all quantity-led segments without breaking multi-digit numbers
    matches = list(re.finditer(rf"{QTY_TOKEN}", rest, re.I))
    if not matches:
        # taste-only leftovers
        for taste in re.finditer(
            r"\b(salt(?:\s+and\s+pepper)?|black\s+pepper|pepper|parsley|oregano|basil|"
            r"cilantro|dill|paprika|cumin|cinnamon)\b",
            rest,
            re.I,
        ):
            add(taste.group(1), 1.0, "tsp", taste.group(0))
        return items

    spans = []
    for i, m in enumerate(matches):
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(rest)
        spans.append(rest[start:end].strip(" ,;"))

    # Text before first qty may have taste seasonings
    prefix = rest[: matches[0].start()]
    for taste in re.finditer(
        r"\b(salt(?:\s+and\s+pepper)?|black\s+pepper|pepper|parsley|oregano|basil|"
        r"cilantro|dill|paprika|cumin|cinnamon)\b",
        prefix,
        re.I,
    ):
        add(taste.group(1), 1.0, "tsp", taste.group(0))

    produce = {
        "mango", "orange", "papaya", "kiwi", "banana", "apple", "avocado", "tomato",
        "onion", "garlic", "lemon", "lime", "grapefruit", "peach", "pear",
    }

    for part in spans:
        m = ITEM_RE.match(part)
        if not m:
            continue
        qty = parse_fraction(m.group("qty").replace(" ", ""))
        if qty is None or qty <= 0:
            continue
        unit = m.group("unit") or ""
        name = m.group("name")
        if m.group("pct"):
            name = f"{m.group('pct')}% {name}"

        # Peel trailing seasonings from name into separate items
        for taste in list(re.finditer(
            r"\b(salt(?:\s+and\s+pepper)?|black\s+pepper|pepper|parsley|oregano|"
            r"basil|cilantro|dill)\b(?:\s*to\s*taste)?",
            name,
            re.I,
        ))[::-1]:
            # only if seasoning is near the end
            if taste.end() >= len(name) - 20:
                add(taste.group(1), 1.0, "tsp", taste.group(0))
                name = name[: taste.start()] + name[taste.end() :]

        name = clean_name(name)
        if re.search(r"\bor\b", name, re.I):
            name = re.split(r"\bor\b", name, maxsplit=1, flags=re.I)[0].strip()

        words = normalize(name).split()
        if unit and len(words) >= 2 and words[0] in produce and words[1] in produce:
            add(words[0], qty, unit, part)
            add(words[1], 1.0, "", words[1])
            continue

        # "avocado cherry tomatoes" after 1/2 avocado
        nl = normalize(name)
        if "avocado" in nl and "cherry tomato" in nl:
            add("avocado", qty, unit, part)
            add("cherry tomatoes", 50.0, "g", "cherry tomatoes")
            continue
        if "onion" in nl and "cherry tomato" in nl:
            add("onion", qty, unit, part)
            add("cherry tomatoes", 50.0, "g", "cherry tomatoes")
            continue
        # "blueberries figs" / "garlic tomatoes"
        for extra in ("figs", "fig", "tomatoes", "tomato"):
            if nl.endswith(" " + extra) or nl.endswith(extra):
                head = nl[: -len(extra)].strip()
                if head and head.split()[-1] in produce.union({"blueberries", "blueberry", "cloves", "garlic"}):
                    add(head.replace("cloves of garlic", "garlic").replace("cloves garlic", "garlic"), qty, unit, part)
                    add(extra, 1.0 if extra.startswith("fig") else 2.0, "", extra)
                    break
        else:
            # strip "cloves of" noise
            name2 = re.sub(r"\bcloves?\s+of\s+", "", name, flags=re.I).strip()
            add(name2 or name, qty, unit, part)
            continue
        continue

    return items


def extract_steps(page_text: str) -> str:
    text = fix_ocr(page_text)
    lines = []
    for raw in re.split(r"[\n.]+", text):
        s = raw.strip(" ;,")
        if len(s) < 12:
            continue
        low = s.lower()
        if low in ("instructions", "ingredients") or "arise" in low or "nicolina" in low:
            continue
        if len(re.findall(r"\d+\s*(?:g|ml|tsp|tbsp)\b", low)) >= 3:
            continue
        if INSTRUCTION_START.match(s) or any(
            w in low for w in ("add", "mix", "blend", "cook", "heat", "slice", "chop", "toast", "spread", "preheat", "season", "serve", "fry", "bake", "melt")
        ):
            s = s[0].upper() + s[1:]
            lines.append(s if s.endswith(".") else s + ".")
    out, seen = [], set()
    for ln in lines:
        k = normalize(ln)
        if k in seen:
            continue
        seen.add(k)
        out.append(ln)
    return "\n".join(out)


_OCR_DIGIT = str.maketrans({"O": "0", "o": "0", "l": "1", "I": "1", "z": "2", "Z": "2", "S": "5", "B": "8"})
BAD_TITLES = {"minutes", "minute", "min", "easy", "medium", "hard", "calories", "difficulty", "total time", "kcal", "time"}

OCR_NAME_FIXES = {
    "poachedcggs toast": "poached eggs toast",
    "egg salad Wrep": "egg salad wrap",
    "jamon naan 0": "jamon naan",
    "lupinhummus": "lupin hummus",
    "eggskillet": "egg skillet",
    "breokast cyps": "breakfast cups",
    "pumpkin gorden": "pumpkin garden",
    "shirelzi solad": "shirazi salad",
    "gezpacho": "gazpacho",
    "one pan reasted fish": "one pan roasted fish",
    "Ssparaguo risotto": "asparagus risotto",
    "pico de salmon gallb": "pico de salmon galette",
    "springrolls": "spring rolls",
    "= tometo mushroom pasta": "tomato mushroom pasta",
    "diooerL bowl": "dinner bowl",
    "cinnamon roll pancakel": "cinnamon roll pancake",
    "berryice pops": "berry ice pops",
    "chocolate Smoothie": "chocolate smoothie",
    "roasted pumpkin creamy sOUp": "roasted pumpkin creamy soup",
}


def extract_title(text: str) -> tuple[str | None, str | None]:
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    for ln in lines[:8]:
        low = ln.lower()
        if any(x in low for x in ("difficulty", "calories", "total time", "arise", "nicolina", "kcal")):
            continue
        if re.fullmatch(r"easy|medium|hard|\d+", low):
            continue
        m = re.match(r"(?i)^([O0-9IlZSBz]{1,3})\s*[.\-]?\s*(.+)$", ln)
        if not m:
            continue
        raw_num = re.sub(r"\D", "", m.group(1).translate(_OCR_DIGIT))
        if not raw_num:
            continue
        num = str(int(raw_num))
        name = m.group(2).strip(" .,:;='\"-")
        name = re.sub(r"\s+", " ", name)
        name = re.sub(r"^[,:.\-]+\s*", "", name)
        if re.search(r"\bbow$", name, re.I):
            name = re.sub(r"bow$", "bowl", name, flags=re.I)
        if len(name) < 3 or normalize(name) in BAD_TITLES:
            continue
        if re.search(r"(?i)kcal|\d+\s*[PCF]\b", name):
            continue
        if name in OCR_NAME_FIXES:
            name = OCR_NAME_FIXES[name]
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


def build():
    pages = load_pages()
    index, keys = load_catalog()
    global ALIASES
    ALIASES = {k: v for k, v in ALIASES.items() if v in keys}

    titles: list[tuple[int, str, str, int | None]] = []
    for pg, text in sorted(pages.items()):
        if not is_title_page(text):
            continue
        num, name = extract_title(text)
        if not name or not num:
            continue
        titles.append((pg, num, name, extract_time(text)))

    seen_nums: set[str] = set()
    uniq = []
    for t in titles:
        if t[1] in seen_nums and t[1] != "0":
            continue
        seen_nums.add(t[1])
        uniq.append(t)
    titles = uniq

    recipes = []
    missing_acc: OrderedDict[str, dict] = OrderedDict()

    for i, (pg, num, name, cook_time) in enumerate(titles):
        next_title = titles[i + 1][0] if i + 1 < len(titles) else pg + 3
        between = [
            adj
            for adj in range(min(pg, next_title) + 1, max(pg, next_title))
            if adj in pages and is_ingredient_page(pages[adj])
        ]
        if not between:
            for adj in (pg + 1, pg - 1, pg + 2, pg - 2):
                if adj in pages and is_ingredient_page(pages[adj]):
                    between = [adj]
                    break

        def dens(p: int) -> int:
            return len(re.findall(r"\d+\s*(?:g|ml|tsp|tbsp)\b", pages[p], re.I))

        ing_page = max(between, key=dens) if between else None
        ing_text = pages[ing_page] if ing_page else ""
        blob = extract_ingredient_blob(ing_text) if ing_text else ""
        raw_ings = parse_ingredients(blob)
        steps = extract_steps(ing_text) if ing_text else ""

        mapped = []
        for ing in raw_ings:
            catalog_key = match_ingredient(ing["name"], index, keys)
            if not (catalog_key and catalog_key in keys):
                catalog_key = suggested_key(ing["name"])
                if catalog_key not in missing_acc:
                    missing_acc[catalog_key] = {
                        "name": ing["name"],
                        "suggestedKey": catalog_key,
                        "exampleQuantityGrams": ing["quantity"],
                        "seenInRecipes": [],
                        "usages": [],
                        "rawExamples": [],
                    }
                entry = missing_acc[catalog_key]
                if name not in entry["seenInRecipes"]:
                    entry["seenInRecipes"].append(name)
                entry["usages"].append({
                    "recipeId": f"arise_{int(num):03d}" if num.isdigit() else f"arise_{pg:03d}",
                    "recipeName": name,
                    "quantity": ing["quantity"],
                    "unit": "gram",
                })
                if ing.get("raw") and ing["raw"] not in entry["rawExamples"]:
                    entry["rawExamples"].append(ing["raw"])

            mapped.append({
                "catalogKey": catalog_key,
                "quantity": ing["quantity"],
                "unit": "gram",
            })

        merged: OrderedDict[str, dict] = OrderedDict()
        for m in mapped:
            k = m["catalogKey"]
            if k in merged:
                merged[k]["quantity"] = round(merged[k]["quantity"] + m["quantity"], 1)
            else:
                merged[k] = dict(m)

        rid = f"arise_{int(num):03d}" if num.isdigit() else f"arise_{pg:03d}"
        if num == "0":
            rid = f"arise_{pg:03d}"

        display = name
        if display in OCR_NAME_FIXES:
            display = OCR_NAME_FIXES[display]
        display = display[0].upper() + display[1:] if display else display

        recipes.append({
            "id": rid,
            "servings": 1,
            "imageId": str(pg),
            "translations": {
                "ru": {"name": display, "steps": steps},
                "en": {"name": display, "steps": steps},
            },
            "ingredients": list(merged.values()),
            "cookTimeMinutes": cook_time or 15,
            "_debugBlob": blob,
            "_ingPage": ing_page,
        })

    # Fix duplicate ids
    used = set()
    for r in recipes:
        base = r["id"]
        if base not in used:
            used.add(base)
            continue
        n = 1
        while f"{base}_{n}" in used:
            n += 1
        r["id"] = f"{base}_{n}"
        used.add(r["id"])

    return recipes, list(missing_acc.values())


def main():
    recipes, missing = build()
    clean = []
    for r in recipes:
        clean.append({k: v for k, v in r.items() if not k.startswith("_")})

    OUT_RECIPES.write_text(
        json.dumps({
            "version": 2,
            "source": "ARISE COOKBOOK — Nicolina Nunes",
            "textSource": "tools/arise-cookbook-full.txt",
            "recipes": clean,
        }, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    OUT_MISSING.write_text(
        json.dumps({
            "description": (
                "Ingredients from ARISE COOKBOOK not found in food-catalog.json. "
                "They ARE still listed in arise-recipes-catalog.json under suggestedKey. "
                "Add them to food-catalog.json using suggestedKey as catalogKey."
            ),
            "count": len(missing),
            "ingredients": sorted(missing, key=lambda x: (-len(x["seenInRecipes"]), x["suggestedKey"])),
        }, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"full text -> {OUT_FULL} ({OUT_FULL.stat().st_size} bytes)")
    print(f"recipes: {len(clean)}")
    print(f"missing: {len(missing)}")
    avg = sum(len(r["ingredients"]) for r in clean) / max(len(clean), 1)
    print(f"avg ingredients/recipe: {avg:.1f}")
    for r in clean[:6]:
        print(f"  {r['id']}: {r['translations']['en']['name']} -> {len(r['ingredients'])} ings")
        for ing in r["ingredients"]:
            print(f"      {ing['catalogKey']}: {ing['quantity']}g")


if __name__ == "__main__":
    main()
