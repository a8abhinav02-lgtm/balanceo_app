import 'complejo.dart';

class HistorialItem {
  final int iteracion;
  final Complejo? masaPlano1;
  final Complejo? masaPlano2;
  final Complejo? masaRealPlano1;
  final Complejo? masaRealPlano2;
  final List<double> vibracionesResiduales;
  final List<Complejo>? vibracionesComplejasResiduales;

  double get vibracionResidual1 => vibracionesResiduales.isNotEmpty ? vibracionesResiduales[0] : 0.0;
  double get vibracionResidual2 => vibracionesResiduales.length > 1 ? vibracionesResiduales[1] : 0.0;

  Complejo? get realPlano1 => masaRealPlano1 ?? masaPlano1;
  Complejo? get realPlano2 => masaRealPlano2 ?? masaPlano2;

  HistorialItem({
    required this.iteracion,
    this.masaPlano1,
    this.masaPlano2,
    this.masaRealPlano1,
    this.masaRealPlano2,
    required this.vibracionesResiduales,
    this.vibracionesComplejasResiduales,
  });

  HistorialItem copyWith({
    int? iteracion,
    Complejo? masaPlano1,
    Complejo? masaPlano2,
    Complejo? masaRealPlano1,
    Complejo? masaRealPlano2,
    List<double>? vibracionesResiduales,
    List<Complejo>? vibracionesComplejasResiduales,
  }) {
    return HistorialItem(
      iteracion: iteracion ?? this.iteracion,
      masaPlano1: masaPlano1 ?? this.masaPlano1,
      masaPlano2: masaPlano2 ?? this.masaPlano2,
      masaRealPlano1: masaRealPlano1 ?? this.masaRealPlano1,
      masaRealPlano2: masaRealPlano2 ?? this.masaRealPlano2,
      vibracionesResiduales: vibracionesResiduales ?? this.vibracionesResiduales,
      vibracionesComplejasResiduales: vibracionesComplejasResiduales ?? this.vibracionesComplejasResiduales,
    );
  }

  Map<String, dynamic> toJson() => {
    'iteracion': iteracion,
    'masaPlano1_real': masaPlano1?.real,
    'masaPlano1_imag': masaPlano1?.imaginario,
    'masaPlano2_real': masaPlano2?.real,
    'masaPlano2_imag': masaPlano2?.imaginario,
    'masaRealPlano1_real': masaRealPlano1?.real,
    'masaRealPlano1_imag': masaRealPlano1?.imaginario,
    'masaRealPlano2_real': masaRealPlano2?.real,
    'masaRealPlano2_imag': masaRealPlano2?.imaginario,
    'vibracionesResiduales': vibracionesResiduales,
    'vibracionesComplejasResiduales': vibracionesComplejasResiduales?.map((e) => {'real': e.real, 'imag': e.imaginario}).toList(),
  };

  factory HistorialItem.fromJson(Map<String, dynamic> json) {
    List<double> residuales = [];
    if (json.containsKey('vibracionesResiduales')) {
      residuales = (json['vibracionesResiduales'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    } else {
      final v1 = (json['vibracionResidual1'] as num? ?? 0.0).toDouble();
      final v2 = (json['vibracionResidual2'] as num? ?? 0.0).toDouble();
      residuales = [v1, v2];
    }

    List<Complejo>? vComp;
    if (json['vibracionesComplejasResiduales'] != null) {
      vComp = (json['vibracionesComplejasResiduales'] as List)
          .map((e) => Complejo(e['real'] as double, e['imag'] as double))
          .toList();
    }

    return HistorialItem(
      iteracion: json['iteracion'] as int,
      masaPlano1: json['masaPlano1_real'] != null
          ? Complejo(json['masaPlano1_real'] as double, json['masaPlano1_imag'] as double)
          : null,
      masaPlano2: json['masaPlano2_real'] != null
          ? Complejo(json['masaPlano2_real'] as double, json['masaPlano2_imag'] as double)
          : null,
      masaRealPlano1: json['masaRealPlano1_real'] != null
          ? Complejo(json['masaRealPlano1_real'] as double, json['masaRealPlano1_imag'] as double)
          : null,
      masaRealPlano2: json['masaRealPlano2_real'] != null
          ? Complejo(json['masaRealPlano2_real'] as double, json['masaRealPlano2_imag'] as double)
          : null,
      vibracionesResiduales: residuales,
      vibracionesComplejasResiduales: vComp,
    );
  }
}