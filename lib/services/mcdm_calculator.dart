import 'dart:math';

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

/// MCDM Calculator - Performs multi-criteria decision making analysis
class MCDMCalculator {
  // Normalize sensor data using min-max normalization
  static List<List<double>> normalizeSensorMatrix(
    List<List<double>> sensorData,
  ) {
    final List<List<double>> normalized = [];
    final int numCriteria = sensorData[0].length;

    // Calculate min and max for each criterion
    final List<double> mins =
        List<double>.generate(numCriteria, (_) => double.infinity);
    final List<double> maxs =
        List<double>.generate(numCriteria, (_) => double.negativeInfinity);

    for (final reading in sensorData) {
      for (int j = 0; j < numCriteria; j++) {
        mins[j] = min(mins[j], reading[j]);
        maxs[j] = max(maxs[j], reading[j]);
      }
    }

    // Normalize using min-max (for all COST criteria)
    for (final reading in sensorData) {
      final normalizedReading = <double>[];
      for (int j = 0; j < numCriteria; j++) {
        final range = maxs[j] - mins[j];
        double normalized;

        if (range == 0) {
          normalized = 0.5;
        } else {
          // All criteria are COST (lower is better)
          // Formula: (max - value) / (max - min)
          normalized = (maxs[j] - reading[j]) / range;
        }

        normalizedReading.add(normalized);
      }
      normalized.add(normalizedReading);
    }

    return normalized;
  }

  /// Calculate weights using Standard Deviation method
  static List<double> calculateWeightsSTD(List<List<double>> normalizedData) {
    if (normalizedData.isEmpty || normalizedData[0].isEmpty) return [];

    final numCriteria = normalizedData[0].length;
    final numSamples = normalizedData.length;

    // Calculate standard deviation for each criterion
    final List<double> means = List<double>.filled(numCriteria, 0);
    for (int j = 0; j < numCriteria; j++) {
      double sum = 0;
      for (int i = 0; i < numSamples; i++) {
        sum += normalizedData[i][j];
      }
      means[j] = sum / numSamples;
    }

    final List<double> stdDevs = List<double>.filled(numCriteria, 0);
    for (int j = 0; j < numCriteria; j++) {
      double sumSquaredDiff = 0;
      for (int i = 0; i < numSamples; i++) {
        final diff = normalizedData[i][j] - means[j];
        sumSquaredDiff += diff * diff;
      }
      stdDevs[j] = sqrt(sumSquaredDiff / numSamples);
    }

    // Normalize to sum to 1
    final double sumStd = stdDevs.fold(0, (a, b) => a + b);
    return stdDevs.map((e) => sumStd > 0 ? e / sumStd : 1.0 / numCriteria).toList();
  }

  /// Calculate weights using Entropy method
  static List<double> calculateWeightsEntropy(List<List<double>> normalizedData) {
    if (normalizedData.isEmpty || normalizedData[0].isEmpty) return [];

    final numCriteria = normalizedData[0].length;
    final numSamples = normalizedData.length;
    const double epsilon = 1e-10;

    // Calculate entropy for each criterion
    final List<double> entropies = List<double>.filled(numCriteria, 0);

    for (int j = 0; j < numCriteria; j++) {
      double entropy = 0;
      final double sum = normalizedData.fold(0.0, (a, row) => a + row[j]);

      if (sum > 0) {
        for (int i = 0; i < numSamples; i++) {
          double pij = normalizedData[i][j] / sum;
          if (pij > epsilon) {
            entropy -= pij * log(pij);
          }
        }
        entropy /= log(numSamples);
      }
      entropies[j] = entropy;
    }

    // Calculate divergence and normalize
    final List<double> divergences =
        entropies.map((e) => 1 - e).toList();
    final double sumDiv = divergences.fold(0, (a, b) => a + b);

    return divergences
        .map((e) => sumDiv > 0 ? e / sumDiv : 1.0 / numCriteria)
        .toList();
  }

