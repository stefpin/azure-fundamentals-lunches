#!/usr/bin/env python3
"""Read and query the Lab 12 product catalogue and show what every operation costs in RU.

Usage (from the labs/12-cosmos-db folder, with COSMOS_ENDPOINT set):
    python3 app/query_products.py read p-coffee-001 coffee          # point read: id + partition key
    python3 app/query_products.py query "SELECT c.id, c.name FROM c WHERE c.category = 'tea'" --pk tea
    python3 app/query_products.py query "SELECT c.id, c.name FROM c WHERE c.price < 50000"
    python3 app/query_products.py compare                           # the three side by side
    python3 app/query_products.py count                             # prints the number of items only

Add --consistency Eventual (or Strong, BoundedStaleness, Session, ConsistentPrefix) after the
command to override the account's default consistency for this run. You can only relax it:
asking for a level stronger than the account default fails.
"""
import argparse
import json

import cosmos_common as cc

MAX_ROWS = 12


def parse_args():
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--consistency", choices=cc.CONSISTENCY_LEVELS,
                        help="consistency level for this client (default: the account default)")
    parser = argparse.ArgumentParser(description="Point reads and queries with request charges.")
    sub = parser.add_subparsers(dest="command", required=True)

    read = sub.add_parser("read", parents=[common], help="point read one item by id and partition key")
    read.add_argument("id")
    read.add_argument("category", help="partition key value (the item's category)")

    query = sub.add_parser("query", parents=[common], help="run a SQL query")
    query.add_argument("sql")
    query.add_argument("--pk", metavar="CATEGORY",
                       help="partition key value: makes it a single-partition query")

    sub.add_parser("compare", parents=[common], help="point read vs single- vs cross-partition query")
    sub.add_parser("count", parents=[common], help="print the number of items in the container")
    return parser.parse_args()


def parse_metrics(headers):
    metrics = {}
    for part in (headers.get("x-ms-documentdb-query-metrics") or "").split(";"):
        if "=" in part:
            key, value = part.split("=", 1)
            metrics[key.strip()] = value.strip()
    return metrics


def point_read(container, item_id, category):
    try:
        item = container.read_item(item=item_id, partition_key=category)
    except Exception as exc:  # pylint: disable=broad-except
        cc.explain_and_exit(exc)
    return item, cc.request_charge(container)


def run_query(container, sql, pk=None):
    """Return (items, pages, total RU, documents retrieved, documents returned)."""
    kwargs = {"query": sql, "populate_query_metrics": True}
    if pk is None:
        kwargs["enable_cross_partition_query"] = True
    else:
        kwargs["partition_key"] = pk
    items, pages, total = [], 0, 0.0
    retrieved = returned = None
    try:
        try:
            page_iter = container.query_items(**kwargs).by_page()
        except TypeError:  # very old SDK without populate_query_metrics
            kwargs.pop("populate_query_metrics")
            page_iter = container.query_items(**kwargs).by_page()
        for page in page_iter:
            items.extend(page)
            pages += 1
            headers = cc.last_headers(container)
            total += cc.request_charge(container)
            metrics = parse_metrics(headers)
            if "retrievedDocumentCount" in metrics:
                retrieved = (retrieved or 0) + int(float(metrics["retrievedDocumentCount"]))
                returned = (returned or 0) + int(float(metrics.get("outputDocumentCount", 0)))
    except Exception as exc:  # pylint: disable=broad-except
        cc.explain_and_exit(exc)
    return items, pages, total, retrieved, returned


def physical_partitions(container):
    try:
        return len(list(container.read_feed_ranges()))
    except Exception:  # pylint: disable=broad-except
        return None


def describe_client(client, auth, consistency):
    level = consistency or f"account default ({cc.account_default_consistency(client) or 'unknown'})"
    print(f"Signed in with: {auth} · consistency: {level}")


