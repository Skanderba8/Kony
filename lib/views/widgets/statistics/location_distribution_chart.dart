// lib/views/widgets/statistics/location_distribution_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LocationDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;

  const LocationDistributionChart({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const Center(
        child: Text('Aucune donnée de localisation disponible'),
      );
    }

    // Prepare data for the chart
    final List<MapEntry<String, int>> sortedEntries =
        distribution.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Take top locations
    final topLocations = sortedEntries.take(10).toList();

    // Calculate total for percentages
    final int total = distribution.values.fold(0, (sum, value) => sum + value);

    // Define colors
    final List<Color> colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.amber.shade600,
      Colors.pink.shade600,
      Colors.cyan.shade600,
    ];

    return Row(
      children: [
        // Pie chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: List.generate(topLocations.length, (i) {
                final entry = topLocations[i];
                final double percentage = entry.value / total * 100;
                final Color color = colors[i % colors.length];

                return PieChartSectionData(
                  color: color,
                  value: entry.value.toDouble(),
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),

        // Legend
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(topLocations.length, (index) {
                final entry = topLocations[index];
                final percentage = (entry.value / total * 100).toStringAsFixed(
                  1,
                );
                final color = colors[index % colors.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.value} ($percentage%)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
