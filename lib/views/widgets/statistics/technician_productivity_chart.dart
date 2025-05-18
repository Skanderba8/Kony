// lib/views/widgets/statistics/technician_productivity_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TechnicianProductivityChart extends StatelessWidget {
  final Map<String, int> productivity;
  final String Function(String) getTechnicianName;

  const TechnicianProductivityChart({
    super.key,
    required this.productivity,
    required this.getTechnicianName,
  });

  @override
  Widget build(BuildContext context) {
    if (productivity.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    // Convert productivity data with technician names
    final Map<String, int> namedProductivity = {};
    productivity.forEach((techId, count) {
      final techName = getTechnicianName(techId);
      namedProductivity[techName] = count;
    });

    // Sort and limit to top 10
    final List<MapEntry<String, int>> sortedEntries =
        namedProductivity.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(10).toList();

    // Max value for scaling
    final double maxValue = topEntries.first.value.toDouble() * 1.1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey.shade800,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final techName = topEntries[groupIndex].key;
                final count = topEntries[groupIndex].value;
                return BarTooltipItem(
                  '$techName\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: count.toString(),
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(
                      text: ' rapports',
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
                  if (value.toInt() >= 0 && value.toInt() < topEntries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _abbreviateName(topEntries[value.toInt()].key),
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
          barGroups: List.generate(topEntries.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: topEntries[index].value.toDouble(),
                  color: Colors.blue.shade700,
                  width: 20,
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
    );
  }

  // Abbreviate technician name for chart display
  String _abbreviateName(String name) {
    if (name.length <= 10) return name;

    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}. ${nameParts.last}';
    } else {
      return '${name.substring(0, 8)}...';
    }
  }
}
