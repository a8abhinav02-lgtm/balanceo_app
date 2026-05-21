/// Modelo de datos flexible para representar un canal/posición de medición.
///
/// Reemplaza los campos rígidos `sensorXAngulo`/`sensorYAngulo` del modelo
/// anterior, permitiendo tags personalizables (ej: "1H", "2V", "DE-H")
/// que se alinean con la nomenclatura estándar de campo (ISO 21940).
class CanalMedicion {
  /// Tag visible para el usuario. Editable libremente.
  /// Ejemplos: "1H", "2H", "1V", "2V", "DE-H", "NDE-V".
  String tag;

  /// Ángulo físico de instalación del sensor respecto al eje vertical
  /// del rotor, en grados (0° = horizontal, 90° = vertical).
  double angulo;

  /// Identificador del soporte/rodamiento físico (1 o 2).
  int idSoporte;

  /// Dirección de medición: "H" (horizontal), "V" (vertical),
  /// "X" o "Y" (para sondas de proximidad).
  String direccion;

  CanalMedicion({
    required this.tag,
    this.angulo = 0,
    this.idSoporte = 1,
    this.direccion = 'H',
  });

  /// Crea una copia independiente del canal.
  CanalMedicion copy() => CanalMedicion(
    tag: tag,
    angulo: angulo,
    idSoporte: idSoporte,
    direccion: direccion,
  );

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'angulo': angulo,
    'idSoporte': idSoporte,
    'direccion': direccion,
  };

  factory CanalMedicion.fromJson(Map<String, dynamic> json) => CanalMedicion(
    tag: json['tag'] as String? ?? '1H',
    angulo: (json['angulo'] as num? ?? 0).toDouble(),
    idSoporte: json['idSoporte'] as int? ?? 1,
    direccion: json['direccion'] as String? ?? 'H',
  );

  /// Canales por defecto para un nuevo activo (2 soportes, horizontal).
  static List<CanalMedicion> defaultCanales() => [
    CanalMedicion(tag: '1H', angulo: 0, idSoporte: 1, direccion: 'H'),
    CanalMedicion(tag: '2H', angulo: 0, idSoporte: 2, direccion: 'H'),
  ];
}
