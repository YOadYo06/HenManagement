import 'dart:convert';
import 'package:flutter/services.dart';

// Import all generated model functions
import '../generated_models/egg_production.dart';
import '../generated_models/green_building.dart';
import '../generated_models/herbal_plant_health.dart';
import '../generated_models/iot_air_quality.dart';
import '../generated_models/iot_mental_health.dart';
import '../generated_models/smart_library.dart';
import '../generated_models/building_occupancy.dart';
import '../generated_models/user_behavior_raed.dart';

class ModelPredictor {
  static Map<String, dynamic>? _normData;

  static Future<void> loadNormalization() async {
    final json = await rootBundle.loadString('assets/model_normalization.json');
    _normData = jsonDecode(json);
  }

  static double _normalize(String datasetId, String featureName, double rawValue) {
    if (_normData == null) return 0.5;
    final norm = _normData!['normalization'] as Map<String, dynamic>;
    final dsNorm = norm[datasetId] as Map<String, dynamic>?;
    if (dsNorm == null) return 0.5;
    final feature = dsNorm[featureName] as Map<String, dynamic>?;
    if (feature == null) return 0.5;
    final minVal = (feature['min'] as num).toDouble();
    final maxVal = (feature['max'] as num).toDouble();
    final range = maxVal - minVal;
    if (range == 0) return 0.5;
    // Determine cost vs profit based on feature name conventions
    final lower = featureName.toLowerCase();
    final isCost = lower.contains('temperature') || lower.contains('humidity') ||
        lower.contains('noise') || lower.contains('co2') ||
        featureName == 'HumidityRatio' || featureName == 'noise_db' ||
        lower.startsWith('indoor_');
    if (isCost) {
      return (maxVal - rawValue) / range;
    } else {
      return (rawValue - minVal) / range;
    }
  }

  static List<String>? getModelFeatures(String datasetId) {
    if (_normData == null) return null;
    final norm = _normData!['normalization'] as Map<String, dynamic>;
    final dsNorm = norm[datasetId] as Map<String, dynamic>?;
    if (dsNorm == null) return null;
    return dsNorm.keys.toList();
  }

  static List<String>? getClasses(String datasetId) {
    if (_normData == null) return null;
    final classes = _normData!['classes'] as Map<String, dynamic>?;
    if (classes == null) return null;
    final c = classes[datasetId];
    if (c is List) return c.cast<String>();
    return null;
  }

  static double _clamp0(double v) => v < 0 ? 0 : v;

  static double _argmax(List<double> probs) {
    double maxVal = probs[0];
    int maxIdx = 0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxVal) {
        maxVal = probs[i];
        maxIdx = i;
      }
    }
    return maxIdx.toDouble();
  }

  static double predict(String datasetId, Map<String, double> sensorValues) {
    final features = getModelFeatures(datasetId);
    if (features == null) return 0;

    final input = <double>[];
    for (final feature in features) {
      final raw = sensorValues[feature] ?? 0.5;
      final normVal = _normalize(datasetId, feature, raw);
      input.add(normVal.clamp(0.0, 1.0));
    }

    switch (datasetId) {
      case 'egg_production':
        return predictEggproduction(input) + 689;
      case 'green_building':
        return _clamp0(predictGreenbuilding(input));
      case 'herbal_plant_health':
        return predictHerbalPlantHealth(input);
      case 'iot_air_quality':
        return _clamp0(predictIotairquality(input));
      case 'smart_library':
        return predictSmartLibrary(input);
      case 'building_occupancy':
        return _argmax(predictBuildingoccupancy(input));
      case 'user_behavior_raed':
        return _argmax(predictUserBehaviorRaed(input));
      case 'iot_mental_health': {
        final raw = predictIotmentalhealth(input);
        // Map decision tree output (0-78 raw) to 0-5 scale
        return (raw.clamp(0, 80) / 80.0) * 5.0;
      }
      default:
        return 0;
    }
  }

  static String predictLabel(String datasetId, Map<String, double> sensorValues) {
    final classes = getClasses(datasetId);
    if (classes != null) {
      final idx = predict(datasetId, sensorValues).toInt();
      if (idx >= 0 && idx < classes.length) return classes[idx];
      return 'Unknown';
    }
    final val = predict(datasetId, sensorValues);
    return val.toStringAsFixed(2);
  }
}
