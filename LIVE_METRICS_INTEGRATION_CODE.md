# Live Metrics System - Integration Code

Copy and paste these exact codes to integrate the Live Metrics system.

## Step 1: Update pubspec.yaml

Find the `flutter:` section and add `mcdm_flutter_config.json` to assets:

```yaml
flutter:
  uses-material-design: true
  assets:
    - mcdm_flutter_config.json
    - assets/
```

## Step 2: Update main.dart

Replace your entire main.dart with this:

```dart
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
    print('📊 Datasets available: ${MetricConfigService().getAllDatasets().length}');
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
```

## Step 3: Run Commands

```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Alternative: Keep Existing main.dart

If you want to keep your existing main.dart and add Live Metrics as a secondary screen:

```dart
// In your existing main.dart, add these imports:
import 'package:flutter/services.dart';
import 'package:env_reading/services/metric_config_service.dart';
import 'package:env_reading/screens/live_metrics_dashboard_screen.dart';

// In your main() function, add config loading:
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... your existing initialization code ...

  // Add this block:
  try {
    final configJson = await rootBundle.loadString('mcdm_flutter_config.json');
    MetricConfigService().loadFromJson(configJson);
  } catch (e) {
    print('Failed to load MCDM config: $e');
  }

  // ... rest of your code ...
  runApp(const MyApp());
}

// In your app navigation, add a route to LiveMetricsDashboardScreen:
// Example using MaterialApp routes:
MaterialApp(
  routes: {
    '/': (context) => YourHomeScreen(),
    '/live-metrics': (context) => const LiveMetricsDashboardScreen(),
  },
)

// Then navigate to it from your home screen:
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/live-metrics'),
  child: const Text('Open Live Metrics'),
)
```

## Step 4: Verify Installation

After running, check that:

1. ✅ App starts without errors
2. ✅ Dashboard loads with dataset name
3. ✅ "Last Metric" shows "No Metric Calculated Yet"
4. ✅ "Edit Metrics" shows sensors with sliders
5. ✅ Changing a sensor value updates the score
6. ✅ Score color matches interpretation

## Troubleshooting

### Error: "mcdm_flutter_config.json" not found

**Problem**: File not in assets
**Solution**: 
```yaml
# Make sure pubspec.yaml has:
flutter:
  assets:
    - mcdm_flutter_config.json
```

### Error: No datasets loaded

**Problem**: Config not loading in main()
**Solution**:
```dart
// Verify this is in main() BEFORE runApp():
final configJson = await rootBundle.loadString('mcdm_flutter_config.json');
MetricConfigService().loadFromJson(configJson);
```

### Error: "The application exited unexpectedly"

**Problem**: Compilation issue
**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

### App starts but "No Dataset Loaded"

**Problem**: Config loaded but datasets are null
**Solution**: Check that JSON file is valid JSON (not corrupted)
```bash
# Verify JSON is valid:
cat mcdm_flutter_config.json | python -m json.tool
```

## Verification Checklist

Run this Dart code in your app to verify setup:

```dart
import 'package:env_reading/services/metric_config_service.dart';
import 'package:env_reading/models/live_metric.dart';
import 'package:env_reading/services/precalculated_mcdm_calculator.dart';

void verifySetup() {
  final service = MetricConfigService();
  
  // Check if loaded
  print('✅ Config loaded: ${service.isLoaded}');
  
  // Check datasets
  final datasets = service.getAllDatasets();
  print('✅ Datasets: ${datasets.length}');
  
  // Check default dataset
  final defaultDataset = service.getDefaultDataset();
  if (defaultDataset != null) {
    print('✅ Default dataset: ${defaultDataset.name}');
    print('✅ Sensors: ${defaultDataset.sensors.length}');
    print('✅ Weight methods: ${defaultDataset.getWeightMethods()}');
  }
  
  // Test score calculation
  if (defaultDataset != null && defaultDataset.sensors.isNotEmpty) {
    final testValues = defaultDataset.sensors.map((s) {
      return LiveMetricValue(
        sensor: s,
        value: s.meanValue,
        isFromDataset: true,
        sourceType: 'mean',
      );
    }).toList();
    
    final score = PreCalculatedMCDMCalculator.calculateScore(
      sensorValues: testValues,
      dataset: defaultDataset,
      weightMethod: 'Compromise',
    );
    
    print('✅ Test score: ${(score * 100).toStringAsFixed(1)}%');
    print('✅ Interpretation: ${PreCalculatedMCDMCalculator.getInterpretation(score)}');
  }
}

// Call this in main() or initState():
verifySetup();
```

## Expected Output

When app loads, you should see:

```
✅ MCDM Config loaded successfully
📊 Datasets available: 8
✅ Config loaded: true
✅ Datasets: 8
✅ Default dataset: IoT University Mental Health
✅ Sensors: 4
✅ Weight methods: [STD, Entropy, CRITIC, MEREC, Compromise]
✅ Test score: 75.3%
✅ Interpretation: Good
```

## Next Steps After Integration

1. **Test Different Datasets**
   - Click "Change Dataset" in app header
   - Try all 8 datasets
   - Notice different sensors and ranges

2. **Test Weight Methods**
   - Click "Weight Method"
   - Try all 5 methods
   - See how scores change
   - Recommend Compromise for consistency

3. **Test Sensor Editing**
   - Toggle "Use Dataset" to see min/max/mean
   - Toggle "Custom" to enter values
   - Watch score update in real-time

4. **Read Documentation**
   - LIVE_METRICS_GUIDE.md - Complete reference
   - LIVE_METRICS_ARCHITECTURE.md - Technical details

5. **Advanced Integration** (Optional)
   - Extract ML models from Jupyter
   - Add Firebase real-time data
   - Create historical tracking
   - Build custom dashboards

## Quick Test: Copy-Paste Scenario

After integration, try this user flow:

1. Open app → See Live Metrics Dashboard
2. Click "Change Dataset" → Select "Air Quality Analysis"
3. Click "Weight Method" → Try "Entropy"
4. In "Edit Metrics":
   - Temperature: Toggle "Custom", enter 28.5
   - Humidity: Leave as "Dataset", select "Max"
   - CO2: Toggle "Custom", enter 450
   - NO2: Leave as "Dataset", select "Mean"
   - PM2.5: Toggle "Custom", enter 35
5. See "Last Metric" update with score

## File Locations for Reference

```
Your Project Root
├── pubspec.yaml (UPDATE: add assets)
├── lib/main.dart (UPDATE: add config loading)
├── mcdm_flutter_config.json (EXISTS: root directory)
│
├── lib/models/
│   └── live_metric.dart (NEW)
├── lib/services/
│   ├── precalculated_mcdm_calculator.dart (NEW)
│   └── metric_config_service.dart (NEW)
├── lib/widgets/
│   ├── last_metric_widget.dart (NEW)
│   └── metric_editor_widget.dart (NEW)
└── lib/screens/
    └── live_metrics_dashboard_screen.dart (NEW)
```

---

**You're Ready!** Run `flutter run` and enjoy the Live Metrics system! 🎉
