import 'package:flutter_test/flutter_test.dart';

import 'package:testar_dart/main.dart';

void main() {
  testWidgets('app starts on login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RookieFoxApp());

    expect(find.text('Rookie Fox Dev Hub'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Cadastre-se'), findsOneWidget);
  });
}
