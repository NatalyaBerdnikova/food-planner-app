#!/usr/bin/env python3
"""Локальная лаборатория импорта рецептов (зеркало пайплайна приложения).

Основной источник данных сейчас — caption из tools/instagram-examples.txt
(Instagram URL опционален, когда доступ к API снова будет).

Примеры:
  python3 tools/import_recipe_lab.py --list
  python3 tools/import_recipe_lab.py --example 3
  python3 tools/import_recipe_lab.py --example 1 --lang en
  python3 tools/import_recipe_lab.py --all
  python3 tools/import_recipe_lab.py --caption '...'
  python3 tools/import_recipe_lab.py --serve --port 8765
"""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass, field
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TOOLS = Path(__file__).resolve().parent
DEFAULT_SECRETS = ROOT / "food-planner" / "ImportSecrets.plist"
DEFAULT_CATALOG = ROOT / "food-planner" / "Resources" / "food-catalog.json"
DEFAULT_EXAMPLES = TOOLS / "instagram-examples.txt"
DEFAULT_HTML = TOOLS / "import-recipe-lab.html"
SCRAPE_BASE = "https://api.scrapecreators.com"

UNITS = (
    "gram",
    "kilogram",
    "milliliter",
    "liter",
    "piece",
    "tablespoon",
    "teaspoon",
)

DERIVED_PRODUCT_MARKERS = {
    "мук",
    "масл",
    "сок",
    "паст",
    "круп",
    "бумаг",
    "сироп",
    "хлоп",
    "хлопя",
    "каш",
    "хлеб",
    "бульон",
    "экстракт",
}


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------


def load_secrets(path: Path | None = None) -> dict[str, Any]:
    secrets_path = path or DEFAULT_SECRETS
    if not secrets_path.exists():
        return {}
    with secrets_path.open("rb") as handle:
        data = plistlib.load(handle)
    return data if isinstance(data, dict) else {}


def cfg(secrets: dict[str, Any], key: str, default: Any = None) -> Any:
    if key in secrets and secrets[key] not in (None, ""):
        return secrets[key]
    return default


# ---------------------------------------------------------------------------
# Units / amounts / stemming (порт Swift-хелперов)
# ---------------------------------------------------------------------------


def normalize_unit(raw: str | None) -> str:
    if not raw:
        return "gram"
    key = raw.strip().lower().replace(".", "")
    if key in UNITS:
        return key
    mapping = {
        "g": "gram",
        "gr": "gram",
        "gram": "gram",
        "grams": "gram",
        "г": "gram",
        "гр": "gram",
        "грамм": "gram",
        "грамма": "gram",
        "граммы": "gram",
        "kg": "kilogram",
        "kilogram": "kilogram",
        "kilograms": "kilogram",
        "кг": "kilogram",
        "килограмм": "kilogram",
        "килограмма": "kilogram",
        "килограммы": "kilogram",
        "ml": "milliliter",
        "milliliter": "milliliter",
        "milliliters": "milliliter",
        "мл": "milliliter",
        "миллилитр": "milliliter",
        "миллилитра": "milliliter",
        "миллилитры": "milliliter",
        "l": "liter",
        "liter": "liter",
        "liters": "liter",
        "litre": "liter",
        "litres": "liter",
        "л": "liter",
        "литр": "liter",
        "литра": "liter",
        "литры": "liter",
        "pc": "piece",
        "pcs": "piece",
        "piece": "piece",
        "pieces": "piece",
        "шт": "piece",
        "штука": "piece",
        "штуки": "piece",
        "штук": "piece",
        "stick": "piece",
        "sticks": "piece",
        "стик": "piece",
        "стика": "piece",
        "стиков": "piece",
        "стики": "piece",
        "зубчик": "piece",
        "зубчика": "piece",
        "зубчиков": "piece",
        "зубчики": "piece",
        "пучок": "piece",
        "пучка": "piece",
        "пучков": "piece",
        "пучки": "piece",
        "стебель": "piece",
        "стебля": "piece",
        "стеблей": "piece",
        "по вкусу": "piece",
        "щепотка": "piece",
        "щепотку": "piece",
        "немного": "piece",
        "cup": "piece",
        "cups": "piece",
        "tbsp": "tablespoon",
        "tablespoon": "tablespoon",
        "tablespoons": "tablespoon",
        "стл": "tablespoon",
        "ст л": "tablespoon",
        "столовая ложка": "tablespoon",
        "столовые ложки": "tablespoon",
        "столовых ложек": "tablespoon",
        "tsp": "teaspoon",
        "teaspoon": "teaspoon",
        "teaspoons": "teaspoon",
        "чл": "teaspoon",
        "ч л": "teaspoon",
        "чайная ложка": "teaspoon",
        "чайные ложки": "teaspoon",
        "чайных ложек": "teaspoon",
        "lb": "gram",
        "pound": "gram",
        "pounds": "gram",
    }
    return mapping.get(key, "gram")


KNOWN_UNIT_COMPACT = {
    "g",
    "gr",
    "gram",
    "grams",
    "г",
    "гр",
    "грамм",
    "грамма",
    "граммы",
    "kg",
    "kilogram",
    "kilograms",
    "кг",
    "килограмм",
    "килограмма",
    "килограммы",
    "ml",
    "milliliter",
    "milliliters",
    "мл",
    "миллилитр",
    "миллилитра",
    "миллилитры",
    "l",
    "liter",
    "liters",
    "litre",
    "litres",
    "л",
    "литр",
    "литра",
    "литры",
    "pc",
    "pcs",
    "piece",
    "pieces",
    "шт",
    "штука",
    "штуки",
    "штук",
    "stick",
    "sticks",
    "стик",
    "стика",
    "стиков",
    "стики",
    "tbsp",
    "tablespoon",
    "tablespoons",
    "стл",
    "столоваяложка",
    "столовыеложки",
    "tsp",
    "teaspoon",
    "teaspoons",
    "чл",
    "чайнаяложка",
    "чайныеложки",
    "cup",
    "cups",
    "lb",
    "pound",
    "pounds",
}


