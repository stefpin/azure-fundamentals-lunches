"""Nusantara Retail storefront for Lab 30.

A tiny Flask app that behaves like last Friday's shop: most checkouts are quick,
about one in five waits for a slow payment provider, and a few time out.

There is no monitoring code in here. Application Insights autoinstrumentation on
App Service collects the requests, the exceptions and the warnings logged below.
"""

import logging
import random
import time

from flask import Flask, jsonify

app = Flask(__name__)
log = logging.getLogger("nusa.storefront")

PRODUCTS = [
    {"sku": "BTK-001", "name": "Batik shirt, Parang pattern", "price_idr": 249000},
    {"sku": "KOP-014", "name": "Toraja coffee beans 250 g", "price_idr": 89000},
    {"sku": "TNN-007", "name": "Woven Sumba scarf", "price_idr": 375000},
    {"sku": "SMB-021", "name": "Sambal matah gift jar", "price_idr": 45000},
]


class PaymentGatewayTimeout(Exception):
    """The simulated payment provider did not answer in time."""


@app.get("/")
def home():
    return (
        "<h1>Nusantara Retail</h1>"
        "<p>Storefront for Lab 30. Try <code>/products</code> or <code>POST /checkout</code>.</p>"
    )


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/products")
def products():
    time.sleep(random.uniform(0.02, 0.08))
    return jsonify(PRODUCTS)


@app.post("/checkout")
def checkout():
    order_id = random.randint(100000, 999999)
    roll = random.random()

    if roll < 0.07:
        time.sleep(random.uniform(2.5, 3.5))
        raise PaymentGatewayTimeout(f"Payment provider did not answer within 3 seconds (order {order_id})")

    if roll < 0.27:
        waited = random.uniform(1.2, 3.0)
        time.sleep(waited)
        log.warning("Payment gateway slow: %d ms for order %s", waited * 1000, order_id)
    else:
        time.sleep(random.uniform(0.08, 0.30))

    return jsonify(order=order_id, status="paid")


if __name__ == "__main__":
    app.run(port=8000, debug=False)
