class Reading {
  Reading({
    required this.id,
    required this.timestamp,
    required this.light,
    required this.noise,
    required this.temperature,
    required this.humidity,
    required this.comfortScore,
  });

  final String id;
  final DateTime timestamp;
  final double light;
  final double noise;
  final double temperature;
  final double humidity;
  final int comfortScore;

  factory Reading.fromMap(String id, Map<dynamic, dynamic> data) {
    return Reading(
      id: id,
      timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      light: (data['light'] as num?)?.toDouble() ?? 0,
      noise: (data['noise'] as num?)?.toDouble() ?? 0,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0,
      comfortScore: (data['comfort_score'] as num?)?.toInt() ?? 0,
    );
  }
}
