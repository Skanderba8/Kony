// lib/views/widgets/report_form/form_number_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A specialized text field for numeric input with optional increment/decrement controls
class FormNumberField extends StatelessWidget {
  final String label;
  final num? value;
  final Function(num?) onChanged;
  final bool required;
  final num min;
  final num max;
  final num step;
  final bool decimal;
  final String? hintText;
  final bool showControls;

  const FormNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.min = 0,
    this.max = double.infinity,
    this.step = 1,
    this.decimal = false,
    this.hintText,
    this.showControls = true,
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: value?.toString() ?? '',
                keyboardType:
                    decimal
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                inputFormatters: [
                  decimal
                      ? FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*$'),
                      )
                      : FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (text) {
                  if (text.isEmpty) {
                    onChanged(null);
                    return;
                  }

                  num? parsedValue;
                  try {
                    parsedValue =
                        decimal ? double.parse(text) : int.parse(text);
                  } catch (e) {
                    return;
                  }

                  // Enforce min/max constraints
                  if (parsedValue < min) {
                    parsedValue = min;
                  } else if (parsedValue > max) {
                    parsedValue = max;
                  }

                  onChanged(parsedValue);
                },
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: Colors.white,
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
                ),
                validator:
                    required
                        ? (value) =>
                            (value == null || value.isEmpty)
                                ? 'Ce champ est obligatoire'
                                : null
                        : null,
              ),
            ),
            if (showControls) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final current = value ?? min;
                        num newValue;
                        if (decimal) {
                          newValue = (current + step).toDouble();
                        } else {
                          newValue = (current + step).toInt();
                        }
                        if (newValue <= max) {
                          onChanged(newValue);
                        }
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade300,
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        final current = value ?? min;
                        num newValue;
                        if (decimal) {
                          newValue = (current - step).toDouble();
                        } else {
                          newValue = (current - step).toInt();
                        }
                        if (newValue >= min) {
                          onChanged(newValue);
                        }
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
