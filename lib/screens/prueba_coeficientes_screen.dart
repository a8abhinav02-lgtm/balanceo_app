import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';
import '../utils/formatters.dart';
import 'guia_screen.dart';

class PruebaCoeficientesScreen extends StatefulWidget {
  const PruebaCoeficientesScreen({super.key});

  @override
  State<PruebaCoeficientesScreen> createState() => _PruebaCoeficientesScreenState();
}

class _PruebaCoeficientesScreenState extends State<PruebaCoeficientesScreen> {
  final _formKey = GlobalKey<FormState>();

  // Peso de prueba 1 (o unico)
  final _mtModController = TextEditingController();
  final _mtFaseController = TextEditingController();

  // Peso de prueba 2
  final _mt2ModController = TextEditingController();
  final _mt2FaseController = TextEditingController();

  // Mediciones dinámicas
  late List<TextEditingController> _v1AmpControllers;
  late List<TextEditingController> _v1FaseControllers;
  late List<TextEditingController> _v2AmpControllers;
  late List<TextEditingController> _v2FaseControllers;

  int _paso = 1; // 1: Plano 1, 2: Plano 2
  int _numCanales = 0;

  final List<Color> _colorsList = const [
    Color(0xFF0D47A1), // Blue
    Color(0xFFB71C1C), // Red
    Color(0xFF2E7D32), // Green
    Color(0xFFE65100), // Amber
  ];

  void _onInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BalanceoProvider>(context, listen: false);
    _numCanales = provider.config?.canales.length ?? 0;

    _v1AmpControllers = List.generate(_numCanales, (_) => TextEditingController());
    _v1FaseControllers = List.generate(_numCanales, (_) => TextEditingController());
    _v2AmpControllers = List.generate(_numCanales, (_) => TextEditingController());
    _v2FaseControllers = List.generate(_numCanales, (_) => TextEditingController());

    // Pre-poblar si el proveedor ya tiene datos
    if (provider.mt1Temp != null) {
      _mtModController.text = provider.mt1Temp!.modulo.toString();
      _mtFaseController.text = provider.mt1Temp!.anguloGrados.toString();
    }
    if (provider.mt2Temp != null) {
      _mt2ModController.text = provider.mt2Temp!.modulo.toString();
      _mt2FaseController.text = provider.mt2Temp!.anguloGrados.toString();
    }
    if (provider.v1Temp != null && provider.v1Temp!.length == _numCanales) {
      for (int i = 0; i < _numCanales; i++) {
        _v1AmpControllers[i].text = provider.v1Temp![i].modulo.toString();
        _v1FaseControllers[i].text = provider.v1Temp![i].anguloGrados.toString();
      }
    }
    if (provider.v2Temp != null && provider.v2Temp!.length == _numCanales) {
      for (int i = 0; i < _numCanales; i++) {
        _v2AmpControllers[i].text = provider.v2Temp![i].modulo.toString();
        _v2FaseControllers[i].text = provider.v2Temp![i].anguloGrados.toString();
      }
    }

