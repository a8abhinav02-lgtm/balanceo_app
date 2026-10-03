import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';
import '../widgets/polar_plot.dart';

class GraficadorManualScreen extends StatefulWidget {
  const GraficadorManualScreen({super.key});

  @override
  State<GraficadorManualScreen> createState() => _GraficadorManualScreenState();
}

class _GraficadorManualScreenState extends State<GraficadorManualScreen> {
  final _mc1MasaController = TextEditingController();
  final _mc1FaseController = TextEditingController();

  final _mc2MasaController = TextEditingController();
  final _mc2FaseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BalanceoProvider>(context, listen: false);

    if (provider.mc1Manual != null) {
      _mc1MasaController.text = provider.mc1Manual!.modulo.toString();
      _mc1FaseController.text = provider.mc1Manual!.anguloGrados.toString();
    }

    if (provider.mc2Manual != null) {
      _mc2MasaController.text = provider.mc2Manual!.modulo.toString();
      _mc2FaseController.text = provider.mc2Manual!.anguloGrados.toString();
    }

    _mc1MasaController.addListener(_updateView);
    _mc1FaseController.addListener(_updateView);
    _mc2MasaController.addListener(_updateView);
    _mc2FaseController.addListener(_updateView);
  }

  void _updateView() {
    setState(() {});
  }

  @override
  void dispose() {
    _mc1MasaController.dispose();
    _mc1FaseController.dispose();
    _mc2MasaController.dispose();
    _mc2FaseController.dispose();
    super.dispose();
  }

  void _guardarEstadoProvider() {
    final provider = Provider.of<BalanceoProvider>(context, listen: false);

    final m1 = double.tryParse(_mc1MasaController.text);
    final f1 = double.tryParse(_mc1FaseController.text);
    if (m1 != null && f1 != null) {
      provider.mc1Manual = Complejo.desdePolar(m1, f1);
    } else {
      provider.mc1Manual = null;
    }

    final m2 = double.tryParse(_mc2MasaController.text);
    final f2 = double.tryParse(_mc2FaseController.text);
    if (m2 != null && f2 != null) {
      provider.mc2Manual = Complejo.desdePolar(m2, f2);
    } else {
      provider.mc2Manual = null;
    }

    provider.saveToDisk();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    final is2Planos = (provider.config?.numPlanos ?? 1) == 2;
    final unidadVib = provider.config?.unidadStr ?? 'µm';
    final unidadPeso = 'g';
    final numCanales = provider.config?.canales.length ?? 1;

    // Vectores para la gráfica polar
    final List<Complejo> previewVectores = [];
    final List<Color> previewColores = [];
    final List<String> previewEtiquetas = [];
    final List<MasaMarker> previewMasas = [];

    // Colors
    final List<Color> _colorsV0 = const [Color(0xFF0D47A1), Color(0xFFB71C1C)];
    final List<Color> _colorsV1 = const [Color(0xFF0288D1), Color(0xFFC2185B)];
    final List<Color> _colorsV2 = const [Color(0xFF009688), Color(0xFFE65100)];

    // V0
    if (provider.v0 != null) {
      for (int i = 0; i < provider.v0!.length && i < numCanales; i++) {
        final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
        previewVectores.add(provider.v0![i]);
        previewColores.add(_colorsV0[i % _colorsV0.length]);
        previewEtiquetas.add('V0 ($tag)');
      }
    }

    // Mt1 & V1
    if (provider.mt1Temp != null) {
      previewMasas.add(MasaMarker(
        masa: provider.mt1Temp!,
        color: Colors.grey.shade700,
        etiqueta: 'Mt1 (${provider.mt1Temp!.modulo.toStringAsFixed(1)}$unidadPeso @ ${provider.mt1Temp!.anguloGrados.toStringAsFixed(1)}°)',
      ));
    }

    if (provider.v1Temp != null) {
      for (int i = 0; i < provider.v1Temp!.length && i < numCanales; i++) {
        final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
        previewVectores.add(provider.v1Temp![i]);
        previewColores.add(_colorsV1[i % _colorsV1.length]);
        previewEtiquetas.add('V1 P1 ($tag)');
      }
    }

    // Mt2 & V2
    if (is2Planos) {
      if (provider.mt2Temp != null) {
        previewMasas.add(MasaMarker(
          masa: provider.mt2Temp!,
          color: Colors.purple.shade700,
          etiqueta: 'Mt2 (${provider.mt2Temp!.modulo.toStringAsFixed(1)}$unidadPeso @ ${provider.mt2Temp!.anguloGrados.toStringAsFixed(1)}°)',
        ));
      }

      if (provider.v2Temp != null) {
        for (int i = 0; i < provider.v2Temp!.length && i < numCanales; i++) {
          final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
          previewVectores.add(provider.v2Temp![i]);
          previewColores.add(_colorsV2[i % _colorsV2.length]);
          previewEtiquetas.add('V2 P2 ($tag)');
        }
      }
    }

    // Masas de Corrección Manuales (Mc1 & Mc2)
    final m1Masa = double.tryParse(_mc1MasaController.text);
    final m1Fase = double.tryParse(_mc1FaseController.text);
    if (m1Masa != null && m1Masa > 0 && m1Fase != null) {
      previewMasas.add(MasaMarker(
        masa: Complejo.desdePolar(m1Masa, m1Fase),
        color: Colors.green.shade700,
        etiqueta: 'Mc1 Manual ($m1Masa $unidadPeso @ $m1Fase°)',
      ));
    }

    if (is2Planos) {
      final m2Masa = double.tryParse(_mc2MasaController.text);
      final m2Fase = double.tryParse(_mc2FaseController.text);
      if (m2Masa != null && m2Masa > 0 && m2Fase != null) {
        previewMasas.add(MasaMarker(
          masa: Complejo.desdePolar(m2Masa, m2Fase),
          color: Colors.amber.shade900,
          etiqueta: 'Mc2 Manual ($m2Masa $unidadPeso @ $m2Fase°)',
        ));
      }
    }

    final double maxAmp = previewVectores.isEmpty
        ? 1.0
        : previewVectores.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    final double maxRadio = previewVectores.isEmpty ? 10.0 : maxAmp * 1.25;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesos Correctores Manuales'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.amber.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.build_circle_outlined, color: Colors.amber.shade900),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Graficación Libre de Corrección:\nIngrese los pesos de corrección (Mc) sugeridos por su experiencia para representarlos dinámicamente en el diagrama vectorial.',
                        style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECCIÓN 1: INGRESO DE MASAS DE CORRECCIÓN MANUALES
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tune, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Text('Pesos de Corrección Manuales (Mc)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text('Plano 1 - Masa Correctora Manual (Mc1):', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mc1MasaController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Masa ($unidadPeso)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _mc1FaseController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Ángulo / Ubicación (°)',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (is2Planos) ...[
                      const Divider(height: 24),
                      const Text('Plano 2 - Masa Correctora Manual (Mc2):', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mc2MasaController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Masa ($unidadPeso)',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _mc2FaseController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Ángulo / Ubicación (°)',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECCIÓN 2: DIAGRAMA POLAR SUPERPUESTO COMPLETO
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Diagrama Polar de Verificación Final',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: PolarPlot(
                        vectores: previewVectores,
                        colores: previewColores,
                        etiquetas: previewEtiquetas,
                        maxRadio: maxRadio,
                        masas: previewMasas,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECCIÓN 3: TABLA DE RESUMEN VECTORIAL COMPLETO
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.table_chart_outlined, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Text('Resumen de Vectores Registrados', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('Vector')),
                          DataColumn(label: Text('Magnitud')),
                          DataColumn(label: Text('Ángulo (°)')),
                          DataColumn(label: Text('Tipo')),
                        ],
                        rows: [
                          ...previewEtiquetas.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final tag = entry.value;
                            final vec = previewVectores[idx];
                            return DataRow(cells: [
                              DataCell(Text(tag, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text('${vec.modulo.toStringAsFixed(2)} $unidadVib')),
                              DataCell(Text('${vec.anguloGrados.toStringAsFixed(1)}°')),
                              DataCell(const Text('Vibración', style: TextStyle(color: Colors.blue))),
                            ]);
                          }),
                          ...previewMasas.map((m) {
                            return DataRow(cells: [
                              DataCell(Text(m.etiqueta.split('(').first.trim(), style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text('${m.masa.modulo.toStringAsFixed(2)} $unidadPeso')),
                              DataCell(Text('${m.masa.anguloGrados.toStringAsFixed(1)}°')),
                              DataCell(Text(
                                m.etiqueta.contains('Mc') ? 'Masa Corrección Manual' : 'Masa Prueba',
                                style: TextStyle(color: m.etiqueta.contains('Mc') ? Colors.green.shade700 : Colors.purple),
                              )),
                            ]);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // BOTONES DE NAVEGACIÓN
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver a Lecturas'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      _guardarEstadoProvider();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nuevo Análisis'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _guardarEstadoProvider();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Reiniciar Lecturas?'),
                          content: const Text('¿Desea limpiar las lecturas vectoriales actuales e iniciar un nuevo estudio?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                provider.reiniciarCalculos();
                                Navigator.popUntil(context, ModalRoute.withName('/'));
                              },
                              child: const Text('Reiniciar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
