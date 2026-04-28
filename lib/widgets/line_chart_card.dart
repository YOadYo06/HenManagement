import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/reading.dart';

class LineChartCard extends StatelessWidget {
  const LineChartCard({
    super.key,
    required this.title,
    required this.unit,
    required this.color,
    required this.values,
  });

  final String title;
  final String unit;
  final Color color;
  final List<Reading> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: _minY(values),
                maxY: _maxY(values),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots(values),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.3), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _spots(List<Reading> values) {
    if (values.isEmpty) return const [FlSpot(0, 0)];
    return values
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), _value(entry.value)))
        .toList();
  }

  double _value(Reading reading) {
    switch (title) {
      case 'Light':
        return reading.light;
      case 'Noise':
        return reading.noise;
      case 'Temperature':
        return reading.temperature;
      case 'Humidity':
        return reading.humidity;
      default:
        return reading.light;
    }
  }

  double _minY(List<Reading> values) {
    if (values.isEmpty) return 0;
    final min = values.map(_value).reduce((a, b) => a < b ? a : b);
    return (min * 0.9).floorToDouble();
  }

  double _maxY(List<Reading> values) {
    if (values.isEmpty) return 100;
    final max = values.map(_value).reduce((a, b) => a > b ? a : b);
    return (max * 1.1).ceilToDouble();
  }
}
