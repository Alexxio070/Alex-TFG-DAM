"""Comprueba que la TUI monta y que se puede navegar por sus secciones."""

from companion.tui.app import CompanionApp

MAIN_BUTTONS = ("btn-pairing", "btn-history", "btn-database", "btn-notes")
PAIRING_TABS = ("tab-device", "tab-security", "tab-service")


async def test_mounts_with_empty_data_area():
    app = CompanionApp()
    async with app.run_test():
        assert app.screen.query_one("#data") is not None


async def test_main_buttons_switch_section():
    app = CompanionApp()
    async with app.run_test() as pilot:
        for button_id in MAIN_BUTTONS:
            await pilot.click(f"#{button_id}")
            await pilot.pause()


async def test_pairing_subtabs_switch():
    app = CompanionApp()
    async with app.run_test() as pilot:
        await pilot.click("#btn-pairing")
        await pilot.pause()
        for tab_id in PAIRING_TABS:
            await pilot.click(f"#{tab_id}")
            await pilot.pause()
