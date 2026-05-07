import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balanceo_provider.dart';
import '../widgets/polar_plot.dart';
import '../widgets/resultado_card.dart';
import '../models/complejo.dart';
import '../utils/pdf_export.dart';

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

    Complejo? m1;
    Complejo? m2;

    if (es2Planos) {
      final correccion = provider.calcularCorreccion2Planos();
      m1 = correccion[0];
      m2 = correccion[1];
    } else {
      m1 = provider.calcularCorreccion1Plano();
    }

    // Construir páginas del carrusel
    List<Widget> pages = [];
    List<String> pageTitles = [];

    // 1. Estado Inicial
    List<Complejo> vIni = [];
    List<Color> cIni = [];
    List<String> eIni = [];
    if (provider.v0_1 != null) { vIni.add(provider.v0_1!); cIni.add(Colors.blue); eIni.add('Sensor 1 (X)'); }
    if (provider.v0_2 != null) { vIni.add(provider.v0_2!); cIni.add(Colors.red); eIni.add('Sensor 2 (Y)'); }
    double maxAmpIni = vIni.isEmpty ? 10.0 : vIni.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    pages.add(Center(child: PolarPlot(vectores: vIni, colores: cIni, etiquetas: eIni, maxRadio: maxAmpIni * 1.2)));
    pageTitles.add("ESTADO INICIAL");

    // 2. Efecto Prueba P1
    if (provider.v1_1_temp != null) {
      List<Complejo> vP1 = List.from(vIni);
      List<Color> cP1 = List.from(cIni);
      List<String> eP1 = List.from(eIni);
      
      // Vibration vectors for P1 trial (no mass in vectors list)
      if (provider.v1_1_temp != null) { vP1.add(provider.v1_1_temp!); cP1.add(Colors.lightBlue); eP1.add('Sens 1 (X) w/P1'); }
      if (provider.v1_2_temp != null) { vP1.add(provider.v1_2_temp!); cP1.add(Colors.pink); eP1.add('Sens 2 (Y) w/P1'); }

      // Mass marker for trial mass P1
      final List<MasaMarker> masasP1 = [];
      if (provider.mt1_temp != null) {
        masasP1.add(MasaMarker(masa: provider.mt1_temp!, color: Colors.grey.shade700, etiqueta: 'Masa Prueba 1'));
      }

      double maxAmpP1 = vP1.isEmpty ? 10.0 : vP1.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
      pages.add(Center(child: PolarPlot(vectores: vP1, colores: cP1, etiquetas: eP1, maxRadio: maxAmpP1 * 1.2, masas: masasP1)));
      pageTitles.add("EFECTO PRUEBA P1");
    }

    // 3. Efecto Prueba P2 (si aplica)
    if (es2Planos && provider.v2_1_temp != null) {
      List<Complejo> vP2 = List.from(vIni);
      List<Color> cP2 = List.from(cIni);
      List<String> eP2 = List.from(eIni);
      
      // Vibration vectors for P2 trial (no mass in vectors list)
      if (provider.v2_1_temp != null) { vP2.add(provider.v2_1_temp!); cP2.add(Colors.lightBlue); eP2.add('Sens 1 (X) w/P2'); }
      if (provider.v2_2_temp != null) { vP2.add(provider.v2_2_temp!); cP2.add(Colors.pink); eP2.add('Sens 2 (Y) w/P2'); }

      // Mass marker for trial mass P2
      final List<MasaMarker> masasP2 = [];
      if (provider.mt2_temp != null) {
        masasP2.add(MasaMarker(masa: provider.mt2_temp!, color: Colors.grey.shade700, etiqueta: 'Masa Prueba 2'));
      }

      double maxAmpP2 = vP2.isEmpty ? 10.0 : vP2.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
      pages.add(Center(child: PolarPlot(vectores: vP2, colores: cP2, etiquetas: eP2, maxRadio: maxAmpP2 * 1.2, masas: masasP2)));
      pageTitles.add("EFECTO PRUEBA P2");
    }

    // 4. Masas Correctoras (Solución)
    List<Complejo> vFin = List.from(vIni);
    List<Color> cFin = List.from(cIni);
    List<String> eFin = List.from(eIni);
    // Correction masses — rendered as markers, NOT added to vectores
    final List<MasaMarker> masasCorr = [];
    if (m1 != null) { masasCorr.add(MasaMarker(masa: m1, color: Colors.green.shade700, etiqueta: 'Masa P1')); }
    if (es2Planos && m2 != null) { masasCorr.add(MasaMarker(masa: m2, color: Colors.orange.shade800, etiqueta: 'Masa P2')); }

    // Scale only from vibration vectors in the final view
    double maxAmpFin = vFin.isEmpty ? 10.0 : vFin.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    pages.add(Center(child: PolarPlot(vectores: vFin, colores: cFin, etiquetas: eFin, maxRadio: maxAmpFin * 1.2, masas: masasCorr)));
    pageTitles.add("MASAS CORRECTORAS");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados del Balanceo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Reporte', onPressed: () => PdfExport.imprimirReporte(provider)),
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
                  const Text('Masas Correctoras Calculadas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ResultadoCard(masa: m1, titulo: es2Planos ? 'Plano 1' : 'Masa Correctora', numeroPlano: 1),
                  if (es2Planos && m2 != null) ResultadoCard(masa: m2, titulo: 'Plano 2', numeroPlano: 2),
                ],
              ),
            ),
            const Divider(),
            
            // Sección Evolución Vectorial con Header Robusto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left), 
                    onPressed: _currentPage == 0 ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  ),
                  Expanded(
                    child: Text(
                      '${_currentPage + 1}/${pages.length} - ${pageTitles[_currentPage]}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right), 
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
                  onPressed: () => Navigator.pop(context),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Medición'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingrese la vibración actual tras instalar las masas:'),
              const SizedBox(height: 16),
              TextField(controller: amp1Controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Sensor 1 (X) - Amplitud (${provider.config?.unidadStr ?? 'µm'})')),
              const SizedBox(height: 8),
              TextField(controller: fase1Controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Sensor 1 (X) - Fase (°)')),
              const SizedBox(height: 8),
              TextField(controller: amp2Controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Sensor 2 (Y) - Amplitud (${provider.config?.unidadStr ?? 'µm'})')),
              const SizedBox(height: 8),
              TextField(controller: fase2Controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Sensor 2 (Y) - Fase (°)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final v1 = Complejo.desdePolar(double.tryParse(amp1Controller.text) ?? 0, double.tryParse(fase1Controller.text) ?? 0);
              final v2 = Complejo.desdePolar(double.tryParse(amp2Controller.text) ?? 0, double.tryParse(fase2Controller.text) ?? 0);
              provider.nuevaIteracion(v1, v2);
              Navigator.pop(context);
              // Tras refinar, nos aseguramos de volver al principio
              setState(() => _currentPage = 0);
            },
            child: const Text('Recalcular'),
          ),
        ],
      ),
    );
  }
}