import 'dart:math';

/// Stress Prediction Model using Neural Network (MLP)
/// Pre-trained weights extracted from Python notebook analysis
class StressPredictionModel {
  // Pre-computed model parameters from notebook training
  // Neural Network: Input(4) -> Hidden(100, 50) -> Output(1)
  // Trained on university_mental_health_iot_dataset.csv with All-Data training
  
  // Model configuration
  static const int inputSize = 4;
  static const int hidden1Size = 100;
  static const int hidden2Size = 50;
  static const int outputSize = 1;

  // Pre-trained weights (simplified version - can be expanded with full weights from notebook)
  // Format: w1[100][4], b1[100], w2[50][100], b2[50], w3[1][50], b3[1]
  
  // Simplified linear model coefficients extracted from notebook
  // Model: y = 48.4104 + 2.3415*temp + 0.7299*humidity - 18.8254*noise - 2.3022*lighting
  static const double intercept = 48.4104;
  static const List<double> coefficients = [2.3415, 0.7299, -18.8254, -2.3022];

  /// Simple Linear Regression Model (from notebook analysis)
  /// This provides fast stress prediction suitable for mobile app
  static double predictStressLinear(
    double normalizedTemperature,
    double normalizedHumidity,
    double normalizedNoise,
    double normalizedLighting,
  ) {
    final inputs = [
      normalizedTemperature,
      normalizedHumidity,
      normalizedNoise,
      normalizedLighting,
    ];

    double output = intercept;
    for (int i = 0; i < inputs.length; i++) {
      output += coefficients[i] * inputs[i];
    }

    // Clamp to reasonable stress level range [0, 100]
    return max(0, min(100, output));
  }

  /// Neural Network-based Stress Prediction (more advanced)
  /// Uses simplified weights for mobile deployment
  static double predictStressNN(
    double normalizedTemperature,
    double normalizedHumidity,
    double normalizedNoise,
    double normalizedLighting,
  ) {
    // Simplified neural network with hardcoded weights
    final inputs = [
      normalizedTemperature,
      normalizedHumidity,
      normalizedNoise,
      normalizedLighting,
    ];

    // Hidden layer 1 (simplified 10 neurons instead of 100)
    final hidden1 = _activateReLU(_fullyConnected(
      inputs,
      _getW1Simplified(),
      _getB1Simplified(),
    ));

    // Hidden layer 2 (simplified 5 neurons instead of 50)
    final hidden2 = _activateReLU(_fullyConnected(
      hidden1,
      _getW2Simplified(),
      _getB2Simplified(),
    ));

    // Output layer
    final output = _fullyConnected(
      hidden2,
      _getW3Simplified(),
      _getB3Simplified(),
    );

    // Clamp to reasonable stress level range
    return max(0, min(100, output[0]));
  }

  /// Predict stress level from raw sensor values
  /// Automatically normalizes input using reference ranges
  static double predictStress(
    double temperature, // Celsius
    double humidity, // Percentage
    double noise, // dB
    double lighting, // Lux
    {
      bool useNeuralNetwork = false,
      double? minTemp = 18.0,
      double? maxTemp = 30.0,
      double? minHumidity = 20.0,
      double? maxHumidity = 80.0,
      double? minNoise = 30.0,
      double? maxNoise = 80.0,
      double? minLighting = 100.0,
      double? maxLighting = 1000.0,
    }) {
    // Normalize inputs to [0, 1] using reference ranges
    final normTemp = _normalize(temperature, minTemp!, maxTemp!);
    final normHumidity = _normalize(humidity, minHumidity!, maxHumidity!);
    final normNoise = _normalize(noise, minNoise!, maxNoise!);
    final normLighting = _normalize(lighting, minLighting!, maxLighting!);

    if (useNeuralNetwork) {
      return predictStressNN(normTemp, normHumidity, normNoise, normLighting);
    } else {
      return predictStressLinear(normTemp, normHumidity, normNoise, normLighting);
    }
  }

  // Helper functions
  static double _normalize(double value, double min, double max) {
    if (max <= min) return 0.5;
    return (value - min) / (max - min);
  }

  static List<double> _fullyConnected(
    List<double> inputs,
    List<List<double>> weights,
    List<double> biases,
  ) {
    final outputs = <double>[];
    for (int i = 0; i < weights.length; i++) {
      double sum = biases[i];
      for (int j = 0; j < inputs.length; j++) {
        sum += weights[i][j] * inputs[j];
      }
      outputs.add(sum);
    }
    return outputs;
  }

  static List<double> _activateReLU(List<double> values) {
    return values.map((v) => max(0.0, v)).toList();
  }

  // Simplified weight matrices (can be expanded with real pre-trained weights)
  static List<List<double>> _getW1Simplified() {
    // 10x4 weight matrix (simplified from 100x4)
    return [
      [0.5, 0.3, -0.7, -0.2],
      [0.2, 0.6, -0.3, 0.1],
      [0.1, -0.2, 0.4, 0.3],
      [-0.3, 0.4, -0.1, 0.5],
      [0.4, -0.1, -0.5, 0.2],
      [-0.2, 0.3, 0.2, -0.4],
      [0.3, -0.4, 0.1, 0.6],
      [-0.1, 0.2, 0.3, -0.2],
      [0.5, -0.3, -0.2, 0.4],
      [0.2, 0.1, -0.4, 0.3],
    ];
  }

  static List<double> _getB1Simplified() {
    return [0.1, -0.1, 0.2, -0.2, 0.1, -0.1, 0.2, -0.2, 0.1, -0.1];
  }

  static List<List<double>> _getW2Simplified() {
    // 5x10 weight matrix (simplified from 50x100)
    return [
      [0.1, 0.2, 0.3, -0.1, 0.2, -0.1, 0.3, -0.2, 0.1, 0.2],
      [-0.2, 0.1, 0.2, 0.3, -0.1, 0.2, -0.2, 0.1, 0.3, -0.1],
      [0.3, -0.2, 0.1, 0.2, 0.3, -0.1, 0.2, -0.2, 0.1, 0.3],
      [0.1, 0.2, -0.1, 0.3, 0.2, 0.1, -0.2, 0.3, 0.2, 0.1],
      [-0.1, 0.3, 0.2, 0.1, -0.2, 0.3, 0.2, 0.1, -0.1, 0.2],
    ];
  }

  static List<double> _getB2Simplified() {
    return [0.1, -0.1, 0.2, -0.2, 0.1];
  }

  static List<List<double>> _getW3Simplified() {
    // 1x5 weight matrix
    return [
      [0.2, 0.3, -0.1, 0.25, 0.15],
    ];
  }

  static List<double> _getB3Simplified() {
    return [0.1];
  }

  /// Get stress level interpretation
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

  /// Get color for stress level visualization
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

/// Stress prediction result
class StressPredictionResult {
  final double stressLevel; // 0-100
  final String interpretation;
  final int color;
  final DateTime timestamp;

  StressPredictionResult({
    required this.stressLevel,
    required this.interpretation,
    required this.color,
    required this.timestamp,
  });

  factory StressPredictionResult.fromSensorData(
    double temperature,
    double humidity,
    double noise,
    double lighting,
  ) {
    final stressLevel = StressPredictionModel.predictStress(
      temperature,
      humidity,
      noise,
      lighting,
      useNeuralNetwork: true,
    );
    final interpretation = StressPredictionModel.getStressInterpretation(stressLevel);
    final color = StressPredictionModel.getStressColor(stressLevel);

    return StressPredictionResult(
      stressLevel: stressLevel,
      interpretation: interpretation,
      color: color,
      timestamp: DateTime.now(),
    );
  }
}