def is_known_unit(raw: str) -> bool:
    key = raw.strip().lower().replace(".", "").replace(" ", "")
    return key in KNOWN_UNIT_COMPACT


def looks_like_instruction(text: str) -> bool:
    lowered = text.lower()
    markers = [
        "примерно в",
        "раза больше",
        "раз больше",
        "кбжу",
        "указала",
        "указал",
        "смотреть",
        "см.",
        "рилл",
    ]
    return any(marker in lowered for marker in markers) or len(text) > 60


def extract_amount(raw_name: str) -> tuple[str, float | None, str | None]:
    trimmed = raw_name.strip()
    if not trimmed or looks_like_instruction(trimmed):
        return trimmed, None, None
    pattern = re.compile(
        r"(?i)^(.+?)\s+(\d+(?:[.,]\d+)?)\s*([a-zа-яё.%]+(?:\s*[a-zа-яё.]+)?)?\s*$"
    )
    match = pattern.match(trimmed)
    if not match:
        return trimmed, None, None
    name = match.group(1).strip()
    if len(name) < 2:
        return trimmed, None, None
    quantity = float(match.group(2).replace(",", "."))
    if quantity <= 0:
        return trimmed, None, None
    unit_raw = (match.group(3) or "").strip()
    unit: str | None = None
    if unit_raw:
        if is_known_unit(unit_raw):
            unit = normalize_unit(unit_raw)
        else:
            return trimmed, None, None
    else:
        lowered = name.lower()
        if any(token in lowered for token in ("вода", "молоко", "сок")):
            unit = "milliliter"
        else:
            unit = "gram"
    return name, quantity, unit


@dataclass
class ParsedIngredient:
    raw_name: str
    quantity: float
    unit: str
    catalog_key: str | None = None


def normalize_ingredient(item: ParsedIngredient) -> ParsedIngredient:
    name, qty, unit = extract_amount(item.raw_name)
    cleaned = name if name else item.raw_name
    if qty and qty > 0:
        return ParsedIngredient(
            raw_name=cleaned,
            quantity=qty,
            unit=unit or normalize_unit(item.unit),
            catalog_key=item.catalog_key,
        )
    if item.quantity > 0:
        return ParsedIngredient(
            raw_name=cleaned,
            quantity=item.quantity,
            unit=normalize_unit(item.unit),
            catalog_key=item.catalog_key,
        )
    return ParsedIngredient(
        raw_name=cleaned,
        quantity=1,
        unit=normalize_unit(item.unit),
        catalog_key=item.catalog_key,
    )


def _strip_suffix(word: str, endings: list[tuple[str, str]], min_stem: int) -> str:
    for ending, replacement in sorted(endings, key=lambda item: len(item[0]), reverse=True):
        if not word.endswith(ending):
            continue
        stem_len = len(word) - len(ending) + len(replacement)
        if stem_len < min_stem:
            continue
        return word[: len(word) - len(ending)] + replacement
    return word


def _fold_russian_orthography(word: str) -> str:
    result = word
    for source, target in (("яи", "яй"), ("цы", "ц"), ("ци", "ц")):
        if source in result:
            result = result.replace(source, target)
    return result


def _stem_russian(word: str) -> str:
    before = word
    adjectival = [
        ("его", ""),
        ("ого", ""),
        ("ему", ""),
        ("ому", ""),
        ("ими", ""),
        ("ыми", ""),
        ("ее", ""),
        ("ие", ""),
        ("ые", ""),
        ("ое", ""),
        ("ей", ""),
        ("ий", ""),
        ("ый", ""),
        ("ой", ""),
        ("ем", ""),
        ("им", ""),
        ("ым", ""),
        ("ом", ""),
        ("их", ""),
        ("ых", ""),
        ("ую", ""),
        ("юю", ""),
        ("ая", ""),
        ("яя", ""),
        ("ою", ""),
        ("ею", ""),
    ]
    word = _strip_suffix(word, adjectival, 3)
    stripped_adj = word != before
    long_noun = [
        ("иями", ""),
        ("ями", ""),
        ("ами", ""),
        ("ией", ""),
        ("иям", ""),
        ("ием", ""),
        ("ам", ""),
        ("ом", ""),
        ("ах", ""),
        ("ях", ""),
        ("ию", ""),
        ("ью", ""),
        ("ия", ""),
        ("ья", ""),
        ("ей", ""),
        ("ий", ""),
        ("ии", ""),
        ("ов", ""),
        ("ев", ""),
        ("ие", ""),
        ("ье", ""),
    ]
    word = _strip_suffix(word, long_noun, 3)
    if not stripped_adj:
        short_noun = [
            ("и", ""),
            ("е", ""),
            ("у", ""),
            ("ы", ""),
            ("ь", ""),
            ("ю", ""),
            ("а", ""),
            ("я", ""),
            ("о", ""),
        ]
        word = _strip_suffix(word, short_noun, 3)
    elif word.endswith("ь") and len(word) > 3:
        word = word[:-1]
    if word.endswith("нн") and len(word) > 4:
        word = word[:-1]
    return word


def _stem_english(word: str) -> str:
    endings = [
        ("ational", "ate"),
        ("tional", "tion"),
        ("ization", "ize"),
        ("ation", "ate"),
        ("ator", "ate"),
        ("iveness", "ive"),
        ("fulness", "ful"),
        ("ousness", "ous"),
        ("ies", "y"),
        ("ied", "y"),
        ("ing", ""),
        ("edly", ""),
        ("ed", ""),
        ("es", ""),
        ("s", ""),
    ]
    return _strip_suffix(word, endings, 3)


