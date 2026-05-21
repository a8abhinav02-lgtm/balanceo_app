import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balanceo_app/models/complejo.dart';
import 'package:balanceo_app/models/canal_medicion.dart';
import 'package:balanceo_app/models/rotor_config.dart';
import 'package:balanceo_app/providers/balanceo_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WLS 1-Plane Tests (M Channels)', () {
    test('3 channels, custom weights', () {
      final provider = BalanceoProvider();
      
      // Configure 3 channels with different weights
      final canales = [
        CanalMedicion(tag: '1H', angulo: 0, idSoporte: 1, direccion: 'H', peso: 1.0),
        CanalMedicion(tag: '2H', angulo: 0, idSoporte: 2, direccion: 'H', peso: 2.0),
        CanalMedicion(tag: '3H', angulo: 0, idSoporte: 3, direccion: 'H', peso: 1.5),
      ];
      
      final config = RotorConfig(
        nombreActivo: 'Test Rotor 1P',
        numPlanos: 1,
        canales: canales,
      );
      
      provider.config = config;

      // Define v0
      final v0 = [
        Complejo(2, 0),
        Complejo(0, -4),
        Complejo(3, 3),
      ];
      provider.v0 = v0;

      // Define influence matrix alpha (M x 1)
      // alpha_1 = 1 + 0j, alpha_2 = 0 + 2j, alpha_3 = 1 - 1j
      provider.matrizCoeficientes = [
        [Complejo(1, 0)],
        [Complejo(0, 2)],
        [Complejo(1, -1)],
      ];

      final mc = provider.calcularCorreccion1Plano();
      expect(mc, isNotNull);
      
      // Expected: 7/6 - 0.75j = 1.166667 - 0.75j
      expect(mc!.real, closeTo(1.1666667, 1e-5));
      expect(mc.imaginario, closeTo(-0.75, 1e-5));
    });
  });

  group('WLS 2-Plane Tests (M Channels)', () {
    test('3 channels, weights = 1.0 (consistent system)', () {
      final provider = BalanceoProvider();
      
      final canales = [
        CanalMedicion(tag: '1H', angulo: 0, idSoporte: 1, direccion: 'H', peso: 1.0),
        CanalMedicion(tag: '2H', angulo: 0, idSoporte: 2, direccion: 'H', peso: 1.0),
        CanalMedicion(tag: '3H', angulo: 0, idSoporte: 3, direccion: 'H', peso: 1.0),
      ];
      
      final config = RotorConfig(
        nombreActivo: 'Test Rotor 2P',
        numPlanos: 2,
        canales: canales,
      );
      
      provider.config = config;

      // Define v0
      final v0 = [
        Complejo(2, 0),
        Complejo(2, 0),
        Complejo(4, 0),
      ];
      provider.v0 = v0;

      // Influence matrix C (3 x 2)
      // c11 = 1, c12 = 0
      // c21 = 0, c22 = 1
      // c31 = 1, c32 = 1
      provider.matrizCoeficientes = [
        [Complejo(1, 0), Complejo(0, 0)],
        [Complejo(0, 0), Complejo(1, 0)],
        [Complejo(1, 0), Complejo(1, 0)],
      ];

      final mc = provider.calcularCorreccion2Planos();
      expect(mc[0], isNotNull);
      expect(mc[1], isNotNull);

      // Expected: m1 = -2, m2 = -2
      expect(mc[0]!.real, closeTo(-2.0, 1e-5));
      expect(mc[0]!.imaginario, closeTo(0.0, 1e-5));
      expect(mc[1]!.real, closeTo(-2.0, 1e-5));
      expect(mc[1]!.imaginario, closeTo(0.0, 1e-5));
    });

    test('3 channels, custom weights (inconsistent system)', () {
      final provider = BalanceoProvider();
      
      final canales = [
        CanalMedicion(tag: '1H', angulo: 0, idSoporte: 1, direccion: 'H', peso: 1.0),
        CanalMedicion(tag: '2H', angulo: 0, idSoporte: 2, direccion: 'H', peso: 2.0),
        CanalMedicion(tag: '3H', angulo: 0, idSoporte: 3, direccion: 'H', peso: 1.5),
      ];
      
      final config = RotorConfig(
        nombreActivo: 'Test Rotor 2P',
        numPlanos: 2,
        canales: canales,
      );
      
      provider.config = config;

      // Define v0
      final v0 = [
        Complejo(2, 0),
        Complejo(3, 0),
        Complejo(4, 0),
      ];
      provider.v0 = v0;

      // Influence matrix C (3 x 2)
      provider.matrizCoeficientes = [
        [Complejo(1, 0), Complejo(0, 0)],
        [Complejo(0, 0), Complejo(1, 0)],
        [Complejo(1, 0), Complejo(1, 0)],
      ];

      final mc = provider.calcularCorreccion2Planos();
      expect(mc[0], isNotNull);
      expect(mc[1], isNotNull);

      // Expected with custom weights: m1 = -20/13 ≈ -1.53846, m2 = -36/13 ≈ -2.76923
      expect(mc[0]!.real, closeTo(-20.0 / 13.0, 1e-5));
      expect(mc[0]!.imaginario, closeTo(0.0, 1e-5));
      expect(mc[1]!.real, closeTo(-36.0 / 13.0, 1e-5));
      expect(mc[1]!.imaginario, closeTo(0.0, 1e-5));
    });
  });

  group('Verification Vibration and Session Persistence Tests', () {
    test('registrarVerificacion updates state and persists to disk', () async {
      final provider = BalanceoProvider();
      
      final canales = [
        CanalMedicion(tag: '1H', angulo: 0, idSoporte: 1, direccion: 'H', peso: 1.0),
        CanalMedicion(tag: '2H', angulo: 0, idSoporte: 2, direccion: 'H', peso: 1.0),
      ];
      
      provider.config = RotorConfig(
        nombreActivo: 'Persistence Test Rotor',
        numPlanos: 1,
        canales: canales,
      );
      
      final vVer = [
        Complejo(0.5, 0.5),
        Complejo(0.2, 0.1),
      ];
      
      provider.registrarVerificacion(vVer);
      await provider.saveToDisk();
      expect(provider.vVerificacion, equals(vVer));
      
      // Test that the session is persisted and can be loaded back
      final anotherProvider = BalanceoProvider();
      await anotherProvider.cargarActivo('Persistence Test Rotor');
      expect(anotherProvider.vVerificacion, isNotNull);
      expect(anotherProvider.vVerificacion![0].real, closeTo(0.5, 1e-5));
      expect(anotherProvider.vVerificacion![0].imaginario, closeTo(0.5, 1e-5));
    });

    test('nuevaIteracion clears vVerificacion', () {
      final provider = BalanceoProvider();
      
      final vVer = [
        Complejo(0.5, 0.5),
        Complejo(0.2, 0.1),
      ];
      provider.vVerificacion = vVer;
      
      final lecturasNuevas = [
        Complejo(0.6, 0.6),
        Complejo(0.3, 0.2),
      ];
      
      provider.nuevaIteracion(lecturasNuevas);
      expect(provider.v0, equals(lecturasNuevas));
      expect(provider.vVerificacion, isNull);
    });

    test('eliminarIteracion removes iteration, renumbers remaining items, updates active iteration and saves to disk', () async {
      final provider = BalanceoProvider();
      
      final canales = [
        CanalMedicion(tag: '1H', angulo: 0, idSoporte: 1, direccion: 'H', peso: 1.0),
      ];
      provider.config = RotorConfig(
        nombreActivo: 'Delete Test Rotor',
        numPlanos: 1,
        canales: canales,
      );
      
      // Add three items to history
      provider.agregarAlHistorial(Complejo(1, 0), null, [1.5]);
      provider.agregarAlHistorial(Complejo(2, 0), null, [1.0]);
      provider.agregarAlHistorial(Complejo(3, 0), null, [0.5]);
      
      await provider.saveToDisk();
      expect(provider.historial.length, equals(3));
      expect(provider.historial[0].iteracion, equals(1));
      expect(provider.historial[1].iteracion, equals(2));
      expect(provider.historial[2].iteracion, equals(3));
      
      provider.iteracion = 4;
      
      // Delete the middle one (index 1, It. 2)
      provider.eliminarIteracion(1);
      await provider.saveToDisk();
      
      expect(provider.historial.length, equals(2));
      // Renumbered check
      expect(provider.historial[0].iteracion, equals(1));
      expect(provider.historial[0].masaPlano1!.real, equals(1.0));
      expect(provider.historial[1].iteracion, equals(2));
      expect(provider.historial[1].masaPlano1!.real, equals(3.0));
      
      // Active iteration should be synchronized
      expect(provider.iteracion, equals(3));
      
      // Verify persistence by loading in another provider instance
      final anotherProvider = BalanceoProvider();
      await anotherProvider.cargarActivo('Delete Test Rotor');
      expect(anotherProvider.historial.length, equals(2));
      expect(anotherProvider.historial[0].iteracion, equals(1));
      expect(anotherProvider.historial[1].iteracion, equals(2));
      expect(anotherProvider.iteracion, equals(3));
    });
  });
}

