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
    final config = provider.config;
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Leyenda con Wrap mejorado para evitar desbordamientos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: List.generate(etiquetas.length, (index) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10, 
                      height: 10, 
                      decoration: BoxDecoration(
                        color: colores[index],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      etiquetas[index], 
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }),
            ),
          ),
          // Gráfico Polar
          AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _PolarPainter(
                vectores: vectores,
                colores: colores,
                etiquetas: etiquetas,
                maxRadio: maxRadio,
                config: config,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolarPainter extends CustomPainter {
  final List<Complejo> vectores;
  final List<Color> colores;
  final List<String> etiquetas;
  final double maxRadio;
  final RotorConfig? config;

  _PolarPainter({
    required this.vectores,
    required this.colores,
    required this.etiquetas,
    required this.maxRadio,
    this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Offset centro = Offset(centerX, centerY);
    // Ajuste de escala dinámico basado en el tamaño real del widget
    final double escala = (size.width * 0.65) / (2 * maxRadio);

    final bool sentidoHorario = config?.sentido == SentidoGiro.horario;

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int r = 1; r <= 4; r++) {
      double radio = (maxRadio * r / 4) * escala;
      canvas.drawCircle(centro, radio, gridPaint);
    }

    for (int i = 0; i < 12; i++) {
      double angulo = i * 30 * pi / 180;
      double x = centerX + maxRadio * escala * cos(angulo);
      double y = centerY + maxRadio * escala * sin(angulo);
      canvas.drawLine(centro, Offset(x, y), gridPaint);
    }

    // Flecha de Rotación (GIRO)
    final Paint rotPaint = Paint()
      ..color = Colors.orange.shade800
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double arcRadio = maxRadio * 1.35 * escala;
    double startAngle = -pi / 2 - 0.7; 
    double sweepAngle = 1.4; 
    
    if (!sentidoHorario) {
      startAngle = -pi / 2 + 0.7;
      sweepAngle = -1.4;
    }

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: arcRadio),
      startAngle,
      sweepAngle,
      false,
      rotPaint,
    );

    double puntaAnguloPos = startAngle + sweepAngle;
    Offset puntaPos = Offset(centerX + arcRadio * cos(puntaAnguloPos), centerY + arcRadio * sin(puntaAnguloPos));
    double tangenteAng = puntaAnguloPos + (sentidoHorario ? pi / 2 : -pi / 2);
    double ala1 = tangenteAng + 160 * pi / 180;
    double ala2 = tangenteAng - 160 * pi / 180;
    double lF = 12.0;

    final Path headPath = Path()
      ..moveTo(puntaPos.dx + lF * cos(ala1), puntaPos.dy + lF * sin(ala1))
      ..lineTo(puntaPos.dx, puntaPos.dy)
      ..lineTo(puntaPos.dx + lF * cos(ala2), puntaPos.dy + lF * sin(ala2));
    
    canvas.drawPath(headPath, rotPaint);
    _drawLabel(canvas, Offset(centerX - 15, centerY - arcRadio - 15), 'GIRO', Colors.orange.shade900, fontSize: 9, bold: true);

    // Keyphasor
    final Paint kpPaint = Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke;
    double kpAngRad = (config?.keyphasorAngulo ?? 0) * pi / 180;
    if (sentidoHorario) kpAngRad = -kpAngRad;
    double kpx = centerX + maxRadio * 1.1 * escala * cos(kpAngRad);
    double kpy = centerY + maxRadio * 1.1 * escala * sin(kpAngRad);
    canvas.drawLine(centro, Offset(kpx, kpy), kpPaint);
    _drawLabel(canvas, Offset(kpx, kpy - 12), 'KP', Colors.black, fontSize: 8, bold: true);

    // Sensores
    final Paint sensorPaint = Paint()..color = Colors.black87..strokeWidth = 1.5..style = PaintingStyle.stroke;
    double xAngRad = (config?.sensorXAngulo ?? 0) * pi / 180;
    if (sentidoHorario) xAngRad = -xAngRad;
    double sx = centerX + maxRadio * 1.2 * escala * cos(xAngRad);
    double sy = centerY + maxRadio * 1.2 * escala * sin(xAngRad);
    canvas.drawCircle(Offset(sx, sy), 7, sensorPaint);
    _drawLabel(canvas, Offset(sx - 2, sy - 4), 'X', Colors.black, fontSize: 8, bold: true);

    double yAngRad = (config?.sensorYAngulo ?? 90) * pi / 180;
    if (sentidoHorario) yAngRad = -yAngRad;
    double syx = centerX + maxRadio * 1.2 * escala * cos(yAngRad);
    double syy = centerY + maxRadio * 1.2 * escala * sin(yAngRad);
    canvas.drawRect(Rect.fromCenter(center: Offset(syx, syy), width: 12, height: 12), sensorPaint);
    _drawLabel(canvas, Offset(syx - 2, syy - 4), 'Y', Colors.black, fontSize: 8, bold: true);

    // Álabes
    if (config?.tipo == TipoRotor.discreto && config!.numAlabes > 0) {
      final int n = config!.numAlabes;
      final double paso = 360 / n;
      final double refAngulo = config!.anguloReferenciaAlabe1;
      final bool numHoraria = config!.numeracionHoraria;
      for (int i = 1; i <= n; i++) {
        double anguloAlabe = refAngulo + (numHoraria ? -(i - 1) * paso : (i - 1) * paso);
        double angRad = anguloAlabe * pi / 180;
        if (sentidoHorario) angRad = -angRad;
        double ax = centerX + maxRadio * 1.05 * escala * cos(angRad);
        double ay = centerY + maxRadio * 1.05 * escala * sin(angRad);
        canvas.drawCircle(Offset(ax, ay), 6, Paint()..color = Colors.blue.withAlpha(20));
        canvas.drawCircle(Offset(ax, ay), 6, Paint()..color = Colors.blue.shade700..style = PaintingStyle.stroke..strokeWidth = 0.5);
        _drawLabel(canvas, Offset(ax - 2.5, ay - 4), i.toString(), Colors.blue.shade900, fontSize: 7);
      }
    }

    // Vectores
    for (int i = 0; i < vectores.length; i++) {
      final v = vectores[i];
      double angRad = v.anguloGrados * pi / 180;
      if (sentidoHorario) angRad = -angRad;
      final double modEsc = v.modulo * escala;
      final x = centerX + modEsc * cos(angRad);
      final y = centerY + modEsc * sin(angRad);
      final punta = Offset(x, y);

      final vPaint = Paint()..color = colores[i]..strokeWidth = 2.0..style = PaintingStyle.stroke;
      canvas.drawLine(centro, punta, vPaint);

      double pAng = atan2(y - centerY, x - centerX);
      double f1 = pAng + 150 * pi / 180;
      double f2 = pAng - 150 * pi / 180;
      double lF = min(10, modEsc / 3);
      canvas.drawLine(punta, Offset(punta.dx + lF * cos(f1), punta.dy + lF * sin(f1)), vPaint);
      canvas.drawLine(punta, Offset(punta.dx + lF * cos(f2), punta.dy + lF * sin(f2)), vPaint);
      String shortLabel = etiquetas[i].contains('Masa') ? 'M${etiquetas[i].contains('P2') ? '2' : '1'}' : 'V${etiquetas[i].contains('Y') ? '2' : '1'}';
      _drawLabel(canvas, Offset(punta.dx + 4, punta.dy - 12), shortLabel, colores[i], fontSize: 8, bold: true);
    }
  }

  void _drawLabel(Canvas canvas, Offset offset, String text, Color color, {double fontSize = 11, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}