  /// Calculate weights using CRITIC method (correlation-based)
  static List<double> calculateWeightsCRITIC(List<List<double>> normalizedData) {
    if (normalizedData.isEmpty || normalizedData[0].isEmpty) return [];

    final numCriteria = normalizedData[0].length;
    final numSamples = normalizedData.length;

    // Calculate standard deviation
    final stdDevs = calculateWeightsSTD(normalizedData);

    // Calculate correlation matrix
    final List<List<double>> correlations =
        List.generate(numCriteria, (_) => List.filled(numCriteria, 0.0));

    final List<double> means = List<double>.filled(numCriteria, 0);
    for (int j = 0; j < numCriteria; j++) {
      double sum = 0;
      for (int i = 0; i < numSamples; i++) {
        sum += normalizedData[i][j];
      }
      means[j] = sum / numSamples;
    }

    for (int j = 0; j < numCriteria; j++) {
      for (int k = 0; k < numCriteria; k++) {
        double numerator = 0;
        double denominator1 = 0;
        double denominator2 = 0;

        for (int i = 0; i < numSamples; i++) {
          final diff1 = normalizedData[i][j] - means[j];
          final diff2 = normalizedData[i][k] - means[k];
          numerator += diff1 * diff2;
          denominator1 += diff1 * diff1;
          denominator2 += diff2 * diff2;
        }

        final denominator = sqrt(denominator1 * denominator2);
        if (denominator > 0) {
          correlations[j][k] = (numerator / denominator).abs();
        }
      }
    }

    // Calculate CRITIC weights
    final List<double> criticWeights = List<double>.filled(numCriteria, 0);
    for (int j = 0; j < numCriteria; j++) {
      double corrSum = 0;
      for (int k = 0; k < numCriteria; k++) {
        corrSum += correlations[j][k];
      }
      corrSum -= 1; // Remove self-correlation
      criticWeights[j] = stdDevs[j] * corrSum;
    }

    final double sumCritic = criticWeights.fold(0, (a, b) => a + b);
    return criticWeights
        .map((e) => sumCritic > 0 ? e / sumCritic : 1.0 / numCriteria)
        .toList();
  }

  /// Calculate weights using MEREC method
  static List<double> calculateWeightsMEREC(List<List<double>> normalizedData) {
    if (normalizedData.isEmpty || normalizedData[0].isEmpty) return [];

    final numCriteria = normalizedData[0].length;
    final numSamples = normalizedData.length;
    const double epsilon = 1e-10;

    // Calculate removal effects
    final List<double> removalEffects = List<double>.filled(numCriteria, 0);

    for (int j = 0; j < numCriteria; j++) {
      // Calculate average performance without criterion j
      double sumWithoutJ = 0;
      for (int i = 0; i < numSamples; i++) {
        double avgWithoutJ = 0;
        int count = 0;
        for (int k = 0; k < numCriteria; k++) {
          if (k != j) {
            avgWithoutJ += normalizedData[i][k];
            count++;
          }
        }
        if (count > 0) {
          sumWithoutJ += avgWithoutJ / count;
        }
      }

      final double avgRemovalEffect = sumWithoutJ / numSamples;
      removalEffects[j] =
          log(max(avgRemovalEffect + epsilon, epsilon));
    }

    // Normalize
    final double minRE = removalEffects.fold(double.infinity, min);
    final List<double> normalizedRE =
        removalEffects.map((e) => e - minRE).toList();
    final double sumNormRE = normalizedRE.fold(0, (a, b) => a + b);

    return normalizedRE
        .map((e) => sumNormRE > 0 ? e / sumNormRE : 1.0 / numCriteria)
        .toList();
  }

  /// Calculate compromise weights (average of all methods)
  static List<double> calculateWeightsCompromise(
    List<List<double>> normalizedData,
  ) {
    final weights1 = calculateWeightsSTD(normalizedData);
    final weights2 = calculateWeightsEntropy(normalizedData);
    final weights3 = calculateWeightsCRITIC(normalizedData);
    final weights4 = calculateWeightsMEREC(normalizedData);

    final int numCriteria = weights1.length;
    final List<double> compromise = List<double>.filled(numCriteria, 0);

    for (int j = 0; j < numCriteria; j++) {
      compromise[j] = (weights1[j] + weights2[j] + weights3[j] + weights4[j]) / 4;
    }

    final double sumCompromise = compromise.fold(0, (a, b) => a + b);
    return compromise
        .map((e) => sumCompromise > 0 ? e / sumCompromise : 1.0 / numCriteria)
        .toList();
  }

  /// Get weights based on selected method
  static List<double> getWeights(
    List<List<double>> normalizedData,
    WeightMethod method,
  ) {
    switch (method) {
      case WeightMethod.std:
        return calculateWeightsSTD(normalizedData);
      case WeightMethod.entropy:
        return calculateWeightsEntropy(normalizedData);
      case WeightMethod.critic:
        return calculateWeightsCRITIC(normalizedData);
      case WeightMethod.merec:
        return calculateWeightsMEREC(normalizedData);
      case WeightMethod.compromise:
        return calculateWeightsCompromise(normalizedData);
    }
  }

