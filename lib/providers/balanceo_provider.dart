import 'package:flutter/material.dart';
import '../models/complejo.dart';
import '../models/rotor_config.dart';
import '../models/historial_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BalanceoProvider extends ChangeNotifier {
  RotorConfig? config;
  Complejo? v0_1;
  Complejo? v0_2;
  Complejo? coeficiente1;
  List<List<Complejo>>? matrizCoeficientes;
  List<HistorialItem> historial = [];
  int numPlanos = 1;
  List<String> listaActivos = [];

  // Paso actual en el flujo de balanceo
  int pasoActual = 0; // 0: config, 1: medicion inicial, 2: prueba coeficientes, 3: resultados

  BalanceoProvider() {
    _init();
  }

  Future<void> _init() async {
    await cargarListaActivos();
    // No cargamos ninguno por defecto para forzar seleccion
  }

  bool get tieneCoeficientes =>
      numPlanos == 1 ? coeficiente1 != null : matrizCoeficientes != null;

  Complejo? get sensor1Actual => v0_1;
  Complejo? get sensor2Actual => v0_2;

  Future<void> cargarListaActivos() async {
    final prefs = await SharedPreferences.getInstance();
    listaActivos = prefs.getStringList('lista_activos') ?? [];
    notifyListeners();
  }

  Future<void> eliminarActivo(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('config_$nombre');
    await prefs.remove('historial_$nombre');
    listaActivos.remove(nombre);
    await prefs.setStringList('lista_activos', listaActivos);
    
    if (config?.nombreActivo == nombre) {
      config = null;
      historial = [];
      pasoActual = 0;
    }
    notifyListeners();
  }

  Future<void> setConfig(RotorConfig newConfig) async {
    config = newConfig;
    numPlanos = newConfig.numPlanos;
    pasoActual = 1;
    reiniciarCalculos();
    
    // Actualizar lista de activos
    if (!listaActivos.contains(newConfig.nombreActivo)) {
      listaActivos.add(newConfig.nombreActivo);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('lista_activos', listaActivos);
    }
    
    await saveToDisk();
    notifyListeners();
  }

  Future<void> cargarActivo(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    final configStr = prefs.getString('config_$nombre');
    final historialStr = prefs.getString('historial_$nombre');

    if (configStr != null) {
      config = RotorConfig.fromJson(jsonDecode(configStr));
      numPlanos = config!.numPlanos;
      pasoActual = 1;
    } else {
      config = RotorConfig(nombreActivo: nombre);
      numPlanos = 1;
      pasoActual = 0;
    }

    if (historialStr != null) {
      final List<dynamic> decoded = jsonDecode(historialStr);
      historial = decoded.map((e) => HistorialItem.fromJson(e)).toList();
      pasoActual = 3;
    } else {
      historial = [];
    }
    
    notifyListeners();
  }

  Future<void> saveToDisk() async {
    if (config == null) return;
    final prefs = await SharedPreferences.getInstance();
    final nombre = config!.nombreActivo;
    
    await prefs.setString('config_$nombre', jsonEncode(config!.toJson()));
    
    if (historial.isNotEmpty) {
      await prefs.setString('historial_$nombre', jsonEncode(historial.map((e) => e.toJson()).toList()));
    } else {
      await prefs.remove('historial_$nombre');
    }
  }

  void reiniciarCalculos() {
    v0_1 = null;
    v0_2 = null;
    coeficiente1 = null;
    matrizCoeficientes = null;
    // El historial no se borra, se mantiene por activo
    saveToDisk();
  }

  void setMedicionInicial(Complejo s1, [Complejo? s2]) {
    v0_1 = s1;
    v0_2 = s2;
    pasoActual = 2;
    notifyListeners();
  }

  void calcularCoeficientes1Plano(Complejo pesoPrueba, Complejo v1) {
    if (v0_1 == null) return;
    Complejo deltaV = v1 - v0_1!;
    coeficiente1 = deltaV / pesoPrueba;
    pasoActual = 3;
    notifyListeners();
  }

  void calcularCoeficientes2Planos(
      Complejo mt1, Complejo mt2,
      Complejo v1_1, Complejo v1_2,
      Complejo v2_1, Complejo v2_2,
      ) {
    if (v0_1 == null || v0_2 == null) return;

    Complejo deltaV1_1 = v1_1 - v0_1!;
    Complejo deltaV1_2 = v1_2 - v0_2!;
    Complejo deltaV2_1 = v2_1 - v0_1!;
    Complejo deltaV2_2 = v2_2 - v0_2!;

    Complejo c11 = deltaV1_1 / mt1;
    Complejo c12 = deltaV2_1 / mt2;
    Complejo c21 = deltaV1_2 / mt1;
    Complejo c22 = deltaV2_2 / mt2;

    matrizCoeficientes = [[c11, c12], [c21, c22]];
    pasoActual = 3;
    notifyListeners();
  }

  Complejo? calcularCorreccion1Plano() {
    if (v0_1 == null || coeficiente1 == null) return null;
    return -v0_1! / coeficiente1!;
  }

  List<Complejo?> calcularCorreccion2Planos() {
    if (v0_1 == null || v0_2 == null || matrizCoeficientes == null) return [null, null];

    final C = matrizCoeficientes!;
    Complejo det = C[0][0] * C[1][1] - C[0][1] * C[1][0];

    Complejo inv00 = C[1][1] / det;
    Complejo inv01 = -C[0][1] / det;
    Complejo inv10 = -C[1][0] / det;
    Complejo inv11 = C[0][0] / det;

    Complejo b1 = -v0_1!;
    Complejo b2 = -v0_2!;

    Complejo m1 = inv00 * b1 + inv01 * b2;
    Complejo m2 = inv10 * b1 + inv11 * b2;

    return [m1, m2];
  }

  void agregarAlHistorial(Complejo? m1, Complejo? m2, double vibracionResidual1, [double vibracionResidual2 = 0]) {
    historial.add(HistorialItem(
      iteracion: historial.length + 1,
      masaPlano1: m1,
      masaPlano2: m2,
      vibracionResidual1: vibracionResidual1,
      vibracionResidual2: vibracionResidual2,
    ));
    saveToDisk();
    notifyListeners();
  }

  void nuevaIteracion(Complejo nuevoV0_1, [Complejo? nuevoV0_2]) {
    v0_1 = nuevoV0_1;
    v0_2 = nuevoV0_2;
    pasoActual = 3;
    saveToDisk();
    notifyListeners();
  }

  void recalcularCoeficientes() {
    pasoActual = 2;
    notifyListeners();
  }

  void resetToConfig() {
    pasoActual = 0;
    // No borramos historial al resetear flujo
    notifyListeners();
  }

  double ajustarAngulo(double angulo) {
    if (config?.sentido == SentidoGiro.horario) {
      return (-angulo) % 360;
    }
    return angulo % 360;
  }

  int? sugerirAlabe(double anguloMasa) {
    if (config?.tipo != TipoRotor.discreto || config!.numAlabes == 0) return null;
    double paso = 360 / config!.numAlabes;
    double anguloAjustado = ajustarAngulo(anguloMasa);
    int indice = (anguloAjustado / paso).round() % config!.numAlabes;
    if (indice == 0) indice = config!.numAlabes;
    return indice;
  }
}