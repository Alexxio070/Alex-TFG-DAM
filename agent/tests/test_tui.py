"""Comprueba que la TUI monta y que se puede navegar por sus secciones."""

from textual.widgets import ContentSwitcher, Static

from sysmote.tui.app import SysmoteApp
from sysmote.tui.screens.main_screen import BANNER_FALLBACK, BANNER_MIN_WIDTH

MAIN_BUTTONS = ("btn-pairing", "btn-history", "btn-database", "btn-notes")
SECTIONS = ("pairing", "history", "database", "notes")
PAIRING_TABS = ("tab-device", "tab-security", "tab-service")

# Tamaño amplio: con el por defecto de run_test() (80x24) el banner y los
# marcos no caben y los clics no llegan a los widgets de más abajo.
SIZE = (120, 40)
NARROW_SIZE = (BANNER_MIN_WIDTH - 1, 24)


async def test_mounts_with_empty_data_area():
    app = SysmoteApp()
    async with app.run_test(size=SIZE):
        switcher = app.screen.query_one("#sections", ContentSwitcher)
        assert switcher.current is None
        for button_id in MAIN_BUTTONS:
            assert app.screen.query_one(f"#{button_id}").variant == "default"


async def test_main_buttons_switch_section():
    app = SysmoteApp()
    async with app.run_test(size=SIZE) as pilot:
        switcher = app.screen.query_one("#sections", ContentSwitcher)
        for button_id, section in zip(MAIN_BUTTONS, SECTIONS):
            await pilot.click(f"#{button_id}")
            await pilot.pause()
            assert switcher.current == section


async def test_active_button_is_highlighted():
    app = SysmoteApp()
    async with app.run_test(size=SIZE) as pilot:
        await pilot.click("#btn-history")
        await pilot.pause()
        assert app.screen.query_one("#btn-history").variant == "primary"
        assert app.screen.query_one("#btn-pairing").variant == "default"

        await pilot.click("#btn-database")
        await pilot.pause()
        assert app.screen.query_one("#btn-database").variant == "primary"
        assert app.screen.query_one("#btn-history").variant == "default"


async def test_pairing_subtabs_switch():
    app = SysmoteApp()
    async with app.run_test(size=SIZE) as pilot:
        await pilot.click("#btn-pairing")
        await pilot.pause()
        switcher = app.screen.query_one("#pairing-tabs", ContentSwitcher)
        assert switcher.current == "device"
        assert app.screen.query_one("#tab-device").variant == "primary"

        for tab_id, tab in zip(PAIRING_TABS, ("device", "security", "service")):
            await pilot.click(f"#{tab_id}")
            await pilot.pause()
            assert switcher.current == tab
            assert app.screen.query_one(f"#{tab_id}").variant == "primary"


async def test_banner_falls_back_to_plain_text_when_narrow():
    app = SysmoteApp()
    async with app.run_test(size=SIZE):
        full_width = app.screen.query_one("#banner-text", Static).region.width
        assert full_width > len(BANNER_FALLBACK)

    app = SysmoteApp()
    async with app.run_test(size=NARROW_SIZE):
        narrow_width = app.screen.query_one("#banner-text", Static).region.width
        assert narrow_width == len(BANNER_FALLBACK)


async def test_buttons_stay_clickable_when_narrow():
    app = SysmoteApp()
    async with app.run_test(size=NARROW_SIZE) as pilot:
        await pilot.click("#btn-pairing")
        await pilot.pause()
        await pilot.click("#tab-security")
        await pilot.pause()
        assert app.screen.query_one("#tab-security").variant == "primary"
