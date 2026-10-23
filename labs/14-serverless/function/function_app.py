"""Nusantara Retail order intake: an HTTP-triggered function for Lab 14.

Python v2 programming model: triggers and bindings are decorators in this file.

POST /api/orders with a JSON body such as
    {"orderId": "JKT-1001", "store": "Jakarta - Kemang",
     "items": [{"sku": "KOPI-TORAJA-250G", "qty": 2}]}

The function validates the order and writes it to the Storage queue "orders"
through a queue *output binding*. The code never calls the Storage SDK: the
Functions host does that, using the connection named "OrdersStorage", which it
reads from app settings:

    OrdersStorage__queueServiceUri = https://<account>.queue.core.windows.net
        identity-based: the function app's managed identity needs the
        "Storage Queue Data Contributor" role on the storage account
    (or OrdersStorage = <connection string>, which works but is a secret)

Responses: 200 queued · 400 rejected (with the reasons) · 401 without a valid function key.
"""
import json
import logging
import uuid
from datetime import datetime, timezone

import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

MAX_LINES = 50
MAX_QTY = 1000


def validate_order(order):
    """Return a list of problems. An empty list means the order is valid."""
    if not isinstance(order, dict):
        return ["The body must be a JSON object."]
    problems = []
    for field in ("orderId", "store"):
        value = order.get(field)
        if not isinstance(value, str) or not value.strip():
            problems.append(f"'{field}' is required and must be text.")
    items = order.get("items")
    if not isinstance(items, list) or not items:
        problems.append("'items' must be a non-empty list.")
    elif len(items) > MAX_LINES:
        problems.append(f"An order can have at most {MAX_LINES} lines.")
    else:
        for i, item in enumerate(items):
            if not isinstance(item, dict):
                problems.append(f"items[{i}] must be an object with 'sku' and 'qty'.")
                continue
            sku = item.get("sku")
            qty = item.get("qty")
            if not isinstance(sku, str) or not sku.strip():
                problems.append(f"items[{i}].sku is required.")
            if isinstance(qty, bool) or not isinstance(qty, int) or not 1 <= qty <= MAX_QTY:
                problems.append(f"items[{i}].qty must be a whole number from 1 to {MAX_QTY}.")
    return problems


def json_response(body, status_code):
    return func.HttpResponse(json.dumps(body), status_code=status_code, mimetype="application/json")


@app.function_name(name="new_order")
@app.route(route="orders", methods=["POST"])
@app.queue_output(arg_name="msg", queue_name="orders", connection="OrdersStorage")
def new_order(req: func.HttpRequest, msg: func.Out[str]) -> func.HttpResponse:
    try:
        order = req.get_json()
    except ValueError:
        return json_response({"status": "rejected", "errors": ["The body must be valid JSON."]}, 400)

    problems = validate_order(order)
    if problems:
        logging.warning("Rejected an order: %s", "; ".join(problems))
        return json_response({"status": "rejected", "errors": problems}, 400)

    message = {
        "orderId": order["orderId"].strip(),
        "store": order["store"].strip(),
        "items": [{"sku": item["sku"].strip(), "qty": item["qty"]} for item in order["items"]],
        "receivedAtUtc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "trackingId": str(uuid.uuid4()),
    }
    msg.set(json.dumps(message))  # the output binding writes this to the queue when the function returns
    logging.info("Queued order %s from %s (%d lines)", message["orderId"], message["store"], len(message["items"]))
    return json_response(
        {"status": "queued", "orderId": message["orderId"], "trackingId": message["trackingId"]}, 200
    )
