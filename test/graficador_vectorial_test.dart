import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balanceo_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Graficador Vectorial flow: Preconfig -> Lecturas -> Graficador Manual', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 4500);
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Render app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 2. Configure asset name
    final assetFinder = find.byType(Autocomplete<String>);
    expect(assetFinder, findsOneWidget);
    
    final nameField = find.descendant(
      of: assetFinder,
      matching: find.byType(TextFormField),
    );
    await tester.enterText(nameField, 'Rotor Graficador Test');
    await tester.pumpAndSettle();

    // 3. Click 'Ir al Graficador Vectorial'
    final comenzarBtn = find.widgetWithText(ElevatedButton, 'Ir al Graficador Vectorial');
    expect(comenzarBtn, findsOneWidget);
    
    await tester.tap(comenzarBtn);
    await tester.pumpAndSettle();

    // 4. Verify we navigated to GraficadorLecturasScreen
    expect(find.text('Graficador Vectorial - Lecturas'), findsOneWidget);
    expect(find.text('Diagrama Vectorial Polar'), findsOneWidget);
    expect(find.text('Operaciones Vectoriales Auxiliares'), findsOneWidget);

    // 5. Navigate to GraficadorManualScreen
    final btnContinuar = find.widgetWithText(ElevatedButton, 'Continuar a Graficación Manual de Pesos Correctores');
    expect(btnContinuar, findsOneWidget);
    await tester.ensureVisible(btnContinuar);
    await tester.pumpAndSettle();
    await tester.tap(btnContinuar, warnIfMissed: false);
    await tester.pumpAndSettle();

    // 6. Verify we are on GraficadorManualScreen
    expect(find.text('Pesos Correctores Manuales'), findsOneWidget);
    expect(find.text('Diagrama Polar de Verificación Final'), findsOneWidget);
    expect(find.text('Resumen de Vectores Registrados'), findsOneWidget);
  });
}
