import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';
import 'package:provider/provider.dart';
import '../models/rotor_config.dart';

/// Renders a polar plot to raw PNG bytes without needing a widget in the tree.
/// Used by PdfExport to embed charts in the report.
Future<Uint8List> renderPolarToBytes({
  required List<Complejo> vectores,
  required List<Color> colores,
  required List<String> etiquetas,
  required double maxRadio,
  required RotorConfig? config,
  required List<MasaMarker> masas,
  double size = 500,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

  // White background
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size, size),
    Paint()..color = Colors.white,
  );

  final painter = _PolarPainter(
    vectores: vectores,
    colores: colores,
    etiquetas: etiquetas,
    maxRadio: maxRadio,
    config: config,
    masas: masas,
  );
  painter.paint(canvas, Size(size, size));

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}


/// Represents a mass marker to be rendered as a dot on the outer ring.
class MasaMarker {
  final Complejo masa;       // .modulo = grams, .anguloGrados = phase from KP
  final Color color;
  final String etiqueta;     // e.g. 'Masa Prueba 1', 'Masa P1'

  const MasaMarker({required this.masa, required this.color, required this.etiqueta});
}

/// Represents a connecting vector drawn from the tip of one vector to another (Vector Triangle).
class VectorConector {
  final Complejo origen;
  final Complejo destino;
  final Color color;
  final String etiqueta;
  final bool esDiscontinuo;

  const VectorConector({
    required this.origen,
    required this.destino,
    required this.color,
    required this.etiqueta,
    this.esDiscontinuo = false,
  });
}

class PolarPlot extends StatelessWidget {
  final List<Complejo> vectores;
  final List<Color> colores;
  final List<String> etiquetas;
  final List<bool>? esDiscontinuo;
  final List<VectorConector> conectores;
  final double maxRadio;
  final RotorConfig? configOverride;

  /// Masses are rendered as labelled dots on the outer ring, NOT as vectors.
  final List<MasaMarker> masas;

