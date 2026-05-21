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
  }

  @override
  void dispose() {
    _mtModController.dispose();
    _mtFaseController.dispose();
    _mt2ModController.dispose();
    _mt2FaseController.dispose();
    for (int i = 0; i < _numCanales; i++) {
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              const Text('Mediciones con peso en P2:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
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
}