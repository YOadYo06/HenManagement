# Quick Integration Guide (5-Minute Setup)

## What You Get

✅ 8 datasets with different sensor configurations  
✅ Manual value entry with sliders  
✅ Firebase real-time data support  
✅ All 5 weight + 4 scoring methods  
✅ Automatic cost/profit handling  

## Files Already Created

All these compile with **zero errors**:

```
lib/models/
  ├── sensor_config.dart                 ✅ Complete
  ├── dataset_config.dart                ✅ Complete
  └── sensor_readings.dart               ✅ Complete
  
lib/widgets/
  ├── dataset_selector.dart              ✅ Complete
  └── multi_sensor_input_widget.dart     ✅ Complete
  
lib/services/
  └── flexible_mcdm_calculator.dart      ✅ Complete
```

## Minimal Dashboard Integration

Copy this into your `dashboard_screen.dart`:

```dart
import 'package:env_reading/models/dataset_config.dart';
import 'package:env_reading/models/sensor_readings.dart';
import 'package:env_reading/widgets/dataset_selector.dart';
import 'package:env_reading/widgets/multi_sensor_input_widget.dart';
import 'package:env_reading/services/flexible_mcdm_calculator.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String currentDatasetId;
  late SensorReadings currentReadings;
  late WeightMethod selectedWeightMethod;
  late ScoringMethod selectedScoringMethod;

  @override
  void initState() {
    super.initState();
    currentDatasetId = 'iot_mental_health'; // Default dataset
    currentReadings = SensorReadings.empty();
    selectedWeightMethod = WeightMethod.compromise;
    selectedScoringMethod = ScoringMethod.mabac;
  }

  @override
  Widget build(BuildContext context) {
    final dataset = DatasetRepository.getDataset(currentDatasetId);
    if (dataset == null) return const SizedBox.shrink();

    return ListView(
      children: [
        // 1. DATASET SELECTOR (at top)
        DatasetSelector(
          currentDatasetId: currentDatasetId,
          onDatasetChanged: (newId) {
            setState(() {
              currentDatasetId = newId;
              currentReadings = SensorReadings.empty();
            });
          },
        ),

        // 2. SENSOR INPUT (with Firebase/Manual toggle)
        MultiSensorInputWidget(
          dataset: dataset,
          initialReadings: currentReadings,
          onReadingsChanged: (newReadings) {
            setState(() {
              currentReadings = newReadings;
            });
          },
          isFirebaseConnected: true,
        ),

        // 3. MCDM ANALYSIS (only if all sensors present)
        if (currentReadings.hasAllRequiredSensors(dataset.requiredSensorIds))
          _buildMCDMCard(dataset)
        else
          _buildWarning(dataset),

        // ... rest of your dashboard
      ],
    );
  }

  Widget _buildMCDMCard(DatasetConfig dataset) {
    final normalized =
        currentReadings.getNormalizedValues(dataset.sensors);

    final score = FlexibleMCDMCalculator.calculateComfortScore(
      normalizedValues: normalized,
      sensorConfigs: dataset.sensors,
      weightMethod: selectedWeightMethod,
      scoringMethod: selectedScoringMethod,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MCDM Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    '${(score * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor:
                      Color(FlexibleMCDMCalculator.getScoreColor(score)),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Method Selection
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Weight Method'),
                    value: selectedWeightMethod.toString().split('.').last,
                    items: ['std', 'entropy', 'critic', 'merec', 'compromise']
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedWeightMethod = WeightMethod.values
                            .firstWhere((e) => e.toString() == 'WeightMethod.$val');
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Scoring Method'),
                    value: selectedScoringMethod.toString().split('.').last,
                    items: ['mabac', 'marcos', 'spotis', 'cococomet']
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedScoringMethod = ScoringMethod.values
                            .firstWhere((e) => e.toString() == 'ScoringMethod.$val');
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Score Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(FlexibleMCDMCalculator.getScoreColor(score))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(FlexibleMCDMCalculator.getScoreColor(score)),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${(score * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(
                        FlexibleMCDMCalculator.getScoreColor(score),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FlexibleMCDMCalculator.getScoreInterpretation(score),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Formulas
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      FlexibleMCDMCalculator.getWeightFormula(
                        selectedWeightMethod,
                        normalized.length,
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      FlexibleMCDMCalculator.getScoringFormula(
                        selectedScoringMethod,
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning(DatasetConfig dataset) {
    final missing = currentReadings.getMissingSensors(dataset.requiredSensorIds);
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Missing: ${missing.join(", ")}',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## That's It!

The system handles:
- ✅ 8 datasets automatically
- ✅ Variable sensor counts (4, 5, or more)
- ✅ Manual sliders with constraints
- ✅ Firebase/Manual toggle
- ✅ All weight + scoring methods
- ✅ Cost/Profit criteria
- ✅ Automatic normalization

## What Each Component Does

### DatasetSelector Widget
- Shows at **TOP** of dashboard
- "Change" button = modal with all 8 datasets
- Tap dataset = switch immediately
- Resets sensor readings

### MultiSensorInputWidget
- Shows below dataset selector
- Firebase/Manual toggle at top
- **Manual mode**: Sliders for each sensor
  - Min/Max/Mean displayed
  - Color coded status
  - Real-time updates
- **Firebase mode**: Shows connection status

### MCDM Analysis Card
- Shows if all required sensors present
- Otherwise shows warning
- Weight method dropdown (5 options)
- Scoring method dropdown (4 options)
- Large comfort score display
- Formula display for transparency

## Testing

1. Run: `flutter pub get && flutter run`
2. Tap "Change" in dataset header → see all 8 datasets
3. Switch to "Smart Library" → see 5 sensors
4. Toggle manual mode → enter values with sliders
5. Toggle weight method → score updates
6. Toggle scoring method → score updates

Done! 🎉

---

## For Full Documentation

See: **MULTI_DATASET_INTEGRATION_GUIDE.md** for:
- Complete code examples
- Firebase integration
- Dataset details
- Troubleshooting
- Advanced customization
- Testing checklist
