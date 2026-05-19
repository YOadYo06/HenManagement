import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    this.isLive = true,
    this.bottom,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final bool isLive;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final opacity = isLive ? 1.0 : 0.45;
    final bgColor = isLive ? Colors.white : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
        border: isLive ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(isLive ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Opacity(
                  opacity: opacity,
                  child: Icon(icon, color: accentColor),
                ),
              ),
              const Spacer(),
              if (!isLive)
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: opacity,
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: opacity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    value,
                    key: ValueKey('$value-$isLive'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isLive ? null : Colors.grey,
                        ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          if (bottom != null) ...[
            const SizedBox(height: 8),
            bottom!,
          ],
        ],
      ),
    );
  }
}
