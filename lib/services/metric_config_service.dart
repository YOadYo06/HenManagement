import 'dart:convert';
import 'package:env_reading/models/live_metric.dart';
import 'package:env_reading/services/model_predictor.dart';

/// Service to load and parse mcdm_flutter_config.json
class MetricConfigService {
  static final MetricConfigService _instance = MetricConfigService._internal();

  factory MetricConfigService() {
    return _instance;
  }

  MetricConfigService._internal();

  bool _isLoaded = false;

  /// Load config from raw JSON string
  /// 
  /// Call this from your main app initialization with the JSON content
  void loadFromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      LiveMetricRepository.initialize(json);
      _isLoaded = true;
    } catch (e) {
      print('Error loading metric config: $e');
      _isLoaded = false;
    }
  }

  /// Initialize the model predictor (load normalization data)
  Future<void> initModelPredictor() async {
    await ModelPredictor.loadNormalization();
  }

  /// Check if config is loaded
  bool get isLoaded => _isLoaded;

  /// Get all datasets
  List<LiveMetricDataset> getAllDatasets() {
    return LiveMetricRepository.getAllDatasets();
  }

  /// Get dataset by ID
  LiveMetricDataset? getDataset(String id) {
    return LiveMetricRepository.getDataset(id);
  }

  /// Get default dataset
  LiveMetricDataset? getDefaultDataset() {
    return LiveMetricRepository.getDefaultDataset();
  }

  /// Search datasets
  List<LiveMetricDataset> searchDatasets(String query) {
    return LiveMetricRepository.searchDatasets(query);
  }
}
