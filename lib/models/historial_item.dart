import 'complejo.dart';

class HistorialItem {
  final int iteracion;
  final Complejo? masaPlano1;
  final Complejo? masaPlano2;
  final double vibracionResidual1;
  final double vibracionResidual2;

  HistorialItem({
    required this.iteracion,
    this.masaPlano1,
    this.masaPlano2,
    required this.vibracionResidual1,
    this.vibracionResidual2 = 0,
  });

  Map<String, dynamic> toJson() => {
    'iteracion': iteracion,
    'masaPlano1_real': masaPlano1?.real,
    'masaPlano1_imag': masaPlano1?.imaginario,
    'masaPlano2_real': masaPlano2?.real,
    'masaPlano2_imag': masaPlano2?.imaginario,
    'vibracionResidual1': vibracionResidual1,
    'vibracionResidual2': vibracionResidual2,
  };

  factory HistorialItem.fromJson(Map<String, dynamic> json) => HistorialItem(
    iteracion: json['iteracion'] as int,
    masaPlano1: json['masaPlano1_real'] != null ? Complejo(json['masaPlano1_real'] as double, json['masaPlano1_imag'] as double) : null,
    masaPlano2: json['masaPlano2_real'] != null ? Complejo(json['masaPlano2_real'] as double, json['masaPlano2_imag'] as double) : null,
    vibracionResidual1: json['vibracionResidual1'] as double,
    vibracionResidual2: json['vibracionResidual2'] as double,
  );
}