    for (int i = 0; i < _numCanales; i++) {
      _v1AmpControllers[i].addListener(_onInputChanged);
      _v1FaseControllers[i].addListener(_onInputChanged);
      _v2AmpControllers[i].addListener(_onInputChanged);
      _v2FaseControllers[i].addListener(_onInputChanged);
    }
  }

  @override
  void dispose() {
    _mtModController.dispose();
    _mtFaseController.dispose();
    _mt2ModController.dispose();
    _mt2FaseController.dispose();
    for (int i = 0; i < _numCanales; i++) {
      _v1AmpControllers[i].removeListener(_onInputChanged);
      _v1FaseControllers[i].removeListener(_onInputChanged);
      _v2AmpControllers[i].removeListener(_onInputChanged);
      _v2FaseControllers[i].removeListener(_onInputChanged);
      _v1AmpControllers[i].dispose();
      _v1FaseControllers[i].dispose();
      _v2AmpControllers[i].dispose();
      _v2FaseControllers[i].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    final es2Planos = provider.config?.numPlanos == 2;

    // Determinar si debemos mostrar la alerta global y el cálculo por canal
    bool mostrarAlertaGlobal = false;
    final List<bool> fails = [];
    final List<bool> active = [];
    final List<double?> ampChanges = List.filled(_numCanales, null);
    final List<double?> phaseChanges = List.filled(_numCanales, null);
    final List<bool> channelFails = List.filled(_numCanales, false);

    for (int i = 0; i < _numCanales; i++) {
      final ampController = (_paso == 1) ? _v1AmpControllers[i] : _v2AmpControllers[i];
      final faseController = (_paso == 1) ? _v1FaseControllers[i] : _v2FaseControllers[i];

      final amp = double.tryParse(ampController.text);
      final fase = double.tryParse(faseController.text);

      if (amp != null && fase != null) {
        active.add(true);
        final v0Val = (provider.v0 != null && i < provider.v0!.length) ? provider.v0![i] : null;
        if (v0Val != null) {
          final double initialAmp = v0Val.modulo;
          final double initialPhase = v0Val.anguloGrados;

          if (initialAmp > 0) {
            ampChanges[i] = ((amp - initialAmp).abs() / initialAmp) * 100;
          } else {
            ampChanges[i] = 0.0;
          }

          double phaseDiff = (fase - initialPhase).abs() % 360;
          phaseChanges[i] = phaseDiff > 180 ? 360 - phaseDiff : phaseDiff;

          if ((ampChanges[i] ?? 0.0) < 30.0 && (phaseChanges[i] ?? 0.0) < 30.0) {
            fails.add(true);
            channelFails[i] = true;
          } else {
            fails.add(false);
            channelFails[i] = false;
          }
        } else {
          fails.add(false);
        }
      } else {
        active.add(false);
        fails.add(false);
      }
    }

    if (active.isNotEmpty && active.any((e) => e) && fails.where((e) => e).length == active.where((e) => e).length) {
      mostrarAlertaGlobal = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(es2Planos ? 'Prueba Coeficientes - P$_paso' : 'Prueba Coeficientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Guía de Operación',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GuiaScreen()));
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_paso == 1) ...[
              Text(
                es2Planos ? 'PESO DE PRUEBA EN PLANO 1' : 'PESO DE PRUEBA',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCampo('Masa de prueba (g)', _mtModController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCampo('Ángulo de colocación (°)', _mtFaseController)),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _mostrarAsistenteMasa(context, provider, _mtModController),
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('Calcular Masa Sugerida'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                es2Planos ? 'Mediciones con peso en P1:' : 'Mediciones con peso de prueba:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Text(
                'PESO DE PRUEBA EN PLANO 2',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCampo('Masa de prueba (g)', _mt2ModController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCampo('Ángulo de colocación (°)', _mt2FaseController)),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _mostrarAsistenteMasa(context, provider, _mt2ModController),
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('Calcular Masa Sugerida'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Mediciones con peso en P2:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
            ],

            if (mostrarAlertaGlobal) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cambio de Señal Insuficiente',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'La masa de prueba colocada no ha provocado un cambio significativo en la vibración en ninguno de los canales. '
                            'Se requiere un cambio de al menos 30% en amplitud o 30° en fase para calcular coeficientes de influencia precisos. '
                            'Se recomienda detener el rotor e incrementar la masa de prueba.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            ...List.generate(_numCanales, (i) {
              final tag = provider.config?.canales[i].tag ?? 'Canal ${i + 1}';
              final color = _colorsList[i % _colorsList.length];
              final ampController = (_paso == 1) ? _v1AmpControllers[i] : _v2AmpControllers[i];
              final faseController = (_paso == 1) ? _v1FaseControllers[i] : _v2FaseControllers[i];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCampo(
                              'Amplitud (${provider.config?.unidadStr ?? 'µm'})',
                              ampController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCampo(
                              'Fase (°)',
                              faseController,
                            ),
                          ),
                        ],
                      ),
                      if (ampChanges[i] != null && phaseChanges[i] != null) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Cambio: ΔAmp: ${ampChanges[i]!.toStringAsFixed(1)}% | ΔFase: ${phaseChanges[i]!.toStringAsFixed(1)}°',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: channelFails[i] ? Colors.orange.shade800 : Colors.teal.shade800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: channelFails[i] ? Colors.orange.shade50 : Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: channelFails[i] ? Colors.orange.shade200 : Colors.teal.shade200),
                              ),
                              child: Text(
                                channelFails[i] ? 'Señal Insuficiente' : 'Señal OK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: channelFails[i] ? Colors.orange.shade900 : Colors.teal.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (es2Planos && _paso == 2) {
                      setState(() => _paso = 1);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (!es2Planos) {
                        final mt = Complejo.desdePolar(double.parse(_mtModController.text), double.parse(_mtFaseController.text));
                        final List<Complejo> v1 = [];
                        for (int i = 0; i < _numCanales; i++) {
                          v1.add(Complejo.desdePolar(double.parse(_v1AmpControllers[i].text), double.parse(_v1FaseControllers[i].text)));
                        }
                        provider.calcularCoeficientes1Plano(mt, v1);
                        Navigator.pushNamed(context, '/resultados');
                      } else {
                        if (_paso == 1) {
                          setState(() => _paso = 2);
                        } else {
                          final mt1 = Complejo.desdePolar(double.parse(_mtModController.text), double.parse(_mtFaseController.text));
                          final mt2 = Complejo.desdePolar(double.parse(_mt2ModController.text), double.parse(_mt2FaseController.text));
                          
                          final List<Complejo> v1 = [];
                          for (int i = 0; i < _numCanales; i++) {
                            v1.add(Complejo.desdePolar(double.parse(_v1AmpControllers[i].text), double.parse(_v1FaseControllers[i].text)));
                          }
                          final List<Complejo> v2 = [];
                          for (int i = 0; i < _numCanales; i++) {
                            v2.add(Complejo.desdePolar(double.parse(_v2AmpControllers[i].text), double.parse(_v2FaseControllers[i].text)));
                          }
                          provider.calcularCoeficientes2Planos(mt1, mt2, v1, v2);
                          Navigator.pushNamed(context, '/resultados');
                        }
                      }
                    }
                  },
                  icon: Icon(es2Planos && _paso == 1 ? Icons.arrow_forward : Icons.calculate),
                  label: Text(es2Planos && _paso == 1 ? 'Siguiente' : 'Calcular'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampo(String label, TextEditingController controller) {
    final isAngulo = label.toLowerCase().contains('fase') || label.toLowerCase().contains('ángulo');
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isAngulo ? [AngleInputFormatter()] : [],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
    );
  }

  void _mostrarAsistenteMasa(
    BuildContext context,
    BalanceoProvider provider,
    TextEditingController targetController,
  ) {
    final config = provider.config;
    final double? peso = config?.pesoRotor;
    final double? rpm = config?.velocidadRPM;
    final double? radio = config?.radioPeso;

    showDialog(
      context: context,
      builder: (context) {
        return _AsistenteMasaDialog(
          pesoInicial: peso,
          rpmInicial: rpm,
          radioInicial: radio,
          onAceptar: (double valor) {
            targetController.text = valor.toStringAsFixed(1);
          },
        );
      },
    );
  }
}

