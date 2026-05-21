import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';
import '../widgets/polar_plot.dart';
import '../utils/formatters.dart';
import 'guia_screen.dart';

class MedicionInicialScreen extends StatefulWidget {
  const MedicionInicialScreen({super.key});

  @override
  State<MedicionInicialScreen> createState() => _MedicionInicialScreenState();
}

class _MedicionInicialScreenState extends State<MedicionInicialScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<TextEditingController> _ampControllers;
  late List<TextEditingController> _faseControllers;
  int _numCanales = 0;

  final List<Color> _colorsList = const [
    Color(0xFF0D47A1), // Blue
    Color(0xFFB71C1C), // Red
    Color(0xFF2E7D32), // Green
    Color(0xFFE65100), // Amber
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BalanceoProvider>(context, listen: false);
    _numCanales = provider.config?.canales.length ?? 0;

    _ampControllers = List.generate(_numCanales, (_) => TextEditingController());
    _faseControllers = List.generate(_numCanales, (_) => TextEditingController());

    if (provider.v0 != null && provider.v0!.length == _numCanales) {
      for (int i = 0; i < _numCanales; i++) {
        _ampControllers[i].text = provider.v0![i].modulo.toString();
        _faseControllers[i].text = provider.v0![i].anguloGrados.toString();
      }
    }

    for (int i = 0; i < _numCanales; i++) {
      _ampControllers[i].addListener(_updatePreview);
      _faseControllers[i].addListener(_updatePreview);
    }
  }

  void _updatePreview() {
    setState(() {});
  }

  @override
  void dispose() {
    for (int i = 0; i < _numCanales; i++) {
      _ampControllers[i].removeListener(_updatePreview);
      _faseControllers[i].removeListener(_updatePreview);
      _ampControllers[i].dispose();
      _faseControllers[i].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    
    final List<Complejo> previewVectores = [];
    final List<Color> previewColores = [];
    final List<String> previewEtiquetas = [];

    for (int i = 0; i < _numCanales; i++) {
      final amp = double.tryParse(_ampControllers[i].text);
      final fase = double.tryParse(_faseControllers[i].text);
      final tag = provider.config?.canales[i].tag ?? 'Sensor ${i + 1}';
      if (amp != null && amp > 0 && fase != null) {
        previewVectores.add(Complejo.desdePolar(amp, fase));
        previewColores.add(_colorsList[i % _colorsList.length]);
        previewEtiquetas.add(tag);
      }
    }

    final double maxAmp = previewVectores.isEmpty
        ? 1.0
        : previewVectores
            .map((v) => v.modulo)
            .reduce((a, b) => a > b ? a : b);
    final double maxRadio = previewVectores.isEmpty ? 10.0 : maxAmp * 1.2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medición Inicial'),
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
            const Text(
              'Mida la vibración a velocidad nominal sin pesos correctores',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            ...List.generate(_numCanales, (i) {
              final tag = provider.config?.canales[i].tag ?? 'Canal ${i + 1}';
              final color = _colorsList[i % _colorsList.length];
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
                            child: TextFormField(
                              controller: _ampControllers[i],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Amplitud (${provider.config?.unidadStr ?? 'µm'})',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _faseControllers[i],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [AngleInputFormatter()],
                              decoration: const InputDecoration(
                                labelText: 'Fase (°)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.radar, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previsualización polar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade800,
                            ),
                      ),
                      if (previewVectores.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Ingrese amplitud y fase para ver vectores',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: PolarPlot(
                vectores: previewVectores,
                colores: previewColores,
                etiquetas: previewEtiquetas,
                maxRadio: maxRadio,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final List<Complejo> lecturas = [];
                      for (int i = 0; i < _numCanales; i++) {
                        final amp = double.parse(_ampControllers[i].text);
                        final fase = double.parse(_faseControllers[i].text);
                        lecturas.add(Complejo.desdePolar(amp, fase));
                      }
                      provider.setMedicionInicial(lecturas);
                      Navigator.pushNamed(context, '/prueba');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Siguiente'),
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
}