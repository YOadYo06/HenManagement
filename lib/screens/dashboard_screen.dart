import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reading.dart';
import '../models/thresholds.dart';
import '../services/data_repository.dart';
import '../widgets/alert_panel.dart';
import '../widgets/comfort_gauge.dart';
import '../widgets/connection_pill.dart';
import '../widgets/line_chart_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/thresholds_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.firebaseReady,
  });

  final DataRepository repository;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: StreamBuilder<List<Reading>>(
              stream: repository.recentReadings(limit: 50),
              builder: (context, snapshot) {
                final readings = snapshot.data ?? [];
                final latest = readings.isNotEmpty ? readings.last : null;

                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 550),
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          repository: repository,
                          firebaseReady: firebaseReady,
                          latest: latest,
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Live metrics',
                          subtitle: 'Current conditions in the study zone.',
                        ),
                        _StatGrid(latest: latest),
                        const SizedBox(height: 26),
                        SectionHeader(
                          title: 'Comfort score',
                          subtitle: 'Computed from light, noise, and temperature.',
                        ),
                        _ComfortSection(
                          repository: repository,
                          latest: latest,
                        ),
                        const SizedBox(height: 26),
                        SectionHeader(
                          title: 'Trends',
                          subtitle: 'Recent sensor readings over time.',
                        ),
                        _TrendGrid(readings: readings),
                        const SizedBox(height: 26),
                        SectionHeader(
                          title: 'Alerts',
                          subtitle: 'Latest detected issues.',
                        ),
                        StreamBuilder(
                          stream: repository.recentAlerts(limit: 8),
                          builder: (context, snapshot) {
                            return AlertPanel(alerts: snapshot.data ?? []);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.repository,
    required this.firebaseReady,
    required this.latest,
  });

  final DataRepository repository;
  final bool firebaseReady;
  final Reading? latest;

  @override
  Widget build(BuildContext context) {
    final time = latest?.timestamp.toLocal();
    final formatted = time != null
        ? DateFormat('MMM d, HH:mm:ss').format(time)
        : 'Waiting for data...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Study Desk Monitor',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Realtime dashboard',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            StreamBuilder<bool>(
              stream: repository.connectionStatus(),
              builder: (context, snapshot) {
                return ConnectionPill(
                  connected: snapshot.data ?? false,
                  showMock: !firebaseReady,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Last update: $formatted',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.latest});

  final Reading? latest;

  @override
  Widget build(BuildContext context) {
    final light = latest?.light ?? 0;
    final noise = latest?.noise ?? 0;
    final temp = latest?.temperature ?? 0;
    final humidity = latest?.humidity ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        final itemWidth = isWide
            ? (constraints.maxWidth - 24) / 4
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: 'Light',
                value: light.toStringAsFixed(0),
                unit: 'lux',
                icon: Icons.light_mode,
                accentColor: const Color(0xFFFFB703),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: 'Noise',
                value: noise.toStringAsFixed(0),
                unit: 'dB',
                icon: Icons.graphic_eq,
                accentColor: const Color(0xFF2A9D8F),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: 'Temperature',
                value: temp.toStringAsFixed(1),
                unit: 'C',
                icon: Icons.thermostat,
                accentColor: const Color(0xFFE76F51),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: 'Humidity',
                value: humidity.toStringAsFixed(0),
                unit: '%',
                icon: Icons.water_drop,
                accentColor: const Color(0xFF457B9D),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ComfortSection extends StatelessWidget {
  const _ComfortSection({required this.repository, required this.latest});

  final DataRepository repository;
  final Reading? latest;

  @override
  Widget build(BuildContext context) {
    final score = latest?.comfortScore ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ComfortGauge(score: score)),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<Thresholds>(
                  stream: repository.thresholds(),
                  builder: (context, snapshot) {
                    return ThresholdsCard(
                      thresholds: snapshot.data ?? Thresholds.defaults,
                    );
                  },
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            ComfortGauge(score: score),
            const SizedBox(height: 16),
            StreamBuilder<Thresholds>(
              stream: repository.thresholds(),
              builder: (context, snapshot) {
                return ThresholdsCard(
                  thresholds: snapshot.data ?? Thresholds.defaults,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _TrendGrid extends StatelessWidget {
  const _TrendGrid({required this.readings});

  final List<Reading> readings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        final itemWidth = isWide
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: itemWidth,
              child: LineChartCard(
                title: 'Light',
                unit: 'lux',
                color: const Color(0xFFFFB703),
                values: readings,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: LineChartCard(
                title: 'Noise',
                unit: 'dB',
                color: const Color(0xFF2A9D8F),
                values: readings,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: LineChartCard(
                title: 'Temperature',
                unit: 'C',
                color: const Color(0xFFE76F51),
                values: readings,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: LineChartCard(
                title: 'Humidity',
                unit: '%',
                color: const Color(0xFF457B9D),
                values: readings,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Stack(
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
        Positioned(
          top: -120,
          right: -80,
          child: _BlurCircle(color: const Color(0xFFB7E4C7)),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: _BlurCircle(color: const Color(0xFFFFE8A1)),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.35),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 80,
          ),
        ],
      ),
    );
  }
}
