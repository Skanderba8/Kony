// lib/views/widgets/technical_visit_report_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/technical_visit_report.dart';

class TechnicalVisitReportCard extends StatelessWidget {
  final TechnicalVisitReport report;
  final Function(String) onStatusUpdate;
  final VoidCallback onViewDetails;

  const TechnicalVisitReportCard({
    super.key,
    required this.report,
    required this.onStatusUpdate,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (report.status) {
      case 'draft':
        statusColor = Colors.grey;
        statusIcon = Icons.edit_note;
        break;
      case 'submitted':
        statusColor = Colors.orange;
        statusIcon = Icons.send;
        break;
      case 'reviewed':
        statusColor = Colors.blue;
        statusIcon = Icons.fact_check;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    report.clientName.isNotEmpty
                        ? report.clientName
                        : 'Rapport de Visite Technique',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    report.status == 'draft'
                        ? 'BROUILLON'
                        : (report.status == 'submitted'
                            ? 'SOUMIS'
                            : (report.status == 'reviewed'
                                ? 'EXAMINÉ'
                                : 'APPROUVÉ')),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor.withOpacity(0.1),
                  avatar: Icon(statusIcon, size: 16, color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.location.isNotEmpty
                  ? report.location
                  : (report.projectContext.isNotEmpty
                      ? "${report.projectContext.substring(0, report.projectContext.length > 100 ? 100 : report.projectContext.length)}..."
                      : 'Aucun lieu spécifié'),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Par: ${report.technicianName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDateTime(report.submittedAt ?? report.createdAt),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Voir les Détails'),
                ),
                const SizedBox(width: 8),
                if (report.status == 'submitted')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('reviewed'),
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Marquer comme Examiné'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                if (report.status == 'reviewed')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('approved'),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Approuver'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormatter = DateFormat('HH:mm');

    return '${dateFormatter.format(dateTime)} à ${timeFormatter.format(dateTime)}';
  }
}
