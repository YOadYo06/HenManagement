import 'package:env_reading/models/live_metric.dart';
import 'package:env_reading/services/model_predictor.dart';
import 'dart:math';

class PreCalculatedMCDMCalculator {
  static const List<String> scoringMethods = ['MABAC', 'MARCOS', 'SPOTIS', 'COCOCOMET'];

  static double calculateScore({
    required List<LiveMetricValue> sensorValues,
    required LiveMetricDataset dataset,
    required String weightMethod,
    String scoringMethod = 'MABAC',
  }) {
    if (sensorValues.isEmpty) return 0.5;

    final weights = dataset.getWeights(weightMethod);
    if (weights.isEmpty) return 0.5;

    final normalizedValues = <String, double>{};
    for (final sv in sensorValues) {
      var normalized = sv.normalize();
      // Invert COST (lower is better): min→1.0 (good), max→0.0 (bad)
      // Keep PROFIT as-is (higher is better): min→0.0 (bad), max→1.0 (good)
      if (sv.sensor.type == 'COST') {
        normalized = 1.0 - normalized;
      }
      normalizedValues[sv.sensor.name] = normalized;
    }

    final vals = <double>[];
    final wts = <double>[];
    for (final entry in normalizedValues.entries) {
      final w = weights[entry.key] ?? (1.0 / sensorValues.length);
      vals.add(entry.value);
      wts.add(w);
    }

    switch (scoringMethod) {
      case 'MABAC':
        return _scoreMABAC(vals, wts);
      case 'MARCOS':
        return _scoreMARCOS(vals, wts);
      case 'SPOTIS':
        return _scoreSPOTIS(vals, wts);
      case 'COCOCOMET':
        return _scoreCOCOCOMET(vals, wts);
      default:
        return _scoreMARCOS(vals, wts);
    }
  }

  /// MABAC: Squared deviation from ideal — penalizes low values more
  static double _scoreMABAC(List<double> vals, List<double> wts) {
    double sumW = 0, sumV2 = 0;
    for (int i = 0; i < vals.length; i++) {
      sumW += wts[i];
      sumV2 += wts[i] * vals[i] * vals[i];
    }
    return (sumW > 0 ? sumV2 / sumW : 0.5).clamp(0.0, 1.0);
  }

  /// MARCOS: Simple weighted sum (linear)
  static double _scoreMARCOS(List<double> vals, List<double> wts) {
    double sumW = 0, sumV = 0;
    for (int i = 0; i < vals.length; i++) {
      sumW += wts[i];
      sumV += wts[i] * vals[i];
    }
    return (sumW > 0 ? sumV / sumW : 0.5).clamp(0.0, 1.0);
  }

  /// SPOTIS: Exponential decay from ideal (0) — always > 0
  static double _scoreSPOTIS(List<double> vals, List<double> wts) {
    double sumW = 0, distSq = 0;
    for (int i = 0; i < vals.length; i++) {
      sumW += wts[i];
      distSq += wts[i] * vals[i] * vals[i];
    }
    final dist = sqrt(sumW > 0 ? distSq / sumW : 0);
    return exp(-dist).clamp(0.0, 1.0);
  }

  /// COCOCOMET: Hybrid geometric × arithmetic compromise (CoCoSo-style).
  /// S = Π(v^w) * (1 + Σ(wv)) / 2  — penalizes unbalanced sensors.
  static double _scoreCOCOCOMET(List<double> vals, List<double> wts) {
    double sumW = 0, sumV = 0;
    double product = 1.0;
    for (int i = 0; i < vals.length; i++) {
      sumW += wts[i];
      sumV += wts[i] * vals[i];
      product *= pow(max(vals[i], 1e-10), wts[i]);
    }
    if (sumW == 0) return 0.5;
    final weightedAvg = sumV / sumW;
    return (product * (1.0 + weightedAvg) / 2.0).clamp(0.0, 1.0);
  }