def stem_token(raw: str) -> str:
    token = raw.lower().replace("ё", "е")
    if len(token) < 3:
        return _fold_russian_orthography(token)
    if any("\u0400" <= ch <= "\u04ff" for ch in token):
        return _fold_russian_orthography(_stem_russian(token))
    return _stem_english(token)


def stem_text(text: str) -> str:
    tokens = [stem_token(part) for part in text.split() if part]
    return " ".join(token for token in tokens if token)


def normalize_for_match(text: str) -> str:
    lowered = text.lower().replace("ё", "е").replace("_", " ")
    decomposed = unicodedata.normalize("NFD", lowered)
    without_marks = "".join(ch for ch in decomposed if unicodedata.category(ch) != "Mn")
    parts = re.findall(r"[0-9a-zа-я]+", without_marks, flags=re.IGNORECASE)
    return " ".join(parts)


# ---------------------------------------------------------------------------
# Catalog matcher
# ---------------------------------------------------------------------------


@dataclass
class CatalogEntry:
    key: str
    display_name: str
    translations: dict[str, str]
    calories: float = 0
    protein: float = 0
    fat: float = 0
    carbs: float = 0


@dataclass
class MatchCandidate:
    normalized: str
    stemmed: str


@dataclass
class IndexEntry:
    key: str
    candidates: list[MatchCandidate]


class CatalogIndex:
    def __init__(self, catalog_path: Path, language: str = "ru") -> None:
        self.products: dict[str, CatalogEntry] = {}
        self.entries: list[IndexEntry] = []
        self.language = language
        self._load(catalog_path)

    def _load(self, catalog_path: Path) -> None:
        data = json.loads(catalog_path.read_text(encoding="utf-8"))
        products = data.get("products", [])
        preferred = ["ru", "en"] if self.language.startswith("ru") else ["en", "ru"]
        for product in products:
            key = product.get("catalogKey") or ""
            if not key:
                continue
            entry = CatalogEntry(
                key=key,
                display_name=product.get("displayName") or key,
                translations=product.get("translations") or {},
                calories=float(product.get("caloriesPer100g") or 0),
                protein=float(product.get("proteinPer100g") or 0),
                fat=float(product.get("fatPer100g") or 0),
                carbs=float(product.get("carbsPer100g") or 0),
            )
            self.products[key] = entry
            texts = [key.replace("_", " ")]
            for code in preferred:
                name = entry.translations.get(code) or (
                    entry.display_name if code.startswith("ru") else None
                )
                if name:
                    texts.append(name)
            candidates: list[MatchCandidate] = []
            seen: set[str] = set()
            for text in texts:
                normalized = normalize_for_match(text)
                if not normalized or normalized in seen:
                    continue
                seen.add(normalized)
                candidates.append(
                    MatchCandidate(normalized=normalized, stemmed=stem_text(normalized))
                )
            if candidates:
                self.entries.append(IndexEntry(key=key, candidates=candidates))

    def name_for(self, key: str) -> str:
        entry = self.products.get(key)
        if not entry:
            return key
        if self.language.startswith("ru"):
            return entry.translations.get("ru") or entry.display_name or key
        return entry.translations.get("en") or entry.display_name or key


def _token_list(text: str) -> list[str]:
    return [part for part in text.split() if part]


def _single_token_score(index: int, candidate_tokens: list[str]) -> int:
    if len(candidate_tokens) == 1:
        return 100
    has_derived = any(
        offset != index and token in DERIVED_PRODUCT_MARKERS
        for offset, token in enumerate(candidate_tokens)
    )
    if index == 0:
        return 78 if has_derived else 96
    if index == len(candidate_tokens) - 1:
        return 82 if has_derived else 90
    return 65


def match_score(
    query: str,
    query_stem: str,
    candidate: str,
    candidate_stem: str,
) -> int:
    if query == candidate or (query_stem and query_stem == candidate_stem):
        return 100
    query_tokens = _token_list(query_stem or query)
    candidate_tokens = _token_list(candidate_stem or candidate)
    if not query_tokens or not candidate_tokens:
        return 0
    query_set = set(query_tokens)
    candidate_set = set(candidate_tokens)
    if len(query_tokens) == 1:
        single = query_tokens[0]
        if single in candidate_tokens:
            return _single_token_score(candidate_tokens.index(single), candidate_tokens)
        return 0
    overlap = query_set & candidate_set
    if not overlap:
        soft = 0
        for q_token in query_set:
            if len(q_token) < 4:
                continue
            if any(c.startswith(q_token) or q_token.startswith(c) for c in candidate_set):
                soft += 1
        if soft == 0:
            return 0
        return int((soft / len(query_set)) * 88)
    if overlap == query_set:
        return 92
    union = len(query_set | candidate_set)
    return int((len(overlap) / union) * 100)


def fuzzy_match_catalog_key(raw_name: str, index: CatalogIndex) -> tuple[str | None, int]:
    query = normalize_for_match(raw_name)
    if not query:
        return None, 0
    query_stem = stem_text(query)
    best_key: str | None = None
    best_score = 0
    best_rank = sys.maxsize
    for entry in index.entries:
        for candidate in entry.candidates:
            score = match_score(
                query=query,
                query_stem=query_stem,
                candidate=candidate.normalized,
                candidate_stem=candidate.stemmed,
            )
            rank = len(candidate.stemmed.split()) * 1000 + len(candidate.normalized)
            if score > best_score or (score == best_score and rank < best_rank):
                best_score = score
                best_rank = rank
                best_key = entry.key
    if best_score >= 70:
        return best_key, best_score
    return None, best_score


@dataclass
class ResolvedIngredient:
    raw_name: str
    catalog_key: str
    display_name: str
    quantity: float
    unit: str
    match_score: int
    calories_per_100g: float = 0
    protein_per_100g: float = 0
    fat_per_100g: float = 0
    carbs_per_100g: float = 0


@dataclass
class UnresolvedIngredient:
    raw_name: str
    quantity: float
    unit: str
    best_score: int = 0


