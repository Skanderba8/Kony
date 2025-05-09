// In file: lib/views/widgets/report_form/form_number_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A specialized text field for numeric input with functional increment/decrement controls
class FormNumberField extends StatefulWidget {
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
  State<FormNumberField> createState() => _FormNumberFieldState();
}

class _FormNumberFieldState extends State<FormNumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(FormNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if the value changes externally
    if (widget.value?.toString() != _controller.text) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Increment the value
  void _increment() {
    num currentValue = widget.value ?? widget.min;
    num newValue;

    if (widget.decimal) {
      newValue = (currentValue + widget.step).toDouble();
    } else {
      newValue = (currentValue + widget.step).toInt();
    }

    if (newValue <= widget.max) {
      _controller.text = newValue.toString();
      widget.onChanged(newValue);
    }
  }

  // Decrement the value
  void _decrement() {
    num currentValue = widget.value ?? widget.min;
    num newValue;

    if (widget.decimal) {
      newValue = (currentValue - widget.step).toDouble();
    } else {
      newValue = (currentValue - widget.step).toInt();
    }

    if (newValue >= widget.min) {
      _controller.text = newValue.toString();
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            if (widget.required) ...[
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
                controller: _controller,
                keyboardType:
                    widget.decimal
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                inputFormatters: [
                  widget.decimal
                      ? FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*$'),
                      )
                      : FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (text) {
                  if (text.isEmpty) {
                    widget.onChanged(null);
                    return;
                  }

                  num? parsedValue;
                  try {
                    parsedValue =
                        widget.decimal ? double.parse(text) : int.parse(text);
                  } catch (e) {
                    return;
                  }

                  // Enforce min/max constraints
                  if (parsedValue < widget.min) {
                    parsedValue = widget.min;
                    _controller.text = parsedValue.toString();
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                  } else if (parsedValue > widget.max) {
                    parsedValue = widget.max;
                    _controller.text = parsedValue.toString();
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                  }

                  widget.onChanged(parsedValue);
                },
                decoration: InputDecoration(
                  hintText: widget.hintText,
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
                    widget.required
                        ? (value) =>
                            (value == null || value.isEmpty)
                                ? 'Ce champ est obligatoire'
                                : null
                        : null,
              ),
            ),
            if (widget.showControls) ...[
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
                      onPressed: _increment,
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
                      onPressed: _decrement,
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
