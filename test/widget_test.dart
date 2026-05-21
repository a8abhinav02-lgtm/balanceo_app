import 'package:flutter_test/flutter_test.dart';
import 'package:balanceo_app/main.dart';

void main() {
  testWidgets('App renders configuration screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our title is present.
    expect(find.text('Configuración del Rotor'), findsOneWidget);
  });
}
