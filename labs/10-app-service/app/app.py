"""Nusantara Retail storefront: a deliberately tiny Flask app for Lab 10.

Configuration comes from App Service *app settings*, which the platform hands to
the app as environment variables:

    STORE_NAME  (required)  shown on the home page, e.g. "Nusantara Retail - Kemang"

App Service sets WEBSITE_HOSTNAME and WEBSITE_INSTANCE_ID by itself. The page
shows them, so you can see which host name (slot) and which instance answered.

Routes:
    /        home page (HTTP 500 with a polite error page if STORE_NAME is missing)
    /health  plain "ok" for health checks
"""
import logging
import os
import socket
import sys
from datetime import datetime, timezone
from html import escape

from flask import Flask

APP_VERSION = "1.0"

logging.basicConfig(
    stream=sys.stderr,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [storefront] %(message)s",
)
log = logging.getLogger("storefront")

app = Flask(__name__)


class MissingSettingError(RuntimeError):
    """A required app setting is not configured."""


def required_setting(name):
    value = os.environ.get(name, "").strip()
    if not value:
        raise MissingSettingError(name)
    return value


def instance_name():
    """Short name of the App Service instance (worker) that serves this request."""
    instance_id = os.environ.get("WEBSITE_INSTANCE_ID", "")
    return instance_id[:8] if instance_id else socket.gethostname()


PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{store}</title>
<style>
  body {{ font-family: "Segoe UI", Arial, sans-serif; margin: 0; background: #f4f6fa; color: #1b1b1b; }}
  main {{ max-width: 42rem; margin: 3rem auto; background: #fff; padding: 2rem 2.5rem; border-radius: 12px;
         box-shadow: 0 6px 18px rgb(0 0 0 / 8%); }}
  h1 {{ margin-top: 0; }}
  .version {{ display: inline-block; padding: .2rem .7rem; border-radius: 99px; color: #fff;
             background: {badge_colour}; font-weight: 600; }}
  dl {{ display: grid; grid-template-columns: max-content 1fr; gap: .4rem 1rem; }}
  dt {{ color: #56607a; }}
  footer {{ margin-top: 2rem; color: #56607a; font-size: .85rem; }}
</style>
</head>
<body>
<main>
  <h1>{store}</h1>
  <p>Selamat datang! Our online shop now runs on Azure App Service.</p>
  <p><span class="version">Version {version}</span></p>
  <dl>
    <dt>Served by instance</dt><dd>{instance}</dd>
    <dt>Host name</dt><dd>{host}</dd>
    <dt>Time (UTC)</dt><dd>{now}</dd>
  </dl>
  <footer>Lab 10 &middot; Azure Fundamentals: One Lunch at a Time</footer>
</main>
</body>
</html>
"""

ERROR_PAGE = """<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>Sorry</title></head>
<body style="font-family: Segoe UI, Arial, sans-serif; margin: 3rem;">
  <h1>Sorry, the shop is having a moment.</h1>
  <p>Something went wrong on our side. Please try again in a few minutes.</p>
</body>
</html>
"""


def render_home(store, version, instance, host, now):
    badge_colour = "#107c10" if version.startswith("2") else "#0078d4"
    return PAGE.format(
        store=escape(store),
        version=escape(version),
        instance=escape(instance),
        host=escape(host),
        now=now.strftime("%Y-%m-%d %H:%M:%S"),
        badge_colour=badge_colour,
    )


@app.route("/")
def home():
    store = required_setting("STORE_NAME")
    instance = instance_name()
    host = os.environ.get("WEBSITE_HOSTNAME", "localhost")
    log.info("Served the home page for %s (version %s, instance %s)", store, APP_VERSION, instance)
    return render_home(store, APP_VERSION, instance, host, datetime.now(timezone.utc))


@app.route("/health")
def health():
    return "ok", 200, {"Content-Type": "text/plain; charset=utf-8"}


@app.errorhandler(MissingSettingError)
def missing_setting(err):
    # Customers get a generic page; the details go to the log stream for the engineers.
    log.error(
        "Required app setting %s is missing. Add it under Settings > Environment variables, "
        "or run: az webapp config appsettings set --settings %s=<value>",
        err, err,
    )
    return ERROR_PAGE, 500


if __name__ == "__main__":
    # Local run: STORE_NAME="Test shop" python app.py  ->  http://localhost:8000
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
