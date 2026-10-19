"""Linux System Companion: interfaz de terminal (TUI) con Textual."""

from textual.app import App

from companion.tui.screens.main_screen import MainScreen


class CompanionApp(App):
    """Punto de entrada: arranca con la pantalla principal."""

    TITLE = "Linux System Companion"

    def __init__(self) -> None:
        # Usa los 16 colores ANSI del tema de la terminal, no la paleta de Textual.
        super().__init__(ansi_color=True)

    def on_mount(self) -> None:
        self.push_screen(MainScreen())


if __name__ == "__main__":
    CompanionApp().run()
