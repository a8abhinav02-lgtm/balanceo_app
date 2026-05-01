import 'package:flutter/material.dart';

class AnguloInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffixText;

  const AnguloInput({
    super.key,
    required this.controller,
    required this.label,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixText: suffixText ?? '°',
      ),
    );
  }
}