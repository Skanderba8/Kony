// lib/views/widgets/report_form/section_header.dart
import 'package:flutter/material.dart';

/// A styled header for each section of the report form
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade300, thickness: 1.0),
        const SizedBox(height: 16),
      ],
    );
  }
}
