import 'dart:math';
import 'package:flutter/material.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';
import 'package:provider/provider.dart';
import '../models/rotor_config.dart';

class PolarPlot extends StatelessWidget {
  final List<Complejo> vectores;
  final List<Color> colores;
  final List<String> etiquetas;
  final double maxRadio;

  const PolarPlot({
    super.key,
    required this.vectores,
    required this.colores,
    required this.etiquetas,
    this.maxRadio = 100,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context, listen: false);
    return SizedBox(
      height: 300,
      width: 300,
      child: CustomPaint(
        painter: _PolarPainter(
          vectores: vectores,
          colores: colores,
          etiquetas: etiquetas,
          maxRadio: maxRadio,
          sentidoHorario: provider.config?.sentido == SentidoGiro.horario,
        ),
      ),
    );
  }
}

class _PolarPainter extends CustomPainter {
  final List<Complejo> vectores;
  final List<Color> colores;
  final List<String> etiquetas;
  final double maxRadio;
  final bool sentidoHorario;

  _PolarPainter({
    required this.vectores,
    required this.colores,
    required this.etiquetas,
    required this.maxRadio,
    required this.sentidoHorario,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Offset centro = Offset(centerX, centerY);
    final double escala = size.width / (2 * maxRadio);

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Círculos concéntricos
    for (int r = 1; r <= 4; r++) {
      double radio = (maxRadio * r / 4) * escala;
      canvas.drawCircle(centro, radio, gridPaint);
    }

    // Líneas radiales cada 30 grados
    for (int i = 0; i < 12; i++) {
      double angulo = i * 30 * pi / 180;
      if (sentidoHorario) angulo = -angulo;
      double x = centerX + maxRadio * escala * cos(angulo);
      double y = centerY + maxRadio * escala * sin(angulo);
      canvas.drawLine(centro, Offset(x, y), gridPaint);
    }

    // Dibujar vectores
    for (int i = 0; i < vectores.length; i++) {
      final Complejo v = vectores[i];
      double anguloRad = v.anguloGrados * pi / 180;
      if (sentidoHorario) anguloRad = -anguloRad;
      final double moduloEscalado = v.modulo * escala;
      final double x = centerX + moduloEscalado * cos(anguloRad);
      final double y = centerY + moduloEscalado * sin(anguloRad);
      final Offset punta = Offset(x, y);

      final Paint vectorPaint = Paint()
        ..color = colores[i]
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(centro, punta, vectorPaint);

      // Flecha
      double puntaAngulo = atan2(y - centerY, x - centerX);
      double flecha1 = puntaAngulo + 150 * pi / 180;
      double flecha2 = puntaAngulo - 150 * pi / 180;
      double longFlecha = min(12, moduloEscalado / 3);
      Offset p1 = Offset(
        punta.dx - longFlecha * cos(flecha1),
        punta.dy - longFlecha * sin(flecha1),
      );
      Offset p2 = Offset(
        punta.dx - longFlecha * cos(flecha2),
        punta.dy - longFlecha * sin(flecha2),
      );
      canvas.drawLine(punta, p1, vectorPaint);
      canvas.drawLine(punta, p2, vectorPaint);

      // Etiqueta
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: etiquetas[i],
          style: TextStyle(color: colores[i], fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(punta.dx + 5, punta.dy - 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}