def match_ingredients(
    ingredients: list[ParsedIngredient],
    index: CatalogIndex,
) -> tuple[list[ResolvedIngredient], list[UnresolvedIngredient]]:
    resolved: list[ResolvedIngredient] = []
    unresolved: list[UnresolvedIngredient] = []
    for raw in ingredients:
        item = normalize_ingredient(raw)
        unit = normalize_unit(item.unit)
        quantity = item.quantity if item.quantity > 0 else 1.0
        key = (item.catalog_key or "").strip()
        score = 100
        if not key:
            key, score = fuzzy_match_catalog_key(item.raw_name, index)
        if key and key in index.products:
            product = index.products[key]
            resolved.append(
                ResolvedIngredient(
                    raw_name=item.raw_name,
                    catalog_key=key,
                    display_name=index.name_for(key),
                    quantity=quantity,
                    unit=unit,
                    match_score=score,
                    calories_per_100g=product.calories,
                    protein_per_100g=product.protein,
                    fat_per_100g=product.fat,
                    carbs_per_100g=product.carbs,
                )
            )
        else:
            unresolved.append(
                UnresolvedIngredient(
                    raw_name=item.raw_name,
                    quantity=quantity,
                    unit=unit,
                    best_score=score,
                )
            )
    return resolved, unresolved


# ---------------------------------------------------------------------------
# LLM prompt (зеркало LLMRecipeParser.swift)
# ---------------------------------------------------------------------------


def system_prompt(language_code: str) -> str:
    language_name = "Russian" if language_code.startswith("ru") else "English"
    return f"""You are a recipe extraction engine for a meal-planning iOS app.
Convert messy Instagram cooking posts into ONE strict JSON object.
TARGET_LANGUAGE = {language_name}. Every user-facing string MUST be written in {language_name}, even when CAPTION/TRANSCRIPT/POST_TITLE_HINT are in another language. Translate naturally; do not leave source-language wording.
Put the final JSON in the assistant content. Keep reasoning short. No markdown fences.

Schema:
{{"name":string,"servings":number|null,"cookTimeMinutes":number|null,"stepsIntro":string|null,"steps":[string],"ingredients":[{{"rawName":string,"quantity":number,"unit":string}}]}}

Rules:
- name: dish title 2–8 words IN {language_name}. Not a marketing hook/CTA/first emoji line. Prefer POST_TITLE_HINT or explicit dish name, then translate. Never include #hashtags or @mentions.
- servings/cookTimeMinutes: only if explicitly stated; else null. Never infer servings from dough balls/pieces.
- stepsIntro: null by default. Only a short tip in {language_name} when the source has an explicit tip that is NOT a cooking step (e.g. serving suggestion). Never put the dish name, first step, or a paraphrase of steps here. No hashtags.
- steps: chronological plain sentences IN {language_name}, no numbering/emojis/hashtags. Keep only facts from the text; translate cooking instructions fully.
- ingredients.rawName: common grocery name IN {language_name} only (no amount/emoji/hashtag/"for the sauce"). Prefer everyday store names (e.g. chicken breast → куриная грудка when TARGET_LANGUAGE is Russian). Merge duplicates by summing quantity.
- ingredients.quantity: positive number. ingredients.unit: exactly one of gram, kilogram, milliliter, liter, piece, tablespoon, teaspoon.
- Map: g/гр→gram, kg/кг→kilogram, ml/мл→milliliter, l/л→liter, tbsp/ст.л→tablespoon, tsp/ч.л/чл→teaspoon, pc/шт/clove/зубчик/bunch→piece.
- cups/lb: 1 cup liquids≈240 milliliter; 1 cup solids≈140 gram if density unknown; 1 lb≈454 gram. Whole produce counted as piece.
- "to taste"/"по вкусу"/"pinch"/"щепотка" → quantity 1, unit piece (teaspoon for spices if clearly a pinch).
- Drop hashtag-only lines (#recipe #salad). Ignore CTA/ads/KBJU. Do not invent ingredients, temps, or steps missing from CAPTION/TRANSCRIPT.
- When TARGET_LANGUAGE is Russian, convert °F to °C in steps. When English, keep or convert to °F only if the source used °F.
- Do not map to catalog ids. Unknown scalars must be null.
"""


def user_content(
    caption: str,
    transcript: str = "",
    post_title_hint: str | None = None,
    language_code: str = "ru",
) -> str:
    language_name = "Russian" if language_code.startswith("ru") else "English"
    parts: list[str] = [
        f"OUTPUT_LANGUAGE: {language_name}\n"
        f"Translate name, stepsIntro, steps, and every ingredients.rawName into {language_name}."
    ]
    if post_title_hint and post_title_hint.strip():
        parts.append(f"POST_TITLE_HINT:\n{post_title_hint.strip()}")
    parts.append(f"CAPTION:\n{caption}")
    trimmed = transcript.strip()
    parts.append(f"TRANSCRIPT:\n{trimmed if trimmed else '(empty)'}")
    parts.append("Return the JSON object now.")
    return "\n\n".join(parts)


def extract_json_payload(content: str) -> str:
    trimmed = content.strip()
    if "```json" in trimmed:
        start = trimmed.find("```json") + 7
        end = trimmed.find("```", start)
        if end != -1:
            return trimmed[start:end].strip()
    if "```" in trimmed:
        start = trimmed.find("```") + 3
        end = trimmed.find("```", start)
        if end != -1:
            return trimmed[start:end].strip()
    start_idx = trimmed.find("{")
    end_idx = trimmed.rfind("}")
    if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
        return trimmed[start_idx : end_idx + 1]
    return trimmed


def strip_emojis(text: str) -> str:
    filtered = []
    for ch in text:
        code = ord(ch)
        if code >= 0x1F300:
            continue
        cat = unicodedata.category(ch)
        if cat.startswith("So") and code > 0x238C:
            continue
        filtered.append(ch)
    return re.sub(r"\s{2,}", " ", "".join(filtered)).strip()


