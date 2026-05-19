/// Flexible MCDM Calculator
/// Supports any number of sensors (not limited to 4)
/// Works with different sensor configurations from DatasetConfig

import 'dart:math';
import 'package:env_reading/models/sensor_config.dart';

enum WeightMethod { std, entropy, critic, merec, compromise }
enum ScoringMethod { mabac, marcos, spotis, cococomet }

class FlexibleMCDMCalculator {
  /// Calculate comfort score with any number of sensors
  /// 
  /// Parameters:
  ///   - normalizedValues: Map of sensor ID -> normalized [0,1] values
  ///   - sensorConfigs: Map of sensor ID -> SensorConfig
  ///   - weightMethod: Which weight calculation method to use
  ///   - scoringMethod: Which scoring method to use
  /// 
  /// Returns: Comfort score [0, 1]
  static double calculateComfortScore({
    required Map<String, double> normalizedValues,
    required Map<String, SensorConfig> sensorConfigs,
    required WeightMethod weightMethod,
    required ScoringMethod scoringMethod,
  }) {
    // Get list of available sensors (only those with values)
    final sensorIds = normalizedValues.keys.toList();
    if (sensorIds.isEmpty) return 0.5;

    // Calculate weights based on method
    final weights = _calculateWeights(
      normalizedValues,
      sensorIds,
      weightMethod,
    );

    // Convert criteria types (cost/profit) for normalization
    final adjustedValues = _adjustForCriteriaType(
      normalizedValues,
      sensorConfigs,
    );

    // Calculate score using selected method
    final score = _calculateScore(
      adjustedValues,
      weights,
      scoringMethod,
    );

    return score;
  }

  /// Calculate weights dynamically based on available sensors
  static Map<String, double> _calculateWeights(
    Map<String, double> normalizedValues,
    List<String> sensorIds,
    WeightMethod method,
  ) {
    final n = sensorIds.length;
    final weights = <String, double>{};

    switch (method) {
      case WeightMethod.std:
        // Standard Deviation method
        final mean = normalizedValues.values.reduce((a, b) => a + b) / n;
        final variance = normalizedValues.values
                .map((v) => pow(v - mean, 2))
                .reduce((a, b) => a + b) /
            n;
        final std = sqrt(variance);

        if (std == 0) {
          for (final id in sensorIds) {
            weights[id] = 1.0 / n;
          }
        } else {
          double sum = 0;
          for (final id in sensorIds) {
            final w = (normalizedValues[id]! - mean).abs();
            weights[id] = w;
            sum += w;
          }
          for (final id in sensorIds) {
            weights[id] = weights[id]! / sum;
          }
        }

      case WeightMethod.entropy:
        // Shannon Entropy method
        final entropyWeights = <String, double>{};
        double totalEntropy = 0;

        for (final id in sensorIds) {
          final p = normalizedValues[id]!;
          final pSafe = p > 0 && p < 1 ? p : 0.5;
          final entropy = -pSafe * log(pSafe);
          entropyWeights[id] = 1 - entropy;
          totalEntropy += entropyWeights[id]!;
        }

        for (final id in sensorIds) {
          weights[id] = entropyWeights[id]! / totalEntropy;
        }

      case WeightMethod.critic:
        // CRITIC method (Correlation-based)
        // Simplified: uses relative importance based on range
        for (final id in sensorIds) {
          final value = normalizedValues[id]!;
          weights[id] = value * (1 - value); // Highest at 0.5, lowest at extremes
        }
        final sum = weights.values.reduce((a, b) => a + b);
        for (final id in sensorIds) {
          weights[id] = weights[id]! / sum;
        }

      case WeightMethod.merec:
        // MEREC method (Removal Effect)
        final merValues = <String, double>{};
        for (final id in sensorIds) {
          merValues[id] = 1 - normalizedValues[id]!;
        }
        final sum = merValues.values.reduce((a, b) => a + b);
        for (final id in sensorIds) {
          weights[id] = merValues[id]! / sum;
        }

      case WeightMethod.compromise:
        // Compromise: average of all methods
        final stdWeights = _calculateWeights(normalizedValues, sensorIds, WeightMethod.std);
        final entropyWeights = _calculateWeights(normalizedValues, sensorIds, WeightMethod.entropy);
        final criticWeights = _calculateWeights(normalizedValues, sensorIds, WeightMethod.critic);
        final merecWeights = _calculateWeights(normalizedValues, sensorIds, WeightMethod.merec);

        for (final id in sensorIds) {
          weights[id] = (stdWeights[id]! +
                  entropyWeights[id]! +
                  criticWeights[id]! +
                  merecWeights[id]!) /
              4;
        }
    }

    return weights;
  }

