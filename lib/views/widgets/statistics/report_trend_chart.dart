// lib/views/widgets/statistics/report_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/statistics/report_stats.dart';
import 'package:intl/intl.dart';

class ReportTrendChart extends StatelessWidget {
  final Map<String, ReportStats> monthlyStats;

  const ReportTrendChart({super.key, required this.monthlyStats});

  @override
  Widget build(BuildContext context) {
    // Sort by date
    final sortedEntries =
        monthlyStats.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    if (sortedEntries.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    // Prepare data for the chart
    final List<FlSpot> totalSpots = [];
    final List<FlSpot> draftSpots = [];
    final List<FlSpot> submittedSpots = [];
    final List<FlSpot> reviewedSpots = [];
    final List<FlSpot> approvedSpots = [];

    final List<String> bottomTitles = [];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final stats = entry.value;
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);

      // Format month
      final formatter = DateFormat('MMM yy');
      final formattedDate = formatter.format(date);
      bottomTitles.add(formattedDate);

      totalSpots.add(FlSpot(i.toDouble(), stats.total.toDouble()));
      draftSpots.add(FlSpot(i.toDouble(), stats.draft.toDouble()));
      submittedSpots.add(FlSpot(i.toDouble(), stats.submitted.toDouble()));
      reviewedSpots.add(FlSpot(i.toDouble(), stats.reviewed.toDouble()));
      approvedSpots.add(FlSpot(i.toDouble(), stats.approved.toDouble()));
    }

    // Find max value for Y axis
    double maxY = 0;
    for (var stats in monthlyStats.values) {
      if (stats.total > maxY) maxY = stats.total.toDouble();
    }
    maxY = (maxY * 1.2).ceilToDouble(); // Add 20% margin

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < bottomTitles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              bottomTitles[value.toInt()],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minX: 0,
                maxX: (sortedEntries.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: totalSpots,
                    isCurved: true,
                    color: Colors.blue.shade700,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: draftSpots,
                    isCurved: true,
                    color: Colors.grey.shade600,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: submittedSpots,
                    isCurved: true,
                    color: Colors.orange.shade600,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: reviewedSpots,
                    isCurved: true,
                    color: Colors.purple.shade600,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: approvedSpots,
                    isCurved: true,
                    color: Colors.green.shade600,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('Total', Colors.blue.shade700),
              _buildLegendItem('Brouillons', Colors.grey.shade600),
              _buildLegendItem('Soumis', Colors.orange.shade600),
              _buildLegendItem('Examinés', Colors.purple.shade600),
              _buildLegendItem('Approuvés', Colors.green.shade600),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
