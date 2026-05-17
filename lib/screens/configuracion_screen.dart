import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balanceo_provider.dart';
import '../models/rotor_config.dart';
import '../utils/formatters.dart';
import 'guia_screen.dart';

import '../widgets/polar_plot.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetController = TextEditingController();
  final _tecnicoController = TextEditingController();
  late SentidoGiro _sentido;
  late TipoRotor _tipo;
  late int _numAlabes;
  late double _keyphasor;
  late double _sensorX;
  late double _sensorY;
  late int _numPlanos;
  late double _limiteVibracion;
  
  // Nuevos campos
  late double _anguloAlabe1;
  late bool _numeracionHoraria;
  late UnidadVibracion _unidadVibracion;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BalanceoProvider>(context, listen: false);
    _assetController.text = provider.config?.nombreActivo ?? '';
    _tecnicoController.text = provider.config?.tecnico ?? '';
    _sentido = provider.config?.sentido ?? SentidoGiro.antihorario;
    _tipo = provider.config?.tipo ?? TipoRotor.continuo;
    _numAlabes = provider.config?.numAlabes ?? 0;
    _keyphasor = provider.config?.keyphasorAngulo ?? 0;
    _sensorX = provider.config?.sensorXAngulo ?? 0;
    _sensorY = provider.config?.sensorYAngulo ?? 90;
    _numPlanos = provider.config?.numPlanos ?? 1;
    _limiteVibracion = provider.config?.limiteVibracion ?? 50;
    _anguloAlabe1 = provider.config?.anguloReferenciaAlabe1 ?? 0;
    _numeracionHoraria = provider.config?.numeracionHoraria ?? false;
    _unidadVibracion = provider.config?.unidadVibracion ?? UnidadVibracion.micras;
  }

  @override
  void dispose() {
    _assetController.dispose();
    _tecnicoController.dispose();
    super.dispose();
  }

  void _cargarDatosActivo(String nombre) {
    if (nombre.isEmpty) return;
    final provider = Provider.of<BalanceoProvider>(context, listen: false);
    provider.cargarActivo(nombre).then((_) {
      if (provider.config != null) {
        setState(() {
          _sentido = provider.config!.sentido;
          _tipo = provider.config!.tipo;
          _numAlabes = provider.config!.numAlabes;
          _keyphasor = provider.config!.keyphasorAngulo;
          _sensorX = provider.config!.sensorXAngulo;
          _sensorY = provider.config!.sensorYAngulo;
          _numPlanos = provider.config!.numPlanos;
          _limiteVibracion = provider.config!.limiteVibracion;
          _anguloAlabe1 = provider.config!.anguloReferenciaAlabe1;
          _numeracionHoraria = provider.config!.numeracionHoraria;
          _unidadVibracion = provider.config!.unidadVibracion;
        });
      }
    });
  }

  Future<void> _confirmarBorrado(BuildContext context, BalanceoProvider provider) async {
    final nombre = _assetController.text;
    if (nombre.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro de que desea eliminar todos los datos del activo "$nombre"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await provider.eliminarActivo(nombre);
      setState(() {
        _assetController.clear();
        _sentido = SentidoGiro.antihorario;
        _tipo = TipoRotor.continuo;
        _numAlabes = 0;
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Activo "$nombre" eliminado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Rotor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Guía de Operación',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GuiaScreen()));
            },
          ),
          if (_assetController.text.isNotEmpty && provider.listaActivos.contains(_assetController.text))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar Activo',
              onPressed: () => _confirmarBorrado(context, provider),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Identificación del Activo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') return const Iterable<String>.empty();
                        return provider.listaActivos.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (selection) {
                        _assetController.text = selection;
                        _cargarDatosActivo(selection);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        if (_assetController.text.isNotEmpty && controller.text.isEmpty) controller.text = _assetController.text;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Activo',
                            prefixIcon: Icon(Icons.precision_manufacturing),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                          onChanged: (v) => setState(() => _assetController.text = v),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Técnico responsable', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    const Text('Aparece en el reporte PDF', style: TextStyle(fontSize: 11, color: Color(0xFF616161))), // grey.shade700
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tecnicoController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del técnico',
                        prefixIcon: Icon(Icons.engineering),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Parámetros del Rotor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    const Text('Sentido de giro', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<SentidoGiro>(
                      segments: [
                        ButtonSegment(value: SentidoGiro.antihorario, label: Semantics(selected: _sentido == SentidoGiro.antihorario, child: const Text('Antihorario'))),
                        ButtonSegment(value: SentidoGiro.horario, label: Semantics(selected: _sentido == SentidoGiro.horario, child: const Text('Horario'))),
                      ],
                      selected: {_sentido},
                      onSelectionChanged: (set) => setState(() => _sentido = set.first),
                    ),
                    const SizedBox(height: 16),

                    const Text('Tipo de rotor', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<TipoRotor>(
                      segments: [
                        ButtonSegment(value: TipoRotor.continuo, label: Semantics(selected: _tipo == TipoRotor.continuo, child: const Text('Continuo'))),
                        ButtonSegment(value: TipoRotor.discreto, label: Semantics(selected: _tipo == TipoRotor.discreto, child: const Text('Discreto'))),
                      ],
                      selected: {_tipo},
                      onSelectionChanged: (set) => setState(() => _tipo = set.first),
                    ),
                    const SizedBox(height: 16),

                    if (_tipo == TipoRotor.discreto) ...[
                      TextFormField(
                        key: ValueKey('numAlabes_${_assetController.text}'),
                        initialValue: _numAlabes.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Número de álabes'),
                        onChanged: (val) => setState(() => _numAlabes = int.tryParse(val) ?? 0),
                        validator: (v) => _tipo == TipoRotor.discreto && (int.tryParse(v ?? '0') ?? 0) <= 0 ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: ValueKey('anguloAlabe1_${_assetController.text}'),
                        initialValue: _anguloAlabe1.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Ángulo del Álabe #1 (°)', helperText: 'Referencia visual en el gráfico'),
                        onChanged: (val) => setState(() => _anguloAlabe1 = double.tryParse(val) ?? 0),
                      ),
                      const SizedBox(height: 16),
                      const Text('Sentido de numeración de álabes', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(value: false, label: Semantics(selected: !_numeracionHoraria, child: const Text('Antihorario'))),
                          ButtonSegment(value: true, label: Semantics(selected: _numeracionHoraria, child: const Text('Horario'))),
                        ],
                        selected: {_numeracionHoraria},
                        onSelectionChanged: (set) => setState(() => _numeracionHoraria = set.first),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      key: ValueKey('keyphasor_${_assetController.text}'),
                      initialValue: _keyphasor.toString(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [AngleInputFormatter()],
                      decoration: const InputDecoration(labelText: 'Ángulo keyphasor (°)'),
                      onChanged: (val) => setState(() => _keyphasor = double.tryParse(val) ?? 0),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('sensorX_${_assetController.text}'),
                            initialValue: _sensorX.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [AngleInputFormatter()],
                            decoration: const InputDecoration(labelText: 'Sensor X (°)'),
                            onChanged: (val) => setState(() => _sensorX = double.tryParse(val) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('sensorY_${_assetController.text}'),
                            initialValue: _sensorY.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [AngleInputFormatter()],
                            decoration: const InputDecoration(labelText: 'Sensor Y (°)'),
                            onChanged: (val) => setState(() => _sensorY = double.tryParse(val) ?? 0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Planos de corrección', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    const Text('Número de puntos de colocación de masa en el rotor', style: TextStyle(fontSize: 11, color: Color(0xFF616161))), // grey.shade700
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1 plano')),
                        ButtonSegment(value: 2, label: Text('2 planos')),
                      ],
                      selected: {_numPlanos},
                      onSelectionChanged: (set) => setState(() => _numPlanos = set.first),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: ValueKey('limite_${_assetController.text}'),
                            initialValue: _limiteVibracion.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Límite Objetivo'),
                            onChanged: (val) => setState(() => _limiteVibracion = double.tryParse(val) ?? 50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: SegmentedButton<UnidadVibracion>(
                            segments: const [
                              ButtonSegment(value: UnidadVibracion.micras, label: Text('µm')),
                              ButtonSegment(value: UnidadVibracion.mils, label: Text('mils')),
                            ],
                            selected: {_unidadVibracion},
                            onSelectionChanged: (set) => setState(() => _unidadVibracion = set.first),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 16),
            const Text('Previsualización del Rotor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Colors.blueGrey.shade50.withAlpha(100),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blueGrey.shade100)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: PolarPlot(
                    vectores: const [],
                    colores: const [],
                    etiquetas: const [],
                    configOverride: RotorConfig(
                      nombreActivo: _assetController.text,
                      sentido: _sentido,
                      tipo: _tipo,
                      numAlabes: _numAlabes,
                      keyphasorAngulo: _keyphasor,
                      sensorXAngulo: _sensorX,
                      sensorYAngulo: _sensorY,
                      numPlanos: _numPlanos,
                      limiteVibracion: _limiteVibracion,
                      anguloReferenciaAlabe1: _anguloAlabe1,
                      numeracionHoraria: _numeracionHoraria,
                      unidadVibracion: _unidadVibracion,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100), // Espacio para no quedar tapado por el botón inferior
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
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final config = RotorConfig(
                  nombreActivo: _assetController.text,
                  sentido: _sentido,
                  tipo: _tipo,
                  numAlabes: _numAlabes,
                  keyphasorAngulo: _keyphasor,
                  sensorXAngulo: _sensorX,
                  sensorYAngulo: _sensorY,
                  numPlanos: _numPlanos,
                  limiteVibracion: _limiteVibracion,
                  anguloReferenciaAlabe1: _anguloAlabe1,
                  numeracionHoraria: _numeracionHoraria,
                  unidadVibracion: _unidadVibracion,
                  tecnico: _tecnicoController.text.trim(),
                );
                provider.setConfig(config).then((_) {
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, '/medicion');
                });
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Comenzar Medición', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ),
    );
  }
}