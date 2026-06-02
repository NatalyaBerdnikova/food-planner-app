#!/usr/bin/env python3
import argparse
import html
import json
import re
import ssl
import sys
import urllib.request


NUTRIENT_MAP = [
    ([r"калорийность", r"энергетическая ценность"], "caloriesPer100g", "kcal"),
    ([r"белки"], "proteinPer100g", "g"),
    ([r"жиры"], "fatPer100g", "g"),
    ([r"углеводы"], "carbsPer100g", "g"),
    ([r"витамин\s*а\b", r"vitamin\s*a", r"ретинол"], "vitaminAPer100g", "mcg"),
    ([r"витамин\s*в6|b6|пиридоксин"], "vitaminB6Per100g", "g"),
    ([r"витамин\s*в12|b12|кобаламин"], "vitaminB12Per100g", "mcg"),
    ([r"витамин\s*с\b|c\b.*витамин|аскорбин"], "vitaminCPer100g", "mg"),
    ([r"витамин\s*d3|витамин\s*d\b|d3\b"], "vitaminD3Per100g", "mcg"),
    ([r"витамин\s*е\b|витамин\s*e\b|токоферол"], "vitaminEPer100g", "g"),
    ([r"витамин\s*к\b|витамин\s*k\b"], "vitaminKPer100g", "mcg"),
    ([r"калий", r"\bk\b.*мг"], "potassiumPer100g", "mg"),
    ([r"кальций", r"\bca\b"], "calciumPer100g", "mg"),
    ([r"магний", r"\bmg\b.*макро"], "magnesiumPer100g", "mg"),
    ([r"железо", r"\bfe\b"], "ironPer100g", "g"),
    ([r"селен", r"\bse\b"], "seleniumPer100g", "mcg"),
    ([r"цинк", r"\bzn\b"], "zincPer100g", "mg"),
    ([r"хром", r"\bcr\b"], "chromiumPer100g", "mcg"),
    ([r"йод", r"\bi\b.*мкг"], "iodinePer100g", "mcg"),
    ([r"фолат|витамин\s*в9|b9"], "vitaminB9Per100g", "mcg"),
    ([r"пищевые волокна|клетчатк|fiber"], "fiberPer100g", "g"),
]


def slugify(value: str) -> str:
    s = value.lower()
    s = re.sub(r"[^a-zа-яё0-9]+", "_", s, flags=re.IGNORECASE)
    s = re.sub(r"^_+|_+$", "", s)
    return s[:64] or "product"


def strip_tags(text: str) -> str:
    text = re.sub(r"<[^>]+>", " ", text)
    text = html.unescape(text)
    return re.sub(r"\s+", " ", text).strip()


def parse_amount(text: str):
    t = text.lower().strip()
    m = re.search(r"([\d.,]+)\s*(ккал|ккалорий|kcal|г|гр|g|мг|mg|мкг|μg|mcg)?", t, re.IGNORECASE)
    if not m:
        return None
    value = float(m.group(1).replace(",", "."))
    unit = (m.group(2) or "").lower()
    if "ккал" in unit or unit == "kcal":
        unit = "kcal"
    elif unit in ("г", "гр", "g"):
        unit = "g"
    elif unit in ("мг", "mg"):
        unit = "mg"
    elif unit in ("мкг", "μg", "mcg"):
        unit = "mcg"
    return value, unit


def convert_unit(value: float, from_unit: str, target_unit: str) -> float:
    if from_unit == target_unit or target_unit == "kcal":
        return value
    if from_unit == "mg" and target_unit == "mcg":
        return value * 1000
    if from_unit == "mcg" and target_unit == "mg":
        return value / 1000
    if from_unit == "g" and target_unit == "mg":
        return value * 1000
    return value


def empty_product():
    return {
        "catalogKey": "",
        "displayName": "",
        "category": "other",
        "defaultPieceWeightGrams": 100,
        "caloriesPer100g": 0,
        "proteinPer100g": 0,
        "fatPer100g": 0,
        "carbsPer100g": 0,
        "fiberPer100g": 0,
        "vitaminD3Per100g": 0,
        "calciumPer100g": 0,
        "magnesiumPer100g": 0,
        "zincPer100g": 0,
        "vitaminKPer100g": 0,
        "vitaminCPer100g": 0,
        "vitaminEPer100g": 0,
        "vitaminAPer100g": 0,
        "vitaminB6Per100g": 0,
        "vitaminB9Per100g": 0,
        "vitaminB12Per100g": 0,
        "seleniumPer100g": 0,
        "chromiumPer100g": 0,
        "ironPer100g": 0,
        "potassiumPer100g": 0,
        "iodinePer100g": 0,
    }


def parse_health_diet_html(page_html: str):
    product = empty_product()

    h1 = re.search(r"<h1[^>]*>(.*?)</h1>", page_html, flags=re.IGNORECASE | re.DOTALL)
    if h1:
        name = strip_tags(h1.group(1))
        name = re.sub(r"^калорийность\s*", "", name, flags=re.IGNORECASE).strip().strip(".")
        product["displayName"] = name
        product["catalogKey"] = slugify(name)

    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", page_html, flags=re.IGNORECASE | re.DOTALL):
        cells = re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row, flags=re.IGNORECASE | re.DOTALL)
        if len(cells) < 2:
            continue
        nutrient_name = strip_tags(cells[0])
        amount_text = strip_tags(cells[1])
        if not nutrient_name or not amount_text:
            continue
        if re.search(r"нутриент|норма", nutrient_name, re.IGNORECASE):
            continue
        parsed = parse_amount(amount_text)
        if not parsed:
            continue
        value, unit = parsed
        for patterns, field, target_unit in NUTRIENT_MAP:
            if any(re.search(p, nutrient_name, re.IGNORECASE) for p in patterns):
                product[field] = convert_unit(value, unit, target_unit)
                break

    if not product["caloriesPer100g"]:
        body_text = strip_tags(page_html)
        cal_match = re.search(r"(\d+[.,]?\d*)\s*ккал", body_text, re.IGNORECASE)
        if cal_match:
            product["caloriesPer100g"] = float(cal_match.group(1).replace(",", "."))
    return product


def fetch_url(url: str, timeout: int = 25, insecure_ssl: bool = False) -> str:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (food-planner parser)"},
    )
    context = ssl._create_unverified_context() if insecure_ssl else None
    with urllib.request.urlopen(req, timeout=timeout, context=context) as res:
        return res.read().decode("utf-8", errors="ignore")


def main():
    parser = argparse.ArgumentParser(description="Parse health-diet page into food-planner product JSON.")
    parser.add_argument("url", help="health-diet product page URL")
    parser.add_argument("--out", help="Output file path (default: stdout)")
    parser.add_argument("--insecure-ssl", action="store_true", help="Disable TLS certificate verification")
    args = parser.parse_args()

    page_html = fetch_url(args.url, timeout=25, insecure_ssl=args.insecure_ssl)

    product = parse_health_diet_html(page_html)
    out = json.dumps(product, ensure_ascii=False, indent=2)

    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(out + "\n")
    else:
        sys.stdout.write(out + "\n")


if __name__ == "__main__":
    main()
