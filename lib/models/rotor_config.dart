enum SentidoGiro { horario, antihorario }
enum TipoRotor { continuo, discreto }

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
  };

  factory RotorConfig.fromJson(Map<String, dynamic> json) => RotorConfig(
    nombreActivo: json['nombreActivo'] as String? ?? 'Desconocido',
    sentido: SentidoGiro.values[json['sentido'] as int],
    tipo: TipoRotor.values[json['tipo'] as int],
    numAlabes: json['numAlabes'] as int,
    keyphasorAngulo: (json['keyphasorAngulo'] as num).toDouble(),
    sensorXAngulo: (json['sensorXAngulo'] as num).toDouble(),
    sensorYAngulo: (json['sensorYAngulo'] as num).toDouble(),
    numPlanos: json['numPlanos'] as int,
    limiteVibracion: (json['limiteVibracion'] as num).toDouble(),
  );
}