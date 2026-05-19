/// Live Metrics Model
/// Loads pre-calculated weights and sensor data from mcdm_flutter_config.json

class LiveMetricSensor {
  final String id;
  final String name;
  final String displayName;
  final String unit;
  final String type; // "COST" or "PROFIT"
  final double minValue;
  final double maxValue;
  final double meanValue;
  final double weight;
  final String? modelFeature; // Name of this sensor's feature in the ML model

  LiveMetricSensor({
    required this.id,
    required this.name,
    required this.displayName,
    required this.unit,
    required this.type,
    required this.minValue,
    required this.maxValue,
    required this.meanValue,
    required this.weight,
    this.modelFeature,
  });

  factory LiveMetricSensor.fromJson(Map<String, dynamic> json) {
    return LiveMetricSensor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      unit: json['unit'] ?? '',
      type: json['type'] ?? 'COST',
      minValue: (json['range']?['min'] ?? 0).toDouble(),
      maxValue: (json['range']?['max'] ?? 100).toDouble(),
      meanValue: (json['mean'] ?? 50).toDouble(),
      weight: (json['weight'] ?? 0.25).toDouble(),
      modelFeature: json['modelFeature'] as String?,
    );
  }

  /// Normalize to [0, 1]
  double normalize(double value) {
    if (maxValue <= minValue) return 0.5;
    return (value - minValue) / (maxValue - minValue);
  }

  /// Get color based on criteria type and normalized value
  int getColor(double normalizedValue) {
    // Green to Red gradient
    if (type == 'COST') {
      // For cost criteria: 0 (green/good) to 1 (red/bad)
      if (normalizedValue < 0.25) return 0xFF4CAF50;  // Green
      if (normalizedValue < 0.5) return 0xFF8BC34A;   // Light green
      if (normalizedValue < 0.75) return 0xFFFFC107;  // Amber
      return 0xFFFF5722;                               // Red
    } else {
      // For profit criteria: 1 (green/good) to 0 (red/bad)
      if (normalizedValue > 0.75) return 0xFF4CAF50;  // Green
      if (normalizedValue > 0.5) return 0xFF8BC34A;   // Light green
      if (normalizedValue > 0.25) return 0xFFFFC107;  // Amber
      return 0xFFFF5722;                               // Red
    }
  }

  @override
  String toString() => '$displayName ($unit)';
}

class LiveMetricDataset {
  final String id;
  final String name;
  final String description;
  final String domain;
  final List<LiveMetricSensor> sensors;
  final String predictionType; // "REGRESSION" or "CLASSIFICATION"
  final List<String> predictions;
  final Map<String, Map<String, double>> allWeights;
  final List<String> models;
  final String bestModel;
  final Map<String, dynamic>? modelConfig;

  LiveMetricDataset({
    required this.id,
    required this.name,
    required this.description,
    required this.domain,
    required this.sensors,
    required this.predictions,
    required this.allWeights,
    this.predictionType = 'REGRESSION',
    this.models = const [],
    this.bestModel = '',
    this.modelConfig,
  });

  bool get isClassification => predictionType == 'CLASSIFICATION';

  factory LiveMetricDataset.fromJson(Map<String, dynamic> json) {
    final sensors = (json['sensors'] as List?)
            ?.map((s) => LiveMetricSensor.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    final predictions = List<String>.from(json['predictions'] as List? ?? []);

    final allWeights = <String, Map<String, double>>{};
    final weightsJson = json['weights'] as Map<String, dynamic>?;
    if (weightsJson != null) {
      weightsJson.forEach((method, weights) {
        allWeights[method] = Map<String, double>.from(
          (weights as Map).cast<String, double>(),
        );
      });
    }

    final models = List<String>.from(json['models'] as List? ?? []);
    final bestModel = json['bestModel'] as String? ?? (models.isNotEmpty ? models.first : '');
    final modelConfig = json['modelConfig'] as Map<String, dynamic>?;

    return LiveMetricDataset(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      domain: json['domain'] ?? '',
      sensors: sensors,
      predictions: predictions,
      allWeights: allWeights,
      predictionType: json['predictionType'] as String? ?? 'REGRESSION',
      models: models,
      bestModel: bestModel,
      modelConfig: modelConfig,
    );
  }

  // Get compromise weights (recommended)
  Map<String, double> getCompromiseWeights() {
    return allWeights['Compromise'] ?? {};
  }

  // Get any weight method
  Map<String, double> getWeights(String method) {
    return allWeights[method] ?? getCompromiseWeights();
  }

  // Get all available weight methods
  List<String> getWeightMethods() {
    return allWeights.keys.toList();
  }
}

class LiveMetricValue {
  final LiveMetricSensor sensor;
  final double value;
  final bool isFromDataset; // true = from dataset (min/max/mean), false = custom
  final String sourceType; // 'min', 'max', 'mean', or 'custom'

