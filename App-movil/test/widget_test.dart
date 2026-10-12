import 'package:flutter_test/flutter_test.dart';

import 'package:tfg/main.dart';

void main() {
  testWidgets('Arranca en Inicio', (WidgetTester tester) async {
    await tester.pumpWidget(const MiApp());

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Ir a Métricas'), findsOneWidget);
  });
}
