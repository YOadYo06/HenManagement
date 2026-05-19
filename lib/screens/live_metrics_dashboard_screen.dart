import 'package:flutter/material.dart';
import 'package:env_reading/models/live_metric.dart';
import 'package:env_reading/services/metric_config_service.dart';
import 'package:env_reading/services/stress_prediction_model_v2.dart';
import 'package:env_reading/widgets/last_metric_widget.dart';
import 'package:env_reading/widgets/metric_editor_widget.dart';

/// Updated Dashboard Screen with Live Metrics
/// Integrates:
/// 1. Dataset selector
/// 2. Metric editor (choose dataset values or custom)
/// 3. Last metric display (calculated MCDM score)
class LiveMetricsDashboardScreen extends StatefulWidget {
  const LiveMetricsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<LiveMetricsDashboardScreen> createState() => _LiveMetricsDashboardScreenState();
}

class _LiveMetricsDashboardScreenState extends State<LiveMetricsDashboardScreen> {
  final MetricConfigService _configService = MetricConfigService();
  
  LiveMetricDataset? _currentDataset;
  LiveMetric? _lastMetric;
  double? _stressPrediction;
  String _selectedWeightMethod = 'Compromise';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      // Initialize model predictor
      await _configService.initModelPredictor();

      setState(() {
        _isLoading = true;
      });

      // Get default dataset
      final defaultDataset = _configService.getDefaultDataset();
      if (defaultDataset != null) {
        setState(() {
          _currentDataset = defaultDataset;
          _isLoading = false;
        });
      } else {
        // Config not loaded yet - you'll need to load from file
        setState(() {
          _isLoading = false;
        });
        _showConfigNotLoadedDialog();
      }
    } catch (e) {
      print('Error loading config: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showConfigNotLoadedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Not Loaded'),
        content: const Text(
          'The MCDM configuration file is not loaded. '
          'Please ensure mcdm_flutter_config.json is added to assets and initialized in main.dart',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _changeDataset() {
    final datasets = _configService.getAllDatasets();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Dataset'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: datasets.length,
            itemBuilder: (context, index) {
              final dataset = datasets[index];
              return ListTile(
                title: Text(dataset.name),
                subtitle: Text('${dataset.sensors.length} sensors'),
                trailing: dataset.id == _currentDataset?.id
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() {
                    _currentDataset = dataset;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _changeWeightMethod() {
    if (_currentDataset == null) return;

    final methods = _currentDataset!.getWeightMethods();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Weight Method'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return ListTile(
                title: Text(method),
                trailing: method == _selectedWeightMethod
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedWeightMethod = method;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  double? _calculateStressPrediction(LiveMetric metric) {
    double? getValue(String sensorId) {
      for (final value in metric.sensorValues) {
        if (value.sensor.id == sensorId) {
          return value.value;
        }
      }
      return null;
    }

    final temperature = getValue('temp');
    final humidity = getValue('humidity');
    final noise = getValue('noise');
    final lighting = getValue('light');

    if (temperature == null || humidity == null || noise == null || lighting == null) {
      return null;
    }

    return StressPredictionModelV2.predictStress(
      temperature,
      humidity,
      noise,
      lighting,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Metrics Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentDataset == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Metrics Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('No Dataset Loaded'),
              const SizedBox(height: 8),
              const Text('Please load mcdm_flutter_config.json'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadConfig,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Metrics Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dataset Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentDataset!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _currentDataset!.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text('${_currentDataset!.sensors.length} Sensors'),
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                                Chip(
                                  label: Text('Weights: $_selectedWeightMethod'),
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _changeDataset,
                          icon: const Icon(Icons.dataset),
                          label: const Text('Change Dataset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _changeWeightMethod,
                          icon: const Icon(Icons.tune),
                          label: const Text('Weight Method'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Last Metric Display
            LastMetricWidget(
              lastMetric: _lastMetric,
              isLoading: false,
            ),

            // Metric Editor
            MetricEditorWidget(
              dataset: _currentDataset!,
              weightMethod: _selectedWeightMethod,
              onMetricChanged: (metric) {
                setState(() {
                  _lastMetric = metric;
                  _stressPrediction = _calculateStressPrediction(metric);
                });
              },
            ),

            if (_stressPrediction != null) ...[
              Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prediction',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stress level: ${_stressPrediction!.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        StressPredictionModelV2.getStressInterpretation(_stressPrediction!),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_stressPrediction == null && _lastMetric != null)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Prediction is available only for datasets with temperature, humidity, noise, and lighting sensors.',
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Help Section
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Use',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      '1. Choose Dataset: Select from ${_configService.getAllDatasets().length} pre-configured datasets',
                    ),
                    _buildHelpItem(
                      '2. Pick Weight Method: Compare STD, Entropy, CRITIC, MEREC, or Compromise approaches',
                    ),
                    _buildHelpItem(
                      '3. Set Sensor Values: Use dataset (min/max/mean) or enter custom values',
                    ),
                    _buildHelpItem(
                      '4. View Score: Real-time MCDM comfort score updates as you edit',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