  LiveMetricValue({
    required this.sensor,
    required this.value,
    this.isFromDataset = true,
    this.sourceType = 'mean',
  });

  // Normalize to [0, 1]
  double normalize() {
    if (sensor.maxValue <= sensor.minValue) return 0.5;
    return (value - sensor.minValue) / (sensor.maxValue - sensor.minValue);
  }

  // Get interpretation
  String getInterpretation() {
    final normalized = normalize();
    if (sensor.type == 'COST') {
      // For cost: lower is better
      if (normalized < 0.25) return 'Excellent';
      if (normalized < 0.5) return 'Good';
      if (normalized < 0.75) return 'Fair';
      return 'Poor';
    } else {
      // For profit: higher is better
      if (normalized > 0.75) return 'Excellent';
      if (normalized > 0.5) return 'Good';
      if (normalized > 0.25) return 'Fair';
      return 'Poor';
    }
  }

  @override
  String toString() => '$sensor: $value ${sensor.unit} ($sourceType)';
}

class LiveMetric {
  final String id;
  final LiveMetricDataset dataset;
  final List<LiveMetricValue> sensorValues;
  final String weightMethod; // Which method was used
  final DateTime timestamp;
  final double? calculatedScore; // 0-1 or null if not all sensors present

  LiveMetric({
    required this.id,
    required this.dataset,
    required this.sensorValues,
    this.weightMethod = 'Compromise',
    DateTime? timestamp,
    this.calculatedScore,
  }) : timestamp = timestamp ?? DateTime.now();

  // Check if all sensors have values
  bool isComplete() {
    return sensorValues.length == dataset.sensors.length;
  }

  // Get missing sensors
  List<String> getMissingSensors() {
    final provided = sensorValues.map((v) => v.sensor.id).toSet();
    return dataset.sensors.map((s) => s.id).where((id) => !provided.contains(id)).toList();
  }

  @override
  String toString() =>
      'Metric: ${dataset.name} - Score: ${calculatedScore != null ? (calculatedScore! * 100).toStringAsFixed(1) : "N/A"}%';
}

class LiveMetricRepository {
  static final Map<String, LiveMetricDataset> _datasets = {};
  static bool _initialized = false;

  /// Initialize from JSON config
  static void initialize(Map<String, dynamic> configJson) {
    final datasets = configJson['datasets'] as List? ?? [];
    for (final datasetJson in datasets) {
      final dataset = LiveMetricDataset.fromJson(datasetJson as Map<String, dynamic>);
      _datasets[dataset.id] = dataset;
    }
    _initialized = true;
  }

  static bool get isInitialized => _initialized;

  /// Get all datasets
  static List<LiveMetricDataset> getAllDatasets() => _datasets.values.toList();

  /// Get dataset by ID
  static LiveMetricDataset? getDataset(String id) => _datasets[id];

  /// Get default (first) dataset
  static LiveMetricDataset? getDefaultDataset() => _datasets.values.isNotEmpty ? _datasets.values.first : null;

  /// Search datasets by name
  static List<LiveMetricDataset> searchDatasets(String query) {
    final lowerQuery = query.toLowerCase();
    return _datasets.values
        .where((d) => d.name.toLowerCase().contains(lowerQuery) || d.domain.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
