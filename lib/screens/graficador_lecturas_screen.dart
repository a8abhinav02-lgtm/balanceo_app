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
  int _selectedView = 0; // 0: Global (Todos), 1: Solo Canal 1 (1H), 2: Solo Canal 2 (2H)
  bool _mostrarTriangulo = true;
  bool _mostrarTrasladado = true;

  final List<Color> _colorsV0 = const [
    Color(0xFF0D47A1), // 1H: Azul oscuro
    Color(0xFFB71C1C), // 2H: Rojo oscuro
    Color(0xFF1B5E20), // 3: Verde oscuro
    Color(0xFF4A148C), // 4: Morado oscuro
  ];

  final List<Color> _colorsV1 = const [
    Color(0xFF0288D1), // 1H: Celeste brillante
    Color(0xFFE91E63), // 2H: Rosado/Magenta
    Color(0xFF4CAF50), // 3: Verde claro
    Color(0xFF9C27B0), // 4: Morado claro
  ];

  final List<Color> _colorsV2 = const [
    Color(0xFF00897B), // 1H: Verde azulado
    Color(0xFFE65100), // 2H: Naranja intenso
    Color(0xFFFF8F00), // 3: Ámbar
    Color(0xFF5D4037), // 4: Café
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

    final List<String> channelTags = List.generate(_numCanales, (i) {
      if (provider.config != null && i < provider.config!.canales.length) {
        return provider.config!.canales[i].tag;
      }
      return i == 0 ? '1H' : (i == 1 ? '2H' : 'Ch ${i + 1}');
    });

    // Parse V0 para todos los canales
    final List<Complejo?> parsedV0 = List.generate(_numCanales, (i) {
      final amp = double.tryParse(_v0AmpControllers[i].text);
      final fase = double.tryParse(_v0FaseControllers[i].text);
      if (amp != null && amp > 0 && fase != null) {
        return Complejo.desdePolar(amp, fase);
      }
      return null;
    });

    // Parse Mt1 & V1
    final mt1Masa = double.tryParse(_mt1MasaController.text);
    final mt1Fase = double.tryParse(_mt1FaseController.text);
    final Complejo? parsedMt1 = (mt1Masa != null && mt1Masa > 0 && mt1Fase != null)
        ? Complejo.desdePolar(mt1Masa, mt1Fase)
        : null;

    final List<Complejo?> parsedV1 = List.generate(_numCanales, (i) {
      final amp = double.tryParse(_v1AmpControllers[i].text);
      final fase = double.tryParse(_v1FaseControllers[i].text);
      if (amp != null && amp > 0 && fase != null) {
        return Complejo.desdePolar(amp, fase);
      }
      return null;
    });

    // Parse Mt2 & V2
    final mt2Masa = double.tryParse(_mt2MasaController.text);
    final mt2Fase = double.tryParse(_mt2FaseController.text);
    final Complejo? parsedMt2 = (mt2Masa != null && mt2Masa > 0 && mt2Fase != null)
        ? Complejo.desdePolar(mt2Masa, mt2Fase)
        : null;

    final List<Complejo?> parsedV2 = List.generate(_numCanales, (i) {
      final amp = double.tryParse(_v2AmpControllers[i].text);
      final fase = double.tryParse(_v2FaseControllers[i].text);
      if (amp != null && amp > 0 && fase != null) {
        return Complejo.desdePolar(amp, fase);
      }
      return null;
    });

    // Construcción de listas para PolarPlot considerando TODOS los canales activos
    final List<Complejo> previewVectores = [];
    final List<Color> previewColores = [];
    final List<String> previewEtiquetas = [];
    final List<bool> previewEsDiscontinuo = [];
    final List<VectorConector> previewConectores = [];
    final List<MasaMarker> previewMasas = [];

    // 1. Masas de Prueba en el anillo exterior
    if (parsedMt1 != null && (_selectedView == 0 || _selectedView == 1)) {
      previewMasas.add(MasaMarker(
        masa: parsedMt1,
        color: Colors.blueGrey.shade800,
        etiqueta: 'Mt1 ($mt1Masa $unidadPeso @ $mt1Fase°)',
      ));
    }

    if (is2Planos && parsedMt2 != null && (_selectedView == 0 || _selectedView == 2)) {
      previewMasas.add(MasaMarker(
        masa: parsedMt2,
        color: Colors.purple.shade700,
        etiqueta: 'Mt2 ($mt2Masa $unidadPeso @ $mt2Fase°)',
      ));
    }

    // 2. Iterar TODOS los canales (1H, 2H, etc.)
    for (int i = 0; i < _numCanales; i++) {
      // Filtrar según vista: 0 = Global (Todos), 1 = Solo Canal 1 (1H), 2 = Solo Canal 2 (2H)
      if (_selectedView != 0 && _selectedView != (i + 1)) {
        continue;
      }

      final tag = channelTags[i];
      final colorV0 = _colorsV0[i % _colorsV0.length];
      final colorV1 = _colorsV1[i % _colorsV1.length];
      final colorV2 = _colorsV2[i % _colorsV2.length];

      // A) Vibración Inicial V0
      if (parsedV0[i] != null) {
        previewVectores.add(parsedV0[i]!);
        previewColores.add(colorV0);
        previewEtiquetas.add('V0 ($tag)');
        previewEsDiscontinuo.add(false);
      }

      // B) Corrida de Prueba 1 (V1)
      if (parsedV1[i] != null) {
        previewVectores.add(parsedV1[i]!);
        previewColores.add(colorV1);
        previewEtiquetas.add(is2Planos && i > 0 ? 'V1 ($tag - Cruz)' : 'V1 ($tag)');
        previewEsDiscontinuo.add(false);

        if (parsedV0[i] != null) {
          final v0 = parsedV0[i]!;
          final v1 = parsedV1[i]!;
          final deltaV1 = v1 - v0;

          // Triángulo Punta a Punta (V0 -> V1)
          if (_mostrarTriangulo) {
            previewConectores.add(VectorConector(
              origen: v0,
              destino: v1,
              color: colorV1,
              etiqueta: 'ΔV1 ($tag)',
              esDiscontinuo: false,
            ));
          }

          // Vector Trasladado al Origen (0,0)
          if (_mostrarTrasladado) {
            previewVectores.add(deltaV1);
            previewColores.add(colorV1.withAlpha(220));
            previewEtiquetas.add('ΔV1 Trasl ($tag)');
            previewEsDiscontinuo.add(true);
          }
        }
      }

      // C) Corrida de Prueba 2 (V2 - si son 2 planos)
      if (is2Planos && parsedV2[i] != null) {
        previewVectores.add(parsedV2[i]!);
        previewColores.add(colorV2);
        previewEtiquetas.add(i == 0 ? 'V2 ($tag - Cruz)' : 'V2 ($tag)');
        previewEsDiscontinuo.add(false);

        if (parsedV0[i] != null) {
          final v0 = parsedV0[i]!;
          final v2 = parsedV2[i]!;
          final deltaV2 = v2 - v0;

          // Triángulo Punta a Punta (V0 -> V2)
          if (_mostrarTriangulo) {
            previewConectores.add(VectorConector(
              origen: v0,
              destino: v2,
              color: colorV2,
              etiqueta: 'ΔV2 ($tag)',
              esDiscontinuo: false,
            ));
          }

          // Vector Trasladado al Origen (0,0)
          if (_mostrarTrasladado) {
            previewVectores.add(deltaV2);
            previewColores.add(colorV2.withAlpha(220));
            previewEtiquetas.add('ΔV2 Trasl ($tag)');
            previewEsDiscontinuo.add(true);
          }
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
                          'Análisis Vectorial Polar (${is2Planos ? "2 Planos" : "1 Plano"}):\nTodos los canales iniciales (1H, 2H) se grafican desde el origen (0,0). Puede alternar entre el triángulo de balanceo y el vector trasladado.',
                          style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SECCIÓN 1: V0 (VIBRACIÓN INICIAL EN TODOS LOS CANALES)
              _buildSectionCard(
                title: '1. Vibración Inicial (V0 - Sin Masa)',
                icon: Icons.vibration,
                children: List.generate(_numCanales, (i) {
                  final tag = channelTags[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            tag,
                            style: TextStyle(fontWeight: FontWeight.bold, color: _colorsV0[i % _colorsV0.length]),
                          ),
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
                    final tag = channelTags[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              is2Planos ? (i == 0 ? 'V1 ($tag - Directo)' : 'V1 ($tag - Cruzado)') : 'V1 ($tag)',
                              style: TextStyle(fontWeight: FontWeight.w500, color: _colorsV1[i % _colorsV1.length]),
                            ),
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
                      final tag = channelTags[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                i == 1 ? 'V2 ($tag - Directo)' : 'V2 ($tag - Cruzado)',
                                style: TextStyle(fontWeight: FontWeight.w500, color: _colorsV2[i % _colorsV2.length]),
                              ),
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

              // SECCIÓN 4: DIAGRAMA POLAR INTERACTIVO
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Diagrama Vectorial Polar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedView == 0
                                  ? 'Global (Todos)'
                                  : 'Solo ${channelTags[_selectedView - 1]}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
                            ),
                          ),
                        ],
                      ),
                      if (_numCanales > 1) ...[
                        const SizedBox(height: 12),
                        SegmentedButton<int>(
                          segments: [
                            const ButtonSegment(value: 0, label: Text('Global (Todos)'), icon: Icon(Icons.hub)),
                            ...List.generate(_numCanales, (i) {
                              return ButtonSegment(
                                value: i + 1,
                                label: Text('Solo ${channelTags[i]}'),
                                icon: Icon(i == 0 ? Icons.looks_one : Icons.looks_two),
                              );
                            }),
                          ],
                          selected: {_selectedView},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedView = newSelection.first;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Controles de Visualización (Switches)
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          FilterChip(
                            label: const Text('Triángulo Punta a Punta', style: TextStyle(fontSize: 11)),
                            selected: _mostrarTriangulo,
                            selectedColor: Colors.cyan.shade100,
                            checkmarkColor: Colors.cyan.shade900,
                            onSelected: (val) => setState(() => _mostrarTriangulo = val),
                          ),
                          FilterChip(
                            label: const Text('Trasladar ΔV al Origen (0,0)', style: TextStyle(fontSize: 11)),
                            selected: _mostrarTrasladado,
                            selectedColor: Colors.teal.shade100,
                            checkmarkColor: Colors.teal.shade900,
                            onSelected: (val) => setState(() => _mostrarTrasladado = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: PolarPlot(
                          vectores: previewVectores,
                          colores: previewColores,
                          etiquetas: previewEtiquetas,
                          esDiscontinuo: previewEsDiscontinuo,
                          conectores: previewConectores,
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
                channelTags: channelTags,
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
    required List<String> channelTags,
  }) {
    List<Widget> auxRows = [];

    // Parse V0
    final List<Complejo?> parsedV0 = List.generate(_numCanales, (i) {
      final amp = double.tryParse(_v0AmpControllers[i].text);
      final fase = double.tryParse(_v0FaseControllers[i].text);
      if (amp != null && fase != null) {
        return Complejo.desdePolar(amp, fase);
      }
      return null;
    });

    // Parse Mt1 & V1
    final mt1Masa = double.tryParse(_mt1MasaController.text);
    final List<Complejo?> parsedV1 = List.generate(_numCanales, (i) {
      final amp = double.tryParse(_v1AmpControllers[i].text);
      final fase = double.tryParse(_v1FaseControllers[i].text);
      if (amp != null && fase != null) {
        return Complejo.desdePolar(amp, fase);
      }
      return null;
    });

    // Parse Mt2 & V2
    final mt2Masa = double.tryParse(_mt2MasaController.text);
    final List<Complejo?> parsedV2 = List.generate(_numCanales, (i) {
      final amp = double.tryParse(_v2AmpControllers[i].text);
      final fase = double.tryParse(_v2FaseControllers[i].text);
      if (amp != null && fase != null) {
        return Complejo.desdePolar(amp, fase);
      }
      return null;
    });

    for (int i = 0; i < _numCanales; i++) {
      final tag = channelTags[i];
      if (parsedV0[i] == null) continue;
      final v0 = parsedV0[i]!;

      List<Widget> channelWidgets = [];

      // Respuesta Prueba 1 (V1)
      if (parsedV1[i] != null) {
        final v1 = parsedV1[i]!;
        final deltaV1 = v1 - v0;
        final dTheta1 = (v1.anguloGrados - v0.anguloGrados) % 360;
        final dTheta1Norm = dTheta1 > 180 ? dTheta1 - 360 : dTheta1;

        channelWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.cyan.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  is2Planos && i > 0
                      ? 'Respuesta Cruzada (Masa Mt1 en Plano 1):'
                      : 'Respuesta Directa (Masa Mt1 en Plano 1):',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00838F)),
                ),
                Text('  - V1 (Resultante): ${v1.modulo.toStringAsFixed(2)} $unidadVib @ ${v1.anguloGrados.toStringAsFixed(1)}°'),
                Text('  - ΔV1 (Efecto neto trasladado): ${deltaV1.modulo.toStringAsFixed(2)} $unidadVib @ ${deltaV1.anguloGrados.toStringAsFixed(1)}°'),
                Text('  - Desfase Δθ1: ${dTheta1Norm.toStringAsFixed(1)}° (${dTheta1Norm >= 0 ? "Adelanto" : "Atraso"})'),
                if (mt1Masa != null && mt1Masa > 0)
                  Text('  - Sensibilidad: ${(deltaV1.modulo / mt1Masa).toStringAsFixed(3)} $unidadVib/$unidadPeso'),
              ],
            ),
          ),
        );
      }

      // Respuesta Prueba 2 (V2 - si 2 planos)
      if (is2Planos && parsedV2[i] != null) {
        final v2 = parsedV2[i]!;
        final deltaV2 = v2 - v0;
        final dTheta2 = (v2.anguloGrados - v0.anguloGrados) % 360;
        final dTheta2Norm = dTheta2 > 180 ? dTheta2 - 360 : dTheta2;

        channelWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i == 0
                      ? 'Respuesta Cruzada (Masa Mt2 en Plano 2):'
                      : 'Respuesta Directa (Masa Mt2 en Plano 2):',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                ),
                Text('  - V2 (Resultante): ${v2.modulo.toStringAsFixed(2)} $unidadVib @ ${v2.anguloGrados.toStringAsFixed(1)}°'),
                Text('  - ΔV2 (Efecto neto trasladado): ${deltaV2.modulo.toStringAsFixed(2)} $unidadVib @ ${deltaV2.anguloGrados.toStringAsFixed(1)}°'),
                Text('  - Desfase Δθ2: ${dTheta2Norm.toStringAsFixed(1)}° (${dTheta2Norm >= 0 ? "Adelanto" : "Atraso"})'),
                if (mt2Masa != null && mt2Masa > 0)
                  Text('  - Sensibilidad: ${(deltaV2.modulo / mt2Masa).toStringAsFixed(3)} $unidadVib/$unidadPeso'),
              ],
            ),
          ),
        );
      }

      auxRows.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: i == 0 ? Colors.blue.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: i == 0 ? Colors.blue.shade300 : Colors.red.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Canal $tag - V0: ${v0.modulo.toStringAsFixed(2)} $unidadVib @ ${v0.anguloGrados.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: i == 0 ? Colors.blue.shade900 : Colors.red.shade900,
                ),
              ),
              if (channelWidgets.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...channelWidgets,
              ],
            ],
          ),
        ),
      );
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
                'Complete los datos de V0 y V1/V2 para calcular automáticamente el triángulo vectorial, la respuesta trasladada (ΔV) y sensibilidad.',
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
