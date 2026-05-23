import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balanceo_provider.dart';
import '../widgets/polar_plot.dart';
import '../widgets/resultado_card.dart';
import '../models/complejo.dart';
import '../models/rotor_config.dart';
import '../utils/pdf_export.dart';
import 'guia_screen.dart';


class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    final es2Planos = provider.config?.numPlanos == 2;
    final iteracion = provider.iteracion;
    final esRefinamiento = iteracion > 1;
    final config = provider.config;
    final List<Color> coloresCanales = [
      const Color(0xFF0D47A1), // Azul industrial
      const Color(0xFFB71C1C), // Rojo rubí
      const Color(0xFF1B5E20), // Verde bosque
      const Color(0xFF4A148C), // Púrpura profundo
    ];

    Complejo? m1;
    Complejo? m2;

    if (es2Planos) {
      final correccion = provider.calcularCorreccion2Planos();
      m1 = correccion[0];
      m2 = correccion[1];
    } else {
      m1 = provider.calcularCorreccion1Plano();
    }

    // ── Construir páginas del carrusel ─────────────────────────────────────
    List<Widget> pages = [];
    List<String> pageTitles = [];

    // Página 1: Estado Inicial (It.1) o Vibración Residual (It.2+)
    List<Complejo> vIni = [];
    List<Color> cIni = [];
    List<String> eIni = [];

    if (esRefinamiento) {
      if (provider.v0Original != null) {
        for (int i = 0; i < provider.v0Original!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vIni.add(provider.v0Original![i]);
          cIni.add(coloresCanales[i % coloresCanales.length].withOpacity(0.4));
          eIni.add('$tag (orig.)');
        }
      }
      if (provider.v0 != null) {
        for (int i = 0; i < provider.v0!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vIni.add(provider.v0![i]);
          cIni.add(coloresCanales[i % coloresCanales.length]);
          eIni.add('$tag (It.${iteracion - 1})');
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

    double maxAmpIni = vIni.isEmpty ? 10.0 : vIni.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    pages.add(Center(child: PolarPlot(vectores: vIni, colores: cIni, etiquetas: eIni, maxRadio: maxAmpIni * 1.2)));
    pageTitles.add(esRefinamiento ? 'RESIDUAL — It.${iteracion - 1}' : 'ESTADO INICIAL');

    // Página 2: Efecto Prueba P1 (siempre visible si hay lecturas)
    if (provider.v1Temp != null && provider.v1Temp!.isNotEmpty) {
      final List<Complejo> baseVecs = esRefinamiento
          ? (provider.v0Original ?? [])
          : (provider.v0 ?? []);
      final List<Color> baseCols = [];
      final List<String> baseEtqs = [];

      for (int i = 0; i < baseVecs.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        baseCols.add(coloresCanales[i % coloresCanales.length].withOpacity(esRefinamiento ? 0.4 : 1.0));
        baseEtqs.add(esRefinamiento ? '$tag (orig.)' : tag);
      }

      List<Complejo> vP1 = List.from(baseVecs);
      List<Color> cP1 = List.from(baseCols);
      List<String> eP1 = List.from(baseEtqs);

      for (int i = 0; i < provider.v1Temp!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        vP1.add(provider.v1Temp![i]);
        cP1.add(coloresCanales[i % coloresCanales.length].withOpacity(0.7));
        eP1.add('$tag w/Prueba');
      }

      final List<MasaMarker> masasP1 = [];
      if (provider.mt1_temp != null) {
        masasP1.add(MasaMarker(masa: provider.mt1_temp!, color: Colors.grey.shade700, etiqueta: 'Masa Prueba 1'));
      }

      double maxAmpP1 = vP1.isEmpty ? 10.0 : vP1.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
      pages.add(Center(child: PolarPlot(vectores: vP1, colores: cP1, etiquetas: eP1, maxRadio: maxAmpP1 * 1.2, masas: masasP1)));
      pageTitles.add(esRefinamiento ? 'PRUEBA ORIGINAL (Ref.)' : 'EFECTO PRUEBA P1');
    }

    // Página 3: Efecto Prueba P2 (si aplica)
    if (es2Planos && provider.v2Temp != null && provider.v2Temp!.isNotEmpty) {
      final List<Complejo> baseVecs2 = esRefinamiento
          ? (provider.v0Original ?? [])
          : (provider.v0 ?? []);
      final List<Color> baseCols2 = [];
      final List<String> baseEtqs2 = [];

      for (int i = 0; i < baseVecs2.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        baseCols2.add(coloresCanales[i % coloresCanales.length].withOpacity(esRefinamiento ? 0.4 : 1.0));
        baseEtqs2.add(esRefinamiento ? '$tag (orig.)' : tag);
      }

      List<Complejo> vP2 = List.from(baseVecs2);
      List<Color> cP2 = List.from(baseCols2);
      List<String> eP2 = List.from(baseEtqs2);

      for (int i = 0; i < provider.v2Temp!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        vP2.add(provider.v2Temp![i]);
        cP2.add(coloresCanales[i % coloresCanales.length].withOpacity(0.7));
        eP2.add('$tag w/Prueba P2');
      }

      final List<MasaMarker> masasP2 = [];
      if (provider.mt2_temp != null) {
        masasP2.add(MasaMarker(masa: provider.mt2_temp!, color: Colors.grey.shade700, etiqueta: 'Masa Prueba 2'));
      }

      double maxAmpP2 = vP2.isEmpty ? 10.0 : vP2.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
      pages.add(Center(child: PolarPlot(vectores: vP2, colores: cP2, etiquetas: eP2, maxRadio: maxAmpP2 * 1.2, masas: masasP2)));
      pageTitles.add(esRefinamiento ? 'PRUEBA P2 ORIGINAL (Ref.)' : 'EFECTO PRUEBA P2');
    }

    // Última página: Masas Correctoras
    List<Complejo> vFin = [];
    List<Color> cFin = [];
    List<String> eFin = [];

    if (esRefinamiento) {
      if (provider.v0Original != null) {
        for (int i = 0; i < provider.v0Original!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vFin.add(provider.v0Original![i]);
          cFin.add(coloresCanales[i % coloresCanales.length].withOpacity(0.4));
          eFin.add('$tag (orig.)');
        }
      }
      if (provider.v0 != null) {
        for (int i = 0; i < provider.v0!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vFin.add(provider.v0![i]);
          cFin.add(coloresCanales[i % coloresCanales.length]);
          eFin.add('$tag (It.${iteracion - 1})');
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
    if (m1 != null) { masasCorr.add(MasaMarker(masa: m1, color: Colors.green.shade700, etiqueta: 'Masa P1')); }
    if (es2Planos && m2 != null) { masasCorr.add(MasaMarker(masa: m2, color: Colors.orange.shade800, etiqueta: 'Masa P2')); }

    double maxAmpFin = vFin.isEmpty ? 10.0 : vFin.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    pages.add(Center(child: PolarPlot(vectores: vFin, colores: cFin, etiquetas: eFin, maxRadio: maxAmpFin * 1.2, masas: masasCorr)));
    pageTitles.add(esRefinamiento ? 'MASAS CORRECTORAS — It.$iteracion' : 'MASAS CORRECTORAS');

    // Página de verificación si existe
    if (provider.vVerificacion != null && provider.vVerificacion!.isNotEmpty) {
      List<Complejo> vVer = [];
      List<Color> cVer = [];
      List<String> eVer = [];

      if (provider.v0 != null) {
        for (int i = 0; i < provider.v0!.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vVer.add(provider.v0![i]);
          cVer.add(coloresCanales[i % coloresCanales.length].withOpacity(0.3));
          eVer.add('$tag (Ini.)');
        }
      }
      for (int i = 0; i < provider.vVerificacion!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        vVer.add(provider.vVerificacion![i]);
        cVer.add(coloresCanales[i % coloresCanales.length]);
        eVer.add('$tag (Verif.)');
      }

      double maxAmpVer = vVer.isEmpty ? 10.0 : vVer.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
      pages.add(Center(child: PolarPlot(vectores: vVer, colores: cVer, etiquetas: eVer, maxRadio: maxAmpVer * 1.2)));
      pageTitles.add('VIBRACIÓN FINAL / VERIFICACIÓN');
    }

    // ── UI ─────────────────────────────────────────────────────────────────
    return Scaffold(
      appBar: AppBar(
        title: Text(esRefinamiento
            ? 'Resultados - Iteración $iteracion'
            : 'Resultados del Balanceo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Guía de Operación',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GuiaScreen()));
            },
          ),
          PopupMenuButton<String>(

            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Reporte PDF',
            onSelected: (value) async {
              if (value == 'compartir') {
                try {
                  await PdfExport.compartirReporte(provider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al compartir: $e')),
                    );
                  }
                }
              } else if (value == 'guardar') {

                try {
                  final path = await PdfExport.guardarReporte(provider);
                  if (context.mounted && path != null && path.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDF guardado en: $path'),
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(label: 'OK', onPressed: () {}),
                      ),
                    );
                  }
                } catch (e) {

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar: $e')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'compartir',
                child: Row(children: [
                  Icon(Icons.share, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Compartir PDF'),
                ]),
              ),
              const PopupMenuItem(
                value: 'guardar',
                child: Row(children: [
                  Icon(Icons.save_alt, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Guardar en dispositivo'),
                ]),
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.pushNamed(context, '/historial')),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Masas Correctoras Calculadas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (esRefinamiento) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text('It. $iteracion', style: const TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  if (esRefinamiento)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        'Coeficientes de influencia reutilizados de la It. 1 — Solo se actualizó la vibración residual.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ResultadoCard(masa: m1, titulo: es2Planos ? 'Plano 1' : 'Masa Correctora', numeroPlano: 1),
                  if (es2Planos && m2 != null) ResultadoCard(masa: m2, titulo: 'Plano 2', numeroPlano: 2),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.teal.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.check_box, color: Colors.teal.shade700),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Masa Real Instalada',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Ajustar peso real',
                                onPressed: () => _mostrarDialogoAjustarPesoReal(context, provider, m1, m2, es2Planos),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Plano 1: ${((provider.masaRealInstalada1 ?? m1)?.modulo ?? 0).toStringAsFixed(2)} g @ ${provider.ajustarAngulo((provider.masaRealInstalada1 ?? m1)?.anguloGrados ?? 0).toStringAsFixed(1)}°',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          if (es2Planos && m2 != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Plano 2: ${((provider.masaRealInstalada2 ?? m2)?.modulo ?? 0).toStringAsFixed(2)} g @ ${provider.ajustarAngulo((provider.masaRealInstalada2 ?? m2)?.anguloGrados ?? 0).toStringAsFixed(1)}°',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (esRefinamiento) ...[
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.history, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Masa Real Acumulada Previa en Rotor',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Plano 1: ${provider.calcularMasaRealAcumuladaPlano1().modulo.toStringAsFixed(2)} g @ ${provider.ajustarAngulo(provider.calcularMasaRealAcumuladaPlano1().anguloGrados).toStringAsFixed(1)}°',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (es2Planos) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Plano 2: ${provider.calcularMasaRealAcumuladaPlano2().modulo.toStringAsFixed(2)} g @ ${provider.ajustarAngulo(provider.calcularMasaRealAcumuladaPlano2().anguloGrados).toStringAsFixed(1)}°',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),

            // Carrusel de gráficas polares
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text('Anterior'),
                    onPressed: _currentPage == 0 ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  ),
                  Expanded(
                    child: Text(
                      '${_currentPage + 1}/${pages.length} \n ${pageTitles[_currentPage]}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    label: const Text('Siguiente'),
                    onPressed: _currentPage == pages.length - 1 ? null : () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 480,
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: pages,
              ),
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Acciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoRegistrarVerificacion(context, provider),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Registrar Vibración de Verificación'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoNuevaIteracion(context, provider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Nueva Iteración (Refinar)'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  if (provider.vVerificacion != null && config != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.teal.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.teal.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified, color: Colors.teal.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Verificación Registrada',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            for (int i = 0; i < provider.vVerificacion!.length; i++) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      (i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${provider.vVerificacion![i].modulo.toStringAsFixed(2)} ${config.unidadStr} @ ${provider.vVerificacion![i].anguloGrados.toStringAsFixed(1)}°',
                                      style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  // Bloqueado en iteraciones 2+ para evitar recálculo incorrecto de H
                  onPressed: esRefinamiento ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final residuales = provider.vVerificacion != null
                        ? provider.vVerificacion!.map((v) => v.modulo).toList()
                        : provider.v0?.map((v) => v.modulo).toList() ?? [];
                    provider.agregarAlHistorial(
                      m1, m2,
                      residuales,
                      mReal1: provider.masaRealInstalada1 ?? m1,
                      mReal2: provider.masaRealInstalada2 ?? m2,
                      vibracionesComplejas: provider.vVerificacion ?? provider.v0,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en historial')));
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoNuevaIteracion(BuildContext context, BalanceoProvider provider) {
    final config = provider.config;
    if (config == null) return;

    if (provider.vVerificacion != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.refresh, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Iteración ${provider.iteracion + 1}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Se detectó una vibración de verificación registrada para esta iteración.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Desea iniciar la nueva iteración utilizando estos valores como la vibración inicial de la siguiente corrida?',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < provider.vVerificacion!.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${config.canales[i].tag}: ${provider.vVerificacion![i].modulo.toStringAsFixed(2)} ${config.unidadStr} @ ${provider.vVerificacion![i].anguloGrados.toStringAsFixed(1)}°',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _mostrarDialogoNuevaIteracionManual(context, provider);
              },
              child: const Text('Ingresar Manualmente'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Sí, Usar Valores'),
              onPressed: () {
                provider.nuevaIteracion(provider.vVerificacion!);
                Navigator.pop(context);
                setState(() => _currentPage = 0);
              },
            ),
          ],
        ),
      );
    } else {
      _mostrarDialogoNuevaIteracionManual(context, provider);
    }
  }

  void _mostrarDialogoNuevaIteracionManual(BuildContext context, BalanceoProvider provider) {
    final config = provider.config;
    if (config == null) return;
    
    final numCanales = config.canales.length;
    final ampControllers = List.generate(numCanales, (_) => TextEditingController());
    final faseControllers = List.generate(numCanales, (_) => TextEditingController());
    final unidad = config.unidadStr;

    final List<Color> coloresCanales = [
      const Color(0xFF0D47A1), // Azul industrial
      const Color(0xFFB71C1C), // Rojo rubí
      const Color(0xFF1B5E20), // Verde bosque
      const Color(0xFF4A148C), // Púrpura profundo
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.refresh, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Iteración ${provider.iteracion + 1}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingrese la vibración residual medida tras instalar las masas correctoras de la It. ${provider.iteracion}.',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < numCanales; i++) ...[
                Text(config.canales[i].tag, style: TextStyle(fontWeight: FontWeight.bold, color: coloresCanales[i % coloresCanales.length])),
                const SizedBox(height: 6),
                TextField(
                  controller: ampControllers[i],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Amplitud ($unidad)', border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: faseControllers[i],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Fase (°)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton.icon(
            icon: const Icon(Icons.calculate),
            label: const Text('Recalcular'),
            style: ElevatedButton.styleFrom(),
            onPressed: () {
              List<Complejo> nuevasLecturas = [];
              for (int i = 0; i < numCanales; i++) {
                final amp = double.tryParse(ampControllers[i].text) ?? 0.0;
                final fase = double.tryParse(faseControllers[i].text) ?? 0.0;
                nuevasLecturas.add(Complejo.desdePolar(amp, fase));
              }
              provider.nuevaIteracion(nuevasLecturas);
              Navigator.pop(context);
              setState(() => _currentPage = 0);
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRegistrarVerificacion(BuildContext context, BalanceoProvider provider) {
    final config = provider.config;
    if (config == null) return;
    
    final numCanales = config.canales.length;
    final ampControllers = List.generate(numCanales, (i) {
      double? val = provider.vVerificacion != null && i < provider.vVerificacion!.length
          ? provider.vVerificacion![i].modulo
          : null;
      return TextEditingController(text: val?.toStringAsFixed(2) ?? '');
    });
    final faseControllers = List.generate(numCanales, (i) {
      double? val = provider.vVerificacion != null && i < provider.vVerificacion!.length
          ? provider.vVerificacion![i].anguloGrados
          : null;
      return TextEditingController(text: val?.toStringAsFixed(1) ?? '');
    });
    final unidad = config.unidadStr;

    final List<Color> coloresCanales = [
      const Color(0xFF0D47A1), // Azul industrial
      const Color(0xFFB71C1C), // Rojo rubí
      const Color(0xFF1B5E20), // Verde bosque
      const Color(0xFF4A148C), // Púrpura profundo
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.teal.shade700),
            const SizedBox(width: 8),
            const Text('Registrar Verificación'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingrese la vibración de verificación (final) obtenida después de colocar los pesos de corrección.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < numCanales; i++) ...[
                Text(config.canales[i].tag, style: TextStyle(fontWeight: FontWeight.bold, color: coloresCanales[i % coloresCanales.length])),
                const SizedBox(height: 6),
                TextField(
                  controller: ampControllers[i],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Amplitud ($unidad)', border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: faseControllers[i],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Fase (°)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Registrar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              List<Complejo> lecturasVerif = [];
              for (int i = 0; i < numCanales; i++) {
                final amp = double.tryParse(ampControllers[i].text) ?? 0.0;
                final fase = double.tryParse(faseControllers[i].text) ?? 0.0;
                lecturasVerif.add(Complejo.desdePolar(amp, fase));
              }
              provider.registrarVerificacion(lecturasVerif);
              Navigator.pop(context);
              
              final es2Planos = config.numPlanos == 2;
              int targetIndex = 1;
              if (provider.v1Temp != null && provider.v1Temp!.isNotEmpty) {
                targetIndex++;
              }
              if (es2Planos && provider.v2Temp != null && provider.v2Temp!.isNotEmpty) {
                targetIndex++;
              }
              targetIndex++; // La página de verificación va después de las masas correctoras

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    targetIndex,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAjustarPesoReal(
    BuildContext context,
    BalanceoProvider provider,
    Complejo? m1,
    Complejo? m2,
    bool es2Planos,
  ) {
    final amp1Controller = TextEditingController(
      text: (provider.masaRealInstalada1 ?? m1)?.modulo.toStringAsFixed(2) ?? '',
    );
    final ang1Controller = TextEditingController(
      text: provider.ajustarAngulo((provider.masaRealInstalada1 ?? m1)?.anguloGrados ?? 0).toStringAsFixed(1),
    );
    final amp2Controller = TextEditingController(
      text: (provider.masaRealInstalada2 ?? m2)?.modulo.toStringAsFixed(2) ?? '',
    );
    final ang2Controller = TextEditingController(
      text: provider.ajustarAngulo((provider.masaRealInstalada2 ?? m2)?.anguloGrados ?? 0).toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Ajustar Peso Real Instalado'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingrese los pesos reales que se instalaron en el rotor.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (m1 != null) ...[
                Text(es2Planos ? 'Plano 1' : 'Masa Correctora', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: amp1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Masa (g)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ang1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Ángulo (°)', border: OutlineInputBorder()),
                ),
              ],
              if (es2Planos && m2 != null) ...[
                const SizedBox(height: 16),
                const Text('Plano 2', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: amp2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Masa (g)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ang2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Ángulo (°)', border: OutlineInputBorder()),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (m1 != null) {
                final amp = double.tryParse(amp1Controller.text) ?? 0.0;
                final ang = double.tryParse(ang1Controller.text) ?? 0.0;
                final anguloFisico = provider.config?.sentido == SentidoGiro.horario ? -ang : ang;
                provider.masaRealInstalada1 = Complejo.desdePolar(amp, anguloFisico);
              }
              if (es2Planos && m2 != null) {
                final amp = double.tryParse(amp2Controller.text) ?? 0.0;
                final ang = double.tryParse(ang2Controller.text) ?? 0.0;
                final anguloFisico = provider.config?.sentido == SentidoGiro.horario ? -ang : ang;
                provider.masaRealInstalada2 = Complejo.desdePolar(amp, anguloFisico);
              }
              provider.saveToDisk();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}