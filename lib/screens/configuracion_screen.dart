import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balanceo_provider.dart';
import '../models/rotor_config.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetController = TextEditingController();
  late SentidoGiro _sentido;
  late TipoRotor _tipo;
  late int _numAlabes;
  late double _keyphasor;
  late double _sensorX;
  late double _sensorY;
  late int _numPlanos;
  late double _limiteVibracion;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BalanceoProvider>(context, listen: false);
    _assetController.text = provider.config?.nombreActivo ?? '';
    _sentido = provider.config?.sentido ?? SentidoGiro.antihorario;
    _tipo = provider.config?.tipo ?? TipoRotor.continuo;
    _numAlabes = provider.config?.numAlabes ?? 0;
    _keyphasor = provider.config?.keyphasorAngulo ?? 0;
    _sensorX = provider.config?.sensorXAngulo ?? 0;
    _sensorY = provider.config?.sensorYAngulo ?? 90;
    _numPlanos = provider.config?.numPlanos ?? 1;
    _limiteVibracion = provider.config?.limiteVibracion ?? 50;
  }

  @override
  void dispose() {
    _assetController.dispose();
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
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
            const Text('Identificación del Activo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.precision_manufacturing),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  onChanged: (v) => setState(() => _assetController.text = v),
                );
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            const Text('Sentido de giro', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<SentidoGiro>(
              segments: const [
                ButtonSegment(value: SentidoGiro.antihorario, label: Text('Antihorario')),
                ButtonSegment(value: SentidoGiro.horario, label: Text('Horario')),
              ],
              selected: {_sentido},
              onSelectionChanged: (set) => setState(() => _sentido = set.first),
            ),
            const SizedBox(height: 16),

            const Text('Tipo de rotor', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<TipoRotor>(
              segments: const [
                ButtonSegment(value: TipoRotor.continuo, label: Text('Continuo')),
                ButtonSegment(value: TipoRotor.discreto, label: Text('Discreto')),
              ],
              selected: {_tipo},
              onSelectionChanged: (set) => setState(() => _tipo = set.first),
            ),
            const SizedBox(height: 16),

            if (_tipo == TipoRotor.discreto)
              TextFormField(
                key: ValueKey('numAlabes_$_numAlabes'),
                initialValue: _numAlabes.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número de álabes', border: OutlineInputBorder()),
                onChanged: (val) => _numAlabes = int.tryParse(val) ?? 0,
                validator: (v) => _tipo == TipoRotor.discreto && (int.tryParse(v ?? '0') ?? 0) <= 0 ? 'Requerido' : null,
              ),
            if (_tipo == TipoRotor.discreto) const SizedBox(height: 16),

            TextFormField(
              key: ValueKey('keyphasor_$_keyphasor'),
              initialValue: _keyphasor.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Ángulo keyphasor (°)', border: OutlineInputBorder()),
              onChanged: (val) => _keyphasor = double.tryParse(val) ?? 0,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('sensorX_$_sensorX'),
                    initialValue: _sensorX.toString(),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Sensor X (°)', border: OutlineInputBorder()),
                    onChanged: (val) => _sensorX = double.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('sensorY_$_sensorY'),
                    initialValue: _sensorY.toString(),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Sensor Y (°)', border: OutlineInputBorder()),
                    onChanged: (val) => _sensorY = double.tryParse(val) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Planos de corrección', style: TextStyle(fontWeight: FontWeight.bold)),
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

            TextFormField(
              key: ValueKey('limite_$_limiteVibracion'),
              initialValue: _limiteVibracion.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Límite Objetivo (μm)', border: OutlineInputBorder()),
              onChanged: (val) => _limiteVibracion = double.tryParse(val) ?? 50,
            ),
            const SizedBox(height: 80),
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
                );
                provider.setConfig(config).then((_) {
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, '/medicion');
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
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