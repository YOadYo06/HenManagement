import 'dart:math';

/// Pre-calculated weights from MCDM_IoT_Analysis.ipynb
/// These are the actual weights computed from the 10,000+ sample dataset
class PreCalculatedWeights {
  // Standard Deviation method weights
  static const Map<String, double> weightsSTD = {
    'temperature_celsius': 0.2456,
    'humidity_percent': 0.1834,
    'noise_level_db': 0.3489,
    'lighting_lux': 0.2221,
  };

  // Shannon Entropy method weights
  static const Map<String, double> weightsEntropy = {
    'temperature_celsius': 0.2198,
    'humidity_percent': 0.1987,
    'noise_level_db': 0.3312,
    'lighting_lux': 0.2503,
  };

  // CRITIC method weights (correlation-based)
  static const Map<String, double> weightsCRITIC = {
    'temperature_celsius': 0.2634,
    'humidity_percent': 0.1521,
    'noise_level_db': 0.3756,
    'lighting_lux': 0.2089,
  };

  // MEREC method weights (removal effects)
  static const Map<String, double> weightsMEREC = {
    'temperature_celsius': 0.1987,
    'humidity_percent': 0.2245,
    'noise_level_db': 0.3187,
    'lighting_lux': 0.2581,
  };

  /// Get weights by method
  static Map<String, double> getWeights(WeightMethod method) {
    switch (method) {
      case WeightMethod.std:
        return weightsSTD;
      case WeightMethod.entropy:
        return weightsEntropy;
      case WeightMethod.critic:
        return weightsCRITIC;
      case WeightMethod.merec:
        return weightsMEREC;
      case WeightMethod.compromise:
        // Average of all 4 methods
        return _calculateCompromiseWeights();
    }
  }

  static Map<String, double> _calculateCompromiseWeights() {
    const criteria = ['temperature_celsius', 'humidity_percent', 'noise_level_db', 'lighting_lux'];
    final result = <String, double>{};

    for (final criterion in criteria) {
      final avg = (weightsSTD[criterion]! +
              weightsEntropy[criterion]! +
              weightsCRITIC[criterion]! +
              weightsMEREC[criterion]!) /
          4;
      result[criterion] = avg;
    }

    // Normalize
    final sum = result.values.fold(0.0, (a, b) => a + b);
    result.updateAll((k, v) => v / sum);

    return result;
  }

  /// Get compromise weights (average)
  static final Map<String, double> weightsCompromise = {
    'temperature_celsius': 0.2319,
    'humidity_percent': 0.1897,
    'noise_level_db': 0.3436,
    'lighting_lux': 0.2348,
  };
}

/// MCDM Weight Calculation Methods
enum WeightMethod { std, entropy, critic, merec, compromise }

/// MCDM Scoring Methods
enum ScoringMethod { mabac, marcos, spotis, cococomet }

/// Class containing sensor reading data for MCDM analysis
class SensorReading {
  final double temperature; // Celsius (cost criteria - lower is better within comfort range)
  final double humidity; // Percentage (cost criteria)
  final double noise; // dB (cost criteria - lower is better)
  final double lighting; // Lux (cost criteria)

  SensorReading({
    required this.temperature,
    required this.humidity,
    required this.noise,
    required this.lighting,
  });

  List<double> toList() => [temperature, humidity, noise, lighting];

  static const List<String> criteriaNames = [
    'Temperature (°C)',
    'Humidity (%)',
    'Noise (dB)',
    'Lighting (Lux)'
  ];

  static const Map<String, String> criteriaTypes = {
    'temperature_celsius': 'cost',
    'humidity_percent': 'cost',
    'noise_level_db': 'cost',
    'lighting_lux': 'cost',
  };
}

/// MCDM Calculator - Uses pre-calculated weights from Jupyter notebook
class MCDMCalculator {
  // Normalize sensor data using min-max normalization
  static List<double> normalizeSensorValues(
    double temperature,
    double humidity,
    double noise,
    double lighting,
  ) {
    // Normalization ranges (cost criteria: lower is better)
    // Formula: (max - value) / (max - min)
    const tempMin = 15.0, tempMax = 32.0;
    const humidityMin = 10.0, humidityMax = 90.0;
    const noiseMin = 20.0, noiseMax = 90.0;
    const lightingMin = 50.0, lightingMax = 2000.0;

    final normTemp = (tempMax - temperature) / (tempMax - tempMin);
    final normHumidity = (humidityMax - humidity) / (humidityMax - humidityMin);
    final normNoise = (noiseMax - noise) / (noiseMax - noiseMin);
    final normLighting = (lightingMax - lighting) / (lightingMax - lightingMin);

    return [
      normTemp.clamp(0.0, 1.0),
      normHumidity.clamp(0.0, 1.0),
      normNoise.clamp(0.0, 1.0),
      normLighting.clamp(0.0, 1.0),
    ];
  }

  /// Calculate MCDM comfort score using pre-calculated weights and selected scoring method
  static double calculateComfortScore(
    double temperature,
    double humidity,
    double noise,
    double lighting,
    WeightMethod weightMethod,
    ScoringMethod scoringMethod,
  ) {
    // Normalize sensor values
    final normalized = normalizeSensorValues(temperature, humidity, noise, lighting);

    // Get pre-calculated weights
    final weights = PreCalculatedWeights.getWeights(weightMethod);
    final weightsList = [
      weights['temperature_celsius']!,
      weights['humidity_percent']!,
      weights['noise_level_db']!,
      weights['lighting_lux']!,
    ];

    // Calculate score using selected method
    final score = _calculateScore(normalized, weightsList, scoringMethod);

    return score.clamp(0.0, 1.0);
  }

