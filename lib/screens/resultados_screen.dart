import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balanceo_provider.dart';
import '../widgets/polar_plot.dart';
import '../widgets/resultado_card.dart';
import '../models/complejo.dart';
import '../models/rotor_config.dart';
import '../utils/pdf_export.dart';
import 'guia_screen.dart';
import '../widgets/consolidacion_card.dart';


class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  TextEditingController? _isoPesoController;
  TextEditingController? _isoRpmController;
  TextEditingController? _isoRadioController;

  void _initIsoControllers(RotorConfig config) {
    if (_isoPesoController == null) {
      _isoPesoController = TextEditingController(text: config.pesoRotor?.toString() ?? '');
      _isoRpmController = TextEditingController(text: config.velocidadRPM?.toString() ?? '');
      _isoRadioController = TextEditingController(text: config.radioPeso?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    _isoPesoController?.dispose();
    _isoRpmController?.dispose();
    _isoRadioController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    final es2Planos = provider.config?.numPlanos == 2;
    final iteracion = provider.iteracion;
    final esRefinamiento = iteracion > 1;
    final config = provider.config;
    final esVoladizo = es2Planos && (config?.esVoladizo ?? false);
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
      pageTitles.add(esRefinamiento ? 'PRUEBA ORIGINAL (Ref.)' : (esVoladizo ? 'EFECTO PRUEBA ESTÁTICA' : 'EFECTO PRUEBA P1'));
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
      pageTitles.add(esRefinamiento ? 'PRUEBA P2 ORIGINAL (Ref.)' : (esVoladizo ? 'EFECTO PRUEBA ACOPLE' : 'EFECTO PRUEBA P2'));
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

      final List<Complejo>? initialVectors = provider.v0Original ?? provider.v0;
      if (initialVectors != null) {
        for (int i = 0; i < initialVectors.length; i++) {
          final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
          vVer.add(initialVectors[i]);
          cVer.add(coloresCanales[i % coloresCanales.length].withOpacity(0.3));
          eVer.add('$tag (inicial)');
        }
      }
      for (int i = 0; i < provider.vVerificacion!.length; i++) {
        final tag = (config != null && i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}';
        vVer.add(provider.vVerificacion![i]);
        cVer.add(coloresCanales[i % coloresCanales.length]);
        eVer.add('$tag (final)');
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
                      const Expanded(
                        child: Text(
                          'Masas Correctoras Calculadas',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                  if (esVoladizo) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.precision_manufacturing, color: Colors.blue.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Método: Descomposición Modal Estático-Acople para rotor en voladizo.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                                tooltip: 'Editar',
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
                                Expanded(
                                  child: Text(
                                    'Masa Real Acumulada Previa en Rotor',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                    const SizedBox(height: 8),
                    ConsolidacionCard(
                      masaRecomendada: m1,
                      mAcumuladaPrevia: provider.calcularMasaRealAcumuladaPlano1(),
                      titulo: es2Planos ? 'Plano 1 - Consolidación' : 'Masa Correctora Consolidada',
                      plano: 1,
                    ),
                    if (es2Planos && m2 != null) ...[
                      const SizedBox(height: 8),
                      ConsolidacionCard(
                        masaRecomendada: m2,
                        mAcumuladaPrevia: provider.calcularMasaRealAcumuladaPlano2(),
                        titulo: 'Plano 2 - Consolidación',
                        plano: 2,
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  _buildControlCalidadISOCard(context, provider),
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
                      onPressed: () => _mostrarDialogoRegistrarVibracionResidual(context, provider),
                      icon: const Icon(Icons.insights),
                      label: const Text('Registrar Vibración Residual'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                      ),
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
                                    Expanded(
                                      child: Text(
                                        (i < config.canales.length) ? config.canales[i].tag : 'Sensor ${i + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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

  void _mostrarDialogoRegistrarVibracionResidual(BuildContext context, BalanceoProvider provider) {
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

    Complejo? m1;
    Complejo? m2;
    final es2Planos = config.numPlanos == 2;
    if (es2Planos) {
      final correccion = provider.calcularCorreccion2Planos();
      m1 = correccion[0];
      m2 = correccion[1];
    } else {
      m1 = provider.calcularCorreccion1Plano();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Vibración Residual'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingrese la vibración medida tras instalar las masas correctoras.',
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
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
            onPressed: () {
              List<Complejo> lecturasVerif = [];
              for (int i = 0; i < numCanales; i++) {
                final amp = double.tryParse(ampControllers[i].text) ?? 0.0;
                final fase = double.tryParse(faseControllers[i].text) ?? 0.0;
                lecturasVerif.add(Complejo.desdePolar(amp, fase));
              }
              
              _mostrarDialogoConfirmacionFin(context, provider, lecturasVerif, m1, m2, es2Planos);
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoConfirmacionFin(
    BuildContext context,
    BalanceoProvider provider,
    List<Complejo> lecturasVerif,
    Complejo? m1,
    Complejo? m2,
    bool es2Planos,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Vibración Residual Registrada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Desea dar por concluido el proceso de balanceo con estos valores o prefiere iniciar una nueva iteración de refinamiento?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Valores ingresados:',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < lecturasVerif.length; i++)
              Text(
                '${provider.config?.canales[i].tag ?? 'Sensor ${i + 1}'}: ${lecturasVerif[i].modulo.toStringAsFixed(2)} ${provider.config?.unidadStr ?? 'µm'} @ ${lecturasVerif[i].anguloGrados.toStringAsFixed(1)}°',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver a editar'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refinar (Nueva It.)'),
            onPressed: () {
              Navigator.pop(context); // Cierra confirmación
              Navigator.pop(context); // Cierra diálogo de entrada
              provider.nuevaIteracion(lecturasVerif);
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nueva iteración iniciada')),
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.verified),
            label: const Text('Concluir Balanceo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Cierra confirmación
              Navigator.pop(context); // Cierra diálogo de entrada
              provider.registrarVerificacion(lecturasVerif);
              
              final residuales = lecturasVerif.map((v) => v.modulo).toList();
              provider.agregarAlHistorial(
                m1, m2,
                residuales,
                mReal1: provider.masaRealInstalada1 ?? m1,
                mReal2: provider.masaRealInstalada2 ?? m2,
                vibracionesComplejas: lecturasVerif,
              );
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  final es2PlanosVal = provider.config?.numPlanos == 2;
                  int targetIndex = 1;
                  if (provider.v1Temp != null && provider.v1Temp!.isNotEmpty) {
                    targetIndex++;
                  }
                  if (es2PlanosVal && provider.v2Temp != null && provider.v2Temp!.isNotEmpty) {
                    targetIndex++;
                  }
                  targetIndex++;
                  
                  _pageController.animateToPage(
                    targetIndex,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Balanceo concluido. Reporte PDF listo.')),
              );
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
    final config = provider.config;
    final esDiscreto = config?.tipo == TipoRotor.discreto && (config?.numAlabes ?? 0) > 1;

    final division1 = esDiscreto && m1 != null ? provider.calcularDivisionPesos(m1) : null;
    final division2 = esDiscreto && es2Planos && m2 != null ? provider.calcularDivisionPesos(m2) : null;

    final amp1Controller = TextEditingController(
      text: (provider.masaRealInstalada1 ?? m1)?.modulo.toStringAsFixed(2) ?? '',
    );
    final ang1Controller = TextEditingController(
      text: provider.ajustarAngulo((provider.masaRealInstalada1 ?? m1)?.anguloGrados ?? 0).toStringAsFixed(1),
    );

    final ampA1Controller = TextEditingController(
      text: division1 != null ? division1['masaA'].toStringAsFixed(2) : '',
    );
    final ampB1Controller = TextEditingController(
      text: division1 != null ? division1['masaB'].toStringAsFixed(2) : '',
    );

    final amp2Controller = TextEditingController(
      text: (provider.masaRealInstalada2 ?? m2)?.modulo.toStringAsFixed(2) ?? '',
    );
    final ang2Controller = TextEditingController(
      text: provider.ajustarAngulo((provider.masaRealInstalada2 ?? m2)?.anguloGrados ?? 0).toStringAsFixed(1),
    );

    final ampA2Controller = TextEditingController(
      text: division2 != null ? division2['masaA'].toStringAsFixed(2) : '',
    );
    final ampB2Controller = TextEditingController(
      text: division2 != null ? division2['masaB'].toStringAsFixed(2) : '',
    );

    final mAcumuladaPrevia1 = provider.calcularMasaRealAcumuladaPlano1();
    final mAcumuladaPrevia2 = provider.calcularMasaRealAcumuladaPlano2();
    final esRefinamiento = provider.iteracion > 1;

    bool registrarPorAlabes = false;
    bool registrarComoConsolidado = false;

    void actualizarCampos(bool comoConsolidado, bool porAlabes) {
      if (m1 != null) {
        final v1 = comoConsolidado
            ? (mAcumuladaPrevia1 + (provider.masaRealInstalada1 ?? m1))
            : (provider.masaRealInstalada1 ?? m1);
        if (porAlabes) {
          final div1 = provider.calcularDivisionPesos(v1);
          if (div1 != null) {
            ampA1Controller.text = div1['masaA'].toStringAsFixed(2);
            ampB1Controller.text = div1['masaB'].toStringAsFixed(2);
          } else {
            ampA1Controller.text = '';
            ampB1Controller.text = '';
          }
        } else {
          amp1Controller.text = v1.modulo.toStringAsFixed(2);
          ang1Controller.text = provider.ajustarAngulo(v1.anguloGrados).toStringAsFixed(1);
        }
      }
      if (es2Planos && m2 != null) {
        final v2 = comoConsolidado
            ? (mAcumuladaPrevia2 + (provider.masaRealInstalada2 ?? m2))
            : (provider.masaRealInstalada2 ?? m2);
        if (porAlabes) {
          final div2 = provider.calcularDivisionPesos(v2);
          if (div2 != null) {
            ampA2Controller.text = div2['masaA'].toStringAsFixed(2);
            ampB2Controller.text = div2['masaB'].toStringAsFixed(2);
          } else {
            ampA2Controller.text = '';
            ampB2Controller.text = '';
          }
        } else {
          amp2Controller.text = v2.modulo.toStringAsFixed(2);
          ang2Controller.text = provider.ajustarAngulo(v2.anguloGrados).toStringAsFixed(1);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final v1 = m1 != null
              ? (registrarComoConsolidado
                  ? (mAcumuladaPrevia1 + (provider.masaRealInstalada1 ?? m1))
                  : (provider.masaRealInstalada1 ?? m1))
              : null;
          final activeDivision1 = esDiscreto && v1 != null ? provider.calcularDivisionPesos(v1) : null;

          final v2 = es2Planos && m2 != null
              ? (registrarComoConsolidado
                  ? (mAcumuladaPrevia2 + (provider.masaRealInstalada2 ?? m2))
                  : (provider.masaRealInstalada2 ?? m2))
              : null;
          final activeDivision2 = esDiscreto && es2Planos && v2 != null ? provider.calcularDivisionPesos(v2) : null;

          return AlertDialog(
            title: const Text('Ajustar Peso Real'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingrese los pesos reales que se instalaron en el rotor.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (esDiscreto) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Registrar por división de álabes', style: TextStyle(fontSize: 14)),
                      value: registrarPorAlabes,
                      onChanged: (val) {
                        setState(() {
                          registrarPorAlabes = val ?? false;
                          actualizarCampos(registrarComoConsolidado, registrarPorAlabes);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (esRefinamiento) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Registrar peso como consolidado', style: TextStyle(fontSize: 14)),
                      subtitle: const Text(
                        'Los valores ingresados representan el peso total final que quedará en el rotor (se restará el peso previo automáticamente).',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: registrarComoConsolidado,
                      onChanged: (val) {
                        setState(() {
                          registrarComoConsolidado = val ?? false;
                          actualizarCampos(registrarComoConsolidado, registrarPorAlabes);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (m1 != null) ...[
                    Text(es2Planos ? 'Plano 1' : 'Masa Correctora', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (registrarPorAlabes && activeDivision1 != null) ...[
                      Text('Montaje dividido en álabes adyacentes ${activeDivision1['alabeA']} y ${activeDivision1['alabeB']}:',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ampA1Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Masa Álabe N° ${activeDivision1['alabeA']} (g)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ampB1Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Masa Álabe N° ${activeDivision1['alabeB']} (g)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
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
                  ],
                  if (es2Planos && m2 != null) ...[
                    const SizedBox(height: 16),
                    Text('Plano 2', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (registrarPorAlabes && activeDivision2 != null) ...[
                      Text('Montaje dividido en álabes adyacentes ${activeDivision2['alabeA']} y ${activeDivision2['alabeB']}:',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ampA2Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Masa Álabe N° ${activeDivision2['alabeA']} (g)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ampB2Controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Masa Álabe N° ${activeDivision2['alabeB']} (g)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
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
                    Complejo vInstalado1;
                    if (registrarPorAlabes && activeDivision1 != null) {
                      final valA = double.tryParse(ampA1Controller.text) ?? 0.0;
                      final valB = double.tryParse(ampB1Controller.text) ?? 0.0;
                      vInstalado1 = provider.calcularMasaEquivalenteDivision(
                        masaA: valA,
                        alabeA: activeDivision1['alabeA'],
                        masaB: valB,
                        alabeB: activeDivision1['alabeB'],
                      );
                    } else {
                      final amp = double.tryParse(amp1Controller.text) ?? 0.0;
                      final ang = double.tryParse(ang1Controller.text) ?? 0.0;
                      final anguloFisico = provider.config?.sentido == SentidoGiro.horario ? -ang : ang;
                      vInstalado1 = Complejo.desdePolar(amp, anguloFisico);
                    }

                    if (registrarComoConsolidado) {
                      provider.masaRealInstalada1 = vInstalado1 - mAcumuladaPrevia1;
                    } else {
                      provider.masaRealInstalada1 = vInstalado1;
                    }
                  }
                  if (es2Planos && m2 != null) {
                    Complejo vInstalado2;
                    if (registrarPorAlabes && activeDivision2 != null) {
                      final valA = double.tryParse(ampA2Controller.text) ?? 0.0;
                      final valB = double.tryParse(ampB2Controller.text) ?? 0.0;
                      vInstalado2 = provider.calcularMasaEquivalenteDivision(
                        masaA: valA,
                        alabeA: activeDivision2['alabeA'],
                        masaB: valB,
                        alabeB: activeDivision2['alabeB'],
                      );
                    } else {
                      final amp = double.tryParse(amp2Controller.text) ?? 0.0;
                      final ang = double.tryParse(ang2Controller.text) ?? 0.0;
                      final anguloFisico = provider.config?.sentido == SentidoGiro.horario ? -ang : ang;
                      vInstalado2 = Complejo.desdePolar(amp, anguloFisico);
                    }

                    if (registrarComoConsolidado) {
                      provider.masaRealInstalada2 = vInstalado2 - mAcumuladaPrevia2;
                    } else {
                      provider.masaRealInstalada2 = vInstalado2;
                    }
                  }
                  provider.saveToDisk();
                  Navigator.pop(context);
                  this.setState(() {}); // Rebuild parent screen to show updated Masa Real
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlCalidadISOCard(BuildContext context, BalanceoProvider provider) {
    final config = provider.config;
    if (config == null) return const SizedBox.shrink();

    final isIsoEnabled = config.gradoISO != null;
    _initIsoControllers(config);

    final resultados = provider.calcularISO1940();
    final cumpleTodo = resultados != null && resultados['cumpleTodo'] == true;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isIsoEnabled
              ? (cumpleTodo ? Colors.green.shade300 : Colors.red.shade300)
              : Colors.grey.shade300,
          width: isIsoEnabled ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isIsoEnabled ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                      color: isIsoEnabled
                          ? (cumpleTodo ? Colors.green.shade700 : Colors.red.shade700)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Control de Calidad ISO 1940',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Switch(
                  key: const Key('iso_switch'),
                  value: isIsoEnabled,
                  onChanged: (val) {
                    if (val) {
                      provider.setGradoISO('G2.5');
                      setState(() {
                        _isoPesoController?.text = provider.config?.pesoRotor?.toString() ?? '';
                        _isoRpmController?.text = provider.config?.velocidadRPM?.toString() ?? '';
                        _isoRadioController?.text = provider.config?.radioPeso?.toString() ?? '';
                      });
                    } else {
                      provider.setGradoISO(null);
                    }
                  },
                  activeColor: Colors.teal.shade700,
                ),
              ],
            ),
            if (!isIsoEnabled) ...[
              const SizedBox(height: 8),
              Text(
                'Habilite esta sección para validar si el desbalance residual final del rotor cumple con las tolerancias admisibles bajo la norma ISO 1940-1.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Dropdown de Grado ISO
              DropdownButtonFormField<String>(
                key: const Key('iso_grade_dropdown'),
                isExpanded: true,
                value: config.gradoISO,
                decoration: const InputDecoration(
                  labelText: 'Grado de Calidad (G)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'G0.4', child: Text('G0.4 - Husillos, rectificadoras de precisión')),
                  DropdownMenuItem(value: 'G1.0', child: Text('G1.0 - Turbinas, sopladores rápidos')),
                  DropdownMenuItem(value: 'G2.5', child: Text('G2.5 - Ventiladores, bombas, inducidos')),
                  DropdownMenuItem(value: 'G6.3', child: Text('G6.3 - Engranajes, turbomáquinas grales.')),
                  DropdownMenuItem(value: 'G16', child: Text('G16 - Ejes cardán, partes agrícolas')),
                  DropdownMenuItem(value: 'G40', child: Text('G40 - Llantas, cigüeñales de autos')),
                ],
                onChanged: (val) {
                  provider.setGradoISO(val);
                },
              ),
              const SizedBox(height: 16),

              // Parámetros Físicos
              const Text(
                'Parámetros del Rotor',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('iso_peso_field'),
                      controller: _isoPesoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        provider.updateISOParams(peso: parsed);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: const Key('iso_rpm_field'),
                      controller: _isoRpmController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'RPM',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        provider.updateISOParams(rpm: parsed);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: const Key('iso_radio_field'),
                      controller: _isoRadioController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Radio (mm)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        provider.updateISOParams(radio: parsed);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Detalles de Cálculos
              _buildCalculosISODetalles(provider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalculosISODetalles(BalanceoProvider provider) {
    final resultados = provider.calcularISO1940();
    
    if (resultados == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ingrese valores válidos para Peso, RPM y Radio, y asegúrese de registrar el peso de prueba para realizar los cálculos de la norma.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }

    final double ePer = resultados['ePer'];
    final double uPerPlane = resultados['uPerPlane'];
    final double mPerPlane = resultados['mPerPlane'];
    
    final double s1 = resultados['s1'];
    final double uResidual1 = resultados['uResidual1'];
    final double mResidual1 = resultados['mResidual1'];
    final bool cumple1 = resultados['cumple1'];

    final bool es2Planos = provider.config?.numPlanos == 2;
    
    final double? s2 = resultados['s2'];
    final double? uResidual2 = resultados['uResidual2'];
    final double? mResidual2 = resultados['mResidual2'];
    final bool? cumple2 = resultados['cumple2'];
    final bool cumpleTodo = resultados['cumpleTodo'];

    final String gradoStr = provider.config!.gradoISO!;
    final String unidadStr = provider.config!.unidadStr;

    return Column(
      key: const Key('iso_results_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        
        // Badge de conformidad
        Center(
          child: Container(
            key: const Key('iso_compliance_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cumpleTodo ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cumpleTodo ? Colors.green : Colors.red, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cumpleTodo ? Icons.check_circle : Icons.cancel,
                  color: cumpleTodo ? Colors.green.shade800 : Colors.red.shade800,
                ),
                const SizedBox(width: 8),
                Text(
                  cumpleTodo
                      ? 'CUMPLE CON ISO $gradoStr'
                      : 'NO CUMPLE CON ISO $gradoStr',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: cumpleTodo ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Límites de Tolerancia
        const Text(
          'Límites Tolerables (ISO 1940-1)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
        ),
        const SizedBox(height: 6),
        _buildDetailRow('Desbalance específico permitido (eper):', '${ePer.toStringAsFixed(2)} g-mm/kg'),
        _buildDetailRow('Desbalance admisible por plano (Uper):', '${uPerPlane.toStringAsFixed(1)} g-mm'),
        _buildDetailRow('Masa límite admisible en radio r:', '${mPerPlane.toStringAsFixed(2)} g'),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),

        // Resultados Plano 1
        Text(
          es2Planos ? 'Resultados Plano 1' : 'Resultados de Desbalance Residual',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
        ),
        const SizedBox(height: 6),
        _buildDetailRow('Sensibilidad S1:', '${s1.toStringAsFixed(2)} g-mm/${unidadStr}'),
        _buildDetailRow('Desbalance residual U1:', '${uResidual1.toStringAsFixed(1)} g-mm', boldVal: true),
        _buildDetailRow('Masa residual equivalente:', '${mResidual1.toStringAsFixed(2)} g'),
        _buildStatusRow('Estado Plano 1:', cumple1),

        if (es2Planos && s2 != null && uResidual2 != null && mResidual2 != null && cumple2 != null) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          
          // Resultados Plano 2
          const Text(
            'Resultados Plano 2',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
          ),
          const SizedBox(height: 6),
          _buildDetailRow('Sensibilidad S2:', '${s2.toStringAsFixed(2)} g-mm/${unidadStr}'),
          _buildDetailRow('Desbalance residual U2:', '${uResidual2.toStringAsFixed(1)} g-mm', boldVal: true),
          _buildDetailRow('Masa residual equivalente:', '${mResidual2.toStringAsFixed(2)} g'),
          _buildStatusRow('Estado Plano 2:', cumple2),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool boldVal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: boldVal ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool cumple) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cumple ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: cumple ? Colors.green : Colors.red),
            ),
            child: Text(
              cumple ? 'CUMPLE' : 'FUERA DE NORMA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cumple ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}