def clean_display_name(text: str) -> str:
    result = text.strip()
    result = re.sub(r"#[\wа-яёА-ЯЁ]+", "", result, flags=re.IGNORECASE)
    result = re.sub(r"@[\w.]+", "", result)
    result = strip_emojis(result)
    return re.sub(r"\s{2,}", " ", result).strip()


def strip_leading_step_marker(text: str) -> str:
    result = text.strip()
    patterns = [
        r"^\d+[\.\)\:\-]\s*",
        r"^[•\-–—]\s*",
        r"^(шаг|step)\s*\d+[\.\)\:\-]?\s*",
    ]
    for pattern in patterns:
        result = re.sub(pattern, "", result, flags=re.IGNORECASE).strip()
    return result


@dataclass
class ParsedRecipe:
    name: str
    servings: int | None
    cook_time_minutes: int | None
    steps_intro: str | None
    steps: list[str]
    ingredients: list[ParsedIngredient]
    source: str = "llm"


def finalize_recipe(payload: dict[str, Any], source: str = "llm") -> ParsedRecipe:
    name = clean_display_name(str(payload.get("name") or ""))
    if not name:
        raise ValueError("empty recipe name")
    ingredients: list[ParsedIngredient] = []
    for item in payload.get("ingredients") or []:
        raw_name = strip_emojis(str(item.get("rawName") or "").strip())
        raw_name = re.sub(
            r"(?i)^(для\s+соуса|соус|заправка)\s*[:\-]?\s*",
            "",
            raw_name,
        ).strip()
        if not raw_name:
            continue
        quantity = item.get("quantity")
        try:
            quantity_value = float(quantity) if quantity is not None else 1.0
        except (TypeError, ValueError):
            quantity_value = 1.0
        if quantity_value <= 0:
            quantity_value = 1.0
        ingredients.append(
            ParsedIngredient(
                raw_name=raw_name,
                quantity=quantity_value,
                unit=normalize_unit(str(item.get("unit") or "piece")),
            )
        )
    steps = [
        strip_leading_step_marker(strip_emojis(str(step)))
        for step in (payload.get("steps") or [])
    ]
    steps = [step for step in steps if step]
    intro_raw = payload.get("stepsIntro")
    intro = clean_display_name(str(intro_raw)) if intro_raw else None
    if intro:
        normalized = intro.casefold()
        if normalized == name.casefold() or (steps and normalized == steps[0].casefold()):
            intro = None
    servings = payload.get("servings")
    cook = payload.get("cookTimeMinutes")
    return ParsedRecipe(
        name=name,
        servings=max(int(servings), 1) if isinstance(servings, (int, float)) else None,
        cook_time_minutes=max(int(cook), 0) if isinstance(cook, (int, float)) else None,
        steps_intro=intro or None,
        steps=steps,
        ingredients=ingredients,
        source=source,
    )


def call_llm(
    secrets: dict[str, Any],
    caption: str,
    transcript: str = "",
    post_title_hint: str | None = None,
    language_code: str = "ru",
) -> ParsedRecipe:
    api_key = str(cfg(secrets, "AI_PROVIDER_API_KEY", "")).strip()
    if not api_key or api_key == "YOUR_AI_PROVIDER_API_KEY":
        raise RuntimeError("AI_PROVIDER_API_KEY не задан в ImportSecrets.plist")
    base = str(cfg(secrets, "AI_PROVIDER_BASE_URL", "https://polza.ai/api/v1")).rstrip("/")
    model = str(cfg(secrets, "AI_PROVIDER_MODEL", "deepseek/deepseek-v4-flash"))
    temperature = float(cfg(secrets, "AI_PROVIDER_TEMPERATURE", 0.2))
    top_p = float(cfg(secrets, "AI_PROVIDER_TOP_P", 0.95))
    max_tokens = int(cfg(secrets, "AI_PROVIDER_MAX_TOKENS", 8192))
    timeout = int(cfg(secrets, "AI_PROVIDER_TIMEOUT_SECONDS", 240))
    thinking = bool(cfg(secrets, "AI_PROVIDER_THINKING", False))

    messages = [
        {"role": "system", "content": system_prompt(language_code)},
        {
            "role": "user",
            "content": user_content(
                caption,
                transcript,
                post_title_hint,
                language_code=language_code,
            ),
        },
    ]
    body: dict[str, Any] = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "top_p": top_p,
        "max_tokens": max_tokens,
        "stream": False,
    }
    if thinking:
        body["chat_template_kwargs"] = {"thinking": True}
    else:
        body["reasoning"] = {"enabled": False}
    if "gpt-oss" not in model.lower():
        body["response_format"] = {"type": "json_object"}
    request = urllib.request.Request(
        f"{base}/chat/completions",
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"AI provider HTTP {error.code}: {detail[:500]}") from error
    message = ((payload.get("choices") or [{}])[0].get("message") or {})
    content = (message.get("content") or "").strip()
    if not content or content in {'{"    ,"}', "{}", "null"}:
        for key in ("reasoning_content", "reasoning"):
            alt = message.get(key)
            if isinstance(alt, str) and "{" in alt:
                content = alt
                break
    if not content:
        raise RuntimeError("пустой ответ LLM")
    try:
        decoded = json.loads(extract_json_payload(content))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"невалидный JSON от LLM: {content[:200]}") from exc
    if not isinstance(decoded, dict) or not decoded.get("name"):
        raise RuntimeError(f"пустой/битый JSON от LLM: {content[:200]}")
    return finalize_recipe(decoded, source="llm")


# ---------------------------------------------------------------------------
# Fallback caption parser (упрощённый порт)
# ---------------------------------------------------------------------------


