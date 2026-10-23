#!/usr/bin/env python3
"""Load the Nusantara Retail product catalogue into Azure Cosmos DB for NoSQL.

Usage (from the labs/12-cosmos-db folder, with COSMOS_ENDPOINT set):
    python3 app/load_products.py               # upsert the 30 products in app/products.json
    python3 app/load_products.py --copies 10   # also upsert 10 synthetic copies of every product

Upserts are idempotent: running the script again overwrites the same items instead of
creating duplicates. Every write prints its request charge in request units (RU).
"""
import argparse
import json
import sys
from pathlib import Path

import cosmos_common as cc


def parse_args():
    parser = argparse.ArgumentParser(description="Upsert products.json into the products container.")
    parser.add_argument("--file", default=str(Path(__file__).with_name("products.json")),
                        help="JSON array of products (default: app/products.json)")
    parser.add_argument("--copies", type=int, default=0, metavar="N",
                        help="also write N synthetic copies of every product (0-50, default 0)")
    args = parser.parse_args()
    if not 0 <= args.copies <= 50:
        parser.error("--copies must be between 0 and 50")
    return args


def load_items(path, copies):
    try:
        products = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        cc.fail(f"Could not read {path}: {exc}", cc.EXIT_SETUP)
    for product in products:
        if not product.get("id") or not product.get("category"):
            cc.fail(f"Every product needs an 'id' and a 'category' (the partition key): {product}", cc.EXIT_SETUP)
    items = list(products)
    for n in range(1, copies + 1):
        for product in products:
            copy = dict(product)
            copy["id"] = f"{product['id']}-copy{n:02d}"
            copy["copyOf"] = product["id"]
            items.append(copy)
    return items


def main():
    args = parse_args()
    items = load_items(args.file, args.copies)
    _client, container, auth = cc.connect()
    print(f"Writing {len(items)} items to {cc.DATABASE}/{cc.CONTAINER} (partition key /category)")
    print(f"Signed in with: {auth}\n")
    total = 0.0
    per_category = {}
    for i, item in enumerate(items, start=1):
        try:
            container.upsert_item(item)
        except Exception as exc:  # pylint: disable=broad-except
            print(f"\nStopped at item {i} of {len(items)} ({item['id']}).", file=sys.stderr)
            cc.explain_and_exit(exc)
        charge = cc.request_charge(container)
        total += charge
        per_category[item["category"]] = per_category.get(item["category"], 0) + 1
        if args.copies == 0 or i <= 5 or i == len(items):
            print(f"  upsert {item['id']:<22} {'[' + item['category'] + ']':<9} {charge:6.2f} RU")
        elif i == 6:
            print("  ...")
    print(f"\nDone: {len(items)} items written for {total:.1f} RU "
          f"(about {total / max(len(items), 1):.1f} RU per write).")
    print("Items per logical partition (category): "
          + ", ".join(f"{k}={v}" for k, v in sorted(per_category.items())))


if __name__ == "__main__":
    main()
