import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balanceo_provider.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    final es2Planos = provider.config?.numPlanos == 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Balanceo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: provider.historial.isEmpty
          ? const Center(child: Text('No hay iteraciones guardadas'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.historial.length,
        itemBuilder: (context, index) {
          final item = provider.historial[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Iteración ${item.iteracion}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (item.masaPlano1 != null)
                    Text('Masa Plano 1: ${item.masaPlano1!.modulo.toStringAsFixed(2)} g @ ${item.masaPlano1!.anguloGrados.toStringAsFixed(1)}°'),
                  if (es2Planos && item.masaPlano2 != null)
                    Text('Masa Plano 2: ${item.masaPlano2!.modulo.toStringAsFixed(2)} g @ ${item.masaPlano2!.anguloGrados.toStringAsFixed(1)}°'),
                  const SizedBox(height: 4),
                  Text('Vibración residual: ${item.vibracionResidual1.toStringAsFixed(2)} μm'),
                  if (es2Planos)
                    Text('Vibración Sensor 2: ${item.vibracionResidual2.toStringAsFixed(2)} μm'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}