import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balanceo_provider.dart';
import 'guia_screen.dart';


class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    final es2Planos = provider.config?.numPlanos == 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Balanceo'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Iteración ${item.iteracion}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Eliminar Iteración',
                        onPressed: () => _confirmarEliminarIteracion(context, provider, index, item.iteracion),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (item.masaPlano1 != null)
                    Text('Masa Plano 1: ${item.masaPlano1!.modulo.toStringAsFixed(2)} g @ ${item.masaPlano1!.anguloGrados.toStringAsFixed(1)}°'),
                  if (es2Planos && item.masaPlano2 != null)
                    Text('Masa Plano 2: ${item.masaPlano2!.modulo.toStringAsFixed(2)} g @ ${item.masaPlano2!.anguloGrados.toStringAsFixed(1)}°'),
                  const SizedBox(height: 4),
                  Text('Vibración residual: ${item.vibracionResidual1.toStringAsFixed(2)} ${provider.config?.unidadStr ?? 'µm'}'),
                  if (es2Planos)
                    Text('Vibración Sensor 2: ${item.vibracionResidual2.toStringAsFixed(2)} ${provider.config?.unidadStr ?? 'µm'}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmarEliminarIteracion(BuildContext context, BalanceoProvider provider, int index, int numeroIteracion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('¿Eliminar Iteración $numeroIteracion?'),
          ],
        ),
        content: const Text(
          'Esta acción eliminará de forma permanente esta iteración del historial. Las iteraciones posteriores se reordenarán secuencialmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.eliminarIteracion(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Iteración $numeroIteracion eliminada del historial')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}