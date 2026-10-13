"""Optional desktop-browser check; requires Playwright and a served Web export.

Run: python tests/browser_smoke.py --url http://127.0.0.1:8080
CHROMIUM_BIN may select a system Chromium; otherwise Playwright uses its browser.
"""
import argparse
import json
import os
from pathlib import Path

from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument("--url", default="http://127.0.0.1:8080")
args = parser.parse_args()
output = Path(__file__).resolve().parents[1] / "test-output"
output.mkdir(exist_ok=True)

with sync_playwright() as playwright:
    options = {
        "headless": True,
        "args": ["--enable-unsafe-swiftshader", "--use-angle=swiftshader", "--disable-dev-shm-usage"],
    }
    if os.environ.get("CHROMIUM_BIN"):
        options["executable_path"] = os.environ["CHROMIUM_BIN"]
    browser = playwright.chromium.launch(**options)
    page = browser.new_page(viewport={"width": 960, "height": 600})
    errors = []
    console_errors = []
    page.on("pageerror", lambda error: errors.append(str(error)))
    page.on("console", lambda message: console_errors.append(message.text)
            if message.type == "error" else None)
    page.goto(args.url, wait_until="networkidle", timeout=60000)
    page.wait_for_function("document.querySelector('#status') === null", timeout=60000)
    page.wait_for_timeout(750)
    page.screenshot(path=str(output / "web-menu.png"))
    page.mouse.click(146, 438)
    page.wait_for_function("document.pointerLockElement !== null", timeout=10000)
    page.keyboard.down("w")
    page.keyboard.down("Shift")
    page.wait_for_timeout(500)
    page.keyboard.up("Shift")
    page.keyboard.up("w")
    page.mouse.down()
    page.wait_for_timeout(300)
    page.mouse.up()
    page.keyboard.press("q")
    page.wait_for_timeout(400)
    page.screenshot(path=str(output / "web-focus.png"))
    page.keyboard.press("Escape")
    page.wait_for_function("document.pointerLockElement === null", timeout=10000)
    page.screenshot(path=str(output / "web-pause.png"))
    page.mouse.click(170, 262)
    page.wait_for_function("document.pointerLockElement !== null", timeout=10000)
    # Switch directly from active Focus; this avoids measuring gameplay cooldowns
    # against wall time on a software-rendered browser with a low frame rate.
    page.keyboard.press("e")
    page.wait_for_timeout(400)
    page.screenshot(path=str(output / "web-shroud.png"))
    result = {
        "loaded_web_export": True,
        "start_and_resume_pointer_lock": True,
        "pause_releases_pointer": True,
        "page_errors": errors,
        "console_errors": console_errors,
    }
    (output / "web-result.json").write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))
    browser.close()
    if errors or console_errors:
        raise SystemExit(1)
