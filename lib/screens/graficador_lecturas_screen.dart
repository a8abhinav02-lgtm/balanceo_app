import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';
import '../widgets/polar_plot.dart';
import 'graficador_manual_screen.dart';

class GraficadorLecturasScreen extends StatefulWidget {
  const GraficadorLecturasScreen({super.key});

  @override
  State<GraficadorLecturasScreen> createState() => _GraficadorLecturasScreenState();
}

class _GraficadorLecturasScreenState extends State<GraficadorLecturasScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores V0
  late List<TextEditingController> _v0AmpControllers;
  late List<TextEditingController> _v0FaseControllers;

  // Controladores Masa de Prueba 1
  final _mt1MasaController = TextEditingController();
  final _mt1FaseController = TextEditingController();
  late List<TextEditingController> _v1AmpControllers;
  late List<TextEditingController> _v1FaseControllers;

  // Controladores Masa de Prueba 2 (para 2 planos)
  final _mt2MasaController = TextEditingController();
  final _mt2FaseController = TextEditingController();
  late List<TextEditingController> _v2AmpControllers;
  late List<TextEditingController> _v2FaseControllers;

  int _numCanales = 0;

  final List<Color> _colorsV0 = const [
    Color(0xFF0D47A1), // Azul
    Color(0xFFB71C1C), // Rojo
  ];

  final List<Color> _colorsV1 = const [
    Color(0xFF0288D1), // Celeste
    Color(0xFFC2185B), // Rosado
  ];

  final List<Color> _colorsV2 = const [
    Color(0xFF009688), // Verde Agua
    Color(0xFFE65100), // Naranja
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BalanceoProvider>(context, listen: false);
    _numCanales = provider.config?.canales.length ?? 1;

    _v0AmpControllers = List.generate(_numCanales, (_) => TextEditingController());
    _v0FaseControllers = List.generate(_numCanales, (_) => TextEditingController());
    _v1AmpControllers = List.generate(_numCanales, (_) => TextEditingController());
    _v1FaseControllers = List.generate(_numCanales, (_) => TextEditingController());
    _v2AmpControllers = List.generate(_numCanales, (_) => TextEditingController());
    _v2FaseControllers = List.generate(_numCanales, (_) => TextEditingController());

    // Cargar datos guardados si existen
    if (provider.v0 != null) {
      for (int i = 0; i < provider.v0!.length && i < _numCanales; i++) {
        _v0AmpControllers[i].text = provider.v0![i].modulo.toString();
        _v0FaseControllers[i].text = provider.v0![i].anguloGrados.toString();
      }
    }

    if (provider.mt1Temp != null) {
      _mt1MasaController.text = provider.mt1Temp!.modulo.toString();
      _mt1FaseController.text = provider.mt1Temp!.anguloGrados.toString();
    }

    if (provider.v1Temp != null) {
      for (int i = 0; i < provider.v1Temp!.length && i < _numCanales; i++) {
        _v1AmpControllers[i].text = provider.v1Temp![i].modulo.toString();
        _v1FaseControllers[i].text = provider.v1Temp![i].anguloGrados.toString();
      }
    }

    if (provider.mt2Temp != null) {
      _mt2MasaController.text = provider.mt2Temp!.modulo.toString();
      _mt2FaseController.text = provider.mt2Temp!.anguloGrados.toString();
    }

    if (provider.v2Temp != null) {
      for (int i = 0; i < provider.v2Temp!.length && i < _numCanales; i++) {
        _v2AmpControllers[i].text = provider.v2Temp![i].modulo.toString();
        _v2FaseControllers[i].text = provider.v2Temp![i].anguloGrados.toString();
      }
    }

    void addListenerToAll(List<TextEditingController> list) {
      for (var c in list) {
        c.addListener(_updateView);
      }
    }

    addListenerToAll(_v0AmpControllers);
    addListenerToAll(_v0FaseControllers);
    _mt1MasaController.addListener(_updateView);
    _mt1FaseController.addListener(_updateView);
    addListenerToAll(_v1AmpControllers);
    addListenerToAll(_v1FaseControllers);
    _mt2MasaController.addListener(_updateView);
    _mt2FaseController.addListener(_updateView);
    addListenerToAll(_v2AmpControllers);
    addListenerToAll(_v2FaseControllers);
  }

  void _updateView() {
    setState(() {});
  }

  @override
  void dispose() {
    for (int i = 0; i < _numCanales; i++) {
      _v0AmpControllers[i].dispose();
      _v0FaseControllers[i].dispose();
      _v1AmpControllers[i].dispose();
      _v1FaseControllers[i].dispose();
      _v2AmpControllers[i].dispose();
      _v2FaseControllers[i].dispose();
    }
    _mt1MasaController.dispose();
    _mt1FaseController.dispose();
    _mt2MasaController.dispose();
    _mt2FaseController.dispose();
    super.dispose();
  }

  void _guardarEstadoProvider() {
    final provider = Provider.of<BalanceoProvider>(context, listen: false);

    // V0
    List<Complejo> v0List = [];
    for (int i = 0; i < _numCanales; i++) {
      final amp = double.tryParse(_v0AmpControllers[i].text) ?? 0;
      final fase = double.tryParse(_v0FaseControllers[i].text) ?? 0;
      v0List.add(Complejo.desdePolar(amp, fase));
    }
    provider.v0 = v0List;
    provider.v0Original = List.from(v0List);

    // Masa prueba 1
    final mt1Masa = double.tryParse(_mt1MasaController.text);
    final mt1Fase = double.tryParse(_mt1FaseController.text);
    if (mt1Masa != null && mt1Fase != null) {
      provider.mt1Temp = Complejo.desdePolar(mt1Masa, mt1Fase);
    }

    // V1
    List<Complejo> v1List = [];
    for (int i = 0; i < _numCanales; i++) {
      final amp = double.tryParse(_v1AmpControllers[i].text) ?? 0;
      final fase = double.tryParse(_v1FaseControllers[i].text) ?? 0;
      v1List.add(Complejo.desdePolar(amp, fase));
    }
    provider.v1Temp = v1List;

    // Si son 2 planos
    if ((provider.config?.numPlanos ?? 1) == 2) {
      final mt2Masa = double.tryParse(_mt2MasaController.text);
      final mt2Fase = double.tryParse(_mt2FaseController.text);
      if (mt2Masa != null && mt2Fase != null) {
        provider.mt2Temp = Complejo.desdePolar(mt2Masa, mt2Fase);
      }

      List<Complejo> v2List = [];
      for (int i = 0; i < _numCanales; i++) {
        final amp = double.tryParse(_v2AmpControllers[i].text) ?? 0;
        final fase = double.tryParse(_v2FaseControllers[i].text) ?? 0;
        v2List.add(Complejo.desdePolar(amp, fase));
      }
      provider.v2Temp = v2List;
    }

    provider.saveToDisk();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    final is2Planos = (provider.config?.numPlanos ?? 1) == 2;
    final unidadVib = provider.config?.unidadStr ?? 'µm';
    final unidadPeso = 'g';

    // Construcción de vectores para la gráfica polar
    final List<Complejo> previewVectores = [];
    final List<Color> previewColores = [];
    final List<String> previewEtiquetas = [];
    final List<MasaMarker> previewMasas = [];

    // V0
    for (int i = 0; i < _numCanales; i++) {
      final amp = double.tryParse(_v0AmpControllers[i].text);
      final fase = double.tryParse(_v0FaseControllers[i].text);
      final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
      if (amp != null && amp > 0 && fase != null) {
        previewVectores.add(Complejo.desdePolar(amp, fase));
        previewColores.add(_colorsV0[i % _colorsV0.length]);
        previewEtiquetas.add('V0 ($tag)');
      }
    }

    // Mt1 & V1
    final mt1Masa = double.tryParse(_mt1MasaController.text);
    final mt1Fase = double.tryParse(_mt1FaseController.text);
    if (mt1Masa != null && mt1Masa > 0 && mt1Fase != null) {
      previewMasas.add(MasaMarker(
        masa: Complejo.desdePolar(mt1Masa, mt1Fase),
        color: Colors.grey.shade700,
        etiqueta: 'Mt1 ($mt1Masa $unidadPeso @ $mt1Fase°)',
      ));
    }

    for (int i = 0; i < _numCanales; i++) {
      final amp = double.tryParse(_v1AmpControllers[i].text);
      final fase = double.tryParse(_v1FaseControllers[i].text);
      final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
      if (amp != null && amp > 0 && fase != null) {
        previewVectores.add(Complejo.desdePolar(amp, fase));
        previewColores.add(_colorsV1[i % _colorsV1.length]);
        previewEtiquetas.add('V1 P1 ($tag)');
      }
    }

    // Mt2 & V2 (si 2 planos)
    if (is2Planos) {
      final mt2Masa = double.tryParse(_mt2MasaController.text);
      final mt2Fase = double.tryParse(_mt2FaseController.text);
      if (mt2Masa != null && mt2Masa > 0 && mt2Fase != null) {
        previewMasas.add(MasaMarker(
          masa: Complejo.desdePolar(mt2Masa, mt2Fase),
          color: Colors.purple.shade700,
          etiqueta: 'Mt2 ($mt2Masa $unidadPeso @ $mt2Fase°)',
        ));
      }

      for (int i = 0; i < _numCanales; i++) {
        final amp = double.tryParse(_v2AmpControllers[i].text);
        final fase = double.tryParse(_v2FaseControllers[i].text);
        final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
        if (amp != null && amp > 0 && fase != null) {
          previewVectores.add(Complejo.desdePolar(amp, fase));
          previewColores.add(_colorsV2[i % _colorsV2.length]);
          previewEtiquetas.add('V2 P2 ($tag)');
        }
      }
    }

    final double maxAmp = previewVectores.isEmpty
        ? 1.0
        : previewVectores.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);
    final double maxRadio = previewVectores.isEmpty ? 10.0 : maxAmp * 1.25;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graficador Vectorial - Lecturas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.show_chart, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Modo Graficador Manual (${is2Planos ? "2 Planos" : "1 Plano"})\nIngrese los vectores de vibración y masas de prueba para analizar el comportamiento gráfico.',
                          style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SECCIÓN 1: V0
              _buildSectionCard(
                title: '1. Vibración Inicial (V0 - Sin Masa)',
                icon: Icons.vibration,
                children: List.generate(_numCanales, (i) {
                  final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(tag, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _v0AmpControllers[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Amp ($unidadVib)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _v0FaseControllers[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Fase (°)',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // SECCIÓN 2: MT1 y V1
              _buildSectionCard(
                title: '2. Prueba Plano 1 (Mt1 y V1)',
                icon: Icons.fitness_center,
                children: [
                  const Text('Masa de Prueba 1 (Mt1):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mt1MasaController,
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
                          controller: _mt1FaseController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Ubicación / Fase (°)',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Vibración Resultante P1 (V1):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...List.generate(_numCanales, (i) {
                    final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text('V1 ($tag)', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _v1AmpControllers[i],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Amp ($unidadVib)',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _v1FaseControllers[i],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Fase (°)',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // SECCIÓN 3: MT2 y V2 (si son 2 planos)
              if (is2Planos) ...[
                _buildSectionCard(
                  title: '3. Prueba Plano 2 (Mt2 y V2)',
                  icon: Icons.fitness_center_outlined,
                  children: [
                    const Text('Masa de Prueba 2 (Mt2):', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mt2MasaController,
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
                            controller: _mt2FaseController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Ubicación / Fase (°)',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text('Vibración Resultante P2 (V2):', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...List.generate(_numCanales, (i) {
                      final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text('V2 ($tag)', style: const TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _v2AmpControllers[i],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Amp ($unidadVib)',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _v2FaseControllers[i],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Fase (°)',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // SECCIÓN 4: GRÁFICA POLAR EN TIEMPO REAL
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Diagrama Vectorial Polar',
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

              // SECCIÓN 5: OPERACIONES VECTORIALES AUXILIARES
              _buildAuxiliaryCard(
                provider: provider,
                unidadVib: unidadVib,
                unidadPeso: unidadPeso,
                is2Planos: is2Planos,
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar a Graficación Manual de Pesos Correctores'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  _guardarEstadoProvider();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GraficadorManualScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAuxiliaryCard({
    required BalanceoProvider provider,
    required String unidadVib,
    required String unidadPeso,
    required bool is2Planos,
  }) {
    List<Widget> auxRows = [];

    for (int i = 0; i < _numCanales; i++) {
      final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';

      final amp0 = double.tryParse(_v0AmpControllers[i].text);
      final fase0 = double.tryParse(_v0FaseControllers[i].text);
      final amp1 = double.tryParse(_v1AmpControllers[i].text);
      final fase1 = double.tryParse(_v1FaseControllers[i].text);
      final mt1Masa = double.tryParse(_mt1MasaController.text);

      if (amp0 != null && fase0 != null && amp1 != null && fase1 != null) {
        final v0 = Complejo.desdePolar(amp0, fase0);
        final v1 = Complejo.desdePolar(amp1, fase1);
        final deltaV1 = v1 - v0;
        final deltaTheta = (fase1 - fase0) % 360;

        auxRows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prueba P1 - $tag:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 4),
                  Text('• Respuesta Neta (ΔV1 = V1 - V0): ${deltaV1.modulo.toStringAsFixed(2)} $unidadVib @ ${deltaV1.anguloGrados.toStringAsFixed(1)}°'),
                  Text('• Desfase Angular (Δθ): ${deltaTheta.toStringAsFixed(1)}°'),
                  if (mt1Masa != null && mt1Masa > 0)
                    Text('• Sensibilidad (│ΔV1│/│Mt1│): ${(deltaV1.modulo / mt1Masa).toStringAsFixed(3)} $unidadVib/$unidadPeso'),
                ],
              ),
            ),
          ),
        );
      }

      if (is2Planos) {
        final amp2 = double.tryParse(_v2AmpControllers[i].text);
        final fase2 = double.tryParse(_v2FaseControllers[i].text);
        final mt2Masa = double.tryParse(_mt2MasaController.text);

        if (amp0 != null && fase0 != null && amp2 != null && fase2 != null) {
          final v0 = Complejo.desdePolar(amp0, fase0);
          final v2 = Complejo.desdePolar(amp2, fase2);
          final deltaV2 = v2 - v0;
          final deltaTheta2 = (fase2 - fase0) % 360;

          auxRows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prueba P2 - $tag:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade900)),
                    const SizedBox(height: 4),
                    Text('• Respuesta Neta (ΔV2 = V2 - V0): ${deltaV2.modulo.toStringAsFixed(2)} $unidadVib @ ${deltaV2.anguloGrados.toStringAsFixed(1)}°'),
                    Text('• Desfase Angular (Δθ): ${deltaTheta2.toStringAsFixed(1)}°'),
                    if (mt2Masa != null && mt2Masa > 0)
                      Text('• Sensibilidad (│ΔV2│/│Mt2│): ${(deltaV2.modulo / mt2Masa).toStringAsFixed(3)} $unidadVib/$unidadPeso'),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.functions, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(
                  'Operaciones Vectoriales Auxiliares',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            if (auxRows.isEmpty)
              const Text(
                'Complete los datos de V0 y V1/V2 para calcular automáticamente la respuesta neta (ΔV) y sensibilidad.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            else
              ...auxRows,
          ],
        ),
      ),
    );
  }
}
