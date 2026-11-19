// Iconos SVG del diseño, dibujados con trazo y color configurables.

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Iconos disponibles; cada uno guarda el cuerpo SVG de su dibujo.
enum AppIcon {
  menu('<path d="M4 7h16"/><path d="M4 12h16"/><path d="M4 17h10"/>'),
  close('<path d="M6 6l12 12"/><path d="M18 6L6 18"/>'),
  home('<path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/>'),
  metrics('<path d="M4 20V10"/><path d="M10 20V4"/><path d="M16 20v-7"/><path d="M22 20H2"/>'),
  terminal(
    '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 9l3 3-3 3"/><path d="M13 15h4"/>',
  ),
  notes('<path d="M6 3h9l4 4v14H6z"/><path d="M9 11h7"/><path d="M9 15h7"/>'),
  settings(
    '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
  ),
  volume('<path d="M4 9h4l5-4v14l-5-4H4z"/><path d="M17 9a4 4 0 0 1 0 6"/>'),
  lock('<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>'),
  moon('<path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z"/>'),
  bolt('<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>'),
  trash(
    '<path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1 13h10l1-13"/><path d="M10 11v6"/><path d="M14 11v6"/>',
  ),
  plus('<path d="M12 5v14"/><path d="M5 12h14"/>'),
  chevronDown('<path d="M6 9l6 6 6-6"/>'),
  check('<path d="M5 12l5 5 9-10"/>'),
  copy('<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V6a2 2 0 0 1 2-2h9"/>'),
  edit('<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>'),
  search('<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>'),
  chevronRight('<path d="M9 6l6 6-6 6"/>'),
  keyboardHide(
    '<rect x="3" y="4" width="18" height="11" rx="2"/><path d="M7 8h.01M11 8h.01M15 8h.01M8 12h8"/><path d="M9 19l3 2 3-2"/>',
  );

  const AppIcon(this.body);
  final String body;
}

/// Dibuja un [AppIcon] con el color, tamaño y grosor de trazo indicados.
class AppIconView extends StatelessWidget {
  const AppIconView(
    this.icon, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth = 2,
  });

  final AppIcon icon;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="currentColor" stroke-width="$strokeWidth" stroke-linecap="round" '
        'stroke-linejoin="round">${icon.body}</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
    );
  }
}
