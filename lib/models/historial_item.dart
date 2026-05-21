import 'complejo.dart';

class HistorialItem {
  final int iteracion;
  final Complejo? masaPlano1;
  final Complejo? masaPlano2;
  final List<double> vibracionesResiduales;

  double get vibracionResidual1 => vibracionesResiduales.isNotEmpty ? vibracionesResiduales[0] : 0.0;
  double get vibracionResidual2 => vibracionesResiduales.length > 1 ? vibracionesResiduales[1] : 0.0;

  HistorialItem({
    required this.iteracion,
    this.masaPlano1,
    this.masaPlano2,
    required this.vibracionesResiduales,
  });

  HistorialItem copyWith({
    int? iteracion,
    Complejo? masaPlano1,
    Complejo? masaPlano2,
    List<double>? vibracionesResiduales,
  }) {
    return HistorialItem(
      iteracion: iteracion ?? this.iteracion,
      masaPlano1: masaPlano1 ?? this.masaPlano1,
      masaPlano2: masaPlano2 ?? this.masaPlano2,
      vibracionesResiduales: vibracionesResiduales ?? this.vibracionesResiduales,
    );
  }

  Map<String, dynamic> toJson() => {
    'iteracion': iteracion,
    'masaPlano1_real': masaPlano1?.real,
    'masaPlano1_imag': masaPlano1?.imaginario,
    'masaPlano2_real': masaPlano2?.real,
    'masaPlano2_imag': masaPlano2?.imaginario,
    'vibracionesResiduales': vibracionesResiduales,
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

    return HistorialItem(
      iteracion: json['iteracion'] as int,
      masaPlano1: json['masaPlano1_real'] != null
          ? Complejo(json['masaPlano1_real'] as double, json['masaPlano1_imag'] as double)
          : null,
      masaPlano2: json['masaPlano2_real'] != null
          ? Complejo(json['masaPlano2_real'] as double, json['masaPlano2_imag'] as double)
          : null,
      vibracionesResiduales: residuales,
    );
  }
}