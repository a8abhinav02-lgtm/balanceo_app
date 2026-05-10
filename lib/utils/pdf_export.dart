import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import '../providers/balanceo_provider.dart';
import '../models/rotor_config.dart';
import '../models/complejo.dart';
import '../widgets/polar_plot.dart';

class PdfExport {

  // ── Renderizado de gráficas polares ───────────────────────────────────────
  static Future<pw.MemoryImage> _renderGrafica({
    required List<Complejo> vectores,
    required List<Color> colores,
    required List<String> etiquetas,
    required double maxRadio,
    required RotorConfig? config,
    required List<MasaMarker> masas,
  }) async {
    final bytes = await renderPolarToBytes(
      vectores: vectores,
      colores: colores,
      etiquetas: etiquetas,
      maxRadio: maxRadio,
      config: config,
      masas: masas,
      size: 600,
    );
    return pw.MemoryImage(bytes);
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────
  static pw.Widget _sectionTitle(String text, pw.Font font) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6, top: 16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(text,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800)),
            pw.Divider(color: PdfColors.blue200, thickness: 1),
          ],
        ),
      );

  static pw.Widget _fila(String label, String value, pw.Font font,
          {pw.Font? fontBold}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 180,
              child: pw.Text('$label:',
                  style: pw.TextStyle(
                      font: fontBold ?? font,
                      fontSize: 10,
                      color: PdfColors.grey700)),
            ),
            pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(font: font, fontSize: 10)),
            ),
          ],
        ),
      );

  static pw.Widget _vectorFila(
          String label, Complejo v, String unidad, pw.Font font,
          {pw.Font? fontBold}) =>
      _fila(
        label,
        '${v.modulo.toStringAsFixed(3)} $unidad  @  ${v.anguloGrados.toStringAsFixed(2)}°',
        font,
        fontBold: fontBold,
      );

  // ── Generador principal ───────────────────────────────────────────────────
  static Future<Uint8List> generarReporte(BalanceoProvider provider) async {
    final pdf = pw.Document();
    final config = provider.config;
    final es2Planos = config?.numPlanos == 2;
    final iteracion = provider.iteracion;
    final unidad = config?.unidadStr ?? 'µm';

    // ── Fuentes ──────────────────────────────────────────────────────────────
    // Intentar cargar Roboto de Google Fonts (con soporte unicode).
    // Si falla (ej. sin internet), hacer fallback a Helvetica estándar.
    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    // ── Masas correctoras ────────────────────────────────────────────────────
    Complejo? m1;
    Complejo? m2;
    if (es2Planos) {
      final corr = provider.calcularCorreccion2Planos();
      m1 = corr[0];
      m2 = corr[1];
    } else {
      m1 = provider.calcularCorreccion1Plano();
    }

    // ── Pre-renderizar gráficas polares ──────────────────────────────────────

    // 1. Estado Inicial / Residual
    List<Complejo> vIni = [];
    List<Color> cIni = [];
    List<String> eIni = [];
    final esRef = iteracion > 1;

    if (esRef) {
      if (provider.v0_1_original != null) {
        vIni.add(provider.v0_1_original!);
        cIni.add(const Color(0x55007BFF)); // blue semi-transparent
        eIni.add('Sensor X (orig.)');
      }
      if (provider.v0_2_original != null) {
        vIni.add(provider.v0_2_original!);
        cIni.add(const Color(0x55FF3B30));
        eIni.add('Sensor Y (orig.)');
      }
      if (provider.v0_1 != null) {
        vIni.add(provider.v0_1!);
        cIni.add(const Color(0xFF007BFF));
        eIni.add('Sensor X (residual)');
      }
      if (provider.v0_2 != null) {
        vIni.add(provider.v0_2!);
        cIni.add(const Color(0xFFFF3B30));
        eIni.add('Sensor Y (residual)');
      }
    } else {
      if (provider.v0_1 != null) { vIni.add(provider.v0_1!); cIni.add(const Color(0xFF007BFF)); eIni.add('Sensor 1 (X)'); }
      if (provider.v0_2 != null) { vIni.add(provider.v0_2!); cIni.add(const Color(0xFFFF3B30)); eIni.add('Sensor 2 (Y)'); }
    }

    final double maxAmpIni = vIni.isEmpty ? 10.0
        : vIni.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    final imgIni = await _renderGrafica(
        vectores: vIni, colores: cIni, etiquetas: eIni,
        maxRadio: maxAmpIni * 1.2, config: config, masas: []);

    // 2. Efecto Prueba P1
    pw.MemoryImage? imgP1;
    if (provider.v1_1_temp != null) {
      final List<Complejo> vP1 = [...vIni.take(2)];
      final List<Color> cP1 = [...cIni.take(2)];
      final List<String> eP1 = [...eIni.take(2)];
      if (provider.v1_1_temp != null) { vP1.add(provider.v1_1_temp!); cP1.add(const Color(0xFF56B4E9)); eP1.add('Sens X w/Prueba'); }
      if (provider.v1_2_temp != null) { vP1.add(provider.v1_2_temp!); cP1.add(const Color(0xFFFFB3C1)); eP1.add('Sens Y w/Prueba'); }
      final List<MasaMarker> masasP1 = [];
      if (provider.mt1_temp != null) {
        masasP1.add(MasaMarker(masa: provider.mt1_temp!, color: const Color(0xFF555555), etiqueta: 'Masa Prueba 1'));
      }
      final double maxP1 = vP1.isEmpty ? 10.0 : vP1.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
      imgP1 = await _renderGrafica(
          vectores: vP1, colores: cP1, etiquetas: eP1,
          maxRadio: maxP1 * 1.2, config: config, masas: masasP1);
    }

    // 3. Masas Correctoras
    List<Complejo> vFin = List.from(vIni);
    List<Color> cFin = List.from(cIni);
    List<String> eFin = List.from(eIni);
    final List<MasaMarker> masasCorr = [];
    if (m1 != null) masasCorr.add(MasaMarker(masa: m1, color: const Color(0xFF2D8653), etiqueta: 'Masa P1'));
    if (es2Planos && m2 != null) masasCorr.add(MasaMarker(masa: m2, color: const Color(0xFFE27700), etiqueta: 'Masa P2'));
    final double maxFin = vFin.isEmpty ? 10.0 : vFin.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    final imgFin = await _renderGrafica(
        vectores: vFin, colores: cFin, etiquetas: eFin,
        maxRadio: maxFin * 1.2, config: config, masas: masasCorr);

    // ── Construir PDF ─────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('REPORTE DE BALANCEO DINÁMICO',
                    style: pw.TextStyle(
                        font: font, fontSize: 16, fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900)),
                pw.Text('Pág. ${ctx.pageNumber}/${ctx.pagesCount}',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey)),
              ],
            ),
            pw.Divider(color: PdfColors.blue300, thickness: 2),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (ctx) => [

          // ── 1. Identificación ────────────────────────────────────────────
          _sectionTitle('1. Identificación', font),
          _fila('Activo / Equipo', config?.nombreActivo ?? 'N/A', font, fontBold: fontBold),
          _fila('Técnico responsable', config?.tecnico.isEmpty == true ? 'N/A' : (config?.tecnico ?? 'N/A'), font, fontBold: fontBold),
          _fila('Fecha del reporte', DateTime.now().toLocal().toString().substring(0, 16), font, fontBold: fontBold),
          _fila('Iteración actual', '$iteracion', font, fontBold: fontBold),

          // ── 2. Configuración del rotor ───────────────────────────────────
          _sectionTitle('2. Configuración del Rotor', font),
          _fila('Sentido de giro', config?.sentidoTexto ?? 'N/A', font),
          _fila('Tipo de rotor', config?.tipoTexto ?? 'N/A', font),
          if (config?.tipo == TipoRotor.discreto)
            _fila('Número de álabes', '${config?.numAlabes}', font),
          _fila('Ángulo Keyphasor', '${config?.keyphasorAngulo ?? 0}°', font),
          _fila('Ángulo Sensor X', '${config?.sensorXAngulo ?? 0}°', font),
          _fila('Ángulo Sensor Y', '${config?.sensorYAngulo ?? 90}°', font),
          _fila('Planos de corrección', '${config?.numPlanos ?? 1}', font),
          _fila('Unidad de vibración', config?.unidadStr ?? 'µm', font),
          _fila('Límite de vibración', '${config?.limiteVibracion ?? 50} ${config?.unidadStr ?? 'µm'}', font),

          // ── 3. Medición Inicial ──────────────────────────────────────────
          _sectionTitle(esRef ? '3. Vibración Residual (It.${iteracion - 1})' : '3. Medición Inicial', font),
          if (provider.v0_1 != null)
            _vectorFila('Sensor 1 (X)', provider.v0_1!, unidad, font, fontBold: fontBold),
          if (provider.v0_2 != null)
            _vectorFila('Sensor 2 (Y)', provider.v0_2!, unidad, font, fontBold: fontBold),
          if (esRef && provider.v0_1_original != null) ...[
            pw.SizedBox(height: 4),
            pw.Text('Valores originales (estado sucio):',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
            _vectorFila('Sensor X (orig.)', provider.v0_1_original!, unidad, font),
            if (provider.v0_2_original != null)
              _vectorFila('Sensor Y (orig.)', provider.v0_2_original!, unidad, font),
          ],
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Image(imgIni, width: 280, height: 280)),

          // ── 4. Peso de Prueba ────────────────────────────────────────────
          if (imgP1 != null) ...[
            _sectionTitle('4. Efecto del Peso de Prueba', font),
            if (provider.mt1_temp != null)
              _vectorFila('Masa de prueba P1', provider.mt1_temp!, 'g', font, fontBold: fontBold),
            if (provider.v1_1_temp != null)
              _vectorFila('Sensor X c/prueba', provider.v1_1_temp!, unidad, font),
            if (provider.v1_2_temp != null)
              _vectorFila('Sensor Y c/prueba', provider.v1_2_temp!, unidad, font),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Image(imgP1, width: 280, height: 280)),
          ],

          // ── 5. Coeficientes de Influencia ────────────────────────────────
          _sectionTitle('5. Coeficientes de Influencia (H)', font),
          if (!es2Planos && provider.coeficiente1 != null) ...[
            _fila('Sensor de cálculo', provider.usarSensorX ? 'Sensor X' : 'Sensor Y', font),
            _vectorFila('H₁', provider.coeficiente1!, '$unidad/g', font, fontBold: fontBold),
          ],
          if (es2Planos && provider.matrizCoeficientes != null) ...[
            _vectorFila('H₁₁', provider.matrizCoeficientes![0][0], '$unidad/g', font),
            _vectorFila('H₁₂', provider.matrizCoeficientes![0][1], '$unidad/g', font),
            _vectorFila('H₂₁', provider.matrizCoeficientes![1][0], '$unidad/g', font),
            _vectorFila('H₂₂', provider.matrizCoeficientes![1][1], '$unidad/g', font),
          ],

          // ── 6. Masa Correctora ───────────────────────────────────────────
          _sectionTitle('6. Masa Correctora - It. $iteracion', font),
          if (m1 != null) ...[
            _fila('Masa P1', '${m1.modulo.toStringAsFixed(3)} g', font, fontBold: fontBold),
            _fila('Ángulo P1', '${m1.anguloGrados.toStringAsFixed(2)}°', font, fontBold: fontBold),
            if (config?.tipo == TipoRotor.discreto)
              _fila('Álabe sugerido P1',
                  '${provider.sugerirAlabe(m1.anguloGrados) ?? 'N/A'}', font),
          ],
          if (es2Planos && m2 != null) ...[
            pw.SizedBox(height: 4),
            _fila('Masa P2', '${m2.modulo.toStringAsFixed(3)} g', font, fontBold: fontBold),
            _fila('Ángulo P2', '${m2.anguloGrados.toStringAsFixed(2)}°', font, fontBold: fontBold),
            if (config?.tipo == TipoRotor.discreto)
              _fila('Álabe sugerido P2',
                  '${provider.sugerirAlabe(m2.anguloGrados) ?? 'N/A'}', font),
          ],
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Image(imgFin, width: 280, height: 280)),

          // ── 7. Historial de Iteraciones ──────────────────────────────────
          _sectionTitle('7. Historial de Iteraciones', font),
          if (provider.historial.isEmpty)
            pw.Text('No hay iteraciones registradas en el historial.',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headerStyle: pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(4),
              headers: [
                'It.', 'Masa P1 (g)', 'Ángulo P1 (°)',
                if (es2Planos) 'Masa P2 (g)', if (es2Planos) 'Ángulo P2 (°)',
                'Vib. S1 ($unidad)', if (es2Planos) 'Vib. S2 ($unidad)',
              ],
              data: [
                for (final item in provider.historial)
                  [
                    '${item.iteracion}',
                    item.masaPlano1?.modulo.toStringAsFixed(3) ?? 'N/A',
                    item.masaPlano1?.anguloGrados.toStringAsFixed(2) ?? 'N/A',
                    if (es2Planos) item.masaPlano2?.modulo.toStringAsFixed(3) ?? 'N/A',
                    if (es2Planos) item.masaPlano2?.anguloGrados.toStringAsFixed(2) ?? 'N/A',
                    item.vibracionResidual1.toStringAsFixed(3),
                    if (es2Planos) item.vibracionResidual2.toStringAsFixed(3),
                  ],
              ],
            ),

          // ── 8. Recomendaciones ───────────────────────────────────────────
          _sectionTitle('8. Recomendaciones', font),
          ...[
            '- Verificar la correcta instalación de las masas correctoras antes de arrancar.',
            '- Confirmar la calibración del sistema de medición de fase (keyphasor).',
            '- Realizar una medición de verificación tras instalar las masas.',
            '- Documentar el proceso completo para futuros mantenimientos.',
            '- Si la vibración residual supera el límite, iniciar nueva iteración de refinamiento.',
          ].map((rec) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(rec, style: pw.TextStyle(font: font, fontSize: 10)),
              )),

          pw.SizedBox(height: 30),
          // Firma
          pw.Row(children: [
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey),
              pw.Text('Firma del Técnico', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey)),
              pw.Text(config?.tecnico.isNotEmpty == true ? config!.tecnico : '________________________',
                  style: pw.TextStyle(font: font, fontSize: 9)),
            ])),
            pw.SizedBox(width: 40),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey),
              pw.Text('Fecha / Hora', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey)),
              pw.Text(DateTime.now().toLocal().toString().substring(0, 16),
                  style: pw.TextStyle(font: font, fontSize: 9)),
            ])),
          ]),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Compartir (email, WhatsApp, etc.) ─────────────────────────────────────
  static Future<void> compartirReporte(BalanceoProvider provider) async {
    final bytes = await generarReporte(provider);
    final nombre = provider.config?.nombreActivo ?? 'reporte';
    final filename = 'balanceo_${nombre.replaceAll(' ', '_')}.pdf';
    
    final xFile = XFile.fromData(
      bytes,
      name: filename,
      mimeType: 'application/pdf',
    );
    await Share.shareXFiles([xFile], text: 'Reporte de Balanceo - $nombre');
  }

  // ── Guardar en almacenamiento local ───────────────────────────────────────
  static Future<String> guardarReporte(BalanceoProvider provider) async {
    final bytes = await generarReporte(provider);
    final nombre = provider.config?.nombreActivo ?? 'reporte';
    final baseName = 'balanceo_${nombre.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

    // file_saver guarda nativamente en la carpeta "Descargas" en Android (Downloads) 
    // y abre un cuadro de diálogo en desktop/iOS para máxima seguridad y conveniencia.
    final path = await FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
    
    return path;
  }

  // ── Función legacy para compatibilidad ───────────────────────────────────
  static Future<void> imprimirReporte(BalanceoProvider provider) async {
    await compartirReporte(provider);
  }
}