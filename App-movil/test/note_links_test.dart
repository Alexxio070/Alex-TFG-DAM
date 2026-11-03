import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/models/note_links.dart';

void main() {
  test('detecta una dirección sola', () {
    final links = findLinks('https://flutter.dev/docs');

    expect(links.map((l) => l.url), ['https://flutter.dev/docs']);
  });

  test('detecta direcciones en mitad del texto', () {
    final links = findLinks('mira http://a.com/x y también www.dart.dev para más');

    expect(links.map((l) => l.url), ['http://a.com/x', 'https://www.dart.dev']);
  });

  test('descarta la puntuación final', () {
    final links = findLinks('Visita https://ejemplo.com/a, (o https://b.org/c).');

    expect(links.map((l) => l.url), ['https://ejemplo.com/a', 'https://b.org/c']);
  });

  test('marca el rango del enlace dentro del texto', () {
    const text = 'ver https://x.es ya';
    final link = findLinks(text).single;

    expect(text.substring(link.start, link.end), 'https://x.es');
  });

  test('ignora prefijos sin dirección y texto normal', () {
    expect(findLinks('solo https:// o www. nada más'), isEmpty);
    expect(findLinks('Llamar al técnico para el router'), isEmpty);
    expect(findLinks('awww.nada.com'), isEmpty);
  });
}
