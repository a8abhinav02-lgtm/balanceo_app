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
  int _selectedView = 0; // 0: Plano 1, 1: Plano 2, 2: Global
  bool _mostrarTriangulo = true;
  bool _mostrarTrasladado = true;

  final List<Color> _colorsV0 = const [
    Color(0xFF0D47A1), // Azul oscuro
    Color(0xFFB71C1C), // Rojo oscuro
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

    final tag1 = provider.config?.canales.isNotEmpty == true ? provider.config!.canales[0].tag : '1H';
    final tag2 = provider.config != null && provider.config!.canales.length > 1
        ? provider.config!.canales[1].tag
        : '2H';

    // Parse V0
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

    // Construcción de listas para PolarPlot
    final List<Complejo> previewVectores = [];
    final List<Color> previewColores = [];
    final List<String> previewEtiquetas = [];
    final List<bool> previewEsDiscontinuo = [];
    final List<VectorConector> previewConectores = [];
    final List<MasaMarker> previewMasas = [];

    if (!is2Planos) {
      // ── 1 PLANO ──────────────────────────────────────────────────────────
      // V0
      if (parsedV0.isNotEmpty && parsedV0[0] != null) {
        previewVectores.add(parsedV0[0]!);
        previewColores.add(_colorsV0[0]);
        previewEtiquetas.add('V0 ($tag1)');
        previewEsDiscontinuo.add(false);
      }

      // Mt1
      if (parsedMt1 != null) {
        previewMasas.add(MasaMarker(
          masa: parsedMt1,
          color: Colors.blueGrey.shade800,
          etiqueta: 'Mt1 ($mt1Masa $unidadPeso @ $mt1Fase°)',
        ));
      }

      // V1
      if (parsedV1.isNotEmpty && parsedV1[0] != null) {
        previewVectores.add(parsedV1[0]!);
        previewColores.add(_colorsV1[0]);
        previewEtiquetas.add('V1 ($tag1)');
        previewEsDiscontinuo.add(false);

        if (parsedV0.isNotEmpty && parsedV0[0] != null) {
          final v0 = parsedV0[0]!;
          final v1 = parsedV1[0]!;
          final deltaV = v1 - v0;

          // Triángulo Vectorial Punta a Punta (V0 -> V1)
          if (_mostrarTriangulo) {
            previewConectores.add(VectorConector(
              origen: v0,
              destino: v1,
              color: const Color(0xFF00838F), // Cian Oscuro
              etiqueta: 'ΔV (Punta a Punta)',
              esDiscontinuo: false,
            ));
          }

          // Vector Trasladado al Origen (0,0)
          if (_mostrarTrasladado) {
            previewVectores.add(deltaV);
            previewColores.add(const Color(0xFF00ACC1));
            previewEtiquetas.add('ΔV Trasladado al Origen');
            previewEsDiscontinuo.add(true);
          }
        }
      }
    } else {
      // ── 2 PLANOS ──────────────────────────────────────────────────────────
      // PESTAÑA 0: PLANO 1 (Sensor 1 / ej 1H)
      if (_selectedView == 0 || _selectedView == 2) {
        if (parsedV0.isNotEmpty && parsedV0[0] != null) {
          previewVectores.add(parsedV0[0]!);
          previewColores.add(_colorsV0[0]);
          previewEtiquetas.add('V0 ($tag1)');
          previewEsDiscontinuo.add(false);
        }

        if (parsedMt1 != null) {
          previewMasas.add(MasaMarker(
            masa: parsedMt1,
            color: Colors.blueGrey.shade800,
            etiqueta: 'Mt1 ($mt1Masa $unidadPeso @ $mt1Fase°)',
          ));
        }

        // V1 en Canal 1 (Respuesta Directa P1)
        if (parsedV1.isNotEmpty && parsedV1[0] != null) {
          previewVectores.add(parsedV1[0]!);
          previewColores.add(_colorsV1[0]);
          previewEtiquetas.add('V1 ($tag1 - Dir)');
          previewEsDiscontinuo.add(false);

          if (parsedV0.isNotEmpty && parsedV0[0] != null) {
            final v0 = parsedV0[0]!;
            final v1 = parsedV1[0]!;
            final deltaV11 = v1 - v0;

            if (_mostrarTriangulo) {
              previewConectores.add(VectorConector(
                origen: v0,
                destino: v1,
                color: const Color(0xFF00838F),
                etiqueta: 'ΔV11 ($tag1)',
                esDiscontinuo: false,
              ));
            }

            if (_mostrarTrasladado) {
              previewVectores.add(deltaV11);
              previewColores.add(const Color(0xFF00ACC1));
              previewEtiquetas.add('ΔV11 Trasl ($tag1)');
              previewEsDiscontinuo.add(true);
            }
          }
        }

        // V2 en Canal 1 (Respuesta Cruzada con Mt2)
        if (parsedV2.isNotEmpty && parsedV2[0] != null && (_selectedView == 0 || _selectedView == 2)) {
          previewVectores.add(parsedV2[0]!);
          previewColores.add(const Color(0xFF8E24AA));
          previewEtiquetas.add('V2 ($tag1 - Cruz)');
          previewEsDiscontinuo.add(false);

          if (parsedV0.isNotEmpty && parsedV0[0] != null) {
            final v0 = parsedV0[0]!;
            final v2 = parsedV2[0]!;
            final deltaV12 = v2 - v0;

            if (_mostrarTriangulo) {
              previewConectores.add(VectorConector(
                origen: v0,
                destino: v2,
                color: const Color(0xFF8E24AA),
                etiqueta: 'ΔV12 ($tag1)',
                esDiscontinuo: true,
              ));
            }

            if (_mostrarTrasladado) {
              previewVectores.add(deltaV12);
              previewColores.add(const Color(0xFFBA68C8));
              previewEtiquetas.add('ΔV12 Trasl ($tag1)');
              previewEsDiscontinuo.add(true);
            }
          }
        }
      }

      // PESTAÑA 1: PLANO 2 (Sensor 2 / ej 2H)
      if (_selectedView == 1 || _selectedView == 2) {
        if (parsedV0.length > 1 && parsedV0[1] != null) {
          previewVectores.add(parsedV0[1]!);
          previewColores.add(_colorsV0[1]);
          previewEtiquetas.add('V0 ($tag2)');
          previewEsDiscontinuo.add(false);
        }

        if (parsedMt2 != null) {
          previewMasas.add(MasaMarker(
            masa: parsedMt2,
            color: Colors.purple.shade700,
            etiqueta: 'Mt2 ($mt2Masa $unidadPeso @ $mt2Fase°)',
          ));
        }

        // V2 en Canal 2 (Respuesta Directa P2)
        if (parsedV2.length > 1 && parsedV2[1] != null) {
          previewVectores.add(parsedV2[1]!);
          previewColores.add(_colorsV2[1]);
          previewEtiquetas.add('V2 ($tag2 - Dir)');
          previewEsDiscontinuo.add(false);

          if (parsedV0.length > 1 && parsedV0[1] != null) {
            final v0 = parsedV0[1]!;
            final v2 = parsedV2[1]!;
            final deltaV22 = v2 - v0;

            if (_mostrarTriangulo) {
              previewConectores.add(VectorConector(
                origen: v0,
                destino: v2,
                color: const Color(0xFFE65100),
                etiqueta: 'ΔV22 ($tag2)',
                esDiscontinuo: false,
              ));
            }

            if (_mostrarTrasladado) {
              previewVectores.add(deltaV22);
              previewColores.add(const Color(0xFFEF6C00));
              previewEtiquetas.add('ΔV22 Trasl ($tag2)');
              previewEsDiscontinuo.add(true);
            }
          }
        }

        // V1 en Canal 2 (Respuesta Cruzada con Mt1)
        if (parsedV1.length > 1 && parsedV1[1] != null && (_selectedView == 1 || _selectedView == 2)) {
          previewVectores.add(parsedV1[1]!);
          previewColores.add(const Color(0xFF43A047));
          previewEtiquetas.add('V1 ($tag2 - Cruz)');
          previewEsDiscontinuo.add(false);

          if (parsedV0.length > 1 && parsedV0[1] != null) {
            final v0 = parsedV0[1]!;
            final v1 = parsedV1[1]!;
            final deltaV21 = v1 - v0;

            if (_mostrarTriangulo) {
              previewConectores.add(VectorConector(
                origen: v0,
                destino: v1,
                color: const Color(0xFF43A047),
                etiqueta: 'ΔV21 ($tag2)',
                esDiscontinuo: true,
              ));
            }

            if (_mostrarTrasladado) {
              previewVectores.add(deltaV21);
              previewColores.add(const Color(0xFF66BB6A));
              previewEtiquetas.add('ΔV21 Trasl ($tag2)');
              previewEsDiscontinuo.add(true);
            }
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
                          'Análisis Vectorial Polar (${is2Planos ? "2 Planos" : "1 Plano"}):\nVisualice el triángulo vectorial de balanceo (punta de V0 a punta de V1) y su traslación paralela al origen para leer la respuesta real.',
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
                  final tag = provider.config?.canales[i].tag ?? (i == 0 ? '1H' : '2H');
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
                    final tag = provider.config?.canales[i].tag ?? (i == 0 ? '1H' : '2H');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              i == 0 ? 'V1 ($tag - Directo)' : 'V1 ($tag - Cruzado)',
                              style: const TextStyle(fontWeight: FontWeight.w500),
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
                      final tag = provider.config?.canales[i].tag ?? (i == 0 ? '1H' : '2H');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                i == 1 ? 'V2 ($tag - Directo)' : 'V2 ($tag - Cruzado)',
                                style: const TextStyle(fontWeight: FontWeight.w500),
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
                          if (is2Planos)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _selectedView == 0
                                    ? 'Plano 1 ($tag1)'
                                    : _selectedView == 1
                                        ? 'Plano 2 ($tag2)'
                                        : 'Global (Ambos)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
                              ),
                            ),
                        ],
                      ),
                      if (is2Planos) ...[
                        const SizedBox(height: 12),
                        SegmentedButton<int>(
                          segments: [
                            ButtonSegment(value: 0, label: Text('Plano 1 ($tag1)'), icon: const Icon(Icons.looks_one)),
                            ButtonSegment(value: 1, label: Text('Plano 2 ($tag2)'), icon: const Icon(Icons.looks_two)),
                            ButtonSegment(value: 2, label: const Text('Global'), icon: const Icon(Icons.hub)),
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
                tag1: tag1,
                tag2: tag2,
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
    required String tag1,
    required String tag2,
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

    if (!is2Planos) {
      // 1 PLANO
      if (parsedV0.isNotEmpty && parsedV0[0] != null && parsedV1.isNotEmpty && parsedV1[0] != null) {
        final v0 = parsedV0[0]!;
        final v1 = parsedV1[0]!;
        final deltaV = v1 - v0;
        final deltaTheta = (v1.anguloGrados - v0.anguloGrados) % 360;
        final deltaThetaNorm = deltaTheta > 180 ? deltaTheta - 360 : deltaTheta;

        auxRows.add(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueGrey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lectura de Vectores y Triángulo de Balanceo ($tag1):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
                ),
                const SizedBox(height: 8),
                Text('• Vector Inicial V0: ${v0.modulo.toStringAsFixed(2)} $unidadVib @ ${v0.anguloGrados.toStringAsFixed(1)}°'),
                Text('• Vector Resultante V1: ${v1.modulo.toStringAsFixed(2)} $unidadVib @ ${v1.anguloGrados.toStringAsFixed(1)}°'),
                const Divider(height: 16),
                Text(
                  '• Vector Efecto Neto (ΔV = V1 - V0 trasladado): ${deltaV.modulo.toStringAsFixed(2)} $unidadVib @ ${deltaV.anguloGrados.toStringAsFixed(1)}°',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00838F)),
                ),
                Text('• Desfase Angular (Δθ = θ1 - θ0): ${deltaThetaNorm.toStringAsFixed(1)}° (${deltaThetaNorm >= 0 ? "Adelanto" : "Atraso"})'),
                if (mt1Masa != null && mt1Masa > 0)
                  Text(
                    '• Sensibilidad Dinámica (|ΔV| / |Mt|): ${(deltaV.modulo / mt1Masa).toStringAsFixed(3)} $unidadVib/$unidadPeso',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        );
      }
    } else {
      // 2 PLANOS
      // BLOQUE PLANO 1 (SENSOR 1 / ej 1H)
      if (parsedV0.isNotEmpty && parsedV0[0] != null) {
        final v01 = parsedV0[0]!;
        List<Widget> p1Widgets = [];

        if (parsedV1.isNotEmpty && parsedV1[0] != null) {
          final v11 = parsedV1[0]!;
          final deltaV11 = v11 - v01;
          final dTheta11 = (v11.anguloGrados - v01.anguloGrados) % 360;
          final dTheta11Norm = dTheta11 > 180 ? dTheta11 - 360 : dTheta11;

          p1Widgets.add(
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
                  const Text('Respuesta Directa (Masa Mt1 en Plano 1):', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00838F))),
                  Text('  - V11 (Resultante): ${v11.modulo.toStringAsFixed(2)} $unidadVib @ ${v11.anguloGrados.toStringAsFixed(1)}°'),
                  Text('  - ΔV11 (Efecto neto trasladado): ${deltaV11.modulo.toStringAsFixed(2)} $unidadVib @ ${deltaV11.anguloGrados.toStringAsFixed(1)}°'),
                  Text('  - Desfase Δθ11: ${dTheta11Norm.toStringAsFixed(1)}° (${dTheta11Norm >= 0 ? "Adelanto" : "Atraso"})'),
                  if (mt1Masa != null && mt1Masa > 0)
                    Text('  - Sensibilidad Directa: ${(deltaV11.modulo / mt1Masa).toStringAsFixed(3)} $unidadVib/$unidadPeso'),
                ],
              ),
            ),
          );
        }

        if (parsedV2.isNotEmpty && parsedV2[0] != null) {
          final v12 = parsedV2[0]!;
          final deltaV12 = v12 - v01;
          final dTheta12 = (v12.anguloGrados - v01.anguloGrados) % 360;
          final dTheta12Norm = dTheta12 > 180 ? dTheta12 - 360 : dTheta12;

          p1Widgets.add(
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Respuesta Cruzada / Cross-Talk (Masa Mt2 en Plano 2):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                  Text('  - V12 (Resultante cruzada): ${v12.modulo.toStringAsFixed(2)} $unidadVib @ ${v12.anguloGrados.toStringAsFixed(1)}°'),
                  Text('  - ΔV12 (Efecto cruzado trasladado): ${deltaV12.modulo.toStringAsFixed(2)} $unidadVib @ ${deltaV12.anguloGrados.toStringAsFixed(1)}°'),
                  Text('  - Desfase Cruzado Δθ12: ${dTheta12Norm.toStringAsFixed(1)}° (${dTheta12Norm >= 0 ? "Adelanto" : "Atraso"})'),
                  if (mt2Masa != null && mt2Masa > 0)
                    Text('  - Sensibilidad Cruzada: ${(deltaV12.modulo / mt2Masa).toStringAsFixed(3)} $unidadVib/$unidadPeso'),
                ],
              ),
            ),
          );
        }

        if (p1Widgets.isNotEmpty) {
          auxRows.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plano 1 ($tag1) - V01: ${v01.modulo.toStringAsFixed(2)} $unidadVib @ ${v01.anguloGrados.toStringAsFixed(1)}°',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  ...p1Widgets,
                ],
              ),
            ),
          );
        }
      }

      // BLOQUE PLANO 2 (SENSOR 2 / ej 2H)
      if (parsedV0.length > 1 && parsedV0[1] != null) {
        final v02 = parsedV0[1]!;
        List<Widget> p2Widgets = [];

        if (parsedV2.length > 1 && parsedV2[1] != null) {
          final v22 = parsedV2[1]!;
          final deltaV22 = v22 - v02;
          final dTheta22 = (v22.anguloGrados - v02.anguloGrados) % 360;
          final dTheta22Norm = dTheta22 > 180 ? dTheta22 - 360 : dTheta22;

          p2Widgets.add(
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
                  const Text('Respuesta Directa (Masa Mt2 en Plano 2):', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                  Text('  - V22 (Resultante): ${v22.modulo.toStringAsFixed(2)} $unidadVib @ ${v22.anguloGrados.toStringAsFixed(1)}°'),
                  Text('  - ΔV22 (Efecto neto trasladado): ${deltaV22.modulo.toStringAsFixed(2)} $unidadVib @ ${deltaV22.anguloGrados.toStringAsFixed(1)}°'),
                  Text('  - Desfase Δθ22: ${dTheta22Norm.toStringAsFixed(1)}° (${dTheta22Norm >= 0 ? "Adelanto" : "Atraso"})'),
                  if (mt2Masa != null && mt2Masa > 0)
                    Text('  - Sensibilidad Directa: ${(deltaV22.modulo / mt2Masa).toStringAsFixed(3)} $unidadVib/$unidadPeso'),
                ],
              ),
            ),
          );
        }

        if (parsedV1.length > 1 && parsedV1[1] != null) {
          final v21 = parsedV1[1]!;
          final deltaV21 = v21 - v02;
          final dTheta21 = (v21.anguloGrados - v02.anguloGrados) % 360;
          final dTheta21Norm = dTheta21 > 180 ? dTheta21 - 360 : dTheta21;

          p2Widgets.add(
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Respuesta Cruzada / Cross-Talk (Masa Mt1 en Plano 1):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  Text('  - V21 (Resultante cruzada): ${v21.modulo.toStringAsFixed(2)} $unidadVib @ ${v21.anguloGrados.toStringAsFixed(1)}°'),
                  Text('  - ΔV21 (Efecto cruzado trasladado): ${deltaV21.modulo.toStringAsFixed(2)} $unidadVib @ ${deltaV21.anguloGrados.toStringAsFixed(1)}°'),
                  Text('  - Desfase Cruzado Δθ21: ${dTheta21Norm.toStringAsFixed(1)}° (${dTheta21Norm >= 0 ? "Adelanto" : "Atraso"})'),
                  if (mt1Masa != null && mt1Masa > 0)
                    Text('  - Sensibilidad Cruzada: ${(deltaV21.modulo / mt1Masa).toStringAsFixed(3)} $unidadVib/$unidadPeso'),
                ],
              ),
            ),
          );
        }

        if (p2Widgets.isNotEmpty) {
          auxRows.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plano 2 ($tag2) - V02: ${v02.modulo.toStringAsFixed(2)} $unidadVib @ ${v02.anguloGrados.toStringAsFixed(1)}°',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple.shade900)),
                  const SizedBox(height: 8),
                  ...p2Widgets,
                ],
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