  /// MABAC Scoring Method
  static List<double> scoreMABAC(
    List<List<double>> normalizedData,
    List<double> weights,
  ) {
    if (normalizedData.isEmpty || normalizedData[0].isEmpty) return [];

    final numCriteria = normalizedData[0].length;
    final numSamples = normalizedData.length;
    const double epsilon = 1e-10;

    // Calculate weighted normalized values (v_ij = w_j * (n_ij + 1))
    final List<List<double>> weighted =
        List.generate(numSamples, (_) => List<double>.filled(numCriteria, 0));

    for (int i = 0; i < numSamples; i++) {
      for (int j = 0; j < numCriteria; j++) {
        weighted[i][j] = weights[j] * (normalizedData[i][j] + 1);
      }
    }

    // Calculate border area (geometric mean)
    final List<double> borderArea = List<double>.filled(numCriteria, 1);
    for (int j = 0; j < numCriteria; j++) {
      double product = 1;
      for (int i = 0; i < numSamples; i++) {
        product *= weighted[i][j] + epsilon;
      }
      borderArea[j] = pow(product, 1.0 / numSamples).toDouble();
    }

    // Calculate MABAC scores
    final List<double> scores = List<double>.filled(numSamples, 0);
    for (int i = 0; i < numSamples; i++) {
      double score = 0;
      for (int j = 0; j < numCriteria; j++) {
        score += weighted[i][j] - borderArea[j];
      }
      scores[i] = score;
    }

    // Normalize to [0, 1]
    final double minScore = scores.fold(double.infinity, min);
    final double maxScore = scores.fold(double.negativeInfinity, max);
    final double range = maxScore - minScore;

    return scores
        .map((s) => range > 0 ? (s - minScore) / range : 0.5)
        .toList();
  }

  /// MARCOS Scoring Method
  static List<double> scoreMARCOS(
    List<List<double>> normalizedData,
    List<double> weights,
  ) {
    if (normalizedData.isEmpty || normalizedData[0].isEmpty) return [];

    final numCriteria = normalizedData[0].length;
    final numSamples = normalizedData.length;

    // Weighted sum of ideal (all 1s) and anti-ideal (all 0s)
    double weightedIdeal = 0;
    double weightedAntiIdeal = 0;

    for (int j = 0; j < numCriteria; j++) {
      weightedIdeal += weights[j] * 1.0;
      weightedAntiIdeal += weights[j] * 0.0;
    }

    // Calculate MARCOS scores
    final List<double> scores = List<double>.filled(numSamples, 0);

    for (int i = 0; i < numSamples; i++) {
      double weightedSum = 0;
      for (int j = 0; j < numCriteria; j++) {
        weightedSum += weights[j] * normalizedData[i][j];
      }

      final double kPlus =
          weightedIdeal > 0 ? weightedSum / weightedIdeal : 0;
      final double kMinus =
          weightedAntiIdeal > 0 ? weightedSum / weightedAntiIdeal : 0;

      scores[i] = kPlus + kMinus;
    }

    // Normalize to [0, 1]
    final double maxScore = scores.fold(double.negativeInfinity, max);
    return scores.map((s) => maxScore > 0 ? s / (maxScore * 2) : 0.5).toList();
  }

  /// SPOTIS Scoring Method
  static List<double> scoreSPOTIS(
    List<List<double>> normalizedData,
    List<double> weights,
  ) {
    if (normalizedData.isEmpty || normalizedData[0].isEmpty) return [];

    final numCriteria = normalizedData[0].length;
    final numSamples = normalizedData.length;

    // Calculate distances from ideal solution (all 1s)
    final List<double> distances = List<double>.filled(numSamples, 0);

    for (int i = 0; i < numSamples; i++) {
      double distance = 0;
      for (int j = 0; j < numCriteria; j++) {
        distance += weights[j] * (normalizedData[i][j] - 1.0).abs();
      }
      distances[i] = distance;
    }

    // Normalize distances to [0, 1] and invert (1 = best, 0 = worst)
    final double minDist = distances.fold(double.infinity, min);
    final double maxDist = distances.fold(double.negativeInfinity, max);
    final double range = maxDist - minDist;

    return distances.map((d) {
      final normalized = range > 0 ? (d - minDist) / range : 0.5;
      return 1 - normalized;
    }).toList();
  }

  /// COCOCOMET Scoring Method (hybrid - power and linear aggregation)
  static List<double> scoreCOCOMET(
    List<List<double>> normalizedData,
    List<double> weights, {
    double lambda = 0.5,
  }) {
    if (normalizedData.isEmpty || normalizedData[0].isEmpty) return [];

    final numCriteria = normalizedData[0].length;
    final numSamples = normalizedData.length;
    const double epsilon = 1e-10;

    // Power aggregation: product(x_ij ^ w_j)
    final List<double> sPower = List<double>.filled(numSamples, 1);
    for (int i = 0; i < numSamples; i++) {
      for (int j = 0; j < numCriteria; j++) {
        sPower[i] *=
            pow(max(normalizedData[i][j], epsilon), weights[j]).toDouble();
      }
    }

    // Linear aggregation: sum(w_j * x_ij)
    final List<double> sLinear = List<double>.filled(numSamples, 0);
    for (int i = 0; i < numSamples; i++) {
      for (int j = 0; j < numCriteria; j++) {
        sLinear[i] += weights[j] * normalizedData[i][j];
      }
    }

    // Normalize
    final double maxPower = sPower.fold(epsilon, max);
    final double maxLinear = sLinear.fold(epsilon, max);

    final List<double> sPowerNorm =
        sPower.map((s) => s / maxPower).toList();
    final List<double> sLinearNorm =
        sLinear.map((s) => s / maxLinear).toList();

    // Combine with lambda parameter
    final List<double> scores = List<double>.filled(numSamples, 0);
    for (int i = 0; i < numSamples; i++) {
      scores[i] = lambda * sPowerNorm[i] + (1 - lambda) * sLinearNorm[i];
    }

    return scores;
  }

