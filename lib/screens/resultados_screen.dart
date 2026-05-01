import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balanceo_provider.dart';
import '../widgets/polar_plot.dart';
import '../widgets/resultado_card.dart';
import '../models/complejo.dart';
import '../utils/pdf_export.dart';

class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    final es2Planos = provider.config?.numPlanos == 2;

    Complejo? m1;
    Complejo? m2;

    if (es2Planos) {
      final correccion = provider.calcularCorreccion2Planos();
      m1 = correccion[0];
      m2 = correccion[1];
    } else {
      m1 = provider.calcularCorreccion1Plano();
    }

    List<Complejo> vectores = [];
    List<Color> colores = [];
    List<String> etiquetas = [];

    if (provider.sensor1Actual != null) {
      vectores.add(provider.sensor1Actual!);
      colores.add(Colors.blue);
      etiquetas.add('Vib. Inicial');
    }
    if (es2Planos && provider.sensor2Actual != null) {
      vectores.add(provider.sensor2Actual!);
      colores.add(Colors.red);
      etiquetas.add('Sensor 2');
    }
    if (m1 != null) {
      vectores.add(m1);
      colores.add(Colors.green);
      etiquetas.add('Masa P1');
    }
    if (es2Planos && m2 != null) {
      vectores.add(m2);
      colores.add(Colors.orange);
      etiquetas.add('Masa P2');
    }

    final maxAmp = vectores.isEmpty ? 10.0 : vectores.map((v) => v.modulo).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados del Balanceo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar Reporte',
            onPressed: () => PdfExport.imprimirReporte(provider),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/historial'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masas Correctoras Calculadas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ResultadoCard(masa: m1, titulo: es2Planos ? 'Plano 1' : 'Masa Correctora', numeroPlano: 1),
            if (es2Planos && m2 != null)
              ResultadoCard(masa: m2, titulo: 'Plano 2', numeroPlano: 2),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Diagrama Polar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: PolarPlot(
                vectores: vectores,
                colores: colores,
                etiquetas: etiquetas,
                maxRadio: maxAmp * 1.2,
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Acciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoNuevaIteracion(context, provider),
                icon: const Icon(Icons.refresh),
                label: const Text('Nueva Iteración (Refinar)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
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
                    provider.agregarAlHistorial(m1, m2, 0);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en historial')));
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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

  void _mostrarDialogoNuevaIteracion(BuildContext context, BalanceoProvider provider) {
    final amp1Controller = TextEditingController();
    final fase1Controller = TextEditingController();
    final amp2Controller = TextEditingController();
    final fase2Controller = TextEditingController();
    final es2Planos = provider.config?.numPlanos == 2;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Medición'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingrese la vibración actual tras instalar las masas:'),
              const SizedBox(height: 16),
              TextField(controller: amp1Controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Sensor 1 (X) - Amplitud (μm)')),
              const SizedBox(height: 8),
              TextField(controller: fase1Controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Sensor 1 (X) - Fase (°)')),
              if (es2Planos) ...[
                const SizedBox(height: 8),
                TextField(controller: amp2Controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Sensor 2 (Y) - Amplitud (μm)')),
                const SizedBox(height: 8),
                TextField(controller: fase2Controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Sensor 2 (Y) - Fase (°)')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final v1 = Complejo.desdePolar(double.tryParse(amp1Controller.text) ?? 0, double.tryParse(fase1Controller.text) ?? 0);
              if (es2Planos) {
                final v2 = Complejo.desdePolar(double.tryParse(amp2Controller.text) ?? 0, double.tryParse(fase2Controller.text) ?? 0);
                provider.nuevaIteracion(v1, v2);
              } else {
                provider.nuevaIteracion(v1);
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Recalcular'),
          ),
        ],
      ),
    );
  }
}