import 'dart:math';

/// Stress Prediction Model V2
/// Uses current sensor data from Firebase + mean values from historical readings
/// 
/// Model: y = 47.5577 + 2.5522*temp + 0.0150*humidity - 18.2843*noise - 1.1560*lighting
/// 
/// The model uses:
/// - Current values: Latest sensor readings from Firebase Realtime DB
/// - Mean values: Calculated from all historical readings in Firebase
class StressPredictionModelV2 {
  // Model coefficients from Python notebook MCDM_IoT_Analysis.ipynb
  static const double intercept = 47.5577;
  static const List<double> coefficients = [2.5522, 0.0150, -18.2843, -1.1560];

  /// Predict stress using current sensor readings + historical mean values
  /// 
  /// Parameters:
  ///   - temperature: Current temperature from latest Firebase reading (°C)
  ///   - humidity: Current humidity from latest Firebase reading (%)
  ///   - noise: Current noise from latest Firebase reading (dB)
  ///   - lighting: Current lighting from latest Firebase reading (lux)
  ///   - meanTemperature: Mean temperature from all historical Firebase readings
  ///   - meanHumidity: Mean humidity from all historical Firebase readings
  ///   - meanNoise: Mean noise from all historical Firebase readings
  ///   - meanLighting: Mean lighting from all historical Firebase readings
  static double predictStress(
    double temperature,         // Current sensor value from Firebase
    double humidity,            // Current sensor value from Firebase
    double noise,               // Current sensor value from Firebase
    double lighting,            // Current sensor value from Firebase
    {
      double? meanTemperature,  // Historical mean from all Firebase readings
      double? meanHumidity,     // Historical mean from all Firebase readings
      double? meanNoise,        // Historical mean from all Firebase readings
      double? meanLighting,     // Historical mean from all Firebase readings
    }
  ) {
    // Use current values directly if means are not provided
    final tempToUse = temperature;
    final humidityToUse = humidity;
    final noiseToUse = noise;
    final lightingToUse = lighting;

    // Normalize inputs to [0, 1]
    final normTemp = _normalize(tempToUse, 18.0, 30.0);
    final normHumidity = _normalize(humidityToUse, 20.0, 80.0);
    final normNoise = _normalize(noiseToUse, 30.0, 80.0);
    final normLighting = _normalize(lightingToUse, 100.0, 1000.0);

    // Linear regression model from Python notebook
    double stress = intercept;
    stress += coefficients[0] * normTemp;
    stress += coefficients[1] * normHumidity;
    stress += coefficients[2] * normNoise;
    stress += coefficients[3] * normLighting;

    // Clamp to [0, 100]
    return max(0, min(100, stress));
  }

  /// Alternative: Predict stress using both current AND mean values (weighted)
  /// This gives more context about deviation from normal patterns
  static double predictStressWithMeans(
    double temperature,
    double humidity,
    double noise,
    double lighting,
    {
      required double meanTemperature,
      required double meanHumidity,
      required double meanNoise,
      required double meanLighting,
      double currentWeight = 0.7,  // 70% current, 30% mean
    }
  ) {
    // Blend current and mean values
    final tempBlended = (temperature * currentWeight) + (meanTemperature * (1 - currentWeight));
    final humidityBlended = (humidity * currentWeight) + (meanHumidity * (1 - currentWeight));
    final noiseBlended = (noise * currentWeight) + (meanNoise * (1 - currentWeight));
    final lightingBlended = (lighting * currentWeight) + (meanLighting * (1 - currentWeight));

    // Normalize blended inputs
    final normTemp = _normalize(tempBlended, 18.0, 30.0);
    final normHumidity = _normalize(humidityBlended, 20.0, 80.0);
    final normNoise = _normalize(noiseBlended, 30.0, 80.0);
    final normLighting = _normalize(lightingBlended, 100.0, 1000.0);

    // Apply model
    double stress = intercept;
    stress += coefficients[0] * normTemp;
    stress += coefficients[1] * normHumidity;
    stress += coefficients[2] * normNoise;
    stress += coefficients[3] * normLighting;

    return max(0, min(100, stress));
  }

  /// Normalize value to [0, 1]
  static double _normalize(double value, double min, double max) {
    if (max <= min) return 0.5;
    return (value - min) / (max - min);
  }

  /// Get stress interpretation
  static String getStressInterpretation(double stressLevel) {
    if (stressLevel < 15) {
      return 'Very Low (Relaxed)';
    } else if (stressLevel < 30) {
      return 'Low (Calm)';
    } else if (stressLevel < 45) {
      return 'Moderate (Normal)';
    } else if (stressLevel < 60) {
      return 'High (Stressed)';
    } else if (stressLevel < 75) {
      return 'Very High (Very Stressed)';
    } else {
      return 'Critical (Extremely Stressed)';
    }
  }

  /// Get color for stress level
  static int getStressColor(double stressLevel) {
    if (stressLevel < 15) {
      return 0xFF4CAF50; // Green
    } else if (stressLevel < 30) {
      return 0xFF8BC34A; // Light Green
    } else if (stressLevel < 45) {
      return 0xFFFFC107; // Amber
    } else if (stressLevel < 60) {
      return 0xFFFF9800; // Orange
    } else if (stressLevel < 75) {
      return 0xFFFF5722; // Deep Orange
    } else {
      return 0xFFF44336; // Red
    }
  }
}
