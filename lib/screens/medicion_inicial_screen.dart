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
  final _amp1Controller = TextEditingController();
  final _fase1Controller = TextEditingController();
  final _amp2Controller = TextEditingController();
  final _fase2Controller = TextEditingController();

  // Local state for real-time polar preview
  double? _amp1, _fase1, _amp2, _fase2;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BalanceoProvider>(context, listen: false);

    if (provider.v0_1 != null) {
      _amp1Controller.text = provider.v0_1!.modulo.toString();
      _fase1Controller.text = provider.v0_1!.anguloGrados.toString();
      _amp1 = provider.v0_1!.modulo;
      _fase1 = provider.v0_1!.anguloGrados;
    }
    if (provider.v0_2 != null) {
      _amp2Controller.text = provider.v0_2!.modulo.toString();
      _fase2Controller.text = provider.v0_2!.anguloGrados.toString();
      _amp2 = provider.v0_2!.modulo;
      _fase2 = provider.v0_2!.anguloGrados;
    }

    // Attach listeners for real-time update
    _amp1Controller.addListener(_updatePreview);
    _fase1Controller.addListener(_updatePreview);
    _amp2Controller.addListener(_updatePreview);
    _fase2Controller.addListener(_updatePreview);
  }

  void _updatePreview() {
    setState(() {
      _amp1 = double.tryParse(_amp1Controller.text);
      _fase1 = double.tryParse(_fase1Controller.text);
      _amp2 = double.tryParse(_amp2Controller.text);
      _fase2 = double.tryParse(_fase2Controller.text);
    });
  }

  @override
  void dispose() {
    _amp1Controller.removeListener(_updatePreview);
    _fase1Controller.removeListener(_updatePreview);
    _amp2Controller.removeListener(_updatePreview);
    _fase2Controller.removeListener(_updatePreview);
    _amp1Controller.dispose();
    _fase1Controller.dispose();
    _amp2Controller.dispose();
    _fase2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);


    // V1 — Sensor X
    final bool v1Valid = _amp1 != null && _amp1! > 0 && _fase1 != null;
    // V2 — Sensor Y (always collected)
    final bool v2Valid = _amp2 != null && _amp2! > 0 && _fase2 != null;
    final List<Complejo> previewVectores = [];
    final List<Color> previewColores = [];
    final List<String> previewEtiquetas = [];

    if (v1Valid) {
      previewVectores.add(Complejo.desdePolar(_amp1!, _fase1!));
      previewColores.add(const Color(0xFF0D47A1));
      previewEtiquetas.add('V1 - Sensor X');
    }
    if (v2Valid) {
      previewVectores.add(Complejo.desdePolar(_amp2!, _fase2!));
      previewColores.add(const Color(0xFFB71C1C));
      previewEtiquetas.add('V2 - Sensor Y');
    }


    // Scale: use the largest amplitude, or a sensible default when empty
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

            const Text('Sensor 1 (X)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amp1Controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText:
                      'Amplitud (${provider.config?.unidadStr ?? 'µm'})',
                  border: const OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fase1Controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AngleInputFormatter()],
              decoration: const InputDecoration(
                  labelText: 'Fase (°)', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 32),

            // Sensor 2 (Y) — always visible
            const Text('Sensor 2 (Y)',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amp2Controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText:
                      'Amplitud (${provider.config?.unidadStr ?? 'µm'})',
                  border: const OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fase2Controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AngleInputFormatter()],
              decoration: const InputDecoration(
                  labelText: 'Fase (°)', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 32),

            // ── Real-time polar preview ─────────────────────────────────
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.radar, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previsualización polar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                      ),
                      if (!v1Valid && !v2Valid)
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
                      final amp1 = double.parse(_amp1Controller.text);
                      final fase1 = double.parse(_fase1Controller.text);
                      final Complejo s1 = Complejo.desdePolar(amp1, fase1);

                      final amp2 = double.parse(_amp2Controller.text);
                      final fase2 = double.parse(_fase2Controller.text);
                      final Complejo s2 = Complejo.desdePolar(amp2, fase2);

                      provider.setMedicionInicial(s1, s2);
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