  /// Get scores based on selected scoring method
  static List<double> getScores(
    List<List<double>> normalizedData,
    List<double> weights,
    ScoringMethod method,
  ) {
    switch (method) {
      case ScoringMethod.mabac:
        return scoreMABAC(normalizedData, weights);
      case ScoringMethod.marcos:
        return scoreMARCOS(normalizedData, weights);
      case ScoringMethod.spotis:
        return scoreSPOTIS(normalizedData, weights);
      case ScoringMethod.cococomet:
        return scoreCOCOMET(normalizedData, weights);
    }
  }

  /// Analyze a single reading and return MCDM score
  static MCDMResult analyzeSingleReading(
    SensorReading reading,
    List<List<double>> historicalData, // historical normalized data for context
    WeightMethod weightMethod,
    ScoringMethod scoringMethod,
  ) {
    // Prepare data with current reading
    final allData = [...historicalData, reading.toList()];
    final normalizedData = normalizeSensorMatrix(allData);
    final currentReadingNormalized = normalizedData.last;

    // Get weights
    final weights = getWeights(normalizedData, weightMethod);

    // Get individual scores
    final mabacScore = scoreMABAC(normalizedData, weights);
    final marcosScore = scoreMARCOS(normalizedData, weights);
    final spotisScore = scoreSPOTIS(normalizedData, weights);
    final cococometScore = scoreCOCOMET(normalizedData, weights);

    // Get the selected score for current reading
    late double selectedScore;
    switch (scoringMethod) {
      case ScoringMethod.mabac:
        selectedScore = mabacScore.last;
        break;
      case ScoringMethod.marcos:
        selectedScore = marcosScore.last;
        break;
      case ScoringMethod.spotis:
        selectedScore = spotisScore.last;
        break;
      case ScoringMethod.cococomet:
        selectedScore = cococometScore.last;
        break;
    }

    // Calculate average score across methods
    final double avgScore = (mabacScore.last + marcosScore.last + spotisScore.last + cococometScore.last) / 4;

    return MCDMResult(
      selectedMethod: scoringMethod,
      selectedScore: selectedScore,
      mabacScore: mabacScore.last,
      marcosScore: marcosScore.last,
      spotisScore: spotisScore.last,
      cococometScore: cococometScore.last,
      averageScore: avgScore,
      weights: weights,
      weightMethod: weightMethod,
      normalizedReading: currentReadingNormalized,
    );
  }
}

/// Result of MCDM analysis
class MCDMResult {
  final ScoringMethod selectedMethod;
  final double selectedScore;
  final double mabacScore;
  final double marcosScore;
  final double spotisScore;
  final double cococometScore;
  final double averageScore;
  final List<double> weights;
  final WeightMethod weightMethod;
  final List<double> normalizedReading;

  MCDMResult({
    required this.selectedMethod,
    required this.selectedScore,
    required this.mabacScore,
    required this.marcosScore,
    required this.spotisScore,
    required this.cococometScore,
    required this.averageScore,
    required this.weights,
    required this.weightMethod,
    required this.normalizedReading,
  });

  /// Get interpretation of the score (0-1)
  String getInterpretation() {
    if (selectedScore >= 0.8) {
      return 'Excellent environment';
    } else if (selectedScore >= 0.6) {
      return 'Good environment';
    } else if (selectedScore >= 0.4) {
      return 'Fair environment';
    } else if (selectedScore >= 0.2) {
      return 'Poor environment';
    } else {
      return 'Very poor environment';
    }
  }

  /// Get color for visualization
  int getScoreColor() {
    if (selectedScore >= 0.8) {
      return 0xFF4CAF50; // Green
    } else if (selectedScore >= 0.6) {
      return 0xFF8BC34A; // Light Green
    } else if (selectedScore >= 0.4) {
      return 0xFFFFC107; // Amber
    } else if (selectedScore >= 0.2) {
      return 0xFFFF9800; // Orange
    } else {
      return 0xFFF44336; // Red
    }
  }
}
