import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

class GuiaScreen extends StatelessWidget {
  const GuiaScreen({super.key});

  Future<String> _loadGuia() async {
    try {
      return await rootBundle.loadString('guia.md');
    } catch (e) {
      return '# Error\nNo se pudo cargar la guía técnica.\nDetalles: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía de Operación', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade50,
      ),
      body: FutureBuilder<String>(
        future: _loadGuia(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error al cargar la guía: ${snapshot.error}'));
          }

          return Markdown(
            data: snapshot.data!,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24),
              h2: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
              h3: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 18),
              p: const TextStyle(fontSize: 16, height: 1.5),
              listBullet: const TextStyle(fontSize: 16),
              code: TextStyle(
                backgroundColor: Colors.blue.shade50,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          );
        },
      ),
    );
  }
}
