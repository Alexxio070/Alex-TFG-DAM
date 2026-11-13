"""Cambio de sección con una barra de botones, común a la pantalla principal y
a las subpestañas de Emparejamiento."""

from textual.widget import Widget
from textual.widgets import Button, ContentSwitcher


def select_section(
    owner: Widget, section_ids: dict[str, str], switcher: str, buttons: str, pressed: Button
) -> None:
    """Muestra la sección del botón pulsado y lo resalta; ignora otros botones."""
    section = section_ids.get(pressed.id)
    if section is None:
        return
    owner.query_one(switcher, ContentSwitcher).current = section
    for button in owner.query(buttons):
        button.variant = "primary" if button is pressed else "default"