  /// Calculate score using selected scoring method
  static double _calculateScore(
    List<double> normalized,
    List<double> weights,
    ScoringMethod method,
  ) {
    switch (method) {
      case ScoringMethod.mabac:
        return _scoreMABAC(normalized, weights);
      case ScoringMethod.marcos:
        return _scoreMARCOS(normalized, weights);
      case ScoringMethod.spotis:
        return _scoreSPOTIS(normalized, weights);
      case ScoringMethod.cococomet:
        return _scoreCOCOMET(normalized, weights);
    }
  }

  /// MABAC Scoring Method
  static double _scoreMABAC(List<double> normalized, List<double> weights) {
    const epsilon = 1e-10;

    // Calculate weighted values: v = w * (n + 1)
    final weighted = <double>[];
    for (int i = 0; i < normalized.length; i++) {
      weighted.add(weights[i] * (normalized[i] + 1));
    }

    // Calculate border area (geometric mean)
    double product = 1;
    for (final w in weighted) {
      product *= max(w + epsilon, epsilon);
    }
    final borderArea = pow(product, 1.0 / weighted.length).toDouble();

    // Calculate score: sum of (value - border area)
    double score = 0;
    for (final w in weighted) {
      score += w - borderArea;
    }

    // Normalize to [0, 1]
    return 0.5 + (score / 10);
  }

  /// MARCOS Scoring Method
  static double _scoreMARCOS(List<double> normalized, List<double> weights) {
    // Weighted sum
    double weightedSum = 0;
    for (int i = 0; i < normalized.length; i++) {
      weightedSum += weights[i] * normalized[i];
    }

    // MARCOS: score is weighted sum (already 0-1 normalized)
    return weightedSum;
  }

  /// SPOTIS Scoring Method (distance-based)
  static double _scoreSPOTIS(List<double> normalized, List<double> weights) {
    // Distance from ideal (all 1s)
    double distance = 0;
    for (int i = 0; i < normalized.length; i++) {
      distance += weights[i] * (normalized[i] - 1.0).abs();
    }

    // Score: 1 - normalized distance
    return 1 - (distance / 2).clamp(0.0, 1.0);
  }

  /// COCOCOMET Scoring Method (hybrid)
  static double _scoreCOCOMET(List<double> normalized, List<double> weights,
      {double lambda = 0.5}) {
    const epsilon = 1e-10;

    // Power aggregation: product(x^w)
    double sPower = 1;
    for (int i = 0; i < normalized.length; i++) {
      sPower *= pow(max(normalized[i], epsilon), weights[i]).toDouble();
    }

    // Linear aggregation: sum(w*x)
    double sLinear = 0;
    for (int i = 0; i < normalized.length; i++) {
      sLinear += weights[i] * normalized[i];
    }

    // Hybrid: lambda * power + (1 - lambda) * linear
    return lambda * sPower + (1 - lambda) * sLinear;
  }

  /// Get weight method formula
  static String getWeightFormula(WeightMethod method) {
    switch (method) {
      case WeightMethod.std:
        return 'wⱼ = σⱼ / Σσₖ\n(Standard Deviation)';
      case WeightMethod.entropy:
        return 'wⱼ = (1 - eⱼ) / Σ(1 - eₖ)\n(Shannon Entropy)';
      case WeightMethod.critic:
        return 'wⱼ = σⱼ × Σ|rⱼₖ| / Σ(...)\n(Correlation Impact)';
      case WeightMethod.merec:
        return 'wⱼ = (REⱼ - min) / Σ(...)\n(Removal Effect)';
      case WeightMethod.compromise:
        return 'wⱼ = (Σwⱼ from 4 methods) / 4\n(Balanced Average)';
    }
  }

  /// Get scoring method formula
  static String getScoringFormula(ScoringMethod method) {
    switch (method) {
      case ScoringMethod.mabac:
        return 'S = Σ(vᵢⱼ - BAⱼ)\n(Border Approximation)';
      case ScoringMethod.marcos:
        return 'S = Σ(wⱼ × nᵢⱼ)\n(Reference Comparison)';
      case ScoringMethod.spotis:
        return 'S = 1 - (D / 2)\n(Distance-based)';
      case ScoringMethod.cococomet:
        return 'S = λ×Sₚₒwₑᵣ + (1-λ)×Sₗᵢₙₑₐᵣ\n(Hybrid)';
    }
  }

  /// Get interpretation for MCDM score
  static String getScoreInterpretation(double score) {
    if (score >= 0.85) {
      return 'Excellent';
    } else if (score >= 0.70) {
      return 'Good';
    } else if (score >= 0.55) {
      return 'Fair';
    } else if (score >= 0.40) {
      return 'Poor';
    } else {
      return 'Critical';
    }
  }

  /// Get color for MCDM score
  static int getScoreColor(double score) {
    if (score >= 0.85) {
      return 0xFF4CAF50; // Green
    } else if (score >= 0.70) {
      return 0xFF8BC34A; // Light Green
    } else if (score >= 0.55) {
      return 0xFFFFC107; // Amber
    } else if (score >= 0.40) {
      return 0xFFFF9800; // Orange
    } else {
      return 0xFFF44336; // Red
    }
  }
}
