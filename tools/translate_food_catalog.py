#!/usr/bin/env python3
import argparse
import json
import re
import ssl
import time
import urllib.parse
import urllib.request


def slugify(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    value = re.sub(r"_+", "_", value).strip("_")
    return value or "item"


def translit_fallback(text: str) -> str:
    table = {
        "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "yo", "ж": "zh",
        "з": "z", "и": "i", "й": "y", "к": "k", "л": "l", "м": "m", "н": "n", "о": "o",
        "п": "p", "р": "r", "с": "s", "т": "t", "у": "u", "ф": "f", "х": "kh", "ц": "ts",
        "ч": "ch", "ш": "sh", "щ": "sch", "ъ": "", "ы": "y", "ь": "", "э": "e", "ю": "yu",
        "я": "ya",
    }
    out = []
    for ch in text.lower():
        out.append(table.get(ch, ch))
    return "".join(out)


def translate_text(text: str, source: str = "ru", target: str = "en") -> str:
    q = urllib.parse.quote(text)
    url = f"https://api.mymemory.translated.net/get?q={q}&langpair={source}|{target}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    context = ssl._create_unverified_context()
    with urllib.request.urlopen(req, timeout=8, context=context) as resp:
        data = json.loads(resp.read().decode("utf-8", errors="ignore"))
    translated = data.get("responseData", {}).get("translatedText", "").strip()
    return translated


def unique_slug(base: str, used: set[str]) -> str:
    if base not in used:
        used.add(base)
        return base
    i = 2
    while f"{base}_{i}" in used:
        i += 1
    candidate = f"{base}_{i}"
    used.add(candidate)
    return candidate


def main():
    parser = argparse.ArgumentParser(description="Translate food-catalog keys and add ru/en translations.")
    parser.add_argument("--in", dest="inp", required=True, help="Input food-catalog.json")
    parser.add_argument("--out", dest="out", required=True, help="Output food-catalog.json")
    parser.add_argument("--delay", type=float, default=0.25, help="Delay between translation requests")
    args = parser.parse_args()

    with open(args.inp, "r", encoding="utf-8") as f:
        payload = json.load(f)

    products = payload.get("products", [])

    key_cache: dict[str, str] = {}
    translation_cache: dict[str, str] = {}
    used_keys: set[str] = set()

    for idx, item in enumerate(products, start=1):
        old_key = str(item.get("catalogKey", "")).strip()
        ru_name = (
            str(item.get("translations", {}).get("ru", "")).strip()
            or str(item.get("displayName", "")).strip()
            or old_key
        )

        if ru_name in translation_cache:
            translated_ru = translation_cache[ru_name]
        else:
            try:
                translated_ru = translate_text(ru_name)
                time.sleep(args.delay)
            except Exception:
                translated_ru = translit_fallback(ru_name)
            translation_cache[ru_name] = translated_ru

        key_en = slugify(translated_ru)
        key_en = unique_slug(key_en, used_keys)
        name_en = translated_ru.replace("_", " ").strip()

        item["catalogKey"] = key_en
        item["translations"] = {
            "ru": ru_name,
            "en": name_en,
        }

        if idx % 25 == 0:
            print(f"Processed {idx}/{len(products)}", flush=True)

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Done: {len(products)} products updated", flush=True)


if __name__ == "__main__":
    main()
