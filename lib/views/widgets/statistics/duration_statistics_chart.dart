// lib/views/widgets/statistics/duration_statistics_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DurationStatisticsChart extends StatelessWidget {
  final Map<String, double> statistics;

  const DurationStatisticsChart({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty ||
        statistics['average'] == 0 &&
            statistics['median'] == 0 &&
            statistics['min'] == 0 &&
            statistics['max'] == 0) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    // Extract statistics
    final double avg = statistics['average'] ?? 0;
    final double median = statistics['median'] ?? 0;
    final double min = statistics['min'] ?? 0;
    final double max = statistics['max'] ?? 0;

    // Bar chart data
    final List<Map<String, dynamic>> data = [
      {'name': 'Minimum', 'value': min},
      {'name': 'Médiane', 'value': median},
      {'name': 'Moyenne', 'value': avg},
      {'name': 'Maximum', 'value': max},
    ];

    // Colors for each bar
    final List<Color> barColors = [
      Colors.blue.shade400,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.red.shade600,
    ];

    // Max value for Y axis
    final double maxY = (max * 1.1).ceilToDouble();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey.shade800,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${data[groupIndex]['name']}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                '${data[groupIndex]['value'].toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const TextSpan(
                            text: ' jours',
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              data[value.toInt()]['name'],
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
                barGroups: List.generate(data.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data[index]['value'],
                        color: barColors[index],
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),

        // Additional statistics text
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analyse de la durée estimée des projets',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La durée moyenne estimée des projets est de ${avg.toStringAsFixed(1)} jours, '
                    'avec une médiane de ${median.toStringAsFixed(1)} jours. '
                    'Le projet le plus court est estimé à ${min.toStringAsFixed(1)} jours, '
                    'tandis que le plus long nécessite ${max.toStringAsFixed(1)} jours.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
