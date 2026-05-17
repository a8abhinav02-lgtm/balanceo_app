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

  // Para 1 plano
  final _mtModController = TextEditingController();
  final _mtFaseController = TextEditingController();
  final _v1AmpController = TextEditingController();
  final _v1FaseController = TextEditingController();
  final _v2AmpController = TextEditingController(); // Sensor 2 en 1 plano
  final _v2FaseController = TextEditingController(); // Sensor 2 en 1 plano

  // Para 2 planos
  final _mt1ModController = TextEditingController();
  final _mt1FaseController = TextEditingController();
  final _v1_1AmpController = TextEditingController();
  final _v1_1FaseController = TextEditingController();
  final _v1_2AmpController = TextEditingController();
  final _v1_2FaseController = TextEditingController();
  final _mt2ModController = TextEditingController();
  final _mt2FaseController = TextEditingController();
  final _v2_1AmpController = TextEditingController();
  final _v2_1FaseController = TextEditingController();
  final _v2_2AmpController = TextEditingController();
  final _v2_2FaseController = TextEditingController();

  int _paso = 1; // 1: Plano1, 2: Plano2 (solo para 2 planos)

  /// En modo 1 plano: true = usar Sensor X como base de cálculo, false = Sensor Y
  bool _usarSensorX = true;

  @override
  void dispose() {
    _mtModController.dispose();
    _mtFaseController.dispose();
    _v1AmpController.dispose();
    _v1FaseController.dispose();
    _v2AmpController.dispose();
    _v2FaseController.dispose();
    _mt1ModController.dispose();
    _mt1FaseController.dispose();
    _v1_1AmpController.dispose();
    _v1_1FaseController.dispose();
    _v1_2AmpController.dispose();
    _v1_2FaseController.dispose();
    _mt2ModController.dispose();
    _mt2FaseController.dispose();
    _v2_1AmpController.dispose();
    _v2_1FaseController.dispose();
    _v2_2AmpController.dispose();
    _v2_2FaseController.dispose();
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
            if (!es2Planos) ...[
              const Text('PESO DE PRUEBA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 12),
              _buildCampo('Masa de prueba (g)', _mtModController),
              const SizedBox(height: 12),
              _buildCampo('Ángulo de colocación (°)', _mtFaseController),
              const SizedBox(height: 24),
              
              const Text('Medición Sensor 1 (X):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 8),
              _buildCampo('Amplitud (${provider.config?.unidadStr ?? 'µm'})', _v1AmpController),
              const SizedBox(height: 12),
              _buildCampo('Fase (°)', _v1FaseController),
              const SizedBox(height: 20),

              const Text('Medición Sensor 2 (Y):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              _buildCampo('Amplitud (${provider.config?.unidadStr ?? 'µm'})', _v2AmpController),
              const SizedBox(height: 12),
              _buildCampo('Fase (°)', _v2FaseController),
              const SizedBox(height: 28),

              // ── Selector de vector para el cálculo ──────────────────────
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Sensor de cálculo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '¿Con cuál sensor se calcula la masa correctora?',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Sensor X'),
                    icon: Icon(Icons.circle, color: Colors.blue, size: 12),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Sensor Y'),
                    icon: Icon(Icons.square, color: Colors.red, size: 12),
                  ),
                ],
                selected: {_usarSensorX},
                onSelectionChanged: (val) => setState(() => _usarSensorX = val.first),
              ),
            ] else ...[
              if (_paso == 1) ...[
                const Text('PESO DE PRUEBA EN PLANO 1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 12),
                _buildCampo('Masa de prueba (g)', _mt1ModController),
                const SizedBox(height: 12),
                _buildCampo('Ángulo de colocación (°)', _mt1FaseController),
                const SizedBox(height: 20),
                const Text('Mediciones con peso en P1:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                _buildCampo('Sensor 1 (X) - Amplitud (${provider.config?.unidadStr ?? 'µm'})', _v1_1AmpController),
                const SizedBox(height: 12),
                _buildCampo('Sensor 1 (X) - Fase (°)', _v1_1FaseController),
                const SizedBox(height: 12),
                _buildCampo('Sensor 2 (Y) - Amplitud (${provider.config?.unidadStr ?? 'µm'})', _v1_2AmpController),
                const SizedBox(height: 12),
                _buildCampo('Sensor 2 (Y) - Fase (°)', _v1_2FaseController),
              ] else ...[
                const Text('PESO DE PRUEBA EN PLANO 2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 12),
                _buildCampo('Masa de prueba (g)', _mt2ModController),
                const SizedBox(height: 12),
                _buildCampo('Ángulo de colocación (°)', _mt2FaseController),
                const SizedBox(height: 20),
                const Text('Mediciones con peso en P2:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                _buildCampo('Sensor 1 (X) - Amplitud (${provider.config?.unidadStr ?? 'µm'})', _v2_1AmpController),
                const SizedBox(height: 12),
                _buildCampo('Sensor 1 (X) - Fase (°)', _v2_1FaseController),
                const SizedBox(height: 12),
                _buildCampo('Sensor 2 (Y) - Amplitud (${provider.config?.unidadStr ?? 'µm'})', _v2_2AmpController),
                const SizedBox(height: 12),
                _buildCampo('Sensor 2 (Y) - Fase (°)', _v2_2FaseController),
              ],
            ],
            const SizedBox(height: 100),
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
                        final v1X = Complejo.desdePolar(double.parse(_v1AmpController.text), double.parse(_v1FaseController.text));
                        final v1Y = Complejo.desdePolar(double.parse(_v2AmpController.text), double.parse(_v2FaseController.text));

                        provider.calcularCoeficientes1Plano(
                          pesoPrueba: mt,
                          v1X: v1X,
                          v1Y: v1Y,
                          usarX: _usarSensorX,
                        );
                        Navigator.pushNamed(context, '/resultados');
                      } else {
                        if (_paso == 1) {
                          setState(() => _paso = 2);
                        } else {
                          final mt1 = Complejo.desdePolar(double.parse(_mt1ModController.text), double.parse(_mt1FaseController.text));
                          final mt2 = Complejo.desdePolar(double.parse(_mt2ModController.text), double.parse(_mt2FaseController.text));
                          final v1_1 = Complejo.desdePolar(double.parse(_v1_1AmpController.text), double.parse(_v1_1FaseController.text));
                          final v1_2 = Complejo.desdePolar(double.parse(_v1_2AmpController.text), double.parse(_v1_2FaseController.text));
                          final v2_1 = Complejo.desdePolar(double.parse(_v2_1AmpController.text), double.parse(_v2_1FaseController.text));
                          final v2_2 = Complejo.desdePolar(double.parse(_v2_2AmpController.text), double.parse(_v2_2FaseController.text));
                          provider.calcularCoeficientes2Planos(mt1, mt2, v1_1, v1_2, v2_1, v2_2);
                          Navigator.pushNamed(context, '/resultados');
                        }
                      }
                    }
                  },
                  icon: Icon(es2Planos && _paso == 1 ? Icons.arrow_forward : Icons.calculate),
                  label: Text(es2Planos && _paso == 1 ? 'Siguiente' : 'Calcular'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
    );
  }
}