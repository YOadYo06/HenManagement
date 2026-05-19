import 'package:firebase_database/firebase_database.dart';

import '../models/mcdm_result.dart';
import '../services/mcdm_calculator.dart';
import '../services/stress_prediction_model.dart';

/// MCDM Service for handling analysis and Firebase storage
class MCDMService {
  MCDMService({required FirebaseDatabase database})
      : _database = database;

  final FirebaseDatabase _database;

  DatabaseReference get _root => _database.ref('study_desk_monitor');
  DatabaseReference get _mcdmRef => _root.child('mcdm_analysis');

  /// Analyze current reading and store result to Firebase
  Future<MCDMAnalysisResult> analyzeAndStore({
    required double temperature,
    required double humidity,
    required double noise,
    required double lighting,
    String weightMethod = 'compromise',
    List<List<double>>? historicalData,
  }) async {
    try {
      // Parse weight method
      final wMethod = _parseWeightMethod(weightMethod);
      
      // Predict stress level
      final stressPrediction = StressPredictionResult.fromSensorData(
        temperature,
        humidity,
        noise,
        lighting,
      );

      // If historical data provided, perform full MCDM analysis
      late MCDMResult mcdmResult;
      if (historicalData != null && historicalData.isNotEmpty) {
        final reading = SensorReading(
          temperature: temperature,
          humidity: humidity,
          noise: noise,
          lighting: lighting,
        );
        
        mcdmResult = MCDMCalculator.analyzeSingleReading(
          reading,
          historicalData,
          wMethod,
          ScoringMethod.mabac, // Default display method
        );
      } else {
        // Fallback to simple scoring if no historical data
        mcdmResult = _createSimpleMCDMResult(
          temperature,
          humidity,
          noise,
          lighting,
          wMethod,
        );
      }

      // Create result object
      final result = MCDMAnalysisResult(
        id: _mcdmRef.push().key ?? '',
        timestamp: DateTime.now(),
        temperature: temperature,
        humidity: humidity,
        noise: noise,
        lighting: lighting,
        weightMethod: weightMethod,
        mabacScore: mcdmResult.mabacScore,
        marcosScore: mcdmResult.marcosScore,
        spotisScore: mcdmResult.spotisScore,
        cococometScore: mcdmResult.cococometScore,
        averageScore: mcdmResult.averageScore,
        stressLevel: stressPrediction.stressLevel,
        stressInterpretation: stressPrediction.interpretation,
      );

      // Store to Firebase
      await _mcdmRef.child(result.id).set(result.toMap());

      return result;
    } catch (e) {
      throw Exception('Failed to analyze and store MCDM result: $e');
    }
  }

  /// Get stream of recent MCDM analysis results
  Stream<List<MCDMAnalysisResult>> recentAnalysis({int limit = 20}) {
    final query = _mcdmRef.orderByKey().limitToLast(limit);
    return query.onValue.map((event) => _mapMCDMResults(event.snapshot));
  }

  /// Get MCDM result by weight method
  Stream<List<MCDMAnalysisResult>> analysisByWeightMethod({
    required String method,
    int limit = 20,
  }) {
    final query = _mcdmRef
        .orderByChild('weight_method')
        .equalTo(method)
        .limitToLast(limit);
    return query.onValue.map((event) => _mapMCDMResults(event.snapshot));
  }

  /// Delete analysis result
  Future<void> deleteAnalysis(String resultId) async {
    await _mcdmRef.child(resultId).remove();
  }

  /// Clear all analysis results
  Future<void> clearAllAnalysis() async {
    await _mcdmRef.remove();
  }

