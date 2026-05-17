import 'package:flutter/services.dart';

class AngleInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Permitir solo números y un solo punto decimal
    final regExp = RegExp(r'^\d*\.?\d*$');
    if (!regExp.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Validar el rango numérico
    final double? value = double.tryParse(newValue.text);
    if (value != null) {
      // Si es mayor a 359.99, retornamos el valor anterior
      if (value >= 360.0) {
        return oldValue;
      }
    }

    return newValue;
  }
}
