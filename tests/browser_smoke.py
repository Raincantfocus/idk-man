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
parser.add_argument("--startup-timeout-ms", type=int, default=180000,
                    help="Allow cold WASM compilation on software-rendered CI")
parser.add_argument("--skip-captures", action="store_true",
                    help="Check interactions when software-rendered screenshots stall")
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
    # Smaller framebuffer keeps SwiftShader captures practical on shared CPU CI.
    page = browser.new_page(viewport={"width": 640, "height": 400})
    page.set_default_timeout(60000)
    def click(x, y):
        page.mouse.click(x * 2 / 3, y * 2 / 3)
    def capture(name):
        if not args.skip_captures:
            page.screenshot(path=str(output / name))
    errors = []
    console_errors = []
    page.on("pageerror", lambda error: errors.append(str(error)))
    page.on("console", lambda message: console_errors.append(message.text)
            if message.type == "error" else None)
    page.goto(args.url, wait_until="networkidle", timeout=60000)
    try:
        page.wait_for_function("document.querySelector('#status') === null",
                               timeout=args.startup_timeout_ms)
    except Exception:
        print(json.dumps({"page_errors": errors, "console_errors": console_errors}, indent=2))
        browser.close()
        raise
    page.wait_for_timeout(750)
    print("Web export loaded", flush=True)
    capture("web-menu.png")
    click(146, 438)
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
    capture("web-focus.png")
    page.keyboard.press("Escape")
    page.wait_for_function("document.pointerLockElement === null", timeout=10000)
    capture("web-pause.png")
    click(170, 262)
    page.wait_for_function("document.pointerLockElement !== null", timeout=10000)
    # Switch directly from active Focus; this avoids measuring gameplay cooldowns
    # against wall time on a software-rendered browser with a low frame rate.
    page.keyboard.press("e")
    page.wait_for_timeout(400)
    capture("web-shroud.png")
    page.keyboard.press("Escape")
    page.wait_for_function("document.pointerLockElement === null", timeout=10000)
    click(170, 370)  # Return to title.
    page.wait_for_timeout(400)
    click(170, 486)  # Movement Lab.
    page.wait_for_function("document.pointerLockElement !== null", timeout=10000)
    page.keyboard.press("t")
    page.wait_for_timeout(400)
    capture("web-movement-lab.png")
    result = {
        "loaded_web_export": True,
        "start_and_resume_pointer_lock": True,
        "pause_releases_pointer": True,
        "movement_lab_pointer_lock": True,
        "screenshots_captured": not args.skip_captures,
        "page_errors": errors,
        "console_errors": console_errors,
    }
    (output / "web-result.json").write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))
    browser.close()
    if errors or console_errors:
        raise SystemExit(1)