  /// Get average scores over time period
  Future<EnvironmentQualityScore> getAverageScores({
    required Duration timeWindow,
  }) async {
    try {
      final snapshot = await _mcdmRef.get();
      if (!snapshot.exists) {
        return EnvironmentQualityScore(
          timestamp: DateTime.now(),
          overallScore: 0,
          mabacScore: 0,
          marcosScore: 0,
          spotisScore: 0,
          cococometScore: 0,
        );
      }

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return EnvironmentQualityScore(
          timestamp: DateTime.now(),
          overallScore: 0,
          mabacScore: 0,
          marcosScore: 0,
          spotisScore: 0,
          cococometScore: 0,
        );
      }

      final cutoffTime = DateTime.now().subtract(timeWindow);
      final results = <MCDMAnalysisResult>[];

      for (final entry in data.entries) {
        if (entry.value is Map<dynamic, dynamic>) {
          final result = MCDMAnalysisResult.fromMap(
            entry.key.toString(),
            entry.value as Map<dynamic, dynamic>,
          );
          if (result.timestamp.isAfter(cutoffTime)) {
            results.add(result);
          }
        }
      }

      if (results.isEmpty) {
        return EnvironmentQualityScore(
          timestamp: DateTime.now(),
          overallScore: 0,
          mabacScore: 0,
          marcosScore: 0,
          spotisScore: 0,
          cococometScore: 0,
        );
      }

      final avgMabac =
          results.fold(0.0, (sum, r) => sum + r.mabacScore) / results.length;
      final avgMarcos =
          results.fold(0.0, (sum, r) => sum + r.marcosScore) / results.length;
      final avgSpotis =
          results.fold(0.0, (sum, r) => sum + r.spotisScore) / results.length;
      final avgCococomet =
          results.fold(0.0, (sum, r) => sum + r.cococometScore) / results.length;
      final overall = (avgMabac + avgMarcos + avgSpotis + avgCococomet) / 4;

      return EnvironmentQualityScore(
        timestamp: DateTime.now(),
        overallScore: overall,
        mabacScore: avgMabac,
        marcosScore: avgMarcos,
        spotisScore: avgSpotis,
        cococometScore: avgCococomet,
      );
    } catch (e) {
      throw Exception('Failed to get average scores: $e');
    }
  }

  // Private helpers

  WeightMethod _parseWeightMethod(String method) {
    switch (method.toLowerCase()) {
      case 'std':
        return WeightMethod.std;
      case 'entropy':
        return WeightMethod.entropy;
      case 'critic':
        return WeightMethod.critic;
      case 'merec':
        return WeightMethod.merec;
      case 'compromise':
      default:
        return WeightMethod.compromise;
    }
  }

  /// Create simple MCDM result when no historical data available
  MCDMResult _createSimpleMCDMResult(
    double temperature,
    double humidity,
    double noise,
    double lighting,
    WeightMethod method,
  ) {
    // Use a single reading as base
    final normalizedData = MCDMCalculator.normalizeSensorMatrix([
      [temperature, humidity, noise, lighting]
    ]);
    
    final weights = MCDMCalculator.getWeights(normalizedData, method);

    // Score the single reading
    final mabacScores = MCDMCalculator.scoreMABAC(normalizedData, weights);
    final marcosScores = MCDMCalculator.scoreMARCOS(normalizedData, weights);
    final spotisScores = MCDMCalculator.scoreSPOTIS(normalizedData, weights);
    final cococometScores = MCDMCalculator.scoreCOCOMET(normalizedData, weights);

    final avgScore =
        (mabacScores[0] + marcosScores[0] + spotisScores[0] + cococometScores[0]) /
            4;

    return MCDMResult(
      selectedMethod: ScoringMethod.mabac,
      selectedScore: mabacScores[0],
      mabacScore: mabacScores[0],
      marcosScore: marcosScores[0],
      spotisScore: spotisScores[0],
      cococometScore: cococometScores[0],
      averageScore: avgScore,
      weights: weights,
      weightMethod: method,
      normalizedReading: normalizedData[0],
    );
  }

  List<MCDMAnalysisResult> _mapMCDMResults(DataSnapshot snapshot) {
    final data = snapshot.value;
    if (data is! Map<dynamic, dynamic>) return [];

    final results = <MCDMAnalysisResult>[];
    for (final entry in data.entries) {
      final id = entry.key.toString();
      final value = entry.value;
      if (value is Map<dynamic, dynamic>) {
        results.add(MCDMAnalysisResult.fromMap(id, value));
      }
    }

    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }
}
