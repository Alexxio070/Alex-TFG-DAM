// Abre enlaces fuera de la app.

import 'package:url_launcher/url_launcher.dart';

/// Abre [url] en el navegador del móvil. Devuelve `false` si no se ha podido abrir.
Future<bool> openLink(String url) async {
  try {
    return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
