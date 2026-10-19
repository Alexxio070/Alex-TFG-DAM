"""Comprueba que la TUI monta y que se puede navegar por sus secciones."""

from textual.widgets import ContentSwitcher

from companion.tui.app import CompanionApp

MAIN_BUTTONS = ("btn-pairing", "btn-history", "btn-database", "btn-notes")
SECTIONS = ("pairing", "history", "database", "notes")
PAIRING_TABS = ("tab-device", "tab-security", "tab-service")

# Tamaño amplio: con el por defecto de run_test() (80x24) el banner y los
# marcos no caben y los clics no llegan a los widgets de más abajo.
SIZE = (120, 40)


async def test_mounts_with_empty_data_area():
    app = CompanionApp()
    async with app.run_test(size=SIZE):
        switcher = app.screen.query_one("#sections", ContentSwitcher)
        assert switcher.current is None
        for button_id in MAIN_BUTTONS:
            assert not app.screen.query_one(f"#{button_id}").has_class("-selected")


async def test_main_buttons_switch_section():
    app = CompanionApp()
    async with app.run_test(size=SIZE) as pilot:
        switcher = app.screen.query_one("#sections", ContentSwitcher)
        for button_id, section in zip(MAIN_BUTTONS, SECTIONS):
            await pilot.click(f"#{button_id}")
            await pilot.pause()
            assert switcher.current == section


async def test_active_button_is_highlighted():
    app = CompanionApp()
    async with app.run_test(size=SIZE) as pilot:
        await pilot.click("#btn-history")
        await pilot.pause()
        assert app.screen.query_one("#btn-history").has_class("-selected")
        assert not app.screen.query_one("#btn-pairing").has_class("-selected")

        await pilot.click("#btn-database")
        await pilot.pause()
        assert app.screen.query_one("#btn-database").has_class("-selected")
        assert not app.screen.query_one("#btn-history").has_class("-selected")


async def test_pairing_subtabs_switch():
    app = CompanionApp()
    async with app.run_test(size=SIZE) as pilot:
        await pilot.click("#btn-pairing")
        await pilot.pause()
        switcher = app.screen.query_one("#pairing-tabs", ContentSwitcher)
        assert switcher.current == "device"

        for tab_id, tab in zip(PAIRING_TABS, ("device", "security", "service")):
            await pilot.click(f"#{tab_id}")
            await pilot.pause()
            assert switcher.current == tab
            assert app.screen.query_one(f"#{tab_id}").has_class("-selected")