def caption_fallback_parse(caption: str) -> ParsedRecipe | None:
    lines = [line.strip() for line in caption.splitlines() if line.strip()]
    if not lines:
        return None
    ingredient_headers = {"ингредиенты", "ingredients", "состав"}
    step_headers = {
        "приготовление",
        "способ приготовления",
        "инструкция",
        "instructions",
        "directions",
        "method",
        "как готовить",
    }

    def header_index(headers: set[str]) -> int | None:
        for idx, line in enumerate(lines):
            lowered = line.lower().rstrip(":")
            if lowered in headers:
                return idx
        return None

    ing_start = header_index(ingredient_headers)
    step_start = header_index(step_headers)
    name = clean_display_name(lines[0])
    for line in lines[:8]:
        lowered = line.lower()
        if any(token in lowered for token in ("хачапури", "салат", "запекан", "wrap", "chicken", "bread")):
            candidate = clean_display_name(line)
            if 2 <= len(candidate.split()) <= 10:
                name = candidate
                break
    ingredients: list[ParsedIngredient] = []
    steps: list[str] = []
    if ing_start is not None:
        end = step_start if step_start is not None and step_start > ing_start else len(lines)
        for line in lines[ing_start + 1 : end]:
            if line.lower().rstrip(":") in ingredient_headers | step_headers:
                continue
            if line.startswith("#") or line.lower().startswith("for the"):
                continue
            parsed_name, qty, unit = extract_amount(strip_emojis(line))
            if not parsed_name or len(parsed_name) < 2:
                continue
            ingredients.append(
                ParsedIngredient(
                    raw_name=parsed_name,
                    quantity=qty or 1,
                    unit=unit or "gram",
                )
            )
    if step_start is not None:
        for line in lines[step_start + 1 :]:
            if line.startswith("#"):
                continue
            cleaned = strip_leading_step_marker(strip_emojis(line))
            if cleaned:
                steps.append(cleaned)
    if not ingredients and not steps:
        return None
    return ParsedRecipe(
        name=name or "Imported recipe",
        servings=None,
        cook_time_minutes=None,
        steps_intro=None,
        steps=steps,
        ingredients=ingredients,
        source="fallback",
    )


# ---------------------------------------------------------------------------
# Instagram / examples
# ---------------------------------------------------------------------------


def normalize_instagram_url(url: str) -> str:
    trimmed = url.strip()
    parts = urllib.parse.urlsplit(trimmed)
    path = parts.path.rstrip("/")
    return urllib.parse.urlunsplit((parts.scheme, parts.netloc, path, "", ""))


def fetch_instagram_post(url: str, api_key: str) -> dict[str, Any]:
    normalized = normalize_instagram_url(url)
    query = urllib.parse.urlencode({"url": normalized, "trim": "true"})
    request = urllib.request.Request(
        f"{SCRAPE_BASE}/v1/instagram/post?{query}",
        headers={"x-api-key": api_key, "Accept": "application/json"},
        method="GET",
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        payload = json.loads(response.read().decode("utf-8"))
    media = payload.get("xdt_shortcode_media") or (payload.get("data") or {}).get(
        "xdt_shortcode_media"
    )
    if not media:
        raise RuntimeError("Instagram post недоступен через ScrapeCreators")
    caption = (media.get("caption") or "").strip()
    if not caption:
        edges = ((media.get("edge_media_to_caption") or {}).get("edges")) or []
        texts = []
        for edge in edges:
            text = ((edge or {}).get("node") or {}).get("text")
            if text:
                texts.append(text)
        caption = "\n".join(texts).strip()
    title_hint = (media.get("title") or media.get("accessibility_caption") or "").strip() or None
    thumb = media.get("thumbnail_src") or media.get("display_url")
    return {
        "url": normalized,
        "caption": caption,
        "title_hint": title_hint,
        "thumbnail_url": thumb,
    }


def load_examples(path: Path = DEFAULT_EXAMPLES) -> dict[int, str]:
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    chunks = re.split(r"(?im)^\s*Reels\s+(\d+)\s*$", text)
    examples: dict[int, str] = {}
    if len(chunks) < 3:
        return examples
    for idx in range(1, len(chunks), 2):
        number = int(chunks[idx])
        body = chunks[idx + 1]
        body = re.split(r"(?m)^\s*-{3,}\s*$", body, maxsplit=1)[0].strip()
        examples[number] = body
    return examples


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------


@dataclass
class ImportResult:
    source_url: str | None
    caption: str
    title_hint: str | None
    language: str
    parsed: ParsedRecipe
    matched: list[ResolvedIngredient] = field(default_factory=list)
    unresolved: list[UnresolvedIngredient] = field(default_factory=list)
    meta: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "sourceURL": self.source_url,
            "caption": self.caption,
            "titleHint": self.title_hint,
            "language": self.language,
            "name": self.parsed.name,
            "servings": self.parsed.servings,
            "cookTimeMinutes": self.parsed.cook_time_minutes,
            "stepsIntro": self.parsed.steps_intro,
            "steps": self.parsed.steps,
            "ingredientsParsed": [
                {
                    "rawName": item.raw_name,
                    "quantity": item.quantity,
                    "unit": item.unit,
                }
                for item in self.parsed.ingredients
            ],
            "ingredientsMatched": [asdict(item) for item in self.matched],
            "ingredientsUnresolved": [asdict(item) for item in self.unresolved],
            "meta": self.meta,
        }


