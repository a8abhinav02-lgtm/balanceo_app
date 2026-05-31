import 'package:flutter/material.dart';
import '../models/complejo.dart';
import '../providers/balanceo_provider.dart';
import 'package:provider/provider.dart';
import '../models/rotor_config.dart';

class ConsolidacionCard extends StatefulWidget {
  final Complejo? masaRecomendada;
  final Complejo mAcumuladaPrevia;
  final String titulo;
  final int plano;

  const ConsolidacionCard({
    super.key,
    required this.masaRecomendada,
    required this.mAcumuladaPrevia,
    required this.titulo,
    required this.plano,
  });

  @override
  State<ConsolidacionCard> createState() => _ConsolidacionCardState();
}

class _ConsolidacionCardState extends State<ConsolidacionCard> {
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
    final config = provider.config;

    if (widget.masaRecomendada == null) {
      return const SizedBox.shrink();
    }

    final mConsolidada = widget.mAcumuladaPrevia + widget.masaRecomendada!;

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

    final anguloAjustado = provider.ajustarAngulo(mConsolidada.anguloGrados);
    final alabeConsolidado = provider.sugerirAlabe(mConsolidada.anguloGrados);
    final esDiscreto = config?.tipo == TipoRotor.discreto && (config?.numAlabes ?? 0) > 1;

    final vActual = widget.plano == 1 ? provider.masaRealInstalada1 : provider.masaRealInstalada2;

    // Calcular estado activo
    bool esConsolidadoActivo = false;
    bool esUnicoActivo = false;
    bool esDivididoActivo = false;

    Complejo? vUnicoConsolidado;
    if (alabeConsolidado != null && config != null) {
      final numAlabes = _numAlabes ?? config.numAlabes;
      final ref = _refAngulo ?? config.anguloReferenciaAlabe1;
      final numHoraria = _numHoraria ?? config.numeracionHoraria;
      final paso = 360.0 / numAlabes;
      final alabeIndex = alabeConsolidado - 1;
      
      double angAlabe = ref + (numHoraria ? -alabeIndex * paso : alabeIndex * paso);
      double phase = (config.sentido == SentidoGiro.horario) 
          ? (angAlabe - config.keyphasorAngulo) 
          : (config.keyphasorAngulo - angAlabe);
      
      vUnicoConsolidado = Complejo.desdePolar(mConsolidada.modulo, phase);
    }

    // Calcular división de la masa consolidada
    final division = esDiscreto
        ? provider.calcularDivisionPesos(
            mConsolidada,
            numAlabesOverride: _numAlabes,
            anguloRefOverride: _refAngulo,
            numeracionHorariaOverride: _numHoraria,
          )
        : null;

    Complejo? vDivididoConsolidado;
    if (division != null && config != null) {
      vDivididoConsolidado = provider.calcularMasaEquivalenteDivision(
        masaA: division['masaA'],
        alabeA: division['alabeA'],
        masaB: division['masaB'],
        alabeB: division['alabeB'],
        numAlabesOverride: _numAlabes,
        anguloRefOverride: _refAngulo,
        numeracionHorariaOverride: _numHoraria,
      );
    }

    if (vActual != null) {
      final vNeto = widget.mAcumuladaPrevia + vActual;
      
      esConsolidadoActivo = vActual.real == widget.masaRecomendada!.real && 
                            vActual.imaginario == widget.masaRecomendada!.imaginario;
                              
      if (vUnicoConsolidado != null) {
        esUnicoActivo = (vNeto.real - vUnicoConsolidado.real).abs() < 1e-2 && 
                        (vNeto.imaginario - vUnicoConsolidado.imaginario).abs() < 1e-2;
      }
      
      if (vDivididoConsolidado != null) {
        esDivididoActivo = !esConsolidadoActivo && 
                          (vNeto.real - vDivididoConsolidado.real).abs() < 1e-2 && 
                          (vNeto.imaginario - vDivididoConsolidado.imaginario).abs() < 1e-2;
      }
    }

    void onInstalarConsolidadoExacto() {
      setState(() {
        if (widget.plano == 1) {
          provider.masaRealInstalada1 = widget.masaRecomendada;
        } else {
          provider.masaRealInstalada2 = widget.masaRecomendada;
        }
      });
      provider.saveToDisk();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se registró la consolidación exacta (${mConsolidada.modulo.toStringAsFixed(2)} g @ ${anguloAjustado.toStringAsFixed(1)}°) como masa real instalada.'
          )
        ),
      );
    }

    void onInstalarUnicoConsolidado() {
      if (vUnicoConsolidado == null) return;
      setState(() {
        if (widget.plano == 1) {
          provider.masaRealInstalada1 = vUnicoConsolidado! - widget.mAcumuladaPrevia;
        } else {
          provider.masaRealInstalada2 = vUnicoConsolidado! - widget.mAcumuladaPrevia;
        }
      });
      provider.saveToDisk();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se registró Álabe N° $alabeConsolidado (${mConsolidada.modulo.toStringAsFixed(2)} g) como masa consolidada instalada.'
          )
        ),
      );
    }

    void onInstalarDivididoConsolidado() {
      if (vDivididoConsolidado == null) return;
      setState(() {
        if (widget.plano == 1) {
          provider.masaRealInstalada1 = vDivididoConsolidado! - widget.mAcumuladaPrevia;
        } else {
          provider.masaRealInstalada2 = vDivididoConsolidado! - widget.mAcumuladaPrevia;
        }
      });
      provider.saveToDisk();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se registró la división consolidada en Álabes N° ${division!['alabeA']} y ${division['alabeB']} (${division['masaA'].toStringAsFixed(2)} g y ${division['masaB'].toStringAsFixed(2)} g) como masa real instalada.'
          )
        ),
      );
    }

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 1.5),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers, color: Colors.blue.shade900),
                const SizedBox(width: 8),
                Text(
                  widget.titulo,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Combina la masa recomendada de esta iteración con todas las masas reales instaladas en las iteraciones anteriores.',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.blur_circular, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Masa Consolidada: ${mConsolidada.modulo.toStringAsFixed(2)} g @ ${anguloAjustado.toStringAsFixed(1)}°',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (alabeConsolidado != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.view_module, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Álabe consolidado recomendado: N° $alabeConsolidado',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Instrucciones de Campo: retire todos los contrapesos anteriores instalados en este plano y coloque una sola masa equivalente.',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (esConsolidadoActivo)
                  ElevatedButton.icon(
                    onPressed: onInstalarConsolidadoExacto,
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Consolidado Activo', style: TextStyle(fontSize: 11)),
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
                    onPressed: onInstalarConsolidadoExacto,
                    icon: const Icon(Icons.layers, size: 14),
                    label: const Text('Instalar Consolidado', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (alabeConsolidado != null) ...[
                  const SizedBox(width: 8),
                  if (esUnicoActivo)
                    ElevatedButton.icon(
                      onPressed: onInstalarUnicoConsolidado,
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
                      onPressed: onInstalarUnicoConsolidado,
                      icon: const Icon(Icons.looks_one, size: 14),
                      label: const Text('Instalar Único', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ],
            ),
            if (widget.plano != null && esDiscreto) ...[
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
                    'Ver división de masa consolidada',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              if (_isExpanded) ...[
                if (division == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'No se pudo calcular la división de la masa consolidada.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'División Vectorial de Masa Consolidada:',
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
                            if (esDivididoActivo)
                              ElevatedButton.icon(
                                onPressed: onInstalarDivididoConsolidado,
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
                                onPressed: onInstalarDivididoConsolidado,
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
                          'Simulación de Consolidado / Ajustes:',
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
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
