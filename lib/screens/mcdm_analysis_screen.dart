import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/mcdm_result.dart';
import '../services/mcdm_calculator.dart';
import '../services/mcdm_service.dart';
import '../services/stress_prediction_model.dart';
import '../widgets/mcdm_score_card.dart';
import '../widgets/stress_prediction_card.dart';

class MCDMAnalysisScreen extends StatefulWidget {
  const MCDMAnalysisScreen({
    super.key,
    required this.firebaseReady,
  });

  final bool firebaseReady;

  @override
  State<MCDMAnalysisScreen> createState() => _MCDMAnalysisScreenState();
}

class _MCDMAnalysisScreenState extends State<MCDMAnalysisScreen> {
  late MCDMService _mcdmService;
  
  String _selectedWeightMethod = 'compromise';
  ScoringMethod _selectedScoringMethod = ScoringMethod.mabac;
  
  MCDMAnalysisResult? _currentAnalysis;
  StressPredictionResult? _stressPrediction;
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseReady) {
      _mcdmService = MCDMService(
        database: FirebaseDatabase.instance,
      );
      _loadLatestAnalysis();
    }
  }

  void _loadLatestAnalysis() async {
    if (!widget.firebaseReady) return;

    setState(() => _isLoading = true);

    try {
      final results = await _mcdmService
          .recentAnalysis(limit: 1)
          .first;

      if (results.isNotEmpty) {
        setState(() {
          _currentAnalysis = results.first;
          _stressPrediction = StressPredictionResult(
            stressLevel: results.first.stressLevel,
            interpretation: results.first.stressInterpretation,
            color: StressPredictionModel.getStressColor(results.first.stressLevel),
            timestamp: results.first.timestamp,
          );
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error loading analysis: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _performAnalysis() async {
    if (!widget.firebaseReady) {
      setState(() => _errorMessage = 'Firebase not initialized');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For demo, use sample sensor values
      // In real app, get these from actual sensors
      final result = await _mcdmService.analyzeAndStore(
        temperature: 22.5,
        humidity: 55.0,
        noise: 45.0,
        lighting: 400.0,
        weightMethod: _selectedWeightMethod,
      );

      setState(() {
        _currentAnalysis = result;
        _stressPrediction = StressPredictionResult(
          stressLevel: result.stressLevel,
          interpretation: result.stressInterpretation,
          color: StressPredictionModel.getStressColor(result.stressLevel),
          timestamp: result.timestamp,
        );
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error performing analysis: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCDM Analysis'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Method selectors
            WeightMethodSelector(
              selectedMethod: _selectedWeightMethod,
              onMethodChanged: (method) {
                setState(() => _selectedWeightMethod = method);
              },
            ),
            const SizedBox(height: 12),

            ScoringMethodSelector(
              selectedMethod: _selectedScoringMethod,
              onMethodChanged: (method) {
                setState(() => _selectedScoringMethod = method);
              },
            ),
            const SizedBox(height: 16),

            // Action button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _performAnalysis,
              icon: const Icon(Icons.analytics),
              label: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Analyze Environment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Results
            if (_currentAnalysis != null) ...[
              MCDMScoreCard(
                result: _currentAnalysis!,
                onRefresh: _performAnalysis,
              ),
              const SizedBox(height: 20),
            ],

            if (_stressPrediction != null) ...[
              StressPredictionCard(
                result: _stressPrediction!,
              ),
              const SizedBox(height: 20),
            ],

            // History section
            if (widget.firebaseReady)
              _buildHistorySection(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Analyses',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<MCDMAnalysisResult>>(
              stream: _mcdmService.recentAnalysis(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final results = snapshot.data ?? [];

                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      'No analyses yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return _buildHistoryItem(result, index);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(MCDMAnalysisResult result, int index) {
    return Padding(
      padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatTime(result.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${result.averageScore.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          result.weightMethod,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.stressLevel.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(
                      StressPredictionModel.getStressColor(result.stressLevel),
                    ),
                  ),
                ),
                Text(
                  'Stress',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
