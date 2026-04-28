class Thresholds {
  const Thresholds({
    required this.lightMin,
    required this.lightMax,
    required this.noiseMin,
    required this.noiseMax,
    required this.tempMin,
    required this.tempMax,
  });

  final double lightMin;
  final double lightMax;
  final double noiseMin;
  final double noiseMax;
  final double tempMin;
  final double tempMax;

  factory Thresholds.fromMap(Map<dynamic, dynamic>? data) {
    return Thresholds(
      lightMin: (data?['light_min'] as num?)?.toDouble() ?? 300,
      lightMax: (data?['light_max'] as num?)?.toDouble() ?? 500,
      noiseMin: (data?['noise_min'] as num?)?.toDouble() ?? 30,
      noiseMax: (data?['noise_max'] as num?)?.toDouble() ?? 70,
      tempMin: (data?['temp_min'] as num?)?.toDouble() ?? 20,
      tempMax: (data?['temp_max'] as num?)?.toDouble() ?? 24,
    );
  }

  static const defaults = Thresholds(
    lightMin: 300,
    lightMax: 500,
    noiseMin: 30,
    noiseMax: 70,
    tempMin: 20,
    tempMax: 24,
  );
}
