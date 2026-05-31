import 'package:flutter/material.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';
import 'package:provider/provider.dart';
import '../models/rotor_config.dart';

class ResultadoCard extends StatefulWidget {
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
  State<ResultadoCard> createState() => _ResultadoCardState();
}

class _ResultadoCardState extends State<ResultadoCard> {
  bool _isExpanded = false;

  int? _numAlabes;
  double? _refAngulo;
  bool? _numHoraria;

  TextEditingController? _numAlabesController;
  TextEditingController? _refAnguloController;

  void _onNumAlabesChanged(String val) {
    final parsed = int.tryParse(val);
    if (parsed != null && parsed > 1) {
      setState(() {
        _numAlabes = parsed;
      });
    }
  }

  void _onRefAnguloChanged(String val) {
    final parsed = double.tryParse(val);
    if (parsed != null) {
      setState(() {
        _refAngulo = parsed;
      });
    }
  }

  void _restaurarValores(RotorConfig config) {
    setState(() {
      _numAlabes = config.numAlabes;
      _refAngulo = config.anguloReferenciaAlabe1;
      _numHoraria = config.numeracionHoraria;
      _numAlabesController?.text = _numAlabes.toString();
      _refAnguloController?.text = _refAngulo.toString();
    });
  }

  @override
  void dispose() {
    _numAlabesController?.dispose();
    _refAnguloController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceoProvider>(context);

    if (widget.masa == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No se pudo calcular ${widget.titulo}'),
        ),
      );
    }

    final config = provider.config;
    if (config != null) {
      if (_numAlabes == null) {
        _numAlabes = config.numAlabes;
        _numAlabesController = TextEditingController(text: _numAlabes.toString());
      }
      if (_refAngulo == null) {
        _refAngulo = config.anguloReferenciaAlabe1;
        _refAnguloController = TextEditingController(text: _refAngulo.toString());
      }
      _numHoraria ??= config.numeracionHoraria;
    }

    final anguloAjustado = provider.ajustarAngulo(widget.masa!.anguloGrados);
    final alabe = provider.sugerirAlabe(widget.masa!.anguloGrados);
    final esDiscreto = config?.tipo == TipoRotor.discreto && (config?.numAlabes ?? 0) > 1;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Masa: ${widget.masa!.modulo.toStringAsFixed(2)} gramos',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timelapse, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Ángulo: ${anguloAjustado.toStringAsFixed(1)}°',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (alabe != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.view_module, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Álabe recomendado: N° $alabe',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            if (widget.numeroPlano != null && esDiscreto) ...[
              const SizedBox(height: 8),
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 18),
                  label: const Text(
                    'Ver división vectorial opcional',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              if (_isExpanded) ...[
                Builder(
                  builder: (context) {
                    final division = provider.calcularDivisionPesos(
                      widget.masa,
                      numAlabesOverride: _numAlabes,
                      anguloRefOverride: _refAngulo,
                      numeracionHorariaOverride: _numHoraria,
                    );
                    if (division == null) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'No se pudo calcular la división de pesos.',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      );
                    }

                    final vActual = widget.numeroPlano == 1 ? provider.masaRealInstalada1 : provider.masaRealInstalada2;
                    bool esUnicoActivo = false;
                    bool esDivididoActivo = false;

                    if (vActual != null && alabe != null) {
                      final numAlabes = _numAlabes ?? config?.numAlabes ?? 4;
                      final ref = _refAngulo ?? config?.anguloReferenciaAlabe1 ?? 0.0;
                      final numHoraria = _numHoraria ?? config?.numeracionHoraria ?? false;
                      final paso = 360.0 / numAlabes;
                      final alabeIndex = alabe - 1;
                      
                      double angAlabe = ref + (numHoraria ? -alabeIndex * paso : alabeIndex * paso);
                      double phase = (config?.sentido == SentidoGiro.horario) 
                          ? (angAlabe - config!.keyphasorAngulo) 
                          : (config!.keyphasorAngulo - angAlabe);
                      
                      final vUnico = Complejo.desdePolar(widget.masa!.modulo, phase);
                      esUnicoActivo = (vActual.real - vUnico.real).abs() < 1e-2 && (vActual.imaginario - vUnico.imaginario).abs() < 1e-2;
                    }

                    if (vActual != null && division != null) {
                      final vDividido = provider.calcularMasaEquivalenteDivision(
                        masaA: division['masaA'],
                        alabeA: division['alabeA'],
                        masaB: division['masaB'],
                        alabeB: division['alabeB'],
                        numAlabesOverride: _numAlabes,
                        anguloRefOverride: _refAngulo,
                        numeracionHorariaOverride: _numHoraria,
                      );
                      esDivididoActivo = (vActual.real - vDividido.real).abs() < 1e-2 && (vActual.imaginario - vDividido.imaginario).abs() < 1e-2;
                    }

                    void onInstalarUnico() {
                      final numAlabes = _numAlabes ?? config?.numAlabes ?? 4;
                      final ref = _refAngulo ?? config?.anguloReferenciaAlabe1 ?? 0.0;
                      final numHoraria = _numHoraria ?? config?.numeracionHoraria ?? false;
                      final paso = 360.0 / numAlabes;
                      final alabeIndex = alabe! - 1;
                      
                      double angAlabe = ref + (numHoraria ? -alabeIndex * paso : alabeIndex * paso);
                      double phase = (config?.sentido == SentidoGiro.horario) 
                          ? (angAlabe - config!.keyphasorAngulo) 
                          : (config!.keyphasorAngulo - angAlabe);
                      
                      final newMass = Complejo.desdePolar(widget.masa!.modulo, phase);
                      setState(() {
                        if (widget.numeroPlano == 1) {
                          provider.masaRealInstalada1 = newMass;
                        } else {
                          provider.masaRealInstalada2 = newMass;
                        }
                      });
                      provider.saveToDisk();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Se registró Álabe N° $alabe (${widget.masa!.modulo.toStringAsFixed(2)} g) como masa real instalada.')),
                      );
                    }

                    void onInstalarDividido() {
                      final eqMass = provider.calcularMasaEquivalenteDivision(
                        masaA: division['masaA'],
                        alabeA: division['alabeA'],
                        masaB: division['masaB'],
                        alabeB: division['alabeB'],
                        numAlabesOverride: _numAlabes,
                        anguloRefOverride: _refAngulo,
                        numeracionHorariaOverride: _numHoraria,
                      );
                      setState(() {
                        if (widget.numeroPlano == 1) {
                          provider.masaRealInstalada1 = eqMass;
                        } else {
                          provider.masaRealInstalada2 = eqMass;
                        }
                      });
                      provider.saveToDisk();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Se registró la división en Álabes N° ${division['alabeA']} y ${division['alabeB']} (${division['masaA'].toStringAsFixed(2)} g y ${division['masaB'].toStringAsFixed(2)} g) como masa real instalada.'
                          )
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'División Vectorial en Álabes Adyacentes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Álabe N° ${division['alabeA']}: ${division['masaA'].toStringAsFixed(2)} g',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Álabe N° ${division['alabeB']}: ${division['masaB'].toStringAsFixed(2)} g',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (esUnicoActivo)
                                ElevatedButton.icon(
                                  onPressed: onInstalarUnico,
                                  icon: const Icon(Icons.check, size: 14),
                                  label: const Text('Único Activo', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: onInstalarUnico,
                                  icon: const Icon(Icons.looks_one, size: 14),
                                  label: const Text('Instalar Único', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              if (esDivididoActivo)
                                ElevatedButton.icon(
                                  onPressed: onInstalarDividido,
                                  icon: const Icon(Icons.check, size: 14),
                                  label: const Text('Dividido Activo', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: onInstalarDividido,
                                  icon: const Icon(Icons.call_split, size: 14),
                                  label: const Text('Instalar Dividido', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Simulación de Montaje / Ajustes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _numAlabesController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Álabes',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onChanged: _onNumAlabesChanged,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _refAnguloController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Ángulo Ref (°)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onChanged: _onRefAnguloChanged,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _numHoraria,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _numHoraria = val;
                                        });
                                      }
                                    },
                                  ),
                                  const Text('Horario (CW)', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              if (config != null)
                                TextButton.icon(
                                  onPressed: () => _restaurarValores(config),
                                  icon: const Icon(Icons.settings_backup_restore, size: 14),
                                  label: const Text('Restaurar', style: TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Nota: Rotor discreto con ${config?.numAlabes} álabes. Se recomienda colocar la masa única en el álabe indicado.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}