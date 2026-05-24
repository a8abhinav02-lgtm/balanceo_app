import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
          {pw.Font? fontBold, String suffix = ''}) =>
      _fila(
        label,
        '${v.modulo.toStringAsFixed(3)} $unidad  @  ${v.anguloGrados.toStringAsFixed(2)}°$suffix',
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
    final tag1 = config != null && config.canales.isNotEmpty ? config.canales[0].tag : 'Sensor 1 (X)';
    final tag2 = config != null && config.canales.length > 1 ? config.canales[1].tag : 'Sensor 2 (Y)';

    // ── Fuentes ──────────────────────────────────────────────────────────────
    // Usar Helvetica estándar. Se evitó GoogleFonts porque puede causar 
    // hangs (bloqueos infinitos) si el dispositivo intenta descargar la fuente 
    // y la red es inestable.
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final List<Color> coloresCanales = [
      const Color(0xFF0D47A1), // Azul industrial
      const Color(0xFFB71C1C), // Rojo rubí
      const Color(0xFF1B5E20), // Verde bosque
      const Color(0xFF4A148C), // Púrpura profundo
    ];

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
      if (provider.v0Original != null) {
        for (int i = 0; i < provider.v0Original!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vIni.add(provider.v0Original![i]);
          cIni.add(coloresCanales[i % coloresCanales.length].withOpacity(0.3));
          eIni.add('$tag (orig.)');
        }
      }
      if (provider.v0 != null) {
        for (int i = 0; i < provider.v0!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vIni.add(provider.v0![i]);
          cIni.add(coloresCanales[i % coloresCanales.length]);
          eIni.add('$tag (residual)');
        }
      }
    } else {
      if (provider.v0 != null) {
        for (int i = 0; i < provider.v0!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vIni.add(provider.v0![i]);
          cIni.add(coloresCanales[i % coloresCanales.length]);
          eIni.add(tag);
        }
      }
    }

    final double maxAmpIni = vIni.isEmpty ? 10.0
        : vIni.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    final imgIni = await _renderGrafica(
        vectores: vIni, colores: cIni, etiquetas: eIni,
        maxRadio: maxAmpIni * 1.2, config: config, masas: []);

    // 2. Efecto Prueba P1
    pw.MemoryImage? imgP1;
    if (provider.v1Temp != null && provider.v1Temp!.isNotEmpty) {
      final List<Complejo> baseVecs = esRef
          ? (provider.v0Original ?? [])
          : (provider.v0 ?? []);
      final List<Complejo> vP1 = [];
      final List<Color> cP1 = [];
      final List<String> eP1 = [];

      for (int i = 0; i < baseVecs.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        vP1.add(baseVecs[i]);
        cP1.add(coloresCanales[i % coloresCanales.length].withOpacity(esRef ? 0.3 : 1.0));
        eP1.add(esRef ? '$tag (orig.)' : tag);
      }

      for (int i = 0; i < provider.v1Temp!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        vP1.add(provider.v1Temp![i]);
        cP1.add(coloresCanales[i % coloresCanales.length].withOpacity(0.7));
        eP1.add('$tag w/Prueba');
      }

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
    List<Complejo> vFin = [];
    List<Color> cFin = [];
    List<String> eFin = [];

    if (esRef) {
      if (provider.v0Original != null) {
        for (int i = 0; i < provider.v0Original!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vFin.add(provider.v0Original![i]);
          cFin.add(coloresCanales[i % coloresCanales.length].withOpacity(0.3));
          eFin.add('$tag (orig.)');
        }
      }
      if (provider.v0 != null) {
        for (int i = 0; i < provider.v0!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vFin.add(provider.v0![i]);
          cFin.add(coloresCanales[i % coloresCanales.length]);
          eFin.add('$tag (residual)');
        }
      }
    } else {
      if (provider.v0 != null) {
        for (int i = 0; i < provider.v0!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vFin.add(provider.v0![i]);
          cFin.add(coloresCanales[i % coloresCanales.length]);
          eFin.add(tag);
        }
      }
    }

    final List<MasaMarker> masasCorr = [];
    if (m1 != null) masasCorr.add(MasaMarker(masa: m1, color: const Color(0xFF2D8653), etiqueta: 'Masa P1'));
    if (es2Planos && m2 != null) masasCorr.add(MasaMarker(masa: m2, color: const Color(0xFFE27700), etiqueta: 'Masa P2'));
    final double maxFin = vFin.isEmpty ? 10.0 : vFin.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    final imgFin = await _renderGrafica(
        vectores: vFin, colores: cFin, etiquetas: eFin,
        maxRadio: maxFin * 1.2, config: config, masas: masasCorr);

    // 4. Vibración de Verificación
    pw.MemoryImage? imgVerif;
    if (provider.vVerificacion != null && provider.vVerificacion!.isNotEmpty) {
      final List<Complejo> vVer = [];
      final List<Color> cVer = [];
      final List<String> eVer = [];

      // Vectores iniciales translúcidos
      final List<Complejo>? initialVectors = provider.v0Original ?? provider.v0;
      if (initialVectors != null) {
        for (int i = 0; i < initialVectors.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vVer.add(initialVectors[i]);
          cVer.add(coloresCanales[i % coloresCanales.length].withOpacity(0.3));
          eVer.add('$tag (inicial)');
        }
      }

      // Vectores de verificación sólidos
      for (int i = 0; i < provider.vVerificacion!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        vVer.add(provider.vVerificacion![i]);
        cVer.add(coloresCanales[i % coloresCanales.length]);
        eVer.add('$tag (final)');
      }

      final double maxAmpVer = vVer.isEmpty ? 10.0 : vVer.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
      imgVerif = await _renderGrafica(
          vectores: vVer, colores: cVer, etiquetas: eVer,
          maxRadio: maxAmpVer * 1.2, config: config, masas: []);
    }

    // Pre-calculate widgets for initial/original readings to support dynamic channels
    final List<pw.Widget> initialVibrationWidgets = [];
    if (provider.v0 != null) {
      for (int i = 0; i < provider.v0!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        initialVibrationWidgets.add(_vectorFila(tag, provider.v0![i], unidad, font, fontBold: fontBold));
      }
    }
    final List<pw.Widget> originalVibrationWidgets = [];
    if (esRef && provider.v0Original != null) {
      for (int i = 0; i < provider.v0Original!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        originalVibrationWidgets.add(_vectorFila('$tag (orig.)', provider.v0Original![i], unidad, font));
      }
    }

    // Pre-calculate widgets for trial readings
    final List<pw.Widget> trial1Widgets = [];
    if (provider.v1Temp != null) {
      for (int i = 0; i < provider.v1Temp!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        trial1Widgets.add(_vectorFila('$tag c/prueba', provider.v1Temp![i], unidad, font));
      }
    }

    // Pre-calculate widgets for verification readings
    final List<pw.Widget> verifWidgets = [];
    if (provider.vVerificacion != null) {
      for (int i = 0; i < provider.vVerificacion!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        final vIniVal = (provider.v0Original != null && i < provider.v0Original!.length)
            ? provider.v0Original![i]
            : ((provider.v0 != null && i < provider.v0!.length) ? provider.v0![i] : null);
        final vVerVal = provider.vVerificacion![i];
        double reduction = 0.0;
        if (vIniVal != null && vIniVal.modulo > 0) {
          reduction = ((vIniVal.modulo - vVerVal.modulo) / vIniVal.modulo) * 100;
        }

        final iniText = vIniVal != null 
            ? '${vIniVal.modulo.toStringAsFixed(3)} $unidad @ ${vIniVal.anguloGrados.toStringAsFixed(1)}°'
            : 'N/A';
        final verText = '${vVerVal.modulo.toStringAsFixed(3)} $unidad @ ${vVerVal.anguloGrados.toStringAsFixed(1)}°';
        final redText = vIniVal != null ? '${reduction.toStringAsFixed(1)}%' : 'N/A';

        verifWidgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tag, style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue800)),
                _fila('  Vibración Inicial', iniText, font),
                _fila('  Vibración Final', verText, font),
                _fila('  Reducción de Vibración', redText, font, fontBold: fontBold),
                pw.SizedBox(height: 4),
              ],
            ),
          ),
        );
      }
    }

    // Pre-calculate history table headers and data
    final List<String> tableHeaders = [
      'It.',
      'M1 Teor(g)',
      'Ang1 Teor',
      'M1 Real(g)',
      'Ang1 Real',
      if (es2Planos) ...[
        'M2 Teor(g)',
        'Ang2 Teor',
        'M2 Real(g)',
        'Ang2 Real',
      ],
    ];
    if (config != null) {
      for (final canal in config.canales) {
        tableHeaders.add('Vib. ${canal.tag} ($unidad)');
      }
    } else {
      tableHeaders.add('Vib. $tag1 ($unidad)');
      if (es2Planos) tableHeaders.add('Vib. $tag2 ($unidad)');
    }

    final List<List<String>> tableData = [];
    for (final item in provider.historial) {
      final List<String> row = [
        '${item.iteracion}',
        item.masaPlano1?.modulo.toStringAsFixed(2) ?? 'N/A',
        provider.ajustarAngulo(item.masaPlano1?.anguloGrados ?? 0).toStringAsFixed(1) + '°',
        item.realPlano1?.modulo.toStringAsFixed(2) ?? 'N/A',
        provider.ajustarAngulo(item.realPlano1?.anguloGrados ?? 0).toStringAsFixed(1) + '°',
        if (es2Planos) ...[
          item.masaPlano2?.modulo.toStringAsFixed(2) ?? 'N/A',
          provider.ajustarAngulo(item.masaPlano2?.anguloGrados ?? 0).toStringAsFixed(1) + '°',
          item.realPlano2?.modulo.toStringAsFixed(2) ?? 'N/A',
          provider.ajustarAngulo(item.realPlano2?.anguloGrados ?? 0).toStringAsFixed(1) + '°',
        ],
      ];
      if (config != null) {
        for (int i = 0; i < config.canales.length; i++) {
          if (i < item.vibracionesResiduales.length) {
            row.add(item.vibracionesResiduales[i].toStringAsFixed(3));
          } else {
            row.add('N/A');
          }
        }
      } else {
        row.add(item.vibracionResidual1.toStringAsFixed(3));
        if (es2Planos) row.add(item.vibracionResidual2.toStringAsFixed(3));
      }
      tableData.add(row);
    }

    final int totalGraficos = 2 + (imgP1 != null ? 1 : 0) + (imgVerif != null && provider.vVerificacion != null ? 1 : 0);
    const int idxIni = 1;
    final int idxP1 = imgP1 != null ? 2 : 0;
    final int idxFin = imgP1 != null ? 3 : 2;
    final int idxVerif = provider.vVerificacion != null ? (imgP1 != null ? 4 : 3) : 0;

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
          if (config != null)
            for (final canal in config.canales)
              _fila('Ángulo ${canal.tag}', '${canal.angulo}°', font)
          else ...[
            _fila('Ángulo $tag1', '${config?.sensorXAngulo ?? 0}°', font),
            _fila('Ángulo $tag2', '${config?.sensorYAngulo ?? 90}°', font),
          ],
          _fila('Planos de corrección', '${config?.numPlanos ?? 1}', font),
          _fila('Unidad de vibración', config?.unidadStr ?? 'µm', font),
          _fila('Límite de vibración', '${config?.limiteVibracion ?? 50} ${config?.unidadStr ?? 'µm'}', font),

          // ── 3. Medición Inicial ──────────────────────────────────────────
          pw.Inseparable(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionTitle(esRef ? '3. Vibración Residual (It.${iteracion - 1})' : '3. Medición Inicial', font),
                ...initialVibrationWidgets,
                if (esRef && originalVibrationWidgets.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Valores originales (estado sucio):',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                  ...originalVibrationWidgets,
                ],
                pw.SizedBox(height: 8),
                pw.Center(child: pw.Image(imgIni, width: 280, height: 280)),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'Gráfica $idxIni de $totalGraficos: ${esRef ? 'Vibración Residual (It.${iteracion - 1})' : 'Vibración Inicial'}',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700),
                  ),
                ),
              ],
            ),
          ),

          // ── 4. Peso de Prueba ────────────────────────────────────────────
          if (imgP1 != null)
            pw.Inseparable(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _sectionTitle('4. Efecto del Peso de Prueba', font),
                  if (provider.mt1_temp != null)
                    _vectorFila('Masa de prueba P1', provider.mt1_temp!, 'g', font, fontBold: fontBold),
                  ...trial1Widgets,
                  pw.SizedBox(height: 8),
                  pw.Center(child: pw.Image(imgP1, width: 280, height: 280)),
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      'Gráfica $idxP1 de $totalGraficos: Efecto del Peso de Prueba P1',
                      style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700),
                    ),
                  ),
                ],
              ),
            ),

          // ── 5. Coeficientes de Influencia ────────────────────────────────
          pw.Inseparable(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionTitle('5. Coeficientes de Influencia (H)', font),
                if (!es2Planos && provider.coeficiente1 != null) ...[
                  _fila('Sensor de cálculo', provider.usarSensorX ? tag1 : tag2, font),
                  _vectorFila('H1', provider.coeficiente1!, '$unidad/g', font, 
                      fontBold: fontBold,
                      suffix: (provider.coeficiente1!.anguloGrados % 360 > 180) ? ' (Lead)' : ' (Lag)'),
                ],
                if (es2Planos && provider.matrizCoeficientes != null) ...[
                  _vectorFila('H11', provider.matrizCoeficientes![0][0], '$unidad/g', font,
                      suffix: (provider.matrizCoeficientes![0][0].anguloGrados % 360 > 180) ? ' (Lead)' : ' (Lag)'),
                  _vectorFila('H12', provider.matrizCoeficientes![0][1], '$unidad/g', font,
                      suffix: (provider.matrizCoeficientes![0][1].anguloGrados % 360 > 180) ? ' (Lead)' : ' (Lag)'),
                  _vectorFila('H21', provider.matrizCoeficientes![1][0], '$unidad/g', font,
                      suffix: (provider.matrizCoeficientes![1][0].anguloGrados % 360 > 180) ? ' (Lead)' : ' (Lag)'),
                  _vectorFila('H22', provider.matrizCoeficientes![1][1], '$unidad/g', font,
                      suffix: (provider.matrizCoeficientes![1][1].anguloGrados % 360 > 180) ? ' (Lead)' : ' (Lag)'),
                ],
              ],
            ),
          ),

          // ── 6. Masa Correctora ───────────────────────────────────────────
          pw.Inseparable(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
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
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'Gráfica $idxFin de $totalGraficos: Ubicación de Masas Correctoras',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700),
                  ),
                ),
              ],
            ),
          ),

          // ── 7. Vibración de Verificación / Resultados Finales ────────────
          if (imgVerif != null && provider.vVerificacion != null)
            pw.Inseparable(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _sectionTitle('7. Vibración de Verificación / Resultados Finales', font),
                  ...verifWidgets,
                  pw.SizedBox(height: 8),
                  pw.Center(child: pw.Image(imgVerif, width: 280, height: 280)),
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      'Gráfica $idxVerif de $totalGraficos: Resultados Finales (Inicial vs. Final)',
                      style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700),
                    ),
                  ),
                ],
              ),
            ),

          // ── 8. Historial de Iteraciones ──────────────────────────────────
          pw.Inseparable(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionTitle('8. Historial de Iteraciones', font),
                if (provider.historial.isEmpty)
                  pw.Text('No hay iteraciones registradas en el historial.',
                      style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey))
                else ...[
                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    headerStyle: pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                    cellStyle: pw.TextStyle(font: font, fontSize: 8),
                    cellPadding: const pw.EdgeInsets.all(3),
                    headers: tableHeaders,
                    data: tableData,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Masa Real Acumulada Final en Rotor:',
                    style: pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.Bullet(
                    text: 'Plano 1: ${provider.calcularMasaRealAcumuladaPlano1().modulo.toStringAsFixed(2)} g @ ${provider.ajustarAngulo(provider.calcularMasaRealAcumuladaPlano1().anguloGrados).toStringAsFixed(1)}°',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                  if (es2Planos)
                    pw.Bullet(
                      text: 'Plano 2: ${provider.calcularMasaRealAcumuladaPlano2().modulo.toStringAsFixed(2)} g @ ${provider.ajustarAngulo(provider.calcularMasaRealAcumuladaPlano2().anguloGrados).toStringAsFixed(1)}°',
                      style: pw.TextStyle(font: font, fontSize: 8),
                    ),
                ],
              ],
            ),
          ),

          // ── 9. Recomendaciones ───────────────────────────────────────────
          pw.Inseparable(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionTitle('9. Recomendaciones', font),
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
          ),
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
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: 'Reporte de Balanceo - $nombre',
      ),
    );
  }

  // ── Guardar en almacenamiento local ───────────────────────────────────────
  static Future<String?> guardarReporte(BalanceoProvider provider) async {
    final bytes = await generarReporte(provider);
    final nombre = provider.config?.nombreActivo ?? 'reporte';
    final baseName = 'balanceo_${nombre.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

    // saveAs abre un cuadro de diálogo nativo en Android (Storage Access Framework) 
    // y en desktop/iOS para que el usuario elija exactamente dónde guardarlo (ej. Descargas).
    final path = await FileSaver.instance.saveAs(
      name: baseName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    
    return path;
  }

  // ── Función legacy para compatibilidad ───────────────────────────────────
  static Future<void> imprimirReporte(BalanceoProvider provider) async {
    await compartirReporte(provider);
  }
}