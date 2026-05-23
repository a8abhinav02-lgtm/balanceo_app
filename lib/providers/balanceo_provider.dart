import 'package:flutter/material.dart';
import '../models/complejo.dart';
import '../models/rotor_config.dart';
import '../models/historial_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BalanceoProvider extends ChangeNotifier {
  RotorConfig? config;
  
  // Listas de lecturas para M canales
  List<Complejo>? v0;
  List<Complejo>? v0Original;
  List<Complejo>? v1Temp;
  List<Complejo>? v2Temp;
  Complejo? mt1Temp;
  Complejo? mt2Temp;
  List<List<Complejo>>? matrizCoeficientes;
  List<Complejo>? vVerificacion;
  Complejo? masaRealInstalada1;
  Complejo? masaRealInstalada2;

  // Propiedades de compatibilidad retroactiva
  Complejo? get v0_1 => (v0 != null && v0!.isNotEmpty) ? v0![0] : null;
  set v0_1(Complejo? val) {
    if (v0 == null) {
      if (val != null) v0 = [val];
    } else {
      if (val != null) {
        if (v0!.isNotEmpty) {
          v0![0] = val;
        } else {
          v0!.add(val);
        }
      }
    }
  }

  Complejo? get v0_2 => (v0 != null && v0!.length > 1) ? v0![1] : null;
  set v0_2(Complejo? val) {
    if (v0 != null && v0!.length > 1 && val != null) {
      v0![1] = val;
    }
  }

  Complejo? get v0_1_original => (v0Original != null && v0Original!.isNotEmpty) ? v0Original![0] : null;
  Complejo? get v0_2_original => (v0Original != null && v0Original!.length > 1) ? v0Original![1] : null;

  Complejo? get mt1_temp => mt1Temp;
  set mt1_temp(Complejo? val) => mt1Temp = val;

  Complejo? get mt2_temp => mt2Temp;
  set mt2_temp(Complejo? val) => mt2Temp = val;

  Complejo? get v1_1_temp => (v1Temp != null && v1Temp!.isNotEmpty) ? v1Temp![0] : null;
  set v1_1_temp(Complejo? val) {
    if (v1Temp == null) {
      if (val != null) v1Temp = [val];
    } else {
      if (val != null) {
        if (v1Temp!.isNotEmpty) {
          v1Temp![0] = val;
        } else {
          v1Temp!.add(val);
        }
      }
    }
  }

  Complejo? get v1_2_temp => (v1Temp != null && v1Temp!.length > 1) ? v1Temp![1] : null;
  set v1_2_temp(Complejo? val) {
    if (v1Temp != null && v1Temp!.length > 1 && val != null) {
      v1Temp![1] = val;
    }
  }

  Complejo? get v2_1_temp => (v2Temp != null && v2Temp!.isNotEmpty) ? v2Temp![0] : null;
  set v2_1_temp(Complejo? val) {
    if (v2Temp == null) {
      if (val != null) v2Temp = [val];
    } else {
      if (val != null) {
        if (v2Temp!.isNotEmpty) {
          v2Temp![0] = val;
        } else {
          v2Temp!.add(val);
        }
      }
    }
  }

  Complejo? get v2_2_temp => (v2Temp != null && v2Temp!.length > 1) ? v2Temp![1] : null;
  set v2_2_temp(Complejo? val) {
    if (v2Temp != null && v2Temp!.length > 1 && val != null) {
      v2Temp![1] = val;
    }
  }

  Complejo? get coeficiente1 => (matrizCoeficientes != null &&
          matrizCoeficientes!.isNotEmpty &&
          matrizCoeficientes![0].isNotEmpty)
      ? matrizCoeficientes![0][0]
      : null;

  bool usarSensorX = true;

  /// Número de iteración actual: 1 = primera corrida, 2+ = refinamientos.
  int iteracion = 1;

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

  bool get tieneCoeficientes => matrizCoeficientes != null && matrizCoeficientes!.isNotEmpty;

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
    await prefs.remove('state_$nombre');
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

    final stateStr = prefs.getString('state_$nombre');
    if (stateStr != null) {
      try {
        final state = jsonDecode(stateStr);
        v0 = (state['v0'] as List?)?.map((e) => Complejo(e['real'] as double, e['imag'] as double)).toList();
        v0Original = (state['v0Original'] as List?)?.map((e) => Complejo(e['real'] as double, e['imag'] as double)).toList();
        v1Temp = (state['v1Temp'] as List?)?.map((e) => Complejo(e['real'] as double, e['imag'] as double)).toList();
        v2Temp = (state['v2Temp'] as List?)?.map((e) => Complejo(e['real'] as double, e['imag'] as double)).toList();
        mt1Temp = state['mt1Temp'] != null ? Complejo(state['mt1Temp']['real'] as double, state['mt1Temp']['imag'] as double) : null;
        mt2Temp = state['mt2Temp'] != null ? Complejo(state['mt2Temp']['real'] as double, state['mt2Temp']['imag'] as double) : null;
        matrizCoeficientes = (state['matrizCoeficientes'] as List?)?.map((row) => (row as List).map((e) => Complejo(e['real'] as double, e['imag'] as double)).toList()).toList();
        iteracion = state['iteracion'] as int? ?? 1;
        pasoActual = state['pasoActual'] as int? ?? 1;
        vVerificacion = (state['vVerificacion'] as List?)?.map((e) => Complejo(e['real'] as double, e['imag'] as double)).toList();
        masaRealInstalada1 = state['masaRealInstalada1'] != null ? Complejo(state['masaRealInstalada1']['real'] as double, state['masaRealInstalada1']['imag'] as double) : null;
        masaRealInstalada2 = state['masaRealInstalada2'] != null ? Complejo(state['masaRealInstalada2']['real'] as double, state['masaRealInstalada2']['imag'] as double) : null;
      } catch (e) {
        // Fallback robusto
      }
    } else {
      v0 = null;
      v0Original = null;
      v1Temp = null;
      v2Temp = null;
      mt1Temp = null;
      mt2Temp = null;
      matrizCoeficientes = null;
      iteracion = 1;
      vVerificacion = null;
      masaRealInstalada1 = null;
      masaRealInstalada2 = null;
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

    final state = {
      'v0': v0?.map((e) => {'real': e.real, 'imag': e.imaginario}).toList(),
      'v0Original': v0Original?.map((e) => {'real': e.real, 'imag': e.imaginario}).toList(),
      'v1Temp': v1Temp?.map((e) => {'real': e.real, 'imag': e.imaginario}).toList(),
      'v2Temp': v2Temp?.map((e) => {'real': e.real, 'imag': e.imaginario}).toList(),
      'mt1Temp': mt1Temp != null ? {'real': mt1Temp!.real, 'imag': mt1Temp!.imaginario} : null,
      'mt2Temp': mt2Temp != null ? {'real': mt2Temp!.real, 'imag': mt2Temp!.imaginario} : null,
      'matrizCoeficientes': matrizCoeficientes?.map((row) => row.map((e) => {'real': e.real, 'imag': e.imaginario}).toList()).toList(),
      'iteracion': iteracion,
      'pasoActual': pasoActual,
      'vVerificacion': vVerificacion?.map((e) => {'real': e.real, 'imag': e.imaginario}).toList(),
      'masaRealInstalada1': masaRealInstalada1 != null ? {'real': masaRealInstalada1!.real, 'imag': masaRealInstalada1!.imaginario} : null,
      'masaRealInstalada2': masaRealInstalada2 != null ? {'real': masaRealInstalada2!.real, 'imag': masaRealInstalada2!.imaginario} : null,
    };
    await prefs.setString('state_$nombre', jsonEncode(state));
  }

  void reiniciarCalculos() {
    v0 = null;
    v0Original = null;
    v1Temp = null;
    v2Temp = null;
    mt1Temp = null;
    mt2Temp = null;
    matrizCoeficientes = null;
    iteracion = 1;
    vVerificacion = null;
    masaRealInstalada1 = null;
    masaRealInstalada2 = null;
    // El historial no se borra, se mantiene por activo
    saveToDisk();
  }

  /// Guarda la medición inicial de M canales.
  /// También fija los vectores originales de referencia.
  void setMedicionInicial(List<Complejo> lecturas) {
    v0 = lecturas;
    v0Original = List.from(lecturas);
    iteracion = 1;
    pasoActual = 2;
    saveToDisk();
    notifyListeners();
  }

  /// Calcula el coeficiente de influencia en modo 1 plano de corrección con M canales.
  void calcularCoeficientes1Plano(Complejo pesoPrueba, List<Complejo> v1) {
    if (v0 == null || config == null) return;

    mt1Temp = pesoPrueba;
    v1Temp = v1;

    // Calcular matriz de coeficientes de influencia (M x 1)
    List<List<Complejo>> coefs = [];
    for (int i = 0; i < v0!.length; i++) {
      Complejo alpha = (v1[i] - v0![i]) / pesoPrueba;
      coefs.add([alpha]);
    }
    matrizCoeficientes = coefs;

    pasoActual = 3;
    saveToDisk();
    notifyListeners();
  }

  /// Calcula los coeficientes de influencia en modo 2 planos con M canales.
  void calcularCoeficientes2Planos(
      Complejo mt1, Complejo mt2,
      List<Complejo> v1, List<Complejo> v2,
  ) {
    if (v0 == null || config == null) return;

    mt1Temp = mt1;
    v1Temp = v1;
    mt2Temp = mt2;
    v2Temp = v2;

    // Calcular matriz de coeficientes de influencia (M x 2)
    List<List<Complejo>> coefs = [];
    for (int i = 0; i < v0!.length; i++) {
      Complejo c1 = (v1[i] - v0![i]) / mt1;
      Complejo c2 = (v2[i] - v0![i]) / mt2;
      coefs.add([c1, c2]);
    }
    matrizCoeficientes = coefs;

    pasoActual = 3;
    saveToDisk();
    notifyListeners();
  }

  /// Calcula la masa de corrección para 1 plano usando Mínimos Cuadrados Ponderados.
  Complejo? calcularCorreccion1Plano() {
    if (matrizCoeficientes == null || v0 == null || config == null) return null;

    Complejo numerador = Complejo(0, 0);
    double denominador = 0.0;

    for (int i = 0; i < v0!.length; i++) {
      double w = (i < config!.canales.length) ? config!.canales[i].peso : 1.0;
      Complejo alpha = matrizCoeficientes![i][0];
      Complejo alphaConj = alpha.conjugado;
      Complejo v0Val = v0![i];

      Complejo term = alphaConj * v0Val;
      numerador = numerador + Complejo(term.real * w, term.imaginario * w);
      denominador += w * (alpha.real * alpha.real + alpha.imaginario * alpha.imaginario);
    }

    if (denominador == 0) return null;
    return -numerador / Complejo(denominador, 0);
  }

  /// Calcula las masas de corrección en 2 planos usando Mínimos Cuadrados Ponderados (2x2).
  List<Complejo?> calcularCorreccion2Planos() {
    if (v0 == null || matrizCoeficientes == null || config == null) return [null, null];

    double a11 = 0;
    Complejo a12 = Complejo(0, 0);
    double a22 = 0;

    Complejo b1 = Complejo(0, 0);
    Complejo b2 = Complejo(0, 0);

    for (int i = 0; i < v0!.length; i++) {
      double w = (i < config!.canales.length) ? config!.canales[i].peso : 1.0;
      Complejo c1 = matrizCoeficientes![i][0];
      Complejo c2 = matrizCoeficientes![i][1];
      Complejo v0Val = v0![i];

      Complejo c1Conj = c1.conjugado;
      Complejo c2Conj = c2.conjugado;

      a11 += w * (c1.real * c1.real + c1.imaginario * c1.imaginario);
      
      Complejo a12Term = c1Conj * c2;
      a12 = a12 + Complejo(a12Term.real * w, a12Term.imaginario * w);

      a22 += w * (c2.real * c2.real + c2.imaginario * c2.imaginario);

      Complejo b1Term = c1Conj * v0Val;
      b1 = b1 - Complejo(b1Term.real * w, b1Term.imaginario * w);

      Complejo b2Term = c2Conj * v0Val;
      b2 = b2 - Complejo(b2Term.real * w, b2Term.imaginario * w);
    }

    Complejo a21 = a12.conjugado;

    // D = a11 * a22 - |a12|^2
    double a12MagSq = a12.real * a12.real + a12.imaginario * a12.imaginario;
    double d = a11 * a22 - a12MagSq;

    if (d.abs() < 1e-11) {
      return [null, null];
    }

    Complejo dComp = Complejo(d, 0);

    Complejo m1 = (Complejo(a22, 0) * b1 - a12 * b2) / dComp;
    Complejo m2 = (Complejo(a11, 0) * b2 - a21 * b1) / dComp;

    return [m1, m2];
  }

  Complejo calcularMasaRealAcumuladaPlano1() {
    Complejo total = Complejo(0, 0);
    for (var item in historial) {
      if (item.realPlano1 != null) {
        total = total + item.realPlano1!;
      }
    }
    return total;
  }

  Complejo calcularMasaRealAcumuladaPlano2() {
    Complejo total = Complejo(0, 0);
    for (var item in historial) {
      if (item.realPlano2 != null) {
        total = total + item.realPlano2!;
      }
    }
    return total;
  }

  void refinarCoeficientes() {
    if (v0Original == null || config == null) return;
    final numCanales = v0Original!.length;

    if (numPlanos == 1) {
      if (mt1Temp == null || v1Temp == null) return;

      List<Complejo> xPoints = [mt1Temp!];
      List<List<Complejo>> yPoints = List.generate(numCanales, (i) => [v1Temp![i] - v0Original![i]]);

      Complejo mAcumulada = Complejo(0, 0);
      for (var item in historial) {
        if (item.realPlano1 != null) {
          mAcumulada = mAcumulada + item.realPlano1!;
        }
        if (item.vibracionesComplejasResiduales != null && item.vibracionesComplejasResiduales!.length == numCanales) {
          xPoints.add(mAcumulada);
          for (int i = 0; i < numCanales; i++) {
            yPoints[i].add(item.vibracionesComplejasResiduales![i] - v0Original![i]);
          }
        }
      }

      List<List<Complejo>> nuevosCoefs = [];
      for (int i = 0; i < numCanales; i++) {
        Complejo num = Complejo(0, 0);
        double den = 0.0;
        for (int p = 0; p < xPoints.length; p++) {
          Complejo x = xPoints[p];
          Complejo y = yPoints[i][p];
          Complejo term = x.conjugado * y;
          num = num + term;
          den += x.real * x.real + x.imaginario * x.imaginario;
        }
        if (den.abs() > 1e-11) {
          nuevosCoefs.add([num / Complejo(den, 0)]);
        } else {
          nuevosCoefs.add([matrizCoeficientes != null ? matrizCoeficientes![i][0] : Complejo(0, 0)]);
        }
      }
      matrizCoeficientes = nuevosCoefs;
    } else if (numPlanos == 2) {
      if (mt1Temp == null || mt2Temp == null || v1Temp == null || v2Temp == null) return;

      List<List<Complejo>> xPoints = [
        [mt1Temp!, Complejo(0, 0)],
        [Complejo(0, 0), mt2Temp!]
      ];
      List<List<Complejo>> yPoints = List.generate(numCanales, (i) => [
        v1Temp![i] - v0Original![i],
        v2Temp![i] - v0Original![i]
      ]);

      Complejo mAcumulada1 = Complejo(0, 0);
      Complejo mAcumulada2 = Complejo(0, 0);
      for (var item in historial) {
        if (item.realPlano1 != null) {
          mAcumulada1 = mAcumulada1 + item.realPlano1!;
        }
        if (item.realPlano2 != null) {
          mAcumulada2 = mAcumulada2 + item.realPlano2!;
        }
        if (item.vibracionesComplejasResiduales != null && item.vibracionesComplejasResiduales!.length == numCanales) {
          xPoints.add([mAcumulada1, mAcumulada2]);
          for (int i = 0; i < numCanales; i++) {
            yPoints[i].add(item.vibracionesComplejasResiduales![i] - v0Original![i]);
          }
        }
      }

      double a11 = 0;
      Complejo a12 = Complejo(0, 0);
      double a22 = 0;

      for (int p = 0; p < xPoints.length; p++) {
        Complejo x1 = xPoints[p][0];
        Complejo x2 = xPoints[p][1];

        a11 += x1.real * x1.real + x1.imaginario * x1.imaginario;
        a12 = a12 + (x1.conjugado * x2);
        a22 += x2.real * x2.real + x2.imaginario * x2.imaginario;
      }

      Complejo a21 = a12.conjugado;
      double a12MagSq = a12.real * a12.real + a12.imaginario * a12.imaginario;
      double det = a11 * a22 - a12MagSq;

      if (det.abs() > 1e-11) {
        List<List<Complejo>> nuevosCoefs = [];
        for (int i = 0; i < numCanales; i++) {
          Complejo b1 = Complejo(0, 0);
          Complejo b2 = Complejo(0, 0);
          for (int p = 0; p < xPoints.length; p++) {
            Complejo x1 = xPoints[p][0];
            Complejo x2 = xPoints[p][1];
            Complejo y = yPoints[i][p];

            b1 = b1 + (x1.conjugado * y);
            b2 = b2 + (x2.conjugado * y);
          }

          Complejo c1 = (Complejo(a22, 0) * b1 - a12 * b2) / Complejo(det, 0);
          Complejo c2 = (Complejo(a11, 0) * b2 - a21 * b1) / Complejo(det, 0);
          nuevosCoefs.add([c1, c2]);
        }
        matrizCoeficientes = nuevosCoefs;
      }
    }
  }

  void agregarAlHistorial(
    Complejo? m1, Complejo? m2,
    List<double> residuales, {
    Complejo? mReal1, Complejo? mReal2,
    List<Complejo>? vibracionesComplejas,
  }) {
    final index = historial.indexWhere((element) => element.iteracion == iteracion);
    final item = HistorialItem(
      iteracion: iteracion,
      masaPlano1: m1,
      masaPlano2: m2,
      masaRealPlano1: mReal1,
      masaRealPlano2: mReal2,
      vibracionesResiduales: residuales,
      vibracionesComplejasResiduales: vibracionesComplejas,
    );

    if (index != -1) {
      historial[index] = item;
    } else {
      historial.add(item);
    }
    saveToDisk();
    notifyListeners();
  }

  /// Registra una nueva medición residual tras instalar las masas correctoras.
  void nuevaIteracion(List<Complejo> nuevasLecturas) {
    bool yaGuardado = historial.any((element) => element.iteracion == iteracion);
    if (!yaGuardado) {
      Complejo? m1;
      Complejo? m2;
      if (numPlanos == 1) {
        m1 = calcularCorreccion1Plano();
      } else {
        final corrections = calcularCorreccion2Planos();
        m1 = corrections[0];
        m2 = corrections[1];
      }
      
      agregarAlHistorial(
        m1, m2,
        nuevasLecturas.map((e) => e.modulo).toList(),
        mReal1: masaRealInstalada1 ?? m1,
        mReal2: masaRealInstalada2 ?? m2,
        vibracionesComplejas: nuevasLecturas,
      );
    } else {
      final idx = historial.indexWhere((element) => element.iteracion == iteracion);
      if (idx != -1) {
        historial[idx] = historial[idx].copyWith(
          vibracionesResiduales: nuevasLecturas.map((e) => e.modulo).toList(),
          vibracionesComplejasResiduales: nuevasLecturas,
        );
      }
    }

    refinarCoeficientes();

    v0 = nuevasLecturas;
    iteracion++;
    pasoActual = 3;
    vVerificacion = null;
    
    masaRealInstalada1 = null;
    masaRealInstalada2 = null;

    saveToDisk();
    notifyListeners();
  }

  /// Registra la vibración de verificación final tras instalar las masas correctoras.
  void registrarVerificacion(List<Complejo> lecturas) {
    vVerificacion = lecturas;
    saveToDisk();
    notifyListeners();
  }

  /// Elimina una iteración específica del historial por su índice.
  /// Reordena las iteraciones restantes para mantener la secuencia y actualiza la iteración activa.
  void eliminarIteracion(int index) {
    if (index < 0 || index >= historial.length) return;
    historial.removeAt(index);
    // Renumerar secuencialmente
    for (int i = 0; i < historial.length; i++) {
      historial[i] = historial[i].copyWith(iteracion: i + 1);
    }
    // Sincronizar la iteración activa
    iteracion = historial.length + 1;
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
    double ref = config!.anguloReferenciaAlabe1;
    bool numHoraria = config!.numeracionHoraria;
    bool sentidoHorario = config!.sentido == SentidoGiro.horario;
    
    // Convertimos la fase de la masa (relativa al KP) a un ángulo absoluto cartesiano
    double angMasaAbsoluto = config!.keyphasorAngulo + (sentidoHorario ? anguloMasa : -anguloMasa);
    
    int alabeCercano = 1;
    double minimaDiferencia = double.infinity;
    
    for (int i = 1; i <= config!.numAlabes; i++) {
      // Ángulo absoluto de este álabe
      double anguloAlabeAbsoluto = ref + (numHoraria ? -(i - 1) * paso : (i - 1) * paso);
      
      double angMasaNorm = angMasaAbsoluto % 360;
      if (angMasaNorm < 0) angMasaNorm += 360;
      
      double angAlabeNorm = anguloAlabeAbsoluto % 360;
      if (angAlabeNorm < 0) angAlabeNorm += 360;
      
      double diff = (angMasaNorm - angAlabeNorm).abs();
      if (diff > 180) diff = 360 - diff;
      
      if (diff < minimaDiferencia) {
        minimaDiferencia = diff;
        alabeCercano = i;
      }
    }
    return alabeCercano;
  }

}