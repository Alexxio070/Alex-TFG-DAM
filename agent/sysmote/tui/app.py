"""Sysmote: interfaz de terminal (TUI) con Textual."""

from textual.app import App

from sysmote.tui.screens.main_screen import MainScreen


class SysmoteApp(App):
    TITLE = "Sysmote"

    def on_mount(self) -> None:
        self.push_screen(MainScreen())


def main() -> None:
    SysmoteApp().run()


if __name__ == "__main__":
    main()
