/// Sensor Readings Model
/// Holds current sensor reading values for MCDM analysis

import 'package:env_reading/models/sensor_config.dart';

class SensorReadings {
  final Map<String, double?> values; // Key: sensor ID, Value: sensor reading
  final InputMode inputMode;         // Source: Firebase or Manual input
  final DateTime timestamp;          // When these readings were taken

  SensorReadings({
    required this.values,
    required this.inputMode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Get value for a specific sensor
  double? getValue(String sensorId) => values[sensorId];

  /// Set value for a specific sensor
  void setValue(String sensorId, double? value) {
    values[sensorId] = value;
  }

  /// Check if all required sensors have values
  bool hasAllRequiredSensors(List<String> requiredSensorIds) {
    return requiredSensorIds.every((id) => values[id] != null && values[id]! >= 0);
  }

  /// Get list of missing required sensors
  List<String> getMissingSensors(List<String> requiredSensorIds) {
    return requiredSensorIds
        .where((id) => values[id] == null || values[id]! < 0)
        .toList();
  }

  /// Convert to normalized values using sensor configs
  Map<String, double> getNormalizedValues(Map<String, SensorConfig> sensorConfigs) {
    final normalized = <String, double>{};
    for (final entry in values.entries) {
      final sensorId = entry.key;
      final value = entry.value;
      final config = sensorConfigs[sensorId];

      if (value != null && config != null && config.isAvailable) {
        normalized[sensorId] = config.normalize(value);
      }
    }
    return normalized;
  }

  /// Create from Firebase data (typical pattern)
  factory SensorReadings.fromFirebase({
    double? temperature,
    double? humidity,
    double? noise,
    double? lighting,
    double? co2,
    double? soilMoisture,
    double? motion,
  }) {
    return SensorReadings(
      values: {
        'temperature': temperature,
        'humidity': humidity,
        'noise': noise,
        'lighting': lighting,
        'co2': co2,
        'soil_moisture': soilMoisture,
        'motion': motion,
      },
      inputMode: InputMode.firebase,
    );
  }

  /// Create empty readings for manual input
  factory SensorReadings.empty() {
    return SensorReadings(
      values: {},
      inputMode: InputMode.manual,
    );
  }

  /// Copy with updated values
  SensorReadings copyWith({
    Map<String, double?>? values,
    InputMode? inputMode,
    DateTime? timestamp,
  }) {
    return SensorReadings(
      values: values ?? Map.from(this.values),
      inputMode: inputMode ?? this.inputMode,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => 'SensorReadings($inputMode): $values';
}
