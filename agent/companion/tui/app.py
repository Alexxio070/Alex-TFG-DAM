"""Linux System Companion: interfaz de terminal (TUI) con Textual."""

from textual.app import App

from companion.tui.screens.main_screen import MainScreen


class CompanionApp(App):
    TITLE = "Linux System Companion"

    def on_mount(self) -> None:
        self.push_screen(MainScreen())


def main() -> None:
    CompanionApp().run()


if __name__ == "__main__":
    main()
