import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final Function(String) onStatusUpdate;
  final VoidCallback onViewDetails;

  const ReportCard({
    super.key,
    required this.report,
    required this.onStatusUpdate,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    // Determine status color and icon
    switch (report.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
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
                    report.interventionTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    report.status.toUpperCase(),
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
              report.description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By: ${report.technicianName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDateTime(report.createdAt),
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
                  label: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                if (report.status == 'pending')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('reviewed'),
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Mark as Reviewed'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                if (report.status == 'reviewed')
                  TextButton.icon(
                    onPressed: () => onStatusUpdate('approved'),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Approve'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Format date and time in a user-friendly way
  String _formatDateTime(DateTime dateTime) {
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormatter = DateFormat('HH:mm');

    return '${dateFormatter.format(dateTime)} at ${timeFormatter.format(dateTime)}';
  }
}
