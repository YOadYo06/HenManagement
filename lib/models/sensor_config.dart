/// Sensor Configuration Model
/// Defines sensor properties, ranges, and criteria types across different datasets

enum CriteriaType { cost, profit }

enum InputMode { firebase, manual }

class SensorConfig {
  final String id;                    // Unique sensor identifier (temp, humidity, noise, light, co2, etc)
  final String displayName;           // User-friendly name (Temperature, Humidity, etc)
  final String unit;                  // Unit of measurement (°C, %, dB, lux, ppm)
  final double minValue;              // Minimum value in dataset
  final double maxValue;              // Maximum value in dataset
  final double meanValue;             // Mean/average value in dataset
  final CriteriaType criteriaType;    // Is this cost (↓ lower better) or profit (↑ higher better)?
  final bool isRequired;              // Whether this sensor is required for MCDM
  final bool isAvailable;             // Whether this sensor is available in the dataset

  SensorConfig({
    required this.id,
    required this.displayName,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.meanValue,
    required this.criteriaType,
    this.isRequired = false,
    this.isAvailable = true,
  });

  /// Get normalized value in [0, 1]
  double normalize(double value) {
    if (maxValue <= minValue) return 0.5;
    return (value - minValue) / (maxValue - minValue);
  }

  /// Get denormalized value from [0, 1]
  double denormalize(double normalizedValue) {
    return minValue + normalizedValue * (maxValue - minValue);
  }

  /// Get color based on criteria type and normalized value
  int getColor(double normalizedValue) {
    if (!isAvailable) {
      return 0xFF9E9E9E; // Gray for unavailable sensors
    }
    
    // Green to Red gradient
    if (criteriaType == CriteriaType.cost) {
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

  /// Get status text based on normalized value
  String getStatus(double normalizedValue) {
    if (!isAvailable) return 'Not Available';
    
    if (criteriaType == CriteriaType.cost) {
      if (normalizedValue < 0.25) return 'Excellent';
      if (normalizedValue < 0.5) return 'Good';
      if (normalizedValue < 0.75) return 'Fair';
      return 'Poor';
    } else {
      if (normalizedValue > 0.75) return 'Excellent';
      if (normalizedValue > 0.5) return 'Good';
      if (normalizedValue > 0.25) return 'Fair';
      return 'Poor';
    }
  }

  @override
  String toString() => '$displayName ($unit): $minValue - $maxValue (mean: $meanValue)';
}