def run_import(
    *,
    caption: str,
    language: str = "ru",
    transcript: str = "",
    title_hint: str | None = None,
    source_url: str | None = None,
    secrets: dict[str, Any] | None = None,
    catalog_path: Path = DEFAULT_CATALOG,
    allow_fallback: bool = True,
) -> ImportResult:
    secrets = secrets if secrets is not None else load_secrets()
    started = time.time()
    parsed: ParsedRecipe | None = None
    error: str | None = None
    try:
        parsed = call_llm(
            secrets=secrets,
            caption=caption,
            transcript=transcript,
            post_title_hint=title_hint,
            language_code="ru" if language.startswith("ru") else "en",
        )
    except Exception as exc:  # noqa: BLE001 - лаборатория должна всегда отдавать диагностику
        error = str(exc)
        if allow_fallback:
            parsed = caption_fallback_parse(caption)
        if parsed is None:
            raise RuntimeError(error) from exc

    index = CatalogIndex(catalog_path, language=language)
    matched, unresolved = match_ingredients(parsed.ingredients, index)
    elapsed_ms = int((time.time() - started) * 1000)
    return ImportResult(
        source_url=source_url,
        caption=caption,
        title_hint=title_hint,
        language=language,
        parsed=parsed,
        matched=matched,
        unresolved=unresolved,
        meta={
            "parser": parsed.source,
            "llmError": error,
            "model": cfg(secrets, "AI_PROVIDER_MODEL", "deepseek/deepseek-v4-flash"),
            "temperature": float(cfg(secrets, "AI_PROVIDER_TEMPERATURE", 0.2)),
            "durationMs": elapsed_ms,
            "matchedCount": len(matched),
            "unresolvedCount": len(unresolved),
            "catalogSize": len(index.products),
        },
    )


def examples_path_from_args(args: argparse.Namespace) -> Path:
    return Path(args.examples) if getattr(args, "examples", None) else DEFAULT_EXAMPLES


def detect_language(caption: str, explicit: str | None = None) -> str:
    if explicit in {"ru", "en"}:
        return explicit
    cyrillic = sum(1 for ch in caption if "\u0400" <= ch <= "\u04ff")
    latin = sum(1 for ch in caption if ("a" <= ch.lower() <= "z"))
    return "ru" if cyrillic >= latin else "en"


def print_examples(path: Path) -> None:
    examples = load_examples(path)
    if not examples:
        print(f"примеры не найдены: {path}")
        return
    print(f"Примеры из {path}:")
    for number, body in sorted(examples.items()):
        preview = " ".join(body.splitlines()[:2]).strip()
        preview = re.sub(r"\s+", " ", preview)[:100]
        print(f"  {number}: {preview}")


def resolve_input(args: argparse.Namespace) -> tuple[str, str | None, str | None, int | None]:
    """Возвращает caption, source_url, title_hint, example_id."""
    if args.caption:
        return args.caption, None, args.title_hint, None
    if args.example:
        examples = load_examples(examples_path_from_args(args))
        if args.example not in examples:
            available = ", ".join(str(key) for key in sorted(examples))
            raise SystemExit(f"пример {args.example} не найден. Доступны: {available or '—'}")
        return examples[args.example], f"example://reels/{args.example}", args.title_hint, args.example
    if args.url:
        secrets = load_secrets(Path(args.secrets) if args.secrets else None)
        api_key = str(cfg(secrets, "SCRAPE_CREATORS_API_KEY", "")).strip()
        if not api_key or api_key == "YOUR_SCRAPECREATORS_API_KEY":
            raise SystemExit(
                "Instagram URL сейчас опционален. Используйте --example N из "
                f"{DEFAULT_EXAMPLES.name} или --caption. Для --url нужен SCRAPE_CREATORS_API_KEY."
            )
        post = fetch_instagram_post(args.url, api_key)
        if not post["caption"]:
            raise SystemExit("пустой caption у поста")
        return post["caption"], post["url"], post["title_hint"] or args.title_hint, None
    raise SystemExit(
        "укажите источник caption:\n"
        f"  --example N          из {DEFAULT_EXAMPLES}\n"
        "  --all                все примеры из файла\n"
        "  --list               список примеров\n"
        "  --caption '...'      произвольный текст\n"
        "  --url URL            Instagram (когда API снова доступен)"
    )


# ---------------------------------------------------------------------------
# HTTP server + HTML
# ---------------------------------------------------------------------------


