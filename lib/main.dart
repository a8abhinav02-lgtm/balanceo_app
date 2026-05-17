import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/balanceo_provider.dart';
import 'screens/configuracion_screen.dart';
import 'screens/medicion_inicial_screen.dart';
import 'screens/prueba_coeficientes_screen.dart';
import 'screens/resultados_screen.dart';
import 'screens/historial_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BalanceoProvider(),
      child: MaterialApp(
        title: 'Balanceo por Coeficientes',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey,
            primary: Colors.blueGrey.shade900,
            secondary: Colors.amber.shade700,
          ),
          scaffoldBackgroundColor: Colors.grey.shade50,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blueGrey.shade900,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.blueGrey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.blueGrey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
            ),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 2,
            shadowColor: Color(0x32607D8B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.blueGrey.shade900,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: BorderSide(color: Colors.blueGrey.shade300),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            ),
          ),
          useMaterial3: true,
        ),

        initialRoute: '/',
        routes: {
          '/': (context) => const ConfiguracionScreen(),
          '/medicion': (context) => const MedicionInicialScreen(),
          '/prueba': (context) => const PruebaCoeficientesScreen(),
          '/resultados': (context) => const ResultadosScreen(),
          '/historial': (context) => const HistorialScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}