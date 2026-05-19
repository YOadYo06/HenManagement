import 'package:flutter/material.dart';
import '../models/mcdm_result.dart';
import '../services/mcdm_calculator.dart';

/// Widget to display MCDM scores in a card format
class MCDMScoreCard extends StatelessWidget {
  const MCDMScoreCard({
    super.key,
    required this.result,
    this.onRefresh,
  });

  final MCDMAnalysisResult result;
  final VoidCallback? onRefresh;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Environment Quality Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Sensor values
            _buildSensorRow('Temperature', '${result.temperature.toStringAsFixed(1)}°C'),
            _buildSensorRow('Humidity', '${result.humidity.toStringAsFixed(1)}%'),
            _buildSensorRow('Noise', '${result.noise.toStringAsFixed(1)} dB'),
            _buildSensorRow('Lighting', '${result.lighting.toStringAsFixed(1)} lux'),

            const Divider(height: 20),

            // MCDM Scores
            Text(
              'MCDM Scores (Weight: ${result.weightMethod})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            _buildScoreBar(
              'MABAC',
              result.mabacScore,
              Colors.blue,
            ),
            _buildScoreBar(
              'MARCOS',
              result.marcosScore,
              Colors.green,
            ),
            _buildScoreBar(
              'SPOTIS',
              result.spotisScore,
              Colors.orange,
            ),
            _buildScoreBar(
              'COCOCOMET',
              result.cococometScore,
              Colors.purple,
            ),

            const SizedBox(height: 12),
            _buildScoreBar(
              'Average',
              result.averageScore,
              Colors.red,
              isHighlight: true,
            ),

            const Divider(height: 20),

            // Quality interpretation
            Center(
              child: Column(
                children: [
                  Text(
                    'Overall Quality',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color(_getQualityColor(result.averageScore)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getQualityInterpretation(result.averageScore),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(
    String label,
    double score,
    Color color, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  fontSize: isHighlight ? 15 : 13,
                ),
              ),
              Text(
                '${(score * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: isHighlight ? 8 : 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityInterpretation(double score) {
    if (score >= 0.8) {
      return 'Excellent';
    } else if (score >= 0.6) {
      return 'Good';
    } else if (score >= 0.4) {
      return 'Fair';
    } else if (score >= 0.2) {
      return 'Poor';
    } else {
      return 'Very Poor';
    }
  }

  int _getQualityColor(double score) {
    if (score >= 0.8) {
      return 0xFF4CAF50; // Green
    } else if (score >= 0.6) {
      return 0xFF8BC34A; // Light Green
    } else if (score >= 0.4) {
      return 0xFFFFC107; // Amber
    } else if (score >= 0.2) {
      return 0xFFFF9800; // Orange
    } else {
      return 0xFFF44336; // Red
    }
  }
}

/// Widget for selecting MCDM weight method
class WeightMethodSelector extends StatelessWidget {
  const WeightMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  final String selectedMethod;
  final Function(String) onMethodChanged;

  @override
  Widget build(BuildContext context) {
    final methods = ['STD', 'Entropy', 'CRITIC', 'MEREC', 'Compromise'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight Calculation Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: methods.map((method) {
                final isSelected = selectedMethod.toLowerCase() ==
                    method.toLowerCase();
                return ChoiceChip(
                  label: Text(method),
                  selected: isSelected,
                  onSelected: (_) =>
                      onMethodChanged(method.toLowerCase()),
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              _getMethodDescription(selectedMethod),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMethodDescription(String method) {
    switch (method.toLowerCase()) {
      case 'std':
        return 'Standard Deviation: Based on variability of criterion values';
      case 'entropy':
        return 'Entropy: Based on information content of each criterion';
      case 'critic':
        return 'CRITIC: Considers contrast and conflicts between criteria';
      case 'merec':
        return 'MEREC: Based on removal effects of each criterion';
      case 'compromise':
        return 'Compromise: Average of all methods for balanced results';
      default:
        return '';
    }
  }
}

/// Widget for selecting MCDM scoring method
class ScoringMethodSelector extends StatelessWidget {
  const ScoringMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  final ScoringMethod selectedMethod;
  final Function(ScoringMethod) onMethodChanged;

  @override
  Widget build(BuildContext context) {
    final methods = ScoringMethod.values;
    final methodNames = ['MABAC', 'MARCOS', 'SPOTIS', 'COCOCOMET'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scoring Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                methods.length,
                (index) {
                  final method = methods[index];
                  final name = methodNames[index];
                  final isSelected = selectedMethod == method;

                  return ChoiceChip(
                    label: Text(name),
                    selected: isSelected,
                    onSelected: (_) => onMethodChanged(method),
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getMethodDescription(selectedMethod),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMethodDescription(ScoringMethod method) {
    switch (method) {
      case ScoringMethod.mabac:
        return 'MABAC: Multi-Attributive Border Approximation Comparison';
      case ScoringMethod.marcos:
        return 'MARCOS: Measurement of Alternatives and Ranking according to COmpromise Solution';
      case ScoringMethod.spotis:
        return 'SPOTIS: Stable Preference Ordering Towards Ideal Solution (distance-based)';
      case ScoringMethod.cococomet:
        return 'COCOCOMET: Hybrid method combining power and linear aggregation';
    }
  }
}
