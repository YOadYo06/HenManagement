import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert_item.dart';

class AlertPanel extends StatelessWidget {
  const AlertPanel({super.key, required this.alerts});

  final List<AlertItem> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'No active alerts right now.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.black54),
        ),
      );
    }

    return Column(
      children: alerts.take(6).map((alert) => _AlertTile(alert: alert)).toList(),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity, Theme.of(context).colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, HH:mm').format(alert.timestamp.toLocal()),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          if (alert.value != null)
            Text(
              alert.value!.toStringAsFixed(1),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: color),
            ),
        ],
      ),
    );
  }

  Color _severityColor(String severity, ColorScheme colors) {
    switch (severity) {
      case 'critical':
        return colors.error;
      case 'warning':
        return const Color(0xFFFF8F1F);
      default:
        return colors.secondary;
    }
  }
}
