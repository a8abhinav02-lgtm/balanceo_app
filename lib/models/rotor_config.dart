enum SentidoGiro { horario, antihorario }
enum TipoRotor { continuo, discreto }
enum UnidadVibracion { micras, mils }

class RotorConfig {
  String nombreActivo;
  SentidoGiro sentido;
  TipoRotor tipo;
  int numAlabes;
  double keyphasorAngulo;
  double sensorXAngulo;
  double sensorYAngulo;
  int numPlanos;
  double limiteVibracion;

  // Nuevos campos para visualización avanzada
  double anguloReferenciaAlabe1;
  bool numeracionHoraria;
  UnidadVibracion unidadVibracion;

  /// Nombre del técnico responsable del balanceo (para el reporte PDF).
  String tecnico;

  String get unidadStr => unidadVibracion == UnidadVibracion.micras ? 'µm' : 'mils';

  RotorConfig({
    required this.nombreActivo,
    this.sentido = SentidoGiro.antihorario,
    this.tipo = TipoRotor.continuo,
    this.numAlabes = 0,
    this.keyphasorAngulo = 0,
    this.sensorXAngulo = 0,
    this.sensorYAngulo = 90,
    this.numPlanos = 1,
    this.limiteVibracion = 50,
    this.anguloReferenciaAlabe1 = 0,
    this.numeracionHoraria = false,
    this.unidadVibracion = UnidadVibracion.micras,
    this.tecnico = '',
  });

  RotorConfig copyWith({
    String? nombreActivo,
    SentidoGiro? sentido,
    TipoRotor? tipo,
    int? numAlabes,
    double? keyphasorAngulo,
    double? sensorXAngulo,
    double? sensorYAngulo,
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
      sensorXAngulo: sensorXAngulo ?? this.sensorXAngulo,
      sensorYAngulo: sensorYAngulo ?? this.sensorYAngulo,
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
    'sensorXAngulo': sensorXAngulo,
    'sensorYAngulo': sensorYAngulo,
    'numPlanos': numPlanos,
    'limiteVibracion': limiteVibracion,
    'anguloReferenciaAlabe1': anguloReferenciaAlabe1,
    'numeracionHoraria': numeracionHoraria,
    'unidadVibracion': unidadVibracion.index,
    'tecnico': tecnico,
  };

  factory RotorConfig.fromJson(Map<String, dynamic> json) => RotorConfig(
    nombreActivo: json['nombreActivo'] as String? ?? 'Desconocido',
    sentido: SentidoGiro.values[json['sentido'] as int? ?? 1],
    tipo: TipoRotor.values[json['tipo'] as int? ?? 0],
    numAlabes: json['numAlabes'] as int? ?? 0,
    keyphasorAngulo: (json['keyphasorAngulo'] as num? ?? 0).toDouble(),
    sensorXAngulo: (json['sensorXAngulo'] as num? ?? 0).toDouble(),
    sensorYAngulo: (json['sensorYAngulo'] as num? ?? 90).toDouble(),
    numPlanos: json['numPlanos'] as int? ?? 1,
    limiteVibracion: (json['limiteVibracion'] as num? ?? 50).toDouble(),
    anguloReferenciaAlabe1: (json['anguloReferenciaAlabe1'] as num? ?? 0).toDouble(),
    numeracionHoraria: json['numeracionHoraria'] as bool? ?? false,
    unidadVibracion: UnidadVibracion.values[json['unidadVibracion'] as int? ?? 0],
    tecnico: json['tecnico'] as String? ?? '',
  );
}