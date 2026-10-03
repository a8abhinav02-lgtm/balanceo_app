import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balanceo_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Configure rotor with optional fields and check if channels cards render', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 4500);
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Render the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 2. Fill in required Asset Name
    final assetFinder = find.byType(Autocomplete<String>);
    expect(assetFinder, findsOneWidget);
    
    final nameField = find.descendant(
      of: assetFinder,
      matching: find.byType(TextFormField),
    );
    await tester.enterText(nameField, 'Rotor Test');
    await tester.pumpAndSettle();

    // Scroll down to reveal the optional fields by dragging the ListView twice
    final listFinder = find.byType(ListView);
    expect(listFinder, findsOneWidget);
    await tester.drag(listFinder, const Offset(0, -350));
    await tester.pumpAndSettle();

    // Now find fields by finding the TextFormField widgets and checking their decoration labels
    final pesoField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Peso del rotor (kg)');
    final velocidadField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Velocidad de rotación (RPM)');
    final radioField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Radio de colocación de masa (mm)');

    expect(pesoField, findsOneWidget);
    expect(velocidadField, findsOneWidget);
    expect(radioField, findsOneWidget);

    await tester.enterText(pesoField, '15.5');
    await tester.enterText(velocidadField, '1800');
    await tester.enterText(radioField, '250');
    await tester.pumpAndSettle();

    // 4. Click 'Ir al Graficador Vectorial'
    final comenzarBtn = find.widgetWithText(ElevatedButton, 'Ir al Graficador Vectorial');
    expect(comenzarBtn, findsOneWidget);
    
    await tester.tap(comenzarBtn);
    await tester.pumpAndSettle();

    // 5. Verify we navigated to 'Graficador Vectorial - Lecturas' screen and cards for channels exist
    expect(find.text('Graficador Vectorial - Lecturas'), findsOneWidget);
    expect(find.text('Diagrama Vectorial Polar'), findsOneWidget);
  });
}