  /// Model prediction from real trained models.
  /// Uses the model predictor which routes to the correct generated Dart function.
  static double? computeModelPrediction({
    required List<LiveMetricValue> sensorValues,
    required LiveMetricDataset dataset,
    double mcdmScore = 0.5,
  }) {
    final config = dataset.modelConfig;
    if (config == null) return null;

    final type = config['type'] as String?;
    final features = config['modelFeatures'] as List<dynamic>?;

    if (type != 'model' || features == null) {
      // Fallback for old config types
      return _legacyPrediction(sensorValues, dataset, config, mcdmScore);
    }

    // Build sensor value map using model feature names
    final sensorMap = <String, double>{};
    for (final sv in sensorValues) {
      final mf = sv.sensor.modelFeature;
      if (mf != null && mf.isNotEmpty) {
        sensorMap[mf] = sv.value;
      }
    }

    return ModelPredictor.predict(dataset.id, sensorMap);
  }

  /// Predict class label for classification models
  static String? predictClassLabel({
    required List<LiveMetricValue> sensorValues,
    required LiveMetricDataset dataset,
    required double mcdmScore,
  }) {
    final config = dataset.modelConfig;
    if (config == null) return null;

    final type = config['type'] as String?;
    final features = config['modelFeatures'] as List<dynamic>?;

    if (type != 'model' || features == null) {
      return _legacyClassLabel(sensorValues, dataset, config, mcdmScore);
    }

    final sensorMap = <String, double>{};
    for (final sv in sensorValues) {
      final mf = sv.sensor.modelFeature;
      if (mf != null && mf.isNotEmpty) {
        sensorMap[mf] = sv.value;
      }
    }

    // Try ModelPredictor's label lookup (reads from model_normalization.json)
    final label = ModelPredictor.predictLabel(dataset.id, sensorMap);
    // If it returns a raw number (norm data missing classes), fall back to config
    if (label != null && (label == '0.00' || label == '1.00' || label == '0.0' || label == '1.0')) {
      final modelClasses = config['modelClasses'] as List<dynamic>?;
      if (modelClasses != null && modelClasses.isNotEmpty) {
        final idx = ModelPredictor.predict(dataset.id, sensorMap).toInt();
        if (idx >= 0 && idx < modelClasses.length) {
          return modelClasses[idx] as String;
        }
      }
    }
    return label;
  }

  /// Legacy fallback for old config types (linear_regression, mcdm_proxy_regression, etc.)
  static double? _legacyPrediction(
    List<LiveMetricValue> sensorValues,
    LiveMetricDataset dataset,
    Map<String, dynamic> config,
    double mcdmScore,
  ) {
    final type = config['type'] as String?;
    if (type == 'linear_regression') {
      return _predictLinearRegression(sensorValues, config);
    }
    if (type == 'mcdm_proxy_regression') {
      final refScore = calculateScore(
        sensorValues: sensorValues,
        dataset: dataset,
        weightMethod: 'Compromise',
        scoringMethod: 'MARCOS',
      );
      return _legacyMCDMProxy(config, refScore);
    }
    return null;
  }

  static String? _legacyClassLabel(
    List<LiveMetricValue> sensorValues,
    LiveMetricDataset dataset,
    Map<String, dynamic> config,
    double mcdmScore,
  ) {
    final type = config['type'] as String?;
    if (type == 'linear_regression') {
      final prediction = computeModelPrediction(sensorValues: sensorValues, dataset: dataset, mcdmScore: mcdmScore);
      if (prediction == null) return null;
      final threshold = (config['threshold'] as num?)?.toDouble() ?? 0.5;
      final classes = List<String>.from(config['classes'] as List? ?? []);
      if (classes.length == 2) return prediction > threshold ? classes[1] : classes[0];
      return prediction.toStringAsFixed(1);
    }
    if (type == 'classification_heuristic') {
      final classes = List<String>.from(config['classes'] as List? ?? []);
      if (classes.isEmpty) return null;
      final classCount = classes.length;
      final index = (mcdmScore * classCount).floor().clamp(0, classCount - 1);
      return classes[index];
    }
    if (type == 'mcdm_proxy_regression') {
      final classes = List<String>.from(config['classes'] as List? ?? []);
      if (classes.length >= 2) {
        final threshold = (config['threshold'] as num?)?.toDouble();
        if (threshold != null) {
          final pred = _legacyMCDMProxy(config, mcdmScore);
          return pred > threshold ? classes[1] : classes[0];
        }
      }
    }
    return null;
  }

