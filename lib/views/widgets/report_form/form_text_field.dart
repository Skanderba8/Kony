// lib/views/widgets/report_form/form_text_field.dart
import 'package:flutter/material.dart';

/// A styled text field for the report form with standard formatting
class FormTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? initialValue;
  final bool required;
  final bool multiline;
  final int maxLines;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool readOnly;

  const FormTextField({
    super.key,
    required this.label,
    this.hintText,
    this.initialValue,
    this.required = false,
    this.multiline = false,
    this.maxLines = 1,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          validator: validator ?? (required ? _requiredValidator : null),
          keyboardType:
              keyboardType ??
              (multiline ? TextInputType.multiline : TextInputType.text),
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Default validator for required fields
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire';
    }
    return null;
  }
}