  const PolarPlot({
    super.key,
    required this.vectores,
    required this.colores,
    required this.etiquetas,
    this.esDiscontinuo,
    this.conectores = const [],
    this.maxRadio = 100,
    this.configOverride,
    this.masas = const [],
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context, listen: false);
    final config = configOverride ?? provider.config;

    // Build combined legend: vibration vectors + connectors + mass markers
    final allEtiquetas = [
      ...etiquetas,
      ...conectores.map((c) => c.etiqueta),
      ...masas.map((m) => m.etiqueta),
    ];
    final allColores = [
      ...colores,
      ...conectores.map((c) => c.color),
      ...masas.map((m) => m.color),
    ];
    final allIsMasa = [
      ...List.filled(etiquetas.length + conectores.length, false),
      ...List.filled(masas.length, true),
    ];
    final allIsDashed = [
      ...List.generate(etiquetas.length, (i) => esDiscontinuo != null && i < esDiscontinuo!.length && esDiscontinuo![i]),
      ...conectores.map((c) => c.esDiscontinuo),
      ...List.filled(masas.length, false),
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Combined legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: List.generate(allEtiquetas.length, (index) {
                final isMasa = allIsMasa[index];
                final isDashed = allIsDashed[index];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isMasa
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: allColores[index],
                              shape: BoxShape.circle,
                              border: Border.all(color: allColores[index].withAlpha(180), width: 1.5),
                            ),
                          )
                        : Container(
                            width: 14,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDashed ? Colors.transparent : allColores[index],
                              border: isDashed ? Border.all(color: allColores[index], width: 1.5) : null,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                    const SizedBox(width: 4),
                    Text(
                      allEtiquetas[index],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontStyle: isDashed ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: Semantics(
              label: 'Gráfico polar de análisis vibracional. Vectores mostrados: ${vectores.length}. Masas mostradas: ${masas.length}.',
              image: true,
              child: CustomPaint(
                painter: _PolarPainter(
                  vectores: vectores,
                  colores: colores,
                  etiquetas: etiquetas,
                  esDiscontinuo: esDiscontinuo,
                  conectores: conectores,
                  maxRadio: maxRadio,
                  config: config,
                  masas: masas,
                ),
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
  final List<bool>? esDiscontinuo;
  final List<VectorConector> conectores;
  final double maxRadio;
  final RotorConfig? config;
  final List<MasaMarker> masas;

  _PolarPainter({
    required this.vectores,
    required this.colores,
    required this.etiquetas,
    this.esDiscontinuo,
    this.conectores = const [],
    required this.maxRadio,
    this.config,
    this.masas = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Offset centro = Offset(centerX, centerY);
    final double safeMaxRadio = (maxRadio <= 0 || maxRadio.isNaN || maxRadio.isInfinite) ? 10.0 : maxRadio;
    final double escala = (size.width * 0.65) / (2 * safeMaxRadio);

    final bool sentidoHorario = config?.sentido == SentidoGiro.horario;

    // ── Grid ──────────────────────────────────────────────────────────────
    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int r = 1; r <= 4; r++) {
      double radio = (safeMaxRadio * r / 4) * escala;
      canvas.drawCircle(centro, radio, gridPaint);
    }

    for (int i = 0; i < 12; i++) {
      double angulo = i * 30 * pi / 180;
      double x = centerX + safeMaxRadio * escala * cos(angulo);
      double y = centerY + safeMaxRadio * escala * sin(angulo);
      canvas.drawLine(centro, Offset(x, y), gridPaint);
    }

    // ── Rotation arrow (GIRO) ─────────────────────────────────────────────
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
    Offset puntaPos = Offset(
        centerX + arcRadio * cos(puntaAnguloPos),
        centerY + arcRadio * sin(puntaAnguloPos));
    double tangenteAng = puntaAnguloPos + (sentidoHorario ? pi / 2 : -pi / 2);
    double ala1 = tangenteAng + 160 * pi / 180;
    double ala2 = tangenteAng - 160 * pi / 180;
    double lF = 12.0;

    final Path headPath = Path()
      ..moveTo(puntaPos.dx + lF * cos(ala1), puntaPos.dy + lF * sin(ala1))
      ..lineTo(puntaPos.dx, puntaPos.dy)
      ..lineTo(puntaPos.dx + lF * cos(ala2), puntaPos.dy + lF * sin(ala2));

    canvas.drawPath(headPath, rotPaint);
    _drawLabel(canvas, Offset(centerX - 15, centerY - arcRadio - 15), 'GIRO',
        Colors.orange.shade900, fontSize: 9, bold: true);

    // Helper: absolute canvas angle from a "physical degrees" value
    // Convention: 0° = 3 o'clock, positive = counter-clockwise (standard math)
    double absRad(double grados) => -grados * pi / 180;

    // ── Keyphasor ─────────────────────────────────────────────────────────
    final Paint kpPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    double kpAngRad = absRad(config?.keyphasorAngulo ?? 0);
    double kpx = centerX + maxRadio * 1.1 * escala * cos(kpAngRad);
    double kpy = centerY + maxRadio * 1.1 * escala * sin(kpAngRad);
    canvas.drawLine(centro, Offset(kpx, kpy), kpPaint);
    _drawLabel(canvas, Offset(kpx, kpy - 12), 'KP', Colors.black, fontSize: 8, bold: true);

    final tag1 = config != null && config!.canales.isNotEmpty ? config!.canales[0].tag : 'X';
    final tag2 = config != null && config!.canales.length > 1 ? config!.canales[1].tag : 'Y';

    // ── Sensors ───────────────────────────────────────────────────────────
    final Paint sensorPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    double xAngRad = absRad(config?.sensorXAngulo ?? 0);
    double sx = centerX + maxRadio * 1.2 * escala * cos(xAngRad);
    double sy = centerY + maxRadio * 1.2 * escala * sin(xAngRad);
    canvas.drawCircle(Offset(sx, sy), 7, sensorPaint);
    double lsx = centerX + (maxRadio * 1.2 * escala + 15) * cos(xAngRad);
    double lsy = centerY + (maxRadio * 1.2 * escala + 15) * sin(xAngRad);
    _drawLabel(canvas, Offset(lsx, lsy), tag1, Colors.black, fontSize: 8, bold: true, center: true);

    double yAngRad = absRad(config?.sensorYAngulo ?? 90);
    double syx = centerX + maxRadio * 1.2 * escala * cos(yAngRad);
    double syy = centerY + maxRadio * 1.2 * escala * sin(yAngRad);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(syx, syy), width: 12, height: 12), sensorPaint);
    double lsyx = centerX + (maxRadio * 1.2 * escala + 15) * cos(yAngRad);
    double lsyy = centerY + (maxRadio * 1.2 * escala + 15) * sin(yAngRad);
    _drawLabel(canvas, Offset(lsyx, lsyy), tag2, Colors.black, fontSize: 8, bold: true, center: true);

    // ── Blades ────────────────────────────────────────────────────────────
    if (config?.tipo == TipoRotor.discreto && config!.numAlabes > 0) {
      final int n = config!.numAlabes;
      final double paso = 360 / n;
      final double refAngulo = config!.anguloReferenciaAlabe1;
      final bool numHoraria = config!.numeracionHoraria;
      for (int i = 1; i <= n; i++) {
        double anguloAlabe = refAngulo + (numHoraria ? -(i - 1) * paso : (i - 1) * paso);
        double angRad = absRad(anguloAlabe);
        double ax = centerX + maxRadio * 1.05 * escala * cos(angRad);
        double ay = centerY + maxRadio * 1.05 * escala * sin(angRad);
        canvas.drawCircle(Offset(ax, ay), 6,
            Paint()..color = Colors.blue.withAlpha(20));
        canvas.drawCircle(Offset(ax, ay), 6,
            Paint()
              ..color = Colors.blue.shade700
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5);
        _drawLabel(canvas, Offset(ax - 2.5, ay - 4), i.toString(),
            Colors.blue.shade900, fontSize: 7);
      }
    }

    // ── Vibration vectors ─────────────────────────────────────────────────
    for (int i = 0; i < vectores.length; i++) {
      final v = vectores[i];
      final bool isDashed = esDiscontinuo != null && i < esDiscontinuo!.length && esDiscontinuo![i];
      double absDegrees =
          (config?.keyphasorAngulo ?? 0) + (sentidoHorario ? v.anguloGrados : -v.anguloGrados);
      double angRad = absRad(absDegrees);
      final double modEsc = v.modulo * escala;
      final x = centerX + modEsc * cos(angRad);
      final y = centerY + modEsc * sin(angRad);
      final punta = Offset(x, y);

      final Color vecColor = i < colores.length ? colores[i] : Colors.blue;
      final String vecEtiqueta = i < etiquetas.length ? etiquetas[i] : 'V${i + 1}';

      final vPaint = Paint()
        ..color = vecColor
        ..strokeWidth = isDashed ? 2.2 : 2.0
        ..style = PaintingStyle.stroke;

      if (isDashed) {
        _drawDashedLine(canvas, centro, punta, vPaint);
      } else {
        canvas.drawLine(centro, punta, vPaint);
      }

      double pAng = atan2(y - centerY, x - centerX);
      double f1 = pAng + 150 * pi / 180;
      double f2 = pAng - 150 * pi / 180;
      double arrowLen = min(10, modEsc / 3);
      final arrowPaint = Paint()
        ..color = vecColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(punta, Offset(punta.dx + arrowLen * cos(f1), punta.dy + arrowLen * sin(f1)), arrowPaint);
      canvas.drawLine(punta, Offset(punta.dx + arrowLen * cos(f2), punta.dy + arrowLen * sin(f2)), arrowPaint);

      // Short label: V0 / V1 / V2 / ΔV1 / ΔV2
      String shortLabel = vecEtiqueta.split(' ').first;
      if (vecEtiqueta.toLowerCase().contains('w/p')) {
        shortLabel = vecEtiqueta.contains('P2') || vecEtiqueta.contains('Y')
            ? "V2'"
            : "V1'";
      }
      _drawLabel(canvas, Offset(punta.dx + 4, punta.dy - 12), shortLabel,
          vecColor, fontSize: 8, bold: true);
    }

    // ── Connecting vectors (Triángulo tip-to-tip) ─────────────────────────
    for (final c in conectores) {
      double absDegreesOrig =
          (config?.keyphasorAngulo ?? 0) + (sentidoHorario ? c.origen.anguloGrados : -c.origen.anguloGrados);
      double angRadOrig = absRad(absDegreesOrig);
      double xOrig = centerX + (c.origen.modulo * escala) * cos(angRadOrig);
      double yOrig = centerY + (c.origen.modulo * escala) * sin(angRadOrig);
      Offset pOrig = Offset(xOrig, yOrig);

      double absDegreesDest =
          (config?.keyphasorAngulo ?? 0) + (sentidoHorario ? c.destino.anguloGrados : -c.destino.anguloGrados);
      double angRadDest = absRad(absDegreesDest);
      double xDest = centerX + (c.destino.modulo * escala) * cos(angRadDest);
      double yDest = centerY + (c.destino.modulo * escala) * sin(angRadDest);
      Offset pDest = Offset(xDest, yDest);

      final cPaint = Paint()
        ..color = c.color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;

      if (c.esDiscontinuo) {
        _drawDashedLine(canvas, pOrig, pDest, cPaint, dashLength: 5, dashSpace: 3);
      } else {
        canvas.drawLine(pOrig, pDest, cPaint);
      }

      // Flecha en destino apuntando de pOrig a pDest
      double pAng = atan2(pDest.dy - pOrig.dy, pDest.dx - pOrig.dx);
      double f1 = pAng + 150 * pi / 180;
      double f2 = pAng - 150 * pi / 180;
      double arrowLen = min(10.0, (pDest - pOrig).distance / 3);
      final arrowPaint = Paint()
        ..color = c.color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pDest, Offset(pDest.dx + arrowLen * cos(f1), pDest.dy + arrowLen * sin(f1)), arrowPaint);
      canvas.drawLine(pDest, Offset(pDest.dx + arrowLen * cos(f2), pDest.dy + arrowLen * sin(f2)), arrowPaint);

      // Etiqueta en el punto medio
      Offset mid = Offset((pOrig.dx + pDest.dx) / 2, (pOrig.dy + pDest.dy) / 2);
      String shortConLabel = c.etiqueta.split(' ').first;
      _drawLabel(canvas, Offset(mid.dx + 4, mid.dy - 10), shortConLabel, c.color, fontSize: 8, bold: true);
    }

    // ── Mass markers (dot on the outer ring) ──────────────────────────────
    final double outerRing = maxRadio * escala; // radius of the outermost grid circle
    for (final marker in masas) {
      // Phase is measured from KP, in the direction opposite to rotation (lag)
      double absDegrees = (config?.keyphasorAngulo ?? 0) +
          (sentidoHorario ? marker.masa.anguloGrados : -marker.masa.anguloGrados);
      double angRad = absRad(absDegrees);

      final double mx = centerX + outerRing * cos(angRad);
      final double my = centerY + outerRing * sin(angRad);
      final dotCenter = Offset(mx, my);

      // Filled dot
      canvas.drawCircle(
          dotCenter, 6, Paint()..color = marker.color..style = PaintingStyle.fill);
      // Outline
      canvas.drawCircle(
          dotCenter,
          6,
          Paint()
            ..color = marker.color.withAlpha(200)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);

      // Short label ID above the dot
      final String id = marker.etiqueta.contains('P2') || marker.etiqueta.contains('2')
          ? 'M2'
          : 'M1';
      // Angle & magnitude label below the dot (offset outward from center)
      final double angDeg = marker.masa.anguloGrados;
      final String valueLabel =
          '${angDeg.toStringAsFixed(1)}° | ${marker.masa.modulo.toStringAsFixed(2)}g';

      // Position text slightly beyond the dot in the radial direction
      final double labelR = outerRing + 16;
      final double lx = centerX + labelR * cos(angRad);
      final double ly = centerY + labelR * sin(angRad);

      _drawLabel(canvas, Offset(dotCenter.dx - 6, dotCenter.dy - 16), id,
          marker.color, fontSize: 8, bold: true);
      _drawLabel(canvas, Offset(lx - 20, ly - 5), valueLabel, marker.color,
          fontSize: 7, bold: false);
    }
  }

  void _drawLabel(Canvas canvas, Offset offset, String text, Color color,
      {double fontSize = 11, bool bold = false, bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final paintOffset = center
        ? Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2)
        : offset;
    tp.paint(canvas, paintOffset);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, {double dashLength = 6, double dashSpace = 4}) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;
    final double ux = dx / distance;
    final double uy = dy / distance;

    double current = 0;
    while (current < distance) {
      final double next = min(current + dashLength, distance);
      canvas.drawLine(
        Offset(p1.dx + ux * current, p1.dy + uy * current),
        Offset(p1.dx + ux * next, p1.dy + uy * next),
        paint,
      );
      current += dashLength + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}