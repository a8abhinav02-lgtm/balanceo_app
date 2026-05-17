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