def show_item(item):
    if not isinstance(item, dict):
        print(f"  {json.dumps(item)}")
        return
    if "name" in item or "category" in item:
        price = cc.rupiah(item["price"]) if "price" in item else ""
        print(f"  {str(item.get('id', '')):<22} {str(item.get('category', '')):<8} "
              f"{str(item.get('name', ''))[:36]:<36} {price}")
    else:
        print(f"  {json.dumps(item, ensure_ascii=False)[:100]}")


def cmd_read(client, container, auth, args):
    describe_client(client, auth, args.consistency)
    item, charge = point_read(container, args.id, args.category)
    print(f"\nPoint read of id '{args.id}' in logical partition '{args.category}':")
    show_item(item)
    print(f"\nRequest charge: {charge:.2f} RU")
    print("A point read of an item up to 1 KB costs about 1 RU with Session, Consistent prefix or Eventual\n"
          "consistency. Strong and Bounded staleness read from two replicas, so expect about double.")


def cmd_query(client, container, auth, args):
    describe_client(client, auth, args.consistency)
    scope = (f"single partition (category = '{args.pk}')" if args.pk
             else "cross-partition (no partition key: every physical partition is asked)")
    print(f"Query : {args.sql}")
    print(f"Scope : {scope}\n")
    items, pages, total, retrieved, returned = run_query(container, args.sql, args.pk)
    for item in items[:MAX_ROWS]:
        show_item(item)
    if len(items) > MAX_ROWS:
        print(f"  ... and {len(items) - MAX_ROWS} more")
    print(f"\n{len(items)} result(s) in {pages} page(s) · request charge: {total:.2f} RU")
    if retrieved is not None:
        print(f"Documents the engine had to load: {retrieved} · documents returned: {returned}")
    else:
        print("No query metrics came back. Data Explorer's Query Stats tab shows the same counts.")
    parts = physical_partitions(container)
    if parts and not args.pk:
        print(f"Physical partitions in this container: {parts}")


def cmd_compare(client, container, auth, args):
    describe_client(client, auth, args.consistency)
    rows = []
    _, charge = point_read(container, "p-coffee-001", "coffee")
    rows.append(("Point read  id='p-coffee-001', key='coffee'", "one item", 1, charge))
    items, _, total, _, _ = run_query(
        container, "SELECT c.id, c.name, c.price FROM c WHERE c.category = 'coffee'", "coffee")
    rows.append(("Query  WHERE c.category = 'coffee'", "single partition", len(items), total))
    items, _, total, _, _ = run_query(
        container, "SELECT c.id, c.name, c.price FROM c WHERE c.price < 50000")
    rows.append(("Query  WHERE c.price < 50000", "cross-partition", len(items), total))

    print(f"\n{'Operation':<46} {'Scope':<17} {'Items':>5} {'RU':>7}")
    print(f"{'-' * 46} {'-' * 17} {'-' * 5} {'-' * 7}")
    for name, scope, count, ru in rows:
        print(f"{name:<46} {scope:<17} {count:>5} {ru:>7.2f}")
    parts = physical_partitions(container)
    if parts:
        print(f"\nPhysical partitions in this container: {parts}. A cross-partition query pays a small "
              "overhead (about 2-3 RU)\nfor every physical partition it visits, so the gap grows as the "
              "container grows.")


def cmd_count(container):
    items, _, _, _, _ = run_query(container, "SELECT VALUE COUNT(1) FROM c")
    total = sum(int(x) for x in items if isinstance(x, (int, float)))
    print(total)


def main():
    args = parse_args()
    client, container, auth = cc.connect(args.consistency)
    if args.command == "read":
        cmd_read(client, container, auth, args)
    elif args.command == "query":
        cmd_query(client, container, auth, args)
    elif args.command == "compare":
        cmd_compare(client, container, auth, args)
    elif args.command == "count":
        cmd_count(container)


if __name__ == "__main__":
    main()