class _AsistenteMasaDialog extends StatefulWidget {
  final double? pesoInicial;
  final double? rpmInicial;
  final double? radioInicial;
  final ValueChanged<double> onAceptar;

  const _AsistenteMasaDialog({
    this.pesoInicial,
    this.rpmInicial,
    this.radioInicial,
    required this.onAceptar,
  });

  @override
  State<_AsistenteMasaDialog> createState() => _AsistenteMasaDialogState();
}

class _AsistenteMasaDialogState extends State<_AsistenteMasaDialog> {
  final _pesoController = TextEditingController();
  final _rpmController = TextEditingController();
  final _radioController = TextEditingController();

  double? _resultado;

  @override
  void initState() {
    super.initState();
    if (widget.pesoInicial != null) _pesoController.text = widget.pesoInicial!.toString();
    if (widget.rpmInicial != null) _rpmController.text = widget.rpmInicial!.toString();
    if (widget.radioInicial != null) _radioController.text = widget.radioInicial!.toString();
    _calcularMasa();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _rpmController.dispose();
    _radioController.dispose();
    super.dispose();
  }

  void _calcularMasa() {
    final p = double.tryParse(_pesoController.text);
    final n = double.tryParse(_rpmController.text);
    final r = double.tryParse(_radioController.text);

    if (p == null || n == null || r == null || p <= 0 || n <= 0 || r <= 0) {
      setState(() {
        _resultado = null;
      });
      return;
    }

    // Fórmula métrica de masa de prueba sugerida:
    // m = (1.79 * 1e8 * peso) / (radio * rpm * rpm)
    final masa = (1.79 * 1e8 * p) / (r * n * n);
    setState(() {
      _resultado = masa;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = double.tryParse(_pesoController.text) ?? 0.0;
    final bool esPequeno = p > 0 && p <= 10;
    final bool esMediano = p > 10 && p <= 100;
    final bool esGrande = p > 100 && p <= 500;
    final bool esMuyGrande = p > 500;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.scale, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('Asistente de Masa'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La masa de prueba óptima debe provocar un cambio notable de vibración sin inducir fuerzas peligrosas.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Cálculo por Parámetros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pesoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso del rotor (kg)',
                isDense: true,
              ),
              onChanged: (_) => _calcularMasa(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rpmController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Velocidad (RPM)',
                isDense: true,
              ),
              onChanged: (_) => _calcularMasa(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _radioController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Radio de colocación (mm)',
                isDense: true,
              ),
              onChanged: (_) => _calcularMasa(),
            ),
            const SizedBox(height: 16),

            if (_resultado != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Masa de Prueba Sugerida:', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${_resultado!.toStringAsFixed(1)} g',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete el peso, velocidad y radio para obtener un cálculo exacto. Si no dispone de datos, use una de las sugerencias rápidas abajo.',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 8),
            const Text('Recomendaciones de Campo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Si no dispone de datos, toque una opción:', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            _buildEmpiricalOption('Rotor Pequeño (hasta 10 kg)', '3 - 10 g', 'Ej: Extractores chicos, poleas de motor.', highlighted: esPequeno),
            _buildEmpiricalOption('Rotor Mediano (10 - 100 kg)', '10 - 40 g', 'Ej: Ventiladores industriales, bombas.', highlighted: esMediano),
            _buildEmpiricalOption('Rotor Grande (100 - 500 kg)', '40 - 150 g', 'Ej: Extractores grandes, turbomáquinas.', highlighted: esGrande),
            _buildEmpiricalOption('Rotor Muy Grande (> 500 kg)', '> 150 g', 'Ej: Torres de enfriamiento gigantes.', highlighted: esMuyGrande),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_resultado != null)
          ElevatedButton(
            onPressed: () {
              widget.onAceptar(_resultado!);
              Navigator.pop(context);
            },
            child: const Text('Usar Masa Sugerida'),
          ),
      ],
    );
  }

  Widget _buildEmpiricalOption(String label, String suggestion, String desc, {bool highlighted = false}) {
    return Card(
      elevation: highlighted ? 1 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: highlighted ? Colors.blue.shade50 : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: highlighted ? Colors.blueAccent.shade200 : Colors.grey.shade200,
          width: highlighted ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label + (highlighted ? ' (Sugerido)' : ''),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: highlighted ? Colors.blue.shade900 : Colors.black87,
              ),
            ),
            Text(suggestion, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ],
        ),
        subtitle: Text(desc, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        onTap: () {
          final num = _parseSuggestion(suggestion);
          if (num != null) {
            widget.onAceptar(num);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  double? _parseSuggestion(String suggestion) {
    final cleanStr = suggestion.replaceAll('g', '').trim();
    if (cleanStr.contains('-')) {
      final parts = cleanStr.split('-');
      final a = double.tryParse(parts[0].trim());
      final b = double.tryParse(parts[1].trim());
      if (a != null && b != null) {
        return (a + b) / 2;
      }
    }
    if (cleanStr.contains('>')) {
      final val = cleanStr.replaceAll('>', '').trim();
      return double.tryParse(val);
    }
    return double.tryParse(cleanStr);
  }
}