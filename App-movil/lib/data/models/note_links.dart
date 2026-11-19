// Detección de enlaces dentro del texto de una nota.

/// Un enlace encontrado y su posición dentro del texto.
class LinkMatch {
  const LinkMatch({required this.start, required this.end, required this.url});

  final int start;
  final int end;
  final String url;
}

final _linkPattern = RegExp(r'\b(?:https?://|www\.)\S+', caseSensitive: false);
const _trailingPunctuation = '.,;:!?)]}"\'»';

/// Busca las direcciones `http(s)://` y `www.` de [text], sin la puntuación final.
List<LinkMatch> findLinks(String text) {
  final links = <LinkMatch>[];
  for (final match in _linkPattern.allMatches(text)) {
    var end = match.end;
    while (end > match.start && _trailingPunctuation.contains(text[end - 1])) {
      end--;
    }
    final raw = text.substring(match.start, end);
    final lower = raw.toLowerCase();
    final prefixLength = lower.startsWith('https://')
        ? 8
        : lower.startsWith('http://')
        ? 7
        : 4;
    if (raw.length <= prefixLength) continue;
    links.add(
      LinkMatch(start: match.start, end: end, url: lower.startsWith('www.') ? 'https://$raw' : raw),
    );
  }
  return links;
}
