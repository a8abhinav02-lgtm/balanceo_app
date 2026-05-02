import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';

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

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BalanceoProvider>(context, listen: false);
    if (provider.v0_1 != null) {
      _amp1Controller.text = provider.v0_1!.modulo.toString();
      _fase1Controller.text = provider.v0_1!.anguloGrados.toString();
    }
    if (provider.v0_2 != null) {
      _amp2Controller.text = provider.v0_2!.modulo.toString();
      _fase2Controller.text = provider.v0_2!.anguloGrados.toString();
    }
  }

  @override
  void dispose() {
    _amp1Controller.dispose();
    _fase1Controller.dispose();
    _amp2Controller.dispose();
    _fase2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medición Inicial'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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

            const Text('Sensor 1 (X)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amp1Controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amplitud (μm)', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fase1Controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Fase (°)', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 32),

            const Text('Sensor 2 (Y)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amp2Controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amplitud (μm)', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fase2Controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Fase (°)', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
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
                    if (_formKey.currentState!.validate()) {
                      final amp1 = double.parse(_amp1Controller.text);
                      final fase1 = double.parse(_fase1Controller.text);
                      Complejo s1 = Complejo.desdePolar(amp1, fase1);

                      final amp2 = double.parse(_amp2Controller.text);
                      final fase2 = double.parse(_fase2Controller.text);
                      Complejo s2 = Complejo.desdePolar(amp2, fase2);
                      
                      provider.setMedicionInicial(s1, s2);
                      Navigator.pushNamed(context, '/prueba');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Siguiente'),
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
}