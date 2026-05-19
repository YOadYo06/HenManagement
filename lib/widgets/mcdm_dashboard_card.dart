import 'package:flutter/material.dart';
import '../services/mcdm_calculator.dart';
import '../services/stress_prediction_model.dart';

/// Dashboard card for MCDM analysis with method selectors
class MCDMDashboardCard extends StatefulWidget {
  final double temperature;
  final double humidity;
  final double noise;
  final double lighting;

  const MCDMDashboardCard({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.noise,
    required this.lighting,
  });

  @override
  State<MCDMDashboardCard> createState() => _MCDMDashboardCardState();
}

class _MCDMDashboardCardState extends State<MCDMDashboardCard> {
  WeightMethod _selectedWeightMethod = WeightMethod.compromise;
  ScoringMethod _selectedScoringMethod = ScoringMethod.mabac;
  MCDMResult? _currentResult;
  double _stressLevel = 0;

  @override
  void initState() {
    super.initState();
    _calculateMCDM();
  }

  void _calculateMCDM() {
    final reading = SensorReading(
      temperature: widget.temperature,
      humidity: widget.humidity,
      noise: widget.noise,
      lighting: widget.lighting,
    );

    // Create historical data for context (use current reading twice for now)
    final historicalData = [reading.toList()];

    final result = MCDMCalculator.analyzeSingleReading(
      reading,
      historicalData,
      _selectedWeightMethod,
      _selectedScoringMethod,
    );

    final stress = StressPredictionModel.predictStress(
      widget.temperature,
      widget.humidity,
      widget.noise,
      widget.lighting,
    );

    setState(() {
      _currentResult = result;
      _stressLevel = stress;
    });
  }

  String _getWeightFormula(WeightMethod method) {
    switch (method) {
      case WeightMethod.std:
        return 'wⱼ = σⱼ / Σσₖ\n(Standard Deviation)';
      case WeightMethod.entropy:
        return 'wⱼ = (1 - eⱼ) / Σ(1 - eₖ)\n(Shannon Entropy)';
      case WeightMethod.critic:
        return 'wⱼ = σⱼ × Σ|rⱼₖ| / Σ(...)\n(Correlation Impact)';
      case WeightMethod.merec:
        return 'wⱼ = (REⱼ - min) / Σ(...)\n(Removal Effect)';
      case WeightMethod.compromise:
        return 'wⱼ = (Σwⱼ from 4 methods) / 4\n(Balanced Average)';
    }
  }

  String _getScoringFormula(ScoringMethod method) {
    switch (method) {
      case ScoringMethod.mabac:
        return 'S = Σ(vᵢⱼ - BAⱼ)\n(Border Approximation)';
      case ScoringMethod.marcos:
        return 'S = K⁺ + K⁻\n(Reference Comparison)';
      case ScoringMethod.spotis:
        return 'S = 1 - (D - Dₘᵢₙ)/(Dₘₐₓ - Dₘᵢₙ)\n(Distance-based)';
      case ScoringMethod.cococomet:
        return 'S = λ×Sₚₒwₑᵣ + (1-λ)×Sₗᵢₙₑₐᵣ\n(Hybrid)';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentResult == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MCDM Analysis & Stress Prediction',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Weight Method Selector
            _buildMethodSelector(
              label: 'Weight Method:',
              value: _selectedWeightMethod.toString().split('.').last,
              onTap: () => _showWeightMethodDialog(),
            ),

            const SizedBox(height: 12),

            // Scoring Method Selector
            _buildMethodSelector(
              label: 'Scoring Method:',
              value: _selectedScoringMethod.toString().split('.').last,
              onTap: () => _showScoringMethodDialog(),
            ),

            const SizedBox(height: 16),

            // Formula Display
            _buildFormulaBox(
              'Weight Formula',
              _getWeightFormula(_selectedWeightMethod),
              Colors.blue.shade50,
            ),

            const SizedBox(height: 12),

            _buildFormulaBox(
              'Scoring Formula',
              _getScoringFormula(_selectedScoringMethod),
              Colors.green.shade50,
            ),

            const SizedBox(height: 16),

            // MCDM Scores
            _buildScoresDisplay(),

            const SizedBox(height: 16),

            // Stress Prediction
            _buildStressDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label ${value.replaceRange(0, 1, value[0].toUpperCase())}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaBox(String title, String formula, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formula,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MCDM Scores (0-1 scale):',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildScoreRow('MABAC', _currentResult!.mabacScore),
        _buildScoreRow('MARCOS', _currentResult!.marcosScore),
        _buildScoreRow('SPOTIS', _currentResult!.spotisScore),
        _buildScoreRow('COCOCOMET', _currentResult!.cococometScore),
        const Divider(height: 12),
        _buildScoreRow('Average', _currentResult!.averageScore, isAverage: true),
      ],
    );
  }

  Widget _buildScoreRow(String label, double score, {bool isAverage = false}) {
    final color = score >= 0.8
        ? Colors.green
        : score >= 0.6
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isAverage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 20,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(score * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressDisplay() {
    final interpretation = StressPredictionModel.getStressInterpretation(_stressLevel);
    final color = StressPredictionModel.getStressColor(_stressLevel);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stress Level Prediction',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _stressLevel / 100,
                  minHeight: 24,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(Color(color)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_stressLevel.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            interpretation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Color(color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Weight Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWeightMethodOption(WeightMethod.std, 'STD', 'Fast & simple'),
            _buildWeightMethodOption(WeightMethod.entropy, 'Entropy', 'Stable'),
            _buildWeightMethodOption(WeightMethod.critic, 'CRITIC', 'Detailed'),
            _buildWeightMethodOption(WeightMethod.merec, 'MEREC', 'Impact-based'),
            _buildWeightMethodOption(WeightMethod.compromise, 'Compromise', 'Balanced ⭐'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightMethodOption(WeightMethod method, String name, String desc) {
    return ListTile(
      title: Text(name),
      subtitle: Text(desc),
      trailing: _selectedWeightMethod == method
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        setState(() {
          _selectedWeightMethod = method;
          _calculateMCDM();
        });
        Navigator.pop(context);
      },
    );
  }

  void _showScoringMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Scoring Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildScoringMethodOption(ScoringMethod.mabac, 'MABAC', 'Boundary'),
            _buildScoringMethodOption(ScoringMethod.marcos, 'MARCOS', 'Reference'),
            _buildScoringMethodOption(ScoringMethod.spotis, 'SPOTIS', 'Distance'),
            _buildScoringMethodOption(ScoringMethod.cococomet, 'COCOCOMET', 'Hybrid'),
          ],
        ),
      ),
    );
  }

  Widget _buildScoringMethodOption(ScoringMethod method, String name, String desc) {
    return ListTile(
      title: Text(name),
      subtitle: Text(desc),
      trailing: _selectedScoringMethod == method
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        setState(() {
          _selectedScoringMethod = method;
          _calculateMCDM();
        });
        Navigator.pop(context);
      },
    );
  }
}
