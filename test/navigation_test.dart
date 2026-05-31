import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:balanceo_app/main.dart';
import 'package:balanceo_app/providers/balanceo_provider.dart';
import 'package:balanceo_app/screens/prueba_coeficientes_screen.dart';
import 'package:balanceo_app/widgets/resultado_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Configure rotor with optional fields and check if channels cards render', (WidgetTester tester) async {
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

    // 4. Click 'Comenzar Medición'
    final comenzarBtn = find.widgetWithText(ElevatedButton, 'Comenzar Medición');
    expect(comenzarBtn, findsOneWidget);
    
    await tester.tap(comenzarBtn);
    await tester.pumpAndSettle();

    // 5. Verify we navigated to 'Medicion Inicial' screen and cards for channels exist
    expect(find.text('Medición Inicial'), findsOneWidget);
    expect(find.text('1H'), findsOneWidget);
    expect(find.text('2H'), findsOneWidget);
  });

  testWidgets('Verify 30/30 rule validation warning banner and channel cards badges', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 4500);
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Render the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 2. Fill in required Asset Name
    final assetFinder = find.byType(Autocomplete<String>);
    final nameField = find.descendant(of: assetFinder, matching: find.byType(TextFormField));
    await tester.enterText(nameField, 'Rotor Test 30/30');
    await tester.pumpAndSettle();

    // 3. Click 'Comenzar Medición'
    final comenzarBtn = find.widgetWithText(ElevatedButton, 'Comenzar Medición');
    await tester.tap(comenzarBtn);
    await tester.pumpAndSettle();

    // 4. Enter initial readings (V0) on 'Medicion Inicial' screen:
    // Channel 1 (1H): Amp = 10, Fase = 120
    // Channel 2 (2H): Amp = 10, Fase = 120
    final ampFieldsMedicion = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true);
    final faseFieldsMedicion = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true);

    expect(ampFieldsMedicion, findsNWidgets(2));
    expect(faseFieldsMedicion, findsNWidgets(2));

    await tester.enterText(ampFieldsMedicion.at(0), '10.0'); // 1H Amp
    await tester.enterText(faseFieldsMedicion.at(0), '120.0'); // 1H Fase
    await tester.enterText(ampFieldsMedicion.at(1), '10.0'); // 2H Amp
    await tester.enterText(faseFieldsMedicion.at(1), '120.0'); // 2H Fase
    await tester.pumpAndSettle();

    // 5. Tap 'Siguiente'
    final siguienteBtn = find.text('Siguiente');
    await tester.tap(siguienteBtn);
    await tester.pumpAndSettle();

    // 6. We are now on 'Prueba Coeficientes' screen
    expect(find.text('Prueba Coeficientes'), findsOneWidget);

    // Fill in trial weight (Masa de prueba, Ángulo de colocación)
    final masaField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Masa de prueba') == true);
    final anguloField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Ángulo de colocación') == true);
    
    expect(masaField, findsOneWidget);
    expect(anguloField, findsOneWidget);

    await tester.enterText(masaField, '5.0'); // Masa
    await tester.enterText(anguloField, '0.0'); // Ángulo
    await tester.pumpAndSettle();

    // Fill in trial readings (V1) that trigger "Señal Insuficiente":
    // Channel 1: Amp = 11.0 (10% change), Fase = 125.0 (5° change) -> BOTH < 30
    // Channel 2: Amp = 11.0 (10% change), Fase = 125.0 (5° change) -> BOTH < 30
    final ampFieldsPrueba = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true);
    final faseFieldsPrueba = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true);

    expect(ampFieldsPrueba, findsNWidgets(2));
    expect(faseFieldsPrueba, findsNWidgets(2));

    await tester.enterText(ampFieldsPrueba.at(0), '11.0');
    await tester.pump();
    await tester.enterText(ampFieldsPrueba.at(1), '11.0');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba.at(0), '125.0');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba.at(1), '125.0');
    await tester.pumpAndSettle();

    // 7. Verify that both channel cards show "Señal Insuficiente"
    expect(find.text('Señal Insuficiente'), findsNWidgets(2));
    expect(find.text('Señal OK'), findsNothing);

    // Verify that the global warning banner is visible
    expect(find.text('Cambio de Señal Insuficiente'), findsOneWidget);

    // 8. Now update one of the channels to pass the rule:
    // Channel 1: Amp = 14.0 (40% change, >= 30%) -> SHOULD PASS!
    await tester.enterText(ampFieldsPrueba.at(0), '14.0');
    await tester.pumpAndSettle();

    // Channel 1 should show "Señal OK", Channel 2 should show "Señal Insuficiente"
    expect(find.text('Señal OK'), findsOneWidget);
    expect(find.text('Señal Insuficiente'), findsOneWidget);

    // Since one channel passed, the global warning banner should disappear
    expect(find.text('Cambio de Señal Insuficiente'), findsNothing);
  });

  testWidgets('Verify discrete rotor weight splitting option and interactive simulation dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 4500);
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Render the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 2. Fill in Asset Name
    final assetFinder = find.byType(Autocomplete<String>);
    final nameField = find.descendant(of: assetFinder, matching: find.byType(TextFormField));
    await tester.enterText(nameField, 'Rotor Discreto');
    await tester.pumpAndSettle();

    // Select 'Discreto' type
    await tester.tap(find.text('Discreto'));
    await tester.pumpAndSettle();

    // Enter number of blades = 4 and reference angle = 0
    final numAlabesField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Número de álabes');
    final anguloAlabe1Field = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Ángulo del Álabe #1 (°)');

    expect(numAlabesField, findsOneWidget);
    expect(anguloAlabe1Field, findsOneWidget);

    await tester.enterText(numAlabesField, '4');
    await tester.enterText(anguloAlabe1Field, '0.0');
    await tester.pumpAndSettle();

    // Scroll down to click Comenzar Medición
    final listFinder = find.byType(ListView);
    await tester.drag(listFinder, const Offset(0, -350));
    await tester.pumpAndSettle();

    // Click 'Comenzar Medición'
    final comenzarBtn = find.widgetWithText(ElevatedButton, 'Comenzar Medición');
    await tester.tap(comenzarBtn);
    await tester.pumpAndSettle();

    // 3. Enter V0: Amp = 10, Fase = 0 (both channels)
    final ampFieldsMedicion = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true);
    final faseFieldsMedicion = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true);

    await tester.enterText(ampFieldsMedicion.at(0), '10.0');
    await tester.enterText(faseFieldsMedicion.at(0), '0.0');
    await tester.enterText(ampFieldsMedicion.at(1), '10.0');
    await tester.enterText(faseFieldsMedicion.at(1), '0.0');
    await tester.pumpAndSettle();

    // Click 'Siguiente'
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // 4. On Prueba Coeficientes Screen
    final masaField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Masa de prueba') == true);
    final anguloField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Ángulo de colocación') == true);

    await tester.enterText(masaField, '5.0');
    await tester.enterText(anguloField, '0.0');
    await tester.pumpAndSettle();

    // Enter V1: Amp = 7.37, Fase = 28.7 (both channels)
    final ampFieldsPrueba = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true);
    final faseFieldsPrueba = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true);

    await tester.enterText(ampFieldsPrueba.at(0), '7.37');
    await tester.pump();
    await tester.enterText(ampFieldsPrueba.at(1), '7.37');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba.at(0), '28.7');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba.at(1), '28.7');
    await tester.pumpAndSettle();

    // Click 'Calcular'
    await tester.tap(find.text('Calcular'));
    await tester.pumpAndSettle();

    // 5. On Resultados Screen
    expect(find.text('Resultados del Balanceo'), findsOneWidget);

    // Verify recommended single blade
    expect(find.textContaining('Álabe recomendado:'), findsOneWidget);

    // Verify option to view split weights is present
    final verDivisionBtn = find.text('Ver división vectorial opcional');
    expect(verDivisionBtn, findsOneWidget);

    // Tap to expand
    await tester.tap(verDivisionBtn);
    await tester.pumpAndSettle();

    // Verify split weights are calculated and shown (7.07 g on Blade 4 and 7.06 g on Blade 1)
    expect(find.textContaining('Álabe N° 4: 7.07 g'), findsOneWidget);
    expect(find.textContaining('Álabe N° 1: 7.06 g'), findsOneWidget);

    // Find the number of blades text field inside the card and change it to 8
    final numAlabesCardField = find.descendant(
      of: find.byType(ResultadoCard),
      matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Álabes'),
    );
    expect(numAlabesCardField, findsOneWidget);
    await tester.enterText(numAlabesCardField, '8');
    await tester.pumpAndSettle();

    // Verify updated split weights on 8 blades
    expect(find.textContaining('Álabe N° 7: 0.01 g'), findsOneWidget);
    expect(find.textContaining('Álabe N° 8: 9.99 g'), findsOneWidget);

    // Test the "Restaurar" button to restore original rotor values (blades = 4)
    final restaurarBtn = find.text('Restaurar');
    expect(restaurarBtn, findsOneWidget);
    await tester.tap(restaurarBtn);
    await tester.pumpAndSettle();

    // Verify split weights are restored to 4 blades
    expect(find.textContaining('Álabe N° 4: 7.07 g'), findsOneWidget);
    expect(find.textContaining('Álabe N° 1: 7.06 g'), findsOneWidget);

    // Tap "Instalar Dividido" to register equivalent split weights
    final instalarDivididoBtn = find.text('Instalar Dividido');
    expect(instalarDivididoBtn, findsOneWidget);
    await tester.tap(instalarDivididoBtn);
    await tester.pumpAndSettle();

    // Verify snackbar confirmation is shown
    expect(find.textContaining('Se registró la división en Álabes'), findsOneWidget);

    // Verify that the "Masa Real Instalada" card updates to equivalent complex mass (9.99 g @ 45.0°)
    expect(find.textContaining('Plano 1: 9.99 g @ 45.0°'), findsOneWidget);

    // Verify button highlights (text changes to 'Dividido Activo')
    expect(find.text('Dividido Activo'), findsOneWidget);
  });
}
