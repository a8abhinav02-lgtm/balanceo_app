import 'package:flutter/material.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';
import 'package:provider/provider.dart';
import '../models/rotor_config.dart';

class ResultadoCard extends StatelessWidget {
  final Complejo? masa;
  final String titulo;
  final int? numeroPlano;

  const ResultadoCard({
    super.key,
    required this.masa,
    required this.titulo,
    this.numeroPlano,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);

    if (masa == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No se pudo calcular $titulo'),
        ),
      );
    }

    final anguloAjustado = provider.ajustarAngulo(masa!.anguloGrados);
    final alabe = provider.sugerirAlabe(masa!.anguloGrados);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Masa: ${masa!.modulo.toStringAsFixed(2)} gramos',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timelapse, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Ángulo: ${anguloAjustado.toStringAsFixed(1)}°',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (alabe != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.view_module, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Álabe recomendado: N° $alabe',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            if (numeroPlano != null && provider.config?.tipo == TipoRotor.discreto && provider.config!.numAlabes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Nota: Rotor discreto con ${provider.config!.numAlabes} álabes. Colocar la masa en el álabe indicado.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}