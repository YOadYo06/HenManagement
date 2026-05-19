import 'package:flutter/material.dart';
import '../services/stress_prediction_model.dart';

/// Widget to display stress level prediction
class StressPredictionCard extends StatelessWidget {
  const StressPredictionCard({
    super.key,
    required this.result,
    this.showChart = true,
  });

  final StressPredictionResult result;
  final bool showChart;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Stress Level Prediction',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Stress gauge/visualization
            Center(
              child: Column(
                children: [
                  // Circular progress indicator
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: result.stressLevel / 100,
                          strokeWidth: 12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(result.color),
                          ),
                          backgroundColor: Colors.grey[300],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${result.stressLevel.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '/ 100',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color(result.color),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      result.interpretation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (showChart) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Stress level scale
              Text(
                'Stress Scale',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildStressScale(),
            ],

            const SizedBox(height: 16),

            // Recommendations
            _buildRecommendations(context),

            const SizedBox(height: 12),

            // Timestamp
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Updated: ${_formatTime(result.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStressScale() {
    final ranges = [
      (0.0, 15.0, 'Very Low', 0xFF4CAF50),
      (15.0, 30.0, 'Low', 0xFF8BC34A),
      (30.0, 45.0, 'Moderate', 0xFFFFC107),
      (45.0, 60.0, 'High', 0xFFFF9800),
      (60.0, 75.0, 'Very High', 0xFFFF5722),
      (75.0, 100.0, 'Critical', 0xFFF44336),
    ];

    return Column(
      children: ranges.map((range) {
        final isCurrentRange = result.stressLevel >= range.$1 && result.stressLevel <= range.$2;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(range.$4),
                  shape: BoxShape.circle,
                  border: isCurrentRange ? Border.all(width: 3, color: Colors.black) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${range.$1.toStringAsFixed(0)} - ${range.$2.toStringAsFixed(0)}: ${range.$3}',
                  style: TextStyle(
                    fontWeight: isCurrentRange ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    String recommendation;
    IconData icon;

    if (result.stressLevel < 30) {
      recommendation = 'Great! Your environment is conducive to relaxation and focus.';
      icon = Icons.thumb_up;
    } else if (result.stressLevel < 45) {
      recommendation = 'Your environment is normal. Monitor for changes.';
      icon = Icons.info;
    } else if (result.stressLevel < 60) {
      recommendation = 'Consider adjusting lighting, noise, or temperature to reduce stress.';
      icon = Icons.warning;
    } else {
      recommendation = 'High stress detected! Check environment settings and take a break.';
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(result.color)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Widget to display historical stress predictions
class StressHistoryChart extends StatelessWidget {
  const StressHistoryChart({
    super.key,
    required this.predictions,
  });

  final List<StressPredictionResult> predictions;

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No stress prediction history',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final maxStress = predictions.fold<double>(
      0,
      (max, p) => p.stressLevel > max ? p.stressLevel : max,
    );
    final minStress = predictions.fold<double>(
      100,
      (min, p) => p.stressLevel < min ? p.stressLevel : min,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stress Trend (Last ${predictions.length} readings)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Simple line representation
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _StressChartPainter(
                  predictions: predictions,
                  maxStress: maxStress,
                  minStress: minStress,
                ),
                size: const Size.fromHeight(120),
              ),
            ),
            const SizedBox(height: 16),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Min', '${minStress.toStringAsFixed(1)}'),
                _buildStat(
                  'Avg',
                  '${(predictions.fold(0.0, (sum, p) => sum + p.stressLevel) / predictions.length).toStringAsFixed(1)}',
                ),
                _buildStat('Max', '${maxStress.toStringAsFixed(1)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

/// Custom painter for stress chart
class _StressChartPainter extends CustomPainter {
  final List<StressPredictionResult> predictions;
  final double maxStress;
  final double minStress;

  _StressChartPainter({
    required this.predictions,
    required this.maxStress,
    required this.minStress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (predictions.isEmpty) return;

    const padding = 8.0;
    final chartWidth = size.width - 2 * padding;
    final chartHeight = size.height - 2 * padding;
    const lineColor = Color(0xFF2196F3);
    const pointColor = Color(0xFF1976D2);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw line and points
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    final range = maxStress - minStress;
    if (range == 0) return;

    for (int i = 0; i < predictions.length; i++) {
      final x = padding + (chartWidth / (predictions.length - 1)) * i;
      final normalizedValue =
          (predictions[i].stressLevel - minStress) / range;
      final y = padding + chartHeight - (chartHeight * normalizedValue);

      // Draw line to next point
      if (i < predictions.length - 1) {
        final nextX = padding +
            (chartWidth / (predictions.length - 1)) * (i + 1);
        final nextNormalizedValue =
            (predictions[i + 1].stressLevel - minStress) / range;
        final nextY = padding +
            chartHeight -
            (chartHeight * nextNormalizedValue);

        canvas.drawLine(Offset(x, y), Offset(nextX, nextY), linePaint);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_StressChartPainter oldDelegate) => true;
}
