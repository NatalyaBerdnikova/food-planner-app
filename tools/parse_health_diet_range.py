#!/usr/bin/env python3
import argparse
import json
import time
import urllib.error
import urllib.request

from parse_health_diet import parse_health_diet_html, slugify, fetch_url


NOT_FOUND_MARKER = "Запрашиваемая страница не найдена!"


def unique_key(base: str, used: set[str], page_id: int) -> str:
    candidate = base
    if candidate not in used:
        used.add(candidate)
        return candidate
    candidate = f"{base}_{page_id}"
    i = 2
    while candidate in used:
        candidate = f"{base}_{page_id}_{i}"
        i += 1
    used.add(candidate)
    return candidate


def parse_range(start: int, end: int, delay_s: float, timeout_s: int, insecure_ssl: bool):
    products = []
    used_keys: set[str] = set()
    stats = {"ok": 0, "not_found": 0, "errors": 0}

    for page_id in range(start, end + 1):
        url = f"https://health-diet.ru/base_of_food/sostav/{page_id}.php"
        try:
            html = None
            last_err = None
            for _ in range(2):
                try:
                    html = fetch_url(url, timeout=timeout_s, insecure_ssl=insecure_ssl)
                    break
                except Exception as err:
                    last_err = err
                    time.sleep(0.5)
            if html is None:
                raise last_err if last_err else RuntimeError("fetch failed")
            if NOT_FOUND_MARKER in html:
                stats["not_found"] += 1
            else:
                item = parse_health_diet_html(html)
                if not item.get("displayName"):
                    stats["not_found"] += 1
                else:
                    base = item.get("catalogKey") or slugify(item["displayName"])
                    item["catalogKey"] = unique_key(base, used_keys, page_id)
                    products.append(item)
                    stats["ok"] += 1
        except urllib.error.HTTPError:
            stats["not_found"] += 1
        except Exception:
            stats["errors"] += 1
        finally:
            if (page_id - start + 1) % 20 == 0:
                print(
                    f"[{page_id}] ok={stats['ok']} nf={stats['not_found']} err={stats['errors']}",
                    flush=True,
                )
            time.sleep(delay_s)

    return products, stats


def main():
    parser = argparse.ArgumentParser(description="Batch parse health-diet pages into food-planner catalog JSON.")
    parser.add_argument("--start", type=int, default=19)
    parser.add_argument("--end", type=int, default=510)
    parser.add_argument("--delay", type=float, default=1.2, help="Delay between requests in seconds")
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument("--insecure-ssl", action="store_true", help="Disable TLS certificate verification")
    parser.add_argument("--out", required=True, help="Output JSON file path")
    args = parser.parse_args()

    products, stats = parse_range(args.start, args.end, args.delay, args.timeout, args.insecure_ssl)
    payload = {"version": 1, "products": products}

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(
        f"Done. ok={stats['ok']} not_found={stats['not_found']} "
        f"errors={stats['errors']} total={args.end - args.start + 1}"
    )
    print(f"Saved: {args.out}")


if __name__ == "__main__":
    main()
