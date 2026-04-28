import 'package:flutter/material.dart';

import '../models/thresholds.dart';

class ThresholdsCard extends StatelessWidget {
  const ThresholdsCard({super.key, required this.thresholds});

  final Thresholds thresholds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            'Thresholds',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _row('Light',
              '${thresholds.lightMin.toStringAsFixed(0)} - ${thresholds.lightMax.toStringAsFixed(0)} lux'),
          _row('Noise',
              '${thresholds.noiseMin.toStringAsFixed(0)} - ${thresholds.noiseMax.toStringAsFixed(0)} dB'),
          _row('Temp',
              '${thresholds.tempMin.toStringAsFixed(0)} - ${thresholds.tempMax.toStringAsFixed(0)} C'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
