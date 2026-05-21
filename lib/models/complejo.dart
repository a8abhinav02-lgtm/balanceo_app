import 'dart:math';

class Complejo {
  final double real;
  final double imaginario;

  Complejo(this.real, this.imaginario);

  // Crear desde módulo y ángulo (en grados)
  factory Complejo.desdePolar(double modulo, double anguloGrados) {
    double anguloRad = anguloGrados * pi / 180;
    return Complejo(modulo * cos(anguloRad), modulo * sin(anguloRad));
  }

  Complejo operator +(Complejo other) => Complejo(real + other.real, imaginario + other.imaginario);
  Complejo operator -(Complejo other) => Complejo(real - other.real, imaginario - other.imaginario);
  Complejo operator *(Complejo other) => Complejo(
    real * other.real - imaginario * other.imaginario,
    real * other.imaginario + imaginario * other.real,
  );
  Complejo operator /(Complejo other) {
    double denominador = other.real * other.real + other.imaginario * other.imaginario;
    return Complejo(
      (real * other.real + imaginario * other.imaginario) / denominador,
      (imaginario * other.real - real * other.imaginario) / denominador,
    );
  }
  Complejo operator -() => Complejo(-real, -imaginario);

  double get modulo => sqrt(real * real + imaginario * imaginario);
  double get anguloGrados => (atan2(imaginario, real) * 180 / pi) % 360;
  Complejo get conjugado => Complejo(real, -imaginario);

  @override
  String toString() => "mod: ${modulo.toStringAsFixed(2)} @ ${anguloGrados.toStringAsFixed(1)}°";
}