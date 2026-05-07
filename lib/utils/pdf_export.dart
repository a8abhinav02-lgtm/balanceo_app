import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/balanceo_provider.dart';
import '../models/rotor_config.dart';

class PdfExport {
  static Future<Uint8List> generarReporte(BalanceoProvider provider) async {
    final pdf = pw.Document();
    final es2Planos = provider.config?.numPlanos == 2;

    // Fuente local para soporte offline
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Título
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Reporte de Balanceo',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: font),
                ),
                pw.Text(
                  'Activo: ${provider.config?.nombreActivo ?? "Desconocido"}',
                  style: pw.TextStyle(fontSize: 18, color: PdfColors.blue700, font: font),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Fecha
          pw.Text(
            'Generado: ${DateTime.now().toString().substring(0, 19)}',
            style: pw.TextStyle(fontSize: 10, font: font),
          ),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Configuración
          pw.Text(
            '1. Configuración del Rotor',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Sentido de giro: ${provider.config?.sentidoTexto ?? "N/A"}', style: pw.TextStyle(font: font)),
          pw.Text('Tipo de rotor: ${provider.config?.tipoTexto ?? "N/A"}', style: pw.TextStyle(font: font)),
          if (provider.config?.tipo == TipoRotor.discreto)
            pw.Text('Número de álabes: ${provider.config?.numAlabes}', style: pw.TextStyle(font: font)),
          pw.Text('Ángulo keyphasor: ${provider.config?.keyphasorAngulo ?? 0}°', style: pw.TextStyle(font: font)),
          pw.Text('Planos de corrección: ${provider.config?.numPlanos ?? 1}', style: pw.TextStyle(font: font)),
          pw.Text('Límite de vibración: ${provider.config?.limiteVibracion ?? 50} ${provider.config?.unidadStr ?? 'µm'}', style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 20),

          // Medición inicial
          pw.Text(
            '2. Medición Inicial',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font),
          ),
          pw.SizedBox(height: 10),
          if (provider.sensor1Actual != null)
            pw.Text('Sensor 1: ${provider.sensor1Actual!.modulo.toStringAsFixed(2)} ${provider.config?.unidadStr ?? 'µm'} @ ${provider.sensor1Actual!.anguloGrados.toStringAsFixed(1)}°', style: pw.TextStyle(font: font)),
          if (es2Planos && provider.sensor2Actual != null)
            pw.Text('Sensor 2: ${provider.sensor2Actual!.modulo.toStringAsFixed(2)} ${provider.config?.unidadStr ?? 'µm'} @ ${provider.sensor2Actual!.anguloGrados.toStringAsFixed(1)}°', style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 20),

          // Coeficientes
          pw.Text(
            '3. Coeficientes de Influencia',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font),
          ),
          pw.SizedBox(height: 10),
          if (!es2Planos && provider.coeficiente1 != null)
            pw.Text('C = ${provider.coeficiente1!.modulo.toStringAsFixed(2)} ${provider.config?.unidadStr ?? 'µm'}/g @ ${provider.coeficiente1!.anguloGrados.toStringAsFixed(1)}°', style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 20),

          // Historial
          pw.Text(
            '4. Historial de Iteraciones',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font),
          ),
          pw.SizedBox(height: 10),
          if (provider.historial.isEmpty)
            pw.Text('No hay iteraciones registradas', style: pw.TextStyle(font: font))
          else
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Text('Iter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                    pw.Text('Masa P1 (g)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                    pw.Text('Ángulo P1 (°)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                    if (es2Planos) pw.Text('Masa P2 (g)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                    if (es2Planos) pw.Text('Ángulo P2 (°)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                    pw.Text('Vib S1 (${provider.config?.unidadStr ?? 'µm'})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                    if (es2Planos) pw.Text('Vib S2 (${provider.config?.unidadStr ?? 'µm'})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                  ],
                ),
                for (final item in provider.historial)
                  pw.TableRow(
                    children: [
                      pw.Text('${item.iteracion}', style: pw.TextStyle(font: font)),
                      pw.Text(item.masaPlano1?.modulo.toStringAsFixed(2) ?? 'N/A', style: pw.TextStyle(font: font)),
                      pw.Text(item.masaPlano1?.anguloGrados.toStringAsFixed(1) ?? 'N/A', style: pw.TextStyle(font: font)),
                      if (es2Planos) pw.Text(item.masaPlano2?.modulo.toStringAsFixed(2) ?? 'N/A', style: pw.TextStyle(font: font)),
                      if (es2Planos) pw.Text(item.masaPlano2?.anguloGrados.toStringAsFixed(1) ?? 'N/A', style: pw.TextStyle(font: font)),
                      pw.Text(item.vibracionResidual1.toStringAsFixed(2), style: pw.TextStyle(font: font)),
                      if (es2Planos) pw.Text(item.vibracionResidual2.toStringAsFixed(2), style: pw.TextStyle(font: font)),
                    ],
                  ),
              ],
            ),
          pw.SizedBox(height: 20),

          // Recomendaciones
          pw.Text(
            '5. Recomendaciones',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font),
          ),
          pw.SizedBox(height: 10),
          pw.Text('• Verificar la correcta instalación de las masas correctoras.', style: pw.TextStyle(font: font)),
          pw.Text('• Confirmar la calibración del sistema de medición de fase.', style: pw.TextStyle(font: font)),
          pw.Text('• Evaluar el paso por velocidades críticas (700 y 1640 cpm).', style: pw.TextStyle(font: font)),
          pw.Text('• Documentar el proceso para futuros mantenimientos.', style: pw.TextStyle(font: font)),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> imprimirReporte(BalanceoProvider provider) async {
    final pdfBytes = await generarReporte(provider);
    await Printing.sharePdf(bytes: pdfBytes, filename: 'reporte_balanceo.pdf');
  }
}