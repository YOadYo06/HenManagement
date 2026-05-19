/// Example of how to integrate Live Metrics system in main.dart
///
/// INTEGRATION STEPS:
/// 
/// 1. Add mcdm_flutter_config.json to pubspec.yaml assets:
/// ```yaml
/// flutter:
///   assets:
///     - mcdm_flutter_config.json
///     - assets/
/// ```
///
/// 2. Load in main() before runApp():
/// ```dart
/// import 'package:flutter/services.dart';
/// import 'package:env_reading/services/metric_config_service.dart';
/// 
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Load MCDM configuration
///   final configJson = await rootBundle.loadString('mcdm_flutter_config.json');
///   MetricConfigService().loadFromJson(configJson);
///   
///   runApp(const MyApp());
/// }
/// ```
///
/// 3. Use LiveMetricsDashboardScreen in your navigation:
/// ```dart
/// import 'package:env_reading/screens/live_metrics_dashboard_screen.dart';
/// 
/// // In your app router or navigation:
/// LiveMetricsDashboardScreen()
/// ```
///
/// 4. To use individual components:
/// 
/// a) Last Metric Widget (shows calculated score):
/// ```dart
/// import 'package:env_reading/widgets/last_metric_widget.dart';
/// import 'package:env_reading/models/live_metric.dart';
/// 
/// Widget build(BuildContext context) {
///   return LastMetricWidget(
///     lastMetric: myMetric,
///     isLoading: false,
///   );
/// }
/// ```
///
/// b) Metric Editor Widget (sensor input):
/// ```dart
/// import 'package:env_reading/widgets/metric_editor_widget.dart';
/// 
/// MetricEditorWidget(
///   dataset: selectedDataset,
///   weightMethod: 'Compromise',
///   onMetricChanged: (metric) {
///     // Update UI with new metric
///     setState(() {
///       lastMetric = metric;
///     });
///   },
/// )
/// ```
///
/// c) Programmatic calculation:
/// ```dart
/// import 'package:env_reading/services/precalculated_mcdm_calculator.dart';
/// import 'package:env_reading/models/live_metric.dart';
/// 
/// final score = PreCalculatedMCDMCalculator.calculateScore(
///   sensorValues: [
///     LiveMetricValue(sensor: temp, value: 25.5),
///     LiveMetricValue(sensor: humidity, value: 60.0),
///   ],
///   dataset: dataset,
///   weightMethod: 'Compromise',
/// );
/// 
/// final interpretation = PreCalculatedMCDMCalculator.getInterpretation(score);
/// // Returns: 'Critical', 'Poor', 'Fair', 'Good', 'Excellent'
/// 
/// final color = PreCalculatedMCDMCalculator.getColor(score);
/// // Returns: 0xAARRGGBB color
/// ```

// COMPLETE EXAMPLE - Copy this to your main.dart

/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:env_reading/services/metric_config_service.dart';
import 'package:env_reading/screens/live_metrics_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load MCDM configuration from assets
  try {
    final configJson = await rootBundle.loadString('mcdm_flutter_config.json');
    MetricConfigService().loadFromJson(configJson);
    print('✅ MCDM Config loaded successfully');
  } catch (e) {
    print('❌ Failed to load MCDM config: $e');
  }
  
  // Initialize Firebase if needed
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Env Reading - Live Metrics',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LiveMetricsDashboardScreen(),
    );
  }
}
*/

// CONFIGURATION FILE STRUCTURE (mcdm_flutter_config.json)
/*
{
  "version": "1.0",
  "datasets": [
    {
      "id": "iot_mental_health",
      "name": "IoT University Mental Health",
      "description": "Monitoring mental health through environmental sensors",
      "domain": "Mental Health",
      "predictionType": "REGRESSION",
      "dataPoints": 1000,
      "sensors": [
        {
          "id": "temp",
          "name": "temperature_celsius",
          "displayName": "Temperature (°C)",
          "unit": "°C",
          "type": "COST",
          "range": {"min": 15.24, "max": 33.58},
          "mean": 24.21,
          "weight": 0.2683
        },
        ...more sensors...
      ],
      "predictions": ["sleep_hours", "stress_level"],
      "models": ["LinearRegression", "RandomForest"],
      "weights": {
        "STD": {...},
        "Entropy": {...},
        "CRITIC": {...},
        "MEREC": {...},
        "Compromise": {...}
      }
    },
    ...more datasets...
  ]
}
*/

// USEFUL QUERIES

// Get all datasets:
// List<LiveMetricDataset> datasets = MetricConfigService().getAllDatasets();

// Get specific dataset:
// LiveMetricDataset? dataset = MetricConfigService().getDataset('iot_mental_health');

// Get weight methods for dataset:
// List<String> methods = dataset.getWeightMethods();
// // Returns: ['STD', 'Entropy', 'CRITIC', 'MEREC', 'Compromise']

// Get weights for specific method:
// Map<String, double> weights = dataset.getWeights('Compromise');
// // Returns: {'temperature_celsius': 0.2683, 'humidity_percent': 0.2769, ...}

// Calculate score:
// double score = PreCalculatedMCDMCalculator.calculateScore(
//   sensorValues: values,
//   dataset: dataset,
//   weightMethod: 'Compromise',
// );

// Format score:
// String interp = PreCalculatedMCDMCalculator.getInterpretation(score);
// int color = PreCalculatedMCDMCalculator.getColor(score);
// String formula = PreCalculatedMCDMCalculator.getFormulaExplanation('Compromise');
