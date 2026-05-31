import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:balanceo_app/main.dart';
import 'package:balanceo_app/providers/balanceo_provider.dart';
import 'package:balanceo_app/screens/prueba_coeficientes_screen.dart';
import 'package:balanceo_app/widgets/resultado_card.dart';
import 'package:balanceo_app/widgets/consolidacion_card.dart';

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

  testWidgets('Verify Paso 4: Vector consolidation card and adjustment in refinement runs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 4500);
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Render the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 2. Fill in Asset Name
    final assetFinder = find.byType(Autocomplete<String>);
    final nameField = find.descendant(of: assetFinder, matching: find.byType(TextFormField));
    await tester.enterText(nameField, 'Rotor Refinement');
    await tester.pumpAndSettle();

    // Select 'Discreto' type
    await tester.tap(find.text('Discreto'));
    await tester.pumpAndSettle();

    // Enter number of blades = 4 and reference angle = 0
    final numAlabesField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Número de álabes');
    final anguloAlabe1Field = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Ángulo del Álabe #1 (°)');
    await tester.enterText(numAlabesField, '4');
    await tester.enterText(anguloAlabe1Field, '0.0');
    await tester.pumpAndSettle();

    // Scroll down and click Comenzar Medición
    final listFinder = find.byType(ListView);
    await tester.drag(listFinder, const Offset(0, -350));
    await tester.pumpAndSettle();
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

    // 5. On Resultados Screen (It 1)
    // Tap "Registrar Vibración Residual"
    final registrarBtn = find.text('Registrar Vibración Residual');
    expect(registrarBtn, findsOneWidget);
    await tester.tap(registrarBtn);
    await tester.pumpAndSettle();

    // Enter V2 (Residual): Amp = 5.0, Fase = 30.0 for both channels in the dialog
    final ampFieldsDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true),
    );
    final faseFieldsDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true),
    );
    expect(ampFieldsDialog, findsNWidgets(2));
    expect(faseFieldsDialog, findsNWidgets(2));

    await tester.enterText(ampFieldsDialog.at(0), '5.0');
    await tester.enterText(faseFieldsDialog.at(0), '30.0');
    await tester.enterText(ampFieldsDialog.at(1), '5.0');
    await tester.enterText(faseFieldsDialog.at(1), '30.0');
    await tester.pumpAndSettle();

    // Tap 'Siguiente' in dialog
    final siguienteDialogBtn = find.descendant(of: find.byType(AlertDialog), matching: find.text('Siguiente'));
    await tester.tap(siguienteDialogBtn);
    await tester.pumpAndSettle();

    // Tap 'Refinar (Nueva It.)' in confirmation dialog
    final refinarBtn = find.text('Refinar (Nueva It.)');
    expect(refinarBtn, findsOneWidget);
    await tester.tap(refinarBtn);
    await tester.pumpAndSettle();

    // 6. On Resultados Screen (It 2)
    // Subtitle check or title check
    expect(find.textContaining('It. 2'), findsOneWidget);

    // Verify ConsolidacionCard is rendered
    expect(find.text('Masa Correctora Consolidada'), findsOneWidget);

    // Verify "Instalar Consolidado" is visible because no action is taken yet
    final instalarConsolidadoBtn = find.text('Instalar Consolidado');
    expect(instalarConsolidadoBtn, findsOneWidget);

    // Click "Instalar Consolidado"
    await tester.tap(instalarConsolidadoBtn);
    await tester.pumpAndSettle();

    // Verify it is highlighted as active
    expect(find.text('Consolidado Activo'), findsOneWidget);

    // Expand the consolidacion split section
    final verDivisionConsolidadaBtn = find.text('Ver división de masa consolidada');
    expect(verDivisionConsolidadaBtn, findsOneWidget);
    await tester.tap(verDivisionConsolidadaBtn);
    await tester.pumpAndSettle();

    // Click 'Instalar Dividido' under ConsolidacionCard
    final instalarDivididoConsolidadoBtn = find.descendant(
      of: find.byType(ConsolidacionCard),
      matching: find.text('Instalar Dividido'),
    );
    expect(instalarDivididoConsolidadoBtn, findsOneWidget);
    await tester.tap(instalarDivididoConsolidadoBtn);
    await tester.pumpAndSettle();

    // Verify divided is now active and exact consolidated is inactive
    expect(
      find.descendant(of: find.byType(ConsolidacionCard), matching: find.text('Dividido Activo')),
      findsOneWidget,
    );
    expect(find.text('Instalar Consolidado'), findsOneWidget);

    // Click 'Instalar Consolidado' to toggle it back to active
    final instalarConsolidadoBtn2 = find.text('Instalar Consolidado');
    await tester.tap(instalarConsolidadoBtn2);
    await tester.pumpAndSettle();

    // Verify it is highlighted as active again and divided is inactive
    expect(find.text('Consolidado Activo'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ConsolidacionCard), matching: find.text('Instalar Dividido')),
      findsOneWidget,
    );

    // 7. Test "Ajustar Peso Real" with consolidated switch
    final editBtn = find.widgetWithIcon(IconButton, Icons.edit);
    expect(editBtn, findsOneWidget);
    await tester.tap(editBtn);
    await tester.pumpAndSettle();

    // Find the 'Registrar peso como consolidado' switch/tile
    final switchTile = find.text('Registrar peso como consolidado');
    expect(switchTile, findsOneWidget);
    await tester.tap(switchTile);
    await tester.pumpAndSettle();

    // Enter custom values in the dialog (Masa = 12.0, Ángulo = 45.0)
    final masaInput = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Masa (g)');
    final anguloInput = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Ángulo (°)');
    expect(masaInput, findsOneWidget);
    expect(anguloInput, findsOneWidget);

    await tester.enterText(masaInput, '12.0');
    await tester.enterText(anguloInput, '45.0');
    await tester.pumpAndSettle();

    // Click Aceptar
    final aceptarBtn = find.text('Aceptar');
    await tester.tap(aceptarBtn);
    await tester.pumpAndSettle();

    // Verify updated Masa Real display. Net real should update.
    // The previous cumulative mass was the first run real mass (which defaulted to the recommended m1 of first iteration, i.e., ~9.99 g @ 45°).
    // Toggling consolidated and entering 12.0 g @ 45.0° means we consolidated to 12.0 g @ 45°.
    // Let's verify that the main display or provider has updated to the expected value.
    // The UI should show the adjusted angle and the net result.
    // Let's search for "Plano 1: " prefix or similar in results screen.
    expect(find.textContaining('Plano 1: 2.01 g'), findsOneWidget);
  });

  testWidgets('Verify Paso 5: Overhung (Rotor en voladizo) static-couple modal balance wizard and results', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 4500);
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Render the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 2. Fill in Asset Name
    final assetFinder = find.byType(Autocomplete<String>);
    final nameField = find.descendant(of: assetFinder, matching: find.byType(TextFormField));
    await tester.enterText(nameField, 'Rotor Voladizo Test');
    await tester.pumpAndSettle();

    // Select '2 planos'
    await tester.tap(find.text('2 planos'));
    await tester.pumpAndSettle();

    // Find and toggle the 'Rotor en voladizo (Overhung)' SwitchListTile
    final switchFinder = find.byType(SwitchListTile);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Scroll down to the bottom
    final listFinder = find.byType(ListView);
    await tester.drag(listFinder, const Offset(0, -500));
    await tester.pumpAndSettle();

    // Click 'Comenzar Medición'
    final comenzarBtn = find.widgetWithText(ElevatedButton, 'Comenzar Medición');
    await tester.tap(comenzarBtn);
    await tester.pumpAndSettle();

    // 3. We are now on 'Medicion Inicial' screen. Enter V0:
    // Channel 1: Amp = 10, Fase = 0
    // Channel 2: Amp = 8, Fase = 120
    final ampFieldsMedicion = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true);
    final faseFieldsMedicion = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true);

    expect(ampFieldsMedicion, findsNWidgets(2));
    expect(faseFieldsMedicion, findsNWidgets(2));

    await tester.enterText(ampFieldsMedicion.at(0), '10.0');
    await tester.enterText(faseFieldsMedicion.at(0), '0.0');
    await tester.enterText(ampFieldsMedicion.at(1), '8.0');
    await tester.enterText(faseFieldsMedicion.at(1), '120.0');
    await tester.pumpAndSettle();

    // Click 'Siguiente'
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // 4. We are on 'Prueba Estática (Paso 1/2)'. Check title and banner
    expect(find.text('Prueba Estática (Paso 1/2)'), findsOneWidget);
    expect(find.textContaining('Fase 1/2: Configuración Estática'), findsOneWidget);

    // Enter trial mass (static trial run): Masa = 5.0, Ángulo = 0.0
    final masaField1 = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Masa de prueba estática') == true);
    final anguloField1 = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Ángulo en Plano 1 & 2') == true);

    expect(masaField1, findsOneWidget);
    expect(anguloField1, findsOneWidget);

    await tester.enterText(masaField1, '5.0');
    await tester.enterText(anguloField1, '0.0');
    await tester.pumpAndSettle();

    // Enter response V1:
    // Channel 1: Amp = 12.0, Fase = 10.0
    // Channel 2: Amp = 9.0, Fase = 130.0
    final ampFieldsPrueba1 = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true);
    final faseFieldsPrueba1 = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true);

    await tester.enterText(ampFieldsPrueba1.at(0), '12.0');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba1.at(0), '10.0');
    await tester.pump();
    await tester.enterText(ampFieldsPrueba1.at(1), '9.0');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba1.at(1), '130.0');
    await tester.pumpAndSettle();

    // Click 'Siguiente' to go to step 2
    final siguienteBtn = find.text('Siguiente');
    expect(siguienteBtn, findsOneWidget);
    await tester.tap(siguienteBtn);
    await tester.pumpAndSettle();

    // 5. We are on 'Prueba de Acople (Paso 2/2)'. Check title and banner
    expect(find.text('Prueba de Acople (Paso 2/2)'), findsOneWidget);
    expect(find.textContaining('Fase 2/2: Configuración de Acople'), findsOneWidget);

    // Enter trial mass (couple trial run): Masa = 5.0, Ángulo = 0.0
    final masaField2 = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Masa de prueba de acople') == true);
    final anguloField2 = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Ángulo en Plano 1') == true);

    expect(masaField2, findsOneWidget);
    expect(anguloField2, findsOneWidget);

    await tester.enterText(masaField2, '5.0');
    await tester.enterText(anguloField2, '0.0');
    await tester.pumpAndSettle();

    // Enter response V2:
    // Channel 1: Amp = 11.0, Fase = 5.0
    // Channel 2: Amp = 7.0, Fase = 110.0
    final ampFieldsPrueba2 = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true);
    final faseFieldsPrueba2 = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true);

    await tester.enterText(ampFieldsPrueba2.at(0), '11.0');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba2.at(0), '5.0');
    await tester.pump();
    await tester.enterText(ampFieldsPrueba2.at(1), '7.0');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba2.at(1), '110.0');
    await tester.pumpAndSettle();

    // Click 'Calcular' to complete balancing
    final calcularBtn = find.text('Calcular');
    expect(calcularBtn, findsOneWidget);
    await tester.tap(calcularBtn);
    await tester.pumpAndSettle();

    // 6. We are now on 'Resultados' screen. Verify modal method description banner
    expect(find.text('Resultados del Balanceo'), findsOneWidget);
    expect(find.textContaining('Método: Descomposición Modal Estático-Acople para rotor en voladizo.'), findsOneWidget);
    
    // Check that recommended correction weight card results exist
    expect(find.text('Plano 1'), findsOneWidget);
    expect(find.text('Plano 2'), findsOneWidget);
  });

  testWidgets('Verify Paso 6: ISO 1940 Quality Control card, inputs, calculations, dynamic updates, and compliance badge', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 4500);
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Render the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // 2. Fill in Asset Name
    final assetFinder = find.byType(Autocomplete<String>);
    final nameField = find.descendant(of: assetFinder, matching: find.byType(TextFormField));
    await tester.enterText(nameField, 'Rotor ISO Test');
    await tester.pumpAndSettle();

    // Fill in physical parameters in config screen
    final listFinder = find.byType(ListView);
    await tester.drag(listFinder, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.drag(listFinder, const Offset(0, -350));
    await tester.pumpAndSettle();

    final pesoField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Peso del rotor (kg)');
    final velocidadField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Velocidad de rotación (RPM)');
    final radioField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Radio de colocación de masa (mm)');

    await tester.enterText(pesoField, '15.5');
    await tester.enterText(velocidadField, '1800');
    await tester.enterText(radioField, '250');
    await tester.pumpAndSettle();

    // Click 'Comenzar Medición'
    final comenzarBtn = find.widgetWithText(ElevatedButton, 'Comenzar Medición');
    await tester.tap(comenzarBtn);
    await tester.pumpAndSettle();

    // 3. Enter V0: Amp = 10.0, Fase = 120.0 (both channels)
    final ampFieldsMedicion = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true);
    final faseFieldsMedicion = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true);

    await tester.enterText(ampFieldsMedicion.at(0), '10.0');
    await tester.enterText(faseFieldsMedicion.at(0), '120.0');
    await tester.enterText(ampFieldsMedicion.at(1), '10.0');
    await tester.enterText(faseFieldsMedicion.at(1), '120.0');
    await tester.pumpAndSettle();

    // Click 'Siguiente'
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // 4. On Prueba Coeficientes Screen
    final trialMasaField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Masa de prueba') == true);
    final trialAnguloField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Ángulo de colocación') == true);
    
    await tester.enterText(trialMasaField, '5.0');
    await tester.enterText(trialAnguloField, '0.0');
    await tester.pumpAndSettle();

    // Enter trial response V1
    final ampFieldsPrueba = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true);
    final faseFieldsPrueba = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true);

    await tester.enterText(ampFieldsPrueba.at(0), '14.0');
    await tester.pump();
    await tester.enterText(ampFieldsPrueba.at(1), '11.0');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba.at(0), '125.0');
    await tester.pump();
    await tester.enterText(faseFieldsPrueba.at(1), '125.0');
    await tester.pumpAndSettle();

    // Click 'Calcular'
    await tester.tap(find.text('Calcular'));
    await tester.pumpAndSettle();

    // 5. On Resultados Screen
    expect(find.text('Resultados del Balanceo'), findsOneWidget);

    // Verify ISO card is visible but Switch is OFF (expanded details not shown)
    expect(find.text('Control de Calidad ISO 1940'), findsOneWidget);
    expect(find.byKey(const Key('iso_results_section')), findsNothing);

    // Toggle the Switch to ON
    final switchFinder = find.byKey(const Key('iso_switch'));
    expect(switchFinder, findsOneWidget);
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify expanded details are now visible
    expect(find.byKey(const Key('iso_results_section')), findsOneWidget);

    // The current residual vibration defaults to v0, which is around 14.0/11.0, which should exceed G2.5 tolerance.
    // Let's verify that the compliance badge shows "NO CUMPLE CON ISO G2.5"
    expect(find.text('NO CUMPLE CON ISO G2.5'), findsOneWidget);

    // 6. Now register a low residual vibration (verification run)
    final registrarBtn = find.text('Registrar Vibración Residual');
    await tester.ensureVisible(registrarBtn);
    await tester.pumpAndSettle();
    await tester.tap(registrarBtn);
    await tester.pumpAndSettle();

    final ampFieldsDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Amplitud') == true),
    );
    final faseFieldsDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Fase') == true),
    );

    // Enter very low vibration (0.1) so it complies
    await tester.enterText(ampFieldsDialog.at(0), '0.1');
    await tester.enterText(faseFieldsDialog.at(0), '120.0');
    await tester.enterText(ampFieldsDialog.at(1), '0.1');
    await tester.enterText(faseFieldsDialog.at(1), '120.0');
    await tester.pumpAndSettle();

    // Tap 'Siguiente' in dialog
    final siguienteDialogBtn = find.descendant(of: find.byType(AlertDialog), matching: find.text('Siguiente'));
    await tester.tap(siguienteDialogBtn);
    await tester.pumpAndSettle();

    // Tap 'Concluir Balanceo' in confirmation dialog
    final concluirBtn = find.text('Concluir Balanceo');
    expect(concluirBtn, findsOneWidget);
    await tester.tap(concluirBtn);
    await tester.pumpAndSettle();

    // 7. Verify the verification run is registered and shown
    expect(find.text('Verificación Registrada'), findsOneWidget);

    // Scroll to the compliance badge to verify it
    final complianceBadge = find.byKey(const Key('iso_compliance_badge'));
    await tester.ensureVisible(complianceBadge);
    await tester.pumpAndSettle();

    // Now, with residual vibration of 0.1, it should show "CUMPLE CON ISO G2.5"
    expect(find.text('CUMPLE CON ISO G2.5'), findsOneWidget);

    // Let's change physical parameters from the results screen card:
    // Update RPM to 3600 (eper should decrease, limits should change)
    final rpmField = find.byKey(const Key('iso_rpm_field'));
    await tester.ensureVisible(rpmField);
    await tester.pumpAndSettle();
    await tester.enterText(rpmField, '3600');
    await tester.pumpAndSettle();

    // Change grade to G0.4 (very high precision, eper is tiny, should fail G0.4)
    final gradeDropdown = find.byKey(const Key('iso_grade_dropdown'));
    await tester.ensureVisible(gradeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(gradeDropdown);
    await tester.pumpAndSettle();
    
    // Tap the G0.4 item
    await tester.tap(find.textContaining('G0.4').last);
    await tester.pumpAndSettle();

    // Verify it now shows "NO CUMPLE CON ISO G0.4"
    expect(find.text('NO CUMPLE CON ISO G0.4'), findsOneWidget);
  });
}
