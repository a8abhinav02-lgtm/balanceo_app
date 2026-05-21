import 'canal_medicion.dart';

enum SentidoGiro { horario, antihorario }
enum TipoRotor { continuo, discreto }
enum UnidadVibracion { micras, mils }

class RotorConfig {
  String nombreActivo;
  SentidoGiro sentido;
  TipoRotor tipo;
  int numAlabes;
  double keyphasorAngulo;

  /// Lista dinámica de canales de medición con tags editables.
  /// Para el modo actual de 2 sensores, contiene exactamente 2 elementos.
  List<CanalMedicion> canales;

  int numPlanos;
  double limiteVibracion;

  // Campos para visualización avanzada
  double anguloReferenciaAlabe1;
  bool numeracionHoraria;
  UnidadVibracion unidadVibracion;

  /// Nombre del técnico responsable del balanceo (para el reporte PDF).
  String tecnico;

  // ── Getters de compatibilidad ──────────────────────────────────────────
  // Permiten que el código existente (polar_plot, pdf_export, etc.) siga
  // funcionando sin modificaciones inmediatas.
  double get sensorXAngulo => canales.isNotEmpty ? canales[0].angulo : 0;
  set sensorXAngulo(double v) { if (canales.isNotEmpty) canales[0].angulo = v; }

  double get sensorYAngulo => canales.length > 1 ? canales[1].angulo : 90;
  set sensorYAngulo(double v) { if (canales.length > 1) canales[1].angulo = v; }

  String get unidadStr => unidadVibracion == UnidadVibracion.micras ? 'µm' : 'mils';

  RotorConfig({
    required this.nombreActivo,
    this.sentido = SentidoGiro.antihorario,
    this.tipo = TipoRotor.continuo,
    this.numAlabes = 0,
    this.keyphasorAngulo = 0,
    List<CanalMedicion>? canales,
    this.numPlanos = 1,
    this.limiteVibracion = 50,
    this.anguloReferenciaAlabe1 = 0,
    this.numeracionHoraria = false,
    this.unidadVibracion = UnidadVibracion.micras,
    this.tecnico = '',
  }) : canales = canales ?? CanalMedicion.defaultCanales();

  RotorConfig copyWith({
    String? nombreActivo,
    SentidoGiro? sentido,
    TipoRotor? tipo,
    int? numAlabes,
    double? keyphasorAngulo,
    List<CanalMedicion>? canales,
    int? numPlanos,
    double? limiteVibracion,
    double? anguloReferenciaAlabe1,
    bool? numeracionHoraria,
    UnidadVibracion? unidadVibracion,
    String? tecnico,
  }) {
    return RotorConfig(
      nombreActivo: nombreActivo ?? this.nombreActivo,
      sentido: sentido ?? this.sentido,
      tipo: tipo ?? this.tipo,
      numAlabes: numAlabes ?? this.numAlabes,
      keyphasorAngulo: keyphasorAngulo ?? this.keyphasorAngulo,
      canales: canales ?? this.canales.map((c) => c.copy()).toList(),
      numPlanos: numPlanos ?? this.numPlanos,
      limiteVibracion: limiteVibracion ?? this.limiteVibracion,
      anguloReferenciaAlabe1: anguloReferenciaAlabe1 ?? this.anguloReferenciaAlabe1,
      numeracionHoraria: numeracionHoraria ?? this.numeracionHoraria,
      unidadVibracion: unidadVibracion ?? this.unidadVibracion,
      tecnico: tecnico ?? this.tecnico,
    );
  }

  String get sentidoTexto => sentido == SentidoGiro.horario ? 'Horario' : 'Antihorario';
  String get tipoTexto => tipo == TipoRotor.continuo ? 'Continuo' : 'Discreto';

  Map<String, dynamic> toJson() => {
    'nombreActivo': nombreActivo,
    'sentido': sentido.index,
    'tipo': tipo.index,
    'numAlabes': numAlabes,
    'keyphasorAngulo': keyphasorAngulo,
    'canales': canales.map((c) => c.toJson()).toList(),
    'numPlanos': numPlanos,
    'limiteVibracion': limiteVibracion,
    'anguloReferenciaAlabe1': anguloReferenciaAlabe1,
    'numeracionHoraria': numeracionHoraria,
    'unidadVibracion': unidadVibracion.index,
    'tecnico': tecnico,
  };

  /// Deserialización con migración retrocompatible.
  /// Si el JSON contiene los campos antiguos `sensorXAngulo`/`sensorYAngulo`
  /// (de versiones anteriores), se construyen automáticamente los objetos
  /// CanalMedicion equivalentes preservando los ángulos del usuario.
  factory RotorConfig.fromJson(Map<String, dynamic> json) {
    List<CanalMedicion> canales;

    if (json.containsKey('canales') && json['canales'] is List) {
      // Formato nuevo: lista de canales serializados
      canales = (json['canales'] as List)
          .map((e) => CanalMedicion.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      // Formato antiguo: migración automática de sensorXAngulo/sensorYAngulo
      final anguloX = (json['sensorXAngulo'] as num? ?? 0).toDouble();
      final anguloY = (json['sensorYAngulo'] as num? ?? 90).toDouble();
      canales = [
        CanalMedicion(tag: '1H', angulo: anguloX, idSoporte: 1, direccion: 'H'),
        CanalMedicion(tag: '2H', angulo: anguloY, idSoporte: 2, direccion: 'H'),
      ];
    }

    return RotorConfig(
      nombreActivo: json['nombreActivo'] as String? ?? 'Desconocido',
      sentido: SentidoGiro.values[json['sentido'] as int? ?? 1],
      tipo: TipoRotor.values[json['tipo'] as int? ?? 0],
      numAlabes: json['numAlabes'] as int? ?? 0,
      keyphasorAngulo: (json['keyphasorAngulo'] as num? ?? 0).toDouble(),
      canales: canales,
      numPlanos: json['numPlanos'] as int? ?? 1,
      limiteVibracion: (json['limiteVibracion'] as num? ?? 50).toDouble(),
      anguloReferenciaAlabe1: (json['anguloReferenciaAlabe1'] as num? ?? 0).toDouble(),
      numeracionHoraria: json['numeracionHoraria'] as bool? ?? false,
      unidadVibracion: UnidadVibracion.values[json['unidadVibracion'] as int? ?? 0],
      tecnico: json['tecnico'] as String? ?? '',
    );
  }
}