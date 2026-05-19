/// MCDM Analysis Result Model
/// Stores the result of MCDM analysis with all scoring methods
class MCDMAnalysisResult {
  MCDMAnalysisResult({
    required this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.noise,
    required this.lighting,
    required this.weightMethod,
    required this.mabacScore,
    required this.marcosScore,
    required this.spotisScore,
    required this.cococometScore,
    required this.averageScore,
    required this.stressLevel,
    required this.stressInterpretation,
  });

  final String id;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double noise;
  final double lighting;
  final String weightMethod; // STD, Entropy, CRITIC, MEREC, Compromise
  final double mabacScore;
  final double marcosScore;
  final double spotisScore;
  final double cococometScore;
  final double averageScore;
  final double stressLevel;
  final String stressInterpretation;

  factory MCDMAnalysisResult.fromMap(String id, Map<dynamic, dynamic> data) {
    return MCDMAnalysisResult(
      id: id,
      timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0,
      noise: (data['noise'] as num?)?.toDouble() ?? 0,
      lighting: (data['lighting'] as num?)?.toDouble() ?? 0,
      weightMethod: data['weight_method']?.toString() ?? 'compromise',
      mabacScore: (data['mabac_score'] as num?)?.toDouble() ?? 0,
      marcosScore: (data['marcos_score'] as num?)?.toDouble() ?? 0,
      spotisScore: (data['spotis_score'] as num?)?.toDouble() ?? 0,
      cococometScore: (data['cococomet_score'] as num?)?.toDouble() ?? 0,
      averageScore: (data['average_score'] as num?)?.toDouble() ?? 0,
      stressLevel: (data['stress_level'] as num?)?.toDouble() ?? 0,
      stressInterpretation: data['stress_interpretation']?.toString() ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'noise': noise,
      'lighting': lighting,
      'weight_method': weightMethod,
      'mabac_score': mabacScore,
      'marcos_score': marcosScore,
      'spotis_score': spotisScore,
      'cococomet_score': cococometScore,
      'average_score': averageScore,
      'stress_level': stressLevel,
      'stress_interpretation': stressInterpretation,
    };
  }
}

/// Environment Quality Score (composite of all MCDM methods)
class EnvironmentQualityScore {
  EnvironmentQualityScore({
    required this.timestamp,
    required this.overallScore, // Average of all MCDM methods
    required this.mabacScore,
    required this.marcosScore,
    required this.spotisScore,
    required this.cococometScore,
  });

  final DateTime timestamp;
  final double overallScore;
  final double mabacScore;
  final double marcosScore;
  final double spotisScore;
  final double cococometScore;

  /// Get interpretation of overall score
  String getQualityInterpretation() {
    if (overallScore >= 0.8) {
      return 'Excellent';
    } else if (overallScore >= 0.6) {
      return 'Good';
    } else if (overallScore >= 0.4) {
      return 'Fair';
    } else if (overallScore >= 0.2) {
      return 'Poor';
    } else {
      return 'Very Poor';
    }
  }

  /// Get color for visualization
  int getQualityColor() {
    if (overallScore >= 0.8) {
      return 0xFF4CAF50; // Green
    } else if (overallScore >= 0.6) {
      return 0xFF8BC34A; // Light Green
    } else if (overallScore >= 0.4) {
      return 0xFFFFC107; // Amber
    } else if (overallScore >= 0.2) {
      return 0xFFFF9800; // Orange
    } else {
      return 0xFFF44336; // Red
    }
  }
}
