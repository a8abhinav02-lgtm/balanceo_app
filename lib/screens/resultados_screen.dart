import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balanceo_provider.dart';
import '../widgets/polar_plot.dart';
import '../widgets/resultado_card.dart';
import '../models/complejo.dart';
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
    // En It.1: mostramos v0 original.
    // En It.2+: mostramos v0 actual (residual) pero mantenemos referencia al original.
    List<Complejo> vIni = [];
    List<Color> cIni = [];
    List<String> eIni = [];

    if (esRefinamiento) {
      // Mostrar primero el vector original (estado sucio) con opacidad diferenciada
      if (provider.v0_1_original != null) {
        vIni.add(provider.v0_1_original!);
        cIni.add(const Color(0xFF0D47A1).withAlpha(100));
        eIni.add('Sensor X (orig.)');
      }
      if (provider.v0_2_original != null) {
        vIni.add(provider.v0_2_original!);
        cIni.add(const Color(0xFFB71C1C).withAlpha(100));
        eIni.add('Sensor Y (orig.)');
      }
      // Luego el residual actual (más intenso)
      if (provider.v0_1 != null) {
        vIni.add(provider.v0_1!);
        cIni.add(const Color(0xFF0D47A1));
        eIni.add('Sensor X (It.${iteracion - 1})');
      }
      if (provider.v0_2 != null) {
        vIni.add(provider.v0_2!);
        cIni.add(const Color(0xFFB71C1C));
        eIni.add('Sensor Y (It.${iteracion - 1})');
      }
    } else {
      if (provider.v0_1 != null) { vIni.add(provider.v0_1!); cIni.add(const Color(0xFF0D47A1)); eIni.add('Sensor 1 (X)'); }
      if (provider.v0_2 != null) { vIni.add(provider.v0_2!); cIni.add(const Color(0xFFB71C1C)); eIni.add('Sensor 2 (Y)'); }
    }


    double maxAmpIni = vIni.isEmpty ? 10.0 : vIni.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    pages.add(Center(child: PolarPlot(vectores: vIni, colores: cIni, etiquetas: eIni, maxRadio: maxAmpIni * 1.2)));
    pageTitles.add(esRefinamiento ? 'RESIDUAL — It.${iteracion - 1}' : 'ESTADO INICIAL');

    // Página 2: Efecto Prueba P1 (siempre visible — datos históricos en It.2+)
    if (provider.v1_1_temp != null) {
      // En refinamiento, tomamos como base el estado sucio original para comparar
      final List<Complejo> baseVecs = esRefinamiento
          ? [
              if (provider.v0_1_original != null) provider.v0_1_original!,
              if (provider.v0_2_original != null) provider.v0_2_original!,
            ]
          : List.from(vIni.take(2));  // solo v0_1 y v0_2 sin residuales
      final List<Color> baseCols = esRefinamiento
          ? [
              if (provider.v0_1_original != null) const Color(0xFF0D47A1).withAlpha(100),
              if (provider.v0_2_original != null) const Color(0xFFB71C1C).withAlpha(100),
            ]
          : cIni.take(2).toList();
      final List<String> baseEtqs = esRefinamiento
          ? [
              if (provider.v0_1_original != null) 'Sensor X (orig.)',
              if (provider.v0_2_original != null) 'Sensor Y (orig.)',
            ]
          : eIni.take(2).toList();

      List<Complejo> vP1 = List.from(baseVecs);
      List<Color> cP1 = List.from(baseCols);
      List<String> eP1 = List.from(baseEtqs);

      if (provider.v1_1_temp != null) { vP1.add(provider.v1_1_temp!); cP1.add(const Color(0xFF00C8FF)); eP1.add('Sens X w/Prueba'); }
      if (provider.v1_2_temp != null) { vP1.add(provider.v1_2_temp!); cP1.add(const Color(0xFFFF007F)); eP1.add('Sens Y w/Prueba'); }


      final List<MasaMarker> masasP1 = [];
      if (provider.mt1_temp != null) {
        masasP1.add(MasaMarker(masa: provider.mt1_temp!, color: Colors.grey.shade700, etiqueta: 'Masa Prueba 1'));
      }

      double maxAmpP1 = vP1.isEmpty ? 10.0 : vP1.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
      pages.add(Center(child: PolarPlot(vectores: vP1, colores: cP1, etiquetas: eP1, maxRadio: maxAmpP1 * 1.2, masas: masasP1)));
      pageTitles.add(esRefinamiento ? 'PRUEBA ORIGINAL (Ref.)' : 'EFECTO PRUEBA P1');
    }

    // Página 3: Efecto Prueba P2 (si aplica — igualmente histórico en It.2+)
    if (es2Planos && provider.v2_1_temp != null) {
      final List<Complejo> baseVecs2 = esRefinamiento
          ? [
              if (provider.v0_1_original != null) provider.v0_1_original!,
              if (provider.v0_2_original != null) provider.v0_2_original!,
            ]
          : [
              if (provider.v0_1 != null) provider.v0_1!,
              if (provider.v0_2 != null) provider.v0_2!,
            ];
      final List<Color> baseCols2 = esRefinamiento
          ? [
              if (provider.v0_1_original != null) const Color(0xFF0D47A1).withAlpha(100),
              if (provider.v0_2_original != null) const Color(0xFFB71C1C).withAlpha(100),
            ]
          : [
              if (provider.v0_1 != null) const Color(0xFF0D47A1),
              if (provider.v0_2 != null) const Color(0xFFB71C1C),
            ];
      final List<String> baseEtqs2 = esRefinamiento
          ? [
              if (provider.v0_1_original != null) 'Sensor X (orig.)',
              if (provider.v0_2_original != null) 'Sensor Y (orig.)',
            ]
          : [
              if (provider.v0_1 != null) 'Sensor 1 (X)',
              if (provider.v0_2 != null) 'Sensor 2 (Y)',
            ];

      List<Complejo> vP2 = List.from(baseVecs2);
      List<Color> cP2 = List.from(baseCols2);
      List<String> eP2 = List.from(baseEtqs2);

      if (provider.v2_1_temp != null) { vP2.add(provider.v2_1_temp!); cP2.add(const Color(0xFF00C8FF)); eP2.add('Sens X w/Prueba P2'); }
      if (provider.v2_2_temp != null) { vP2.add(provider.v2_2_temp!); cP2.add(const Color(0xFFFF007F)); eP2.add('Sens Y w/Prueba P2'); }


      final List<MasaMarker> masasP2 = [];
      if (provider.mt2_temp != null) {
        masasP2.add(MasaMarker(masa: provider.mt2_temp!, color: Colors.grey.shade700, etiqueta: 'Masa Prueba 2'));
      }

      double maxAmpP2 = vP2.isEmpty ? 10.0 : vP2.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
      pages.add(Center(child: PolarPlot(vectores: vP2, colores: cP2, etiquetas: eP2, maxRadio: maxAmpP2 * 1.2, masas: masasP2)));
      pageTitles.add(esRefinamiento ? 'PRUEBA P2 ORIGINAL (Ref.)' : 'EFECTO PRUEBA P2');
    }

    // Última página: Masas Correctoras
    // En It.2+: mostrar tanto el original como el residual para ver la evolución
    List<Complejo> vFin = [];
    List<Color> cFin = [];
    List<String> eFin = [];

    if (esRefinamiento) {
      if (provider.v0_1_original != null) { vFin.add(provider.v0_1_original!); cFin.add(const Color(0xFF0D47A1).withAlpha(100)); eFin.add('Sensor X (orig.)'); }
      if (provider.v0_2_original != null) { vFin.add(provider.v0_2_original!); cFin.add(const Color(0xFFB71C1C).withAlpha(100)); eFin.add('Sensor Y (orig.)'); }
      if (provider.v0_1 != null) { vFin.add(provider.v0_1!); cFin.add(const Color(0xFF0D47A1)); eFin.add('Sensor X (It.${iteracion - 1})'); }
      if (provider.v0_2 != null) { vFin.add(provider.v0_2!); cFin.add(const Color(0xFFB71C1C)); eFin.add('Sensor Y (It.${iteracion - 1})'); }
    } else {
      if (provider.v0_1 != null) { vFin.add(provider.v0_1!); cFin.add(const Color(0xFF0D47A1)); eFin.add('Sensor 1 (X)'); }
      if (provider.v0_2 != null) { vFin.add(provider.v0_2!); cFin.add(const Color(0xFFB71C1C)); eFin.add('Sensor 2 (Y)'); }
    }


    final List<MasaMarker> masasCorr = [];
    if (m1 != null) { masasCorr.add(MasaMarker(masa: m1, color: Colors.green.shade700, etiqueta: 'Masa P1')); }
    if (es2Planos && m2 != null) { masasCorr.add(MasaMarker(masa: m2, color: Colors.orange.shade800, etiqueta: 'Masa P2')); }

    double maxAmpFin = vFin.isEmpty ? 10.0 : vFin.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    pages.add(Center(child: PolarPlot(vectores: vFin, colores: cFin, etiquetas: eFin, maxRadio: maxAmpFin * 1.2, masas: masasCorr)));
    pageTitles.add(esRefinamiento ? 'MASAS CORRECTORAS — It.$iteracion' : 'MASAS CORRECTORAS');

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
                      onPressed: () => _mostrarDialogoNuevaIteracion(context, provider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Nueva Iteración (Refinar)'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
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
                    provider.agregarAlHistorial(m1, m2, provider.sensor1Actual?.modulo ?? 0, provider.sensor2Actual?.modulo ?? 0);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en historial')));
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoNuevaIteracion(BuildContext context, BalanceoProvider provider) {
    final amp1Controller = TextEditingController();
    final fase1Controller = TextEditingController();
    final amp2Controller = TextEditingController();
    final fase2Controller = TextEditingController();
    final unidad = provider.config?.unidadStr ?? 'µm';

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
              const Text('Sensor 1 (X)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 6),
              TextField(
                controller: amp1Controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amplitud ($unidad)', border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fase1Controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Fase (°)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Sensor 2 (Y)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 6),
              TextField(
                controller: amp2Controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amplitud ($unidad)', border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fase2Controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Fase (°)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton.icon(
            icon: const Icon(Icons.calculate),
            label: const Text('Recalcular'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              final v1 = Complejo.desdePolar(
                double.tryParse(amp1Controller.text) ?? 0,
                double.tryParse(fase1Controller.text) ?? 0,
              );
              final v2 = Complejo.desdePolar(
                double.tryParse(amp2Controller.text) ?? 0,
                double.tryParse(fase2Controller.text) ?? 0,
              );
              provider.nuevaIteracion(v1, v2);
              Navigator.pop(context);
              setState(() => _currentPage = 0);
            },
          ),
        ],
      ),
    );
  }
}