class LabHandler(BaseHTTPRequestHandler):
    secrets: dict[str, Any] = {}
    catalog_path: Path = DEFAULT_CATALOG
    html_path: Path = DEFAULT_HTML
    examples_path: Path = DEFAULT_EXAMPLES

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A003
        sys.stderr.write("[%s] %s\n" % (self.log_date_time_string(), format % args))

    def _send(self, code: int, body: bytes, content_type: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _send_json(self, code: int, payload: dict[str, Any]) -> None:
        data = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
        self._send(code, data, "application/json; charset=utf-8")

    def do_GET(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path in {"/", "/index.html", "/import-recipe-lab.html"}:
            html = self.html_path.read_text(encoding="utf-8").encode("utf-8")
            self._send(200, html, "text/html; charset=utf-8")
            return
        if parsed.path == "/api/examples":
            examples = load_examples(self.examples_path)
            self._send_json(
                200,
                {
                    "examples": [
                        {
                            "id": key,
                            "preview": value[:180].replace("\n", " "),
                            "caption": value,
                        }
                        for key, value in sorted(examples.items())
                    ]
                },
            )
            return
        if parsed.path == "/api/health":
            self._send_json(
                200,
                {
                    "ok": True,
                    "hasAiProvider": bool(cfg(self.secrets, "AI_PROVIDER_API_KEY")),
                    "hasScrape": bool(cfg(self.secrets, "SCRAPE_CREATORS_API_KEY")),
                    "catalog": str(self.catalog_path),
                },
            )
            return
        self._send_json(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            payload = json.loads(raw.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            self._send_json(400, {"error": "invalid json"})
            return
        if parsed.path != "/api/import":
            self._send_json(404, {"error": "not found"})
            return
        try:
            result = self._run_from_payload(payload)
            self._send_json(200, result.to_dict())
        except Exception as exc:  # noqa: BLE001
            self._send_json(500, {"error": str(exc)})

    def _run_from_payload(self, payload: dict[str, Any]) -> ImportResult:
        language_raw = str(payload.get("language") or "auto")
        title_hint = payload.get("titleHint")
        caption = (payload.get("caption") or "").strip()
        source_url = payload.get("url")
        example_id = payload.get("example")
        if example_id is not None and not caption:
            examples = load_examples(self.examples_path)
            caption = examples.get(int(example_id), "")
            source_url = source_url or f"example://reels/{int(example_id)}"
        if source_url and not caption:
            api_key = str(cfg(self.secrets, "SCRAPE_CREATORS_API_KEY", "")).strip()
            if not api_key:
                raise RuntimeError(
                    "Instagram URL пока недоступен без ключа. Выберите пример Reels или вставьте caption."
                )
            post = fetch_instagram_post(str(source_url), api_key)
            caption = post["caption"]
            source_url = post["url"]
            title_hint = title_hint or post["title_hint"]
        if not caption:
            raise RuntimeError("выберите пример Reels или вставьте caption")
        language = detect_language(
            caption,
            None if language_raw == "auto" else language_raw,
        )
        return run_import(
            caption=caption,
            language=language,
            title_hint=title_hint,
            source_url=source_url,
            secrets=self.secrets,
            catalog_path=self.catalog_path,
        )


def serve(
    host: str,
    port: int,
    secrets: dict[str, Any],
    catalog: Path,
    html: Path,
    examples_path: Path = DEFAULT_EXAMPLES,
) -> None:
    LabHandler.secrets = secrets
    LabHandler.catalog_path = catalog
    LabHandler.html_path = html
    LabHandler.examples_path = examples_path
    server = ThreadingHTTPServer((host, port), LabHandler)
    print(f"Import Recipe Lab: http://{host}:{port}/", flush=True)
    print(f"Examples file: {examples_path}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Лаборатория импорта рецептов. По умолчанию — caption из instagram-examples.txt."
    )
    parser.add_argument(
        "--examples",
        default=str(DEFAULT_EXAMPLES),
        help=f"Файл с Reels-примерами (default: {DEFAULT_EXAMPLES})",
    )
    parser.add_argument("--list", action="store_true", help="Показать примеры из файла")
    parser.add_argument("--example", type=int, help="Номер Reels N из файла примеров")
    parser.add_argument("--all", action="store_true", help="Прогнать все примеры из файла")
    parser.add_argument("--caption", help="Произвольный caption")
    parser.add_argument(
        "--url",
        help="Instagram URL (опционально; пока предпочтительнее --example)",
    )
    parser.add_argument("--title-hint", help="POST_TITLE_HINT")
    parser.add_argument(
        "--lang",
        choices=("ru", "en", "auto"),
        default="ru",
        help="Язык вывода LLM (auto = по алфавиту caption)",
    )
    parser.add_argument("--secrets", help="Путь к ImportSecrets.plist")
    parser.add_argument("--catalog", default=str(DEFAULT_CATALOG))
    parser.add_argument("--out", help="Записать JSON в файл (для --all: директория)")
    parser.add_argument("--serve", action="store_true", help="Поднять HTML UI")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--no-fallback", action="store_true")
    return parser


def run_one(
    *,
    caption: str,
    language: str,
    title_hint: str | None,
    source_url: str | None,
    secrets: dict[str, Any],
    catalog: Path,
    allow_fallback: bool,
    out_path: Path | None,
) -> dict[str, Any]:
    lang = detect_language(caption, None if language == "auto" else language)
    result = run_import(
        caption=caption,
        language=lang,
        title_hint=title_hint,
        source_url=source_url,
        secrets=secrets,
        catalog_path=catalog,
        allow_fallback=allow_fallback,
    )
    payload = result.to_dict()
    text = json.dumps(payload, ensure_ascii=False, indent=2)
    if out_path:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(text + "\n", encoding="utf-8")
        print(f"saved {out_path}", file=sys.stderr)
    print(text)
    return payload


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    secrets = load_secrets(Path(args.secrets) if args.secrets else None)
    catalog = Path(args.catalog)
    examples_path = Path(args.examples)

    if args.serve:
        if not DEFAULT_HTML.exists():
            raise SystemExit(f"не найден HTML: {DEFAULT_HTML}")
        serve(
            args.host,
            args.port,
            secrets,
            catalog,
            DEFAULT_HTML,
            examples_path=examples_path,
        )
        return 0

    if args.list or (
        not args.example
        and not args.all
        and not args.caption
        and not args.url
    ):
        print_examples(examples_path)
        if not args.list and not args.example and not args.all and not args.caption and not args.url:
            print("\nДальше: python3 tools/import_recipe_lab.py --example 3")
        return 0

    if args.all:
        examples = load_examples(examples_path)
        if not examples:
            raise SystemExit(f"примеры не найдены: {examples_path}")
        out_dir = Path(args.out) if args.out else None
        summary = []
        for number, caption in sorted(examples.items()):
            print(f"\n===== Reels {number} =====", file=sys.stderr)
            out_path = out_dir / f"reels-{number}.json" if out_dir else None
            payload = run_one(
                caption=caption,
                language=args.lang,
                title_hint=args.title_hint,
                source_url=f"example://reels/{number}",
                secrets=secrets,
                catalog=catalog,
                allow_fallback=not args.no_fallback,
                out_path=out_path,
            )
            summary.append(
                {
                    "example": number,
                    "name": payload.get("name"),
                    "matched": payload.get("meta", {}).get("matchedCount"),
                    "unresolved": payload.get("meta", {}).get("unresolvedCount"),
                    "parser": payload.get("meta", {}).get("parser"),
                }
            )
        print(json.dumps({"summary": summary}, ensure_ascii=False, indent=2), file=sys.stderr)
        return 0

    caption, source_url, title_hint, example_id = resolve_input(args)
    out_path = Path(args.out) if args.out else None
    if example_id is not None:
        source_url = source_url or f"example://reels/{example_id}"
    run_one(
        caption=caption,
        language=args.lang,
        title_hint=title_hint,
        source_url=source_url,
        secrets=secrets,
        catalog=catalog,
        allow_fallback=not args.no_fallback,
        out_path=out_path,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
