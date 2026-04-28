import 'package:flutter/material.dart';

class ComfortGauge extends StatelessWidget {
  const ComfortGauge({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score, Theme.of(context).colorScheme);
    final label = _scoreLabel(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Comfort score',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 650),
                  tween: Tween(begin: 0, end: score / 100),
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 14,
                      backgroundColor: color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    );
                  },
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            _scoreHint(score),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score, ColorScheme colors) {
    if (score >= 85) return colors.secondary;
    if (score >= 70) return const Color(0xFF5DBB63);
    if (score >= 55) return const Color(0xFFFFB703);
    return colors.error;
  }

  String _scoreLabel(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 55) return 'Fair';
    return 'Poor';
  }

  String _scoreHint(int score) {
    if (score >= 85) return 'Desk environment is optimal for focus.';
    if (score >= 70) return 'Small tweaks could improve comfort.';
    if (score >= 55) return 'Adjust light or noise for better focus.';
    return 'Immediate action recommended for comfort.';
  }
}
