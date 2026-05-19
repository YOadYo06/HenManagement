import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reading.dart';
import '../services/data_repository.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.repository});

  final DataRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF4F7F4), Color(0xFFE5EEF0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'History',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<Reading>>(
                    stream: repository.recentReadings(limit: 200),
                    builder: (context, snapshot) {
                      final readings = snapshot.data ?? [];
                      if (readings.isEmpty) {
                        return const Center(
                          child: Text('No history data available.',
                            style: TextStyle(color: Colors.black45)),
                        );
                      }
                      return _SensorHistoryGrid(readings: readings);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorHistoryGrid extends StatelessWidget {
  const _SensorHistoryGrid({required this.readings});

  final List<Reading> readings;

  @override
  Widget build(BuildContext context) {
    final sensors = <_SensorDef>[
      _SensorDef(title: 'Temperature', unit: '°C', color: const Color(0xFFE76F51)),
      _SensorDef(title: 'Humidity', unit: '%', color: const Color(0xFF457B9D)),
      _SensorDef(title: 'Noise', unit: 'dB', color: const Color(0xFF2A9D8F)),
      _SensorDef(title: 'Light', unit: 'lux', color: const Color(0xFFFFB703)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          itemCount: sensors.length,
          itemBuilder: (context, index) {
            final s = sensors[index];
            return Padding(
              padding: EdgeInsets.only(bottom: isWide ? 16 : 12),
              child: _SensorChart(
                title: s.title,
                unit: s.unit,
                color: s.color,
                readings: readings,
              ),
            );
          },
        );
      },
    );
  }
}

class _SensorDef {
  final String title;
  final String unit;
  final Color color;
  const _SensorDef({required this.title, required this.unit, required this.color});
}

class _SensorChart extends StatelessWidget {
  const _SensorChart({
    required this.title,
    required this.unit,
    required this.color,
    required this.readings,
  });

  final String title;
  final String unit;
  final Color color;
  final List<Reading> readings;

  double _value(Reading r) {
    switch (title) {
      case 'Temperature': return r.temperature;
      case 'Humidity': return r.humidity;
      case 'Noise': return r.noise;
      case 'Light': return r.light;
      default: return 0;
    }
  }

  String _timeRange() {
    if (readings.length < 2) return '';
    final first = readings.first.timestamp.toLocal();
    final last = readings.last.timestamp.toLocal();
    return '${DateFormat('MMM d, HH:mm').format(first)} – ${DateFormat('MMM d, HH:mm').format(last)}';
  }

  @override
  Widget build(BuildContext context) {
    final spots = readings.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), _value(e.value))).toList();
    final values = readings.map((r) => _value(r)).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final yPad = ((maxY - minY) * 0.15).clamp(0.1, double.infinity);
    final labelCount = readings.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text('${_value(readings.last).toStringAsFixed(1)} $unit',
                style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${readings.length} readings • ${_timeRange()}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY - yPad,
                maxY: maxY + yPad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _yInterval(minY, maxY),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text('Reading #',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _xInterval(labelCount),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= readings.length) return const SizedBox.shrink();
                        final t = readings[idx].timestamp.toLocal();
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            DateFormat('HH:mm').format(t),
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(unit,
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: _yInterval(minY, maxY),
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value == value.roundToDouble()
                              ? value.toInt().toString()
                              : value.toStringAsFixed(1),
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      final idx = spot.spotIndex;
                      final r = readings[idx];
                      final t = DateFormat('MMM d, HH:mm').format(r.timestamp.toLocal());
                      return LineTooltipItem(
                        '$t\n${_value(r).toStringAsFixed(1)} $unit',
                        TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _yInterval(double min, double max) {
    final range = max - min;
    if (range <= 1) return 0.2;
    if (range <= 5) return 1;
    if (range <= 20) return 5;
    if (range <= 100) return 20;
    return (range / 5).ceilToDouble();
  }

  double _xInterval(int count) {
    if (count <= 10) return 1;
    if (count <= 30) return 5;
    if (count <= 60) return 10;
    return (count / 6).ceilToDouble();
  }
}