  /// Adjust values based on criteria type (cost/profit)
  static Map<String, double> _adjustForCriteriaType(
    Map<String, double> normalizedValues,
    Map<String, SensorConfig> sensorConfigs,
  ) {
    final adjusted = <String, double>{};

    for (final entry in normalizedValues.entries) {
      final sensorId = entry.key;
      final value = entry.value;
      final config = sensorConfigs[sensorId];

      if (config != null) {
        // For profit criteria, invert the value (keep as is)
        // For cost criteria, value is already normalized correctly
        if (config.criteriaType == CriteriaType.profit) {
          adjusted[sensorId] = 1.0 - value; // Invert for scoring
        } else {
          adjusted[sensorId] = value;
        }
      }
    }

    return adjusted;
  }

  /// Calculate score using selected scoring method
  static double _calculateScore(
    Map<String, double> values,
    Map<String, double> weights,
    ScoringMethod method,
  ) {
    final sensorIds = values.keys.toList();

    switch (method) {
      case ScoringMethod.mabac:
        // Multi-Attributive Border Approximation Area Comparison
        double score = 0;
        for (final id in sensorIds) {
          score += weights[id]! * (values[id]! - 0.5);
        }
        return 0.5 + score;

      case ScoringMethod.marcos:
        // Multi-Attribute Ranking Compromise Solution
        double score = 0;
        for (final id in sensorIds) {
          score += weights[id]! * values[id]!;
        }
        return score;

      case ScoringMethod.spotis:
        // Stable Preference Ordering Towards Ideal Solution
        double distance = 0;
        for (final id in sensorIds) {
          final diff = values[id]! - 0.5;
          distance += pow(diff, 2);
        }
        distance = sqrt(distance);
        return 1.0 - (distance / 2);

      case ScoringMethod.cococomet:
        // Compromise COmplementary Correlation Method
        // Hybrid approach
        double weighted = 0;
        double linear = 0;
        for (final id in sensorIds) {
          weighted += weights[id]! * values[id]!;
          linear += values[id]! / sensorIds.length;
        }
        final lambda = 0.5; // 50/50 compromise
        return lambda * weighted + (1 - lambda) * linear;
    }
  }

  /// Get weight method formula
  static String getWeightFormula(WeightMethod method, int sensorCount) {
    switch (method) {
      case WeightMethod.std:
        return 'w = σᵢ / Σσⱼ (Standard Deviation)';
      case WeightMethod.entropy:
        return 'w = (1 - e) / Σ(1 - eⱼ) (Shannon Entropy)';
      case WeightMethod.critic:
        return 'w = v(1-v) / Σv(1-v) (Correlation Impact)';
      case WeightMethod.merec:
        return 'w = (1 - v) / Σ(1 - vⱼ) (Removal Effect)';
      case WeightMethod.compromise:
        return 'w = (wₛₜₐ + wₑₙₜ + wᴄᴫᴛ + wₘₑᴿₑᴄ) / 4 (Balanced)';
    }
  }

  /// Get scoring method formula
  static String getScoringFormula(ScoringMethod method) {
    switch (method) {
      case ScoringMethod.mabac:
        return 'S = Σ wⱼ(vᵢⱼ - 0.5) (Border Approximation)';
      case ScoringMethod.marcos:
        return 'S = Σ wⱼ × vᵢⱼ (Weighted Sum)';
      case ScoringMethod.spotis:
        return 'S = 1 - D/2, D=√Σ(v-0.5)² (Distance)';
      case ScoringMethod.cococomet:
        return 'S = λ×Σwⱼvⱼ + (1-λ)×Σvⱼ (Hybrid)';
    }
  }

  /// Get interpretation of score
  static String getScoreInterpretation(double score) {
    if (score < 0.2) return 'Critical';
    if (score < 0.4) return 'Poor';
    if (score < 0.6) return 'Fair';
    if (score < 0.8) return 'Good';
    return 'Excellent';
  }

  /// Get color for score
  static int getScoreColor(double score) {
    if (score < 0.2) return 0xFFF44336; // Red
    if (score < 0.4) return 0xFFFF5722; // Deep Orange
    if (score < 0.6) return 0xFFFFC107; // Amber
    if (score < 0.8) return 0xFF8BC34A; // Light Green
    return 0xFF4CAF50; // Green
  }
}