  static double _legacyMCDMProxy(Map<String, dynamic> config, double mcdmScore) {
    final targetMin = (config['targetMin'] as num?)?.toDouble() ?? 0;
    final targetMax = (config['targetMax'] as num?)?.toDouble() ?? 100;
    final invert = config['invertScore'] as bool? ?? false;
    final score = invert ? (1.0 - mcdmScore) : mcdmScore;
    return targetMin + score * (targetMax - targetMin);
  }

  static double? _predictLinearRegression(
    List<LiveMetricValue> sensorValues,
    Map<String, dynamic> config,
  ) {
    final intercept = (config['intercept'] as num?)?.toDouble();
    final coeffsRaw = config['coeffs'] as Map<String, dynamic>?;
    if (intercept == null || coeffsRaw == null) return null;
    final coeffs = coeffsRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    double result = intercept;
    for (final sv in sensorValues) {
      final c = coeffs[sv.sensor.name];
      if (c != null) {
        result += c * sv.value;
      }
    }
    return result;
  }

  static String getInterpretation(double score) {
    if (score < 0.2) return 'Critical';
    if (score < 0.4) return 'Poor';
    if (score < 0.6) return 'Fair';
    if (score < 0.8) return 'Good';
    return 'Excellent';
  }

  static int getColor(double score) {
    if (score < 0.2) return 0xFFF44336;
    if (score < 0.4) return 0xFFFF5722;
    if (score < 0.6) return 0xFFFFC107;
    if (score < 0.8) return 0xFF8BC34A;
    return 0xFF4CAF50;
  }

  static String getFormulaExplanation(String method) {
    return getWeightFormula(method);
  }

  static String getWeightFormula(String method) {
    switch (method) {
      case 'STD': return 'Weight = σ(sensor) / Σσ';
      case 'Entropy': return 'Weight = (1 - H) / Σ(1 - H)';
      case 'CRITIC': return 'Weight = C·C / ΣC·C';
      case 'MEREC': return 'Weight = (1 - v) / Σ(1 - v)';
      case 'Compromise': return 'Weight = (STD+Entropy+CRITIC+MEREC)/4';
      default: return '';
    }
  }

  static String getScoringFormula(String method) {
    switch (method) {
      case 'MABAC': return 'S = Σ(w×v²)/Σw (Quadratic)';
      case 'MARCOS': return 'S = Σ(w×v)/Σw (Weighted Sum)';
      case 'SPOTIS': return 'S = e^(-√Σwv²) (Exp-Decay)';
      case 'COCOCOMET': return 'S = Π(v^w)·(1+Σwv)/2 (Compromise)';
      default: return '';
    }
  }

  static String getPredictionDescription(String datasetId) {
    switch (datasetId) {
      case 'egg_production':
        return 'Predicted egg output — calibrated (+689), higher = more eggs';
      case 'green_building':
        return 'Predicted electricity consumption — lower = less energy used (model R²≈0)';
      case 'herbal_plant_health':
        return 'Predicted plant health status (Healthy / Unhealthy)';
      case 'iot_air_quality':
        return 'Predicted number of people present (model R²≈0)';
      case 'smart_library':
        return 'Predicted environment quality (Critical / Optimal / Sub Optimal)';
      case 'building_occupancy':
        return 'Predicted occupancy (Present / Absent)';
      case 'user_behavior_raed':
        return 'Predicted user activity (eating / sleeping / stressed / studying / walking)';
      case 'iot_mental_health':
        return 'Predicted stress level (0=low, 5=high)';
      default:
        return '';
    }
  }

  static String getPredictionRange(String datasetId) {
    switch (datasetId) {
      case 'egg_production':
        return 'Range: 150-450 eggs (+689 calibrated)';
      case 'green_building':
        return 'Range: 0-500 kWh';
      case 'herbal_plant_health':
        return 'Classes: Healthy, Unhealthy';
      case 'iot_air_quality':
        return 'Range: 0-20 people';
      case 'smart_library':
        return 'Classes: Critical, Optimal, Sub Optimal';
      case 'building_occupancy':
        return 'Classes: Present, Absent';
      case 'user_behavior_raed':
        return 'Classes: eating, sleeping, stressed, studying, walking';
      case 'iot_mental_health':
        return 'Range: 0-5 (0=least stressed, 5=most)';
      default:
        return '';
    }
  }
}
