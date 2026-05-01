import '../models/complejo.dart';

class BalanceoLogic {
  // Caso 1 plano
  static Complejo balanceo1Plano(Complejo v0, Complejo pesoPrueba, Complejo v1) {
    Complejo deltaV = v1 - v0;
    Complejo coeficiente = deltaV / pesoPrueba;
    Complejo masaCorrectora = -v0 / coeficiente;
    return masaCorrectora;
  }

  // Caso 2 planos - retorna [m1, m2]
  static List<Complejo> balanceo2Planos(
      Complejo v0_1, Complejo v0_2,
      Complejo mt1, Complejo mt2,
      Complejo v1_1, Complejo v1_2,
      Complejo v2_1, Complejo v2_2,
      ) {
    // Cambios de vibración
    Complejo deltaV1_1 = v1_1 - v0_1;
    Complejo deltaV1_2 = v1_2 - v0_2;
    Complejo deltaV2_1 = v2_1 - v0_1;
    Complejo deltaV2_2 = v2_2 - v0_2;

    // Coeficientes de influencia
    Complejo c11 = deltaV1_1 / mt1;
    Complejo c12 = deltaV2_1 / mt2;
    Complejo c21 = deltaV1_2 / mt1;
    Complejo c22 = deltaV2_2 / mt2;

    // Sistema: A * [m1; m2] = -[v0_1; v0_2]
    // Determinante de la matriz 2x2 de complejos
    Complejo det = c11 * c22 - c12 * c21;

    // Inversa de A
    Complejo invC11 = c22 / det;
    Complejo invC12 = -c12 / det;
    Complejo invC21 = -c21 / det;
    Complejo invC22 = c11 / det;

    Complejo b1 = -v0_1;
    Complejo b2 = -v0_2;

    Complejo m1 = invC11 * b1 + invC12 * b2;
    Complejo m2 = invC21 * b1 + invC22 * b2;

    return [m1, m2];
  }
}