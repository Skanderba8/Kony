// lib/views/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../../view_models/admin_view_model.dart';
import '../../models/technical_visit_report.dart';
import '../../utils/notification_utils.dart';
import '../../app/routes.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Navigate to user management screen
  void _navigateToUserManagement() {
    Navigator.pushNamed(context, AppRoutes.userManagement);
  }

  // Handle logout action
  Future<void> _logout() async {
    final viewModel = Provider.of<AdminViewModel>(context, listen: false);

    try {
      await viewModel.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(
          context,
          "Error logging out: ${viewModel.errorMessage ?? e}",
        );
      }
    }
  }

  // Open the PDF associated with a technical visit report
  Future<void> _viewReportPdf(TechnicalVisitReport report) async {
    final viewModel = Provider.of<AdminViewModel>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfFile = await viewModel.generateReportPdf(report.id);

      // Close loading indicator
      if (mounted) Navigator.of(context).pop();

      if (pdfFile != null) {
        if (Platform.isAndroid || Platform.isIOS) {
          try {
            final result = await OpenFile.open(pdfFile.path);
            // Check if opening was successful in a way that's compatible with any version of open_file
            if (result.type != 'done' && result.type != 'done') {
              debugPrint('Error opening PDF: ${result.message}');
              if (mounted) {
                NotificationUtils.showError(
                  context,
                  'Could not open PDF: ${result.message}',
                );
              }
            }
          } catch (e) {
            debugPrint('Exception opening PDF: $e');
            if (mounted) {
              NotificationUtils.showError(context, 'Failed to open PDF: $e');
            }
          }
        } else {
          NotificationUtils.showInfo(
            context,
            'PDF generated at: ${pdfFile.path}',
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        if (mounted) {
          NotificationUtils.showError(
            context,
            viewModel.errorMessage ?? 'Failed to generate PDF',
          );
        }
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (mounted) Navigator.of(context).pop();
      debugPrint('Error generating PDF: $e');
      NotificationUtils.showError(context, 'Error generating PDF: $e');
    }
  }

  // Update the status of a technical visit report
  Future<void> _updateReportStatus(
    TechnicalVisitReport report,
    String newStatus,
  ) async {
    final String statusText =
        newStatus == 'reviewed' ? 'Mark as Reviewed' : 'Approve';

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('$statusText?'),
                content: Text(
                  'Are you sure you want to $statusText this report?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(statusText),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      final viewModel = Provider.of<AdminViewModel>(context, listen: false);
      final success = await viewModel.updateReportStatus(report.id, newStatus);

      if (success && mounted) {
        NotificationUtils.showSuccess(
          context,
          'Report marked as ${newStatus.toUpperCase()} successfully',
        );
      } else if (mounted) {
        NotificationUtils.showError(
          context,
          viewModel.errorMessage ?? 'Failed to update report status',
        );
      }
    }
  }

  // Delete a technical visit report
  Future<void> _confirmDeleteReport(TechnicalVisitReport report) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Report?'),
                content: const Text(
                  'Are you sure you want to delete this report? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      final viewModel = Provider.of<AdminViewModel>(context, listen: false);
      final success = await viewModel.deleteReport(report.id);

      if (success && mounted) {
        NotificationUtils.showSuccess(context, 'Report deleted successfully');
      } else if (mounted) {
        NotificationUtils.showError(
          context,
          viewModel.errorMessage ?? 'Failed to delete report',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          // User Management button
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _navigateToUserManagement,
            tooltip: 'User Management',
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor:
              Theme.of(context).primaryColor, // Blue text for selected tab
          unselectedLabelColor: Colors.grey, // Grey text for unselected tabs
          indicatorColor: Theme.of(context).primaryColor, // Blue indicator line
          indicatorWeight: 3, // Makes the indicator line more visible
          tabs: const [
            Tab(text: 'Submitted'),
            Tab(text: 'Reviewed'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: Consumer<AdminViewModel>(
        builder: (context, viewModel, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Submitted Reports Tab
              _buildReportList(
                viewModel.getSubmittedReportsStream(),
                'submitted',
              ),

              // Reviewed Reports Tab
              _buildReportList(
                viewModel.getReviewedReportsStream(),
                'reviewed',
              ),

              // Approved Reports Tab
              _buildReportList(
                viewModel.getApprovedReportsStream(),
                'approved',
              ),
            ],
          );
        },
      ),
    );
  }

  // Build a list of reports based on the provided stream and status
  Widget _buildReportList(
    Stream<List<TechnicalVisitReport>> stream,
    String status,
  ) {
    return StreamBuilder<List<TechnicalVisitReport>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading reports: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}), // Force refresh
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.toLowerCase()} reports',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report, status);
          },
        );
      },
    );
  }

  // Build a card to display a technical visit report
  Widget _buildReportCard(TechnicalVisitReport report, String status) {
    // Get status color
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'submitted':
        statusColor = Colors.blue;
        statusIcon = Icons.assignment_turned_in;
        break;
      case 'reviewed':
        statusColor = Colors.purple;
        statusIcon = Icons.fact_check;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    // Get the date to display
    final displayDate = report.submittedAt ?? report.createdAt;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Submitted: ${dateFormat.format(displayDate)} at ${timeFormat.format(displayDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // Report content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Client',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.clientName.isNotEmpty
                                ? report.clientName
                                : '(No client name)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.location.isNotEmpty
                                ? report.location
                                : '(No location)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Technician info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Technician',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.technicianName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Project Manager',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.projectManager.isNotEmpty
                                ? report.projectManager
                                : '(Not specified)',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Floors and components summary
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildInfoBadge(
                        'Floors',
                        '${report.floors.length}',
                        Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                        'Components',
                        _calculateTotalComponents(report).toString(),
                        Colors.amber.shade700,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                        'Est. Duration',
                        '${report.estimatedDurationDays} days',
                        Colors.green.shade700,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons - fixes overflow issue
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    // Delete button
                    IconButton(
                      onPressed: () => _confirmDeleteReport(report),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      tooltip: 'Delete Report',
                    ),

                    // View PDF button
                    OutlinedButton.icon(
                      onPressed: () => _viewReportPdf(report),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('View PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    // Status update buttons based on current status
                    if (status == 'submitted')
                      ElevatedButton.icon(
                        onPressed:
                            () => _updateReportStatus(report, 'reviewed'),
                        icon: const Icon(Icons.fact_check, size: 18),
                        label: const Text('Mark as Reviewed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                    if (status == 'reviewed')
                      ElevatedButton.icon(
                        onPressed:
                            () => _updateReportStatus(report, 'approved'),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build an info badge with a label and value
  Widget _buildInfoBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Calculate the total number of components across all floors
  int _calculateTotalComponents(TechnicalVisitReport report) {
    int total = 0;
    for (final floor in report.floors) {
      total += floor.totalComponentCount;
    }
    return total;
  }
}
