# Multi-Dataset MCDM Integration Guide

## Overview

You now have a complete multi-dataset monitoring system that supports:
- ✅ **8 Different Monitoring Types** (datasets)
- ✅ **Variable Sensor Counts** (4-5+ sensors per dataset)
- ✅ **Manual & Firebase Input Modes** (switch freely)
- ✅ **Flexible MCDM Calculator** (works with any sensor configuration)
- ✅ **Dynamic Cost/Profit Criteria** (different sensor types)

---

## Architecture

### New Components

#### 1. **Models** (`lib/models/`)

**`sensor_config.dart`**
- `SensorConfig`: Defines individual sensor properties
  - `id`: Unique identifier (temp, humidity, co2, etc)
  - `displayName`: User-friendly name
  - `unit`: Measurement unit (°C, %, dB, lux, ppm)
  - `minValue`, `maxValue`, `meanValue`: Dataset statistics
  - `criteriaType`: Cost (↓ lower=better) or Profit (↑ higher=better)
  - `isAvailable`: Whether this sensor exists in the dataset
- Methods: `normalize()`, `denormalize()`, `getColor()`, `getStatus()`

**`dataset_config.dart`**
- `DatasetConfig`: Defines a complete dataset with all sensors
- `DatasetRepository`: Repository with 8 pre-configured datasets:
  1. 🏫 IoT University Mental Health (4 sensors)
  2. 💨 Indoor Air Quality (4 sensors + CO2)
  3. 🏢 Green Building (4 sensors)
  4. 📚 Smart Library (5 sensors: temp, humidity, CO2, lighting, noise)
  5. 👥 Building Occupancy (4 sensors + CO2)
  6. 🐔 Egg Production (3-4 sensors)
  7. 🌿 Herbal Plant Health (4 sensors + soil moisture)
  8. 👤 User Behavior (5 sensors + motion)

**`sensor_readings.dart`**
- `SensorReadings`: Holds current sensor values
- `InputMode`: Enum - `firebase` or `manual`
- Methods: `normalize()`, `getNormalizedValues()`, `getMissingSensors()`

#### 2. **Widgets** (`lib/widgets/`)

**`dataset_selector.dart`**
- `DatasetSelector`: Header widget showing current dataset
- Features:
  - Displays dataset name, description, sensor count
  - "Change" button opens modal with all 8 datasets
  - Bottom sheet shows sensor configs for each dataset
  - Smooth switching between datasets

**`multi_sensor_input_widget.dart`**
- `MultiSensorInputWidget`: Complete sensor input UI
- Features:
  - **Firebase/Manual toggle** at top
  - **Firebase mode**: Shows connection status per sensor
  - **Manual mode**: Sliders for each sensor with:
    - Min/Max/Mean/Current values displayed
    - Color-coded status (green/amber/red)
    - Real-time normalization
  - Handles missing sensors gracefully (null state)
  - Shows sensor ranges and statistics

#### 3. **Services** (`lib/services/`)

**`flexible_mcdm_calculator.dart`**
- `FlexibleMCDMCalculator`: MCDM with variable sensor count
- Key methods:
  - `calculateComfortScore()`: Main calculation with any sensors
  - `_calculateWeights()`: Supports all 5 weight methods
  - `_adjustForCriteriaType()`: Handles cost/profit automatically
  - `_calculateScore()`: All 4 scoring methods
  - `getWeightFormula()`, `getScoringFormula()`: Return formulas

---

## Integration Steps

### Step 1: Update Dashboard Screen

Add the new widgets to your dashboard:

```dart
// lib/screens/dashboard_screen.dart

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
    // Initialize with default dataset
    currentDatasetId = DatasetRepository.getDefaultDatasetId();
    currentReadings = SensorReadings.empty();
    selectedWeightMethod = WeightMethod.compromise;
    selectedScoringMethod = ScoringMethod.mabac;
  }

  void _onDatasetChanged(String newDatasetId) {
    setState(() {
      currentDatasetId = newDatasetId;
      // Reset readings when switching datasets
      currentReadings = SensorReadings.empty();
    });
  }

  void _onReadingsChanged(SensorReadings newReadings) {
    setState(() {
      currentReadings = newReadings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataset = DatasetRepository.getDataset(currentDatasetId);
    if (dataset == null) return const SizedBox.shrink();

    return ListView(
      children: [
        // 1. Dataset Selector at Top
        DatasetSelector(
          currentDatasetId: currentDatasetId,
          onDatasetChanged: _onDatasetChanged,
        ),

        // 2. Sensor Input Widget
        MultiSensorInputWidget(
          dataset: dataset,
          initialReadings: currentReadings,
          onReadingsChanged: _onReadingsChanged,
          isFirebaseConnected: true,
        ),

        // 3. MCDM Analysis (if all required sensors available)
        if (currentReadings.hasAllRequiredSensors(dataset.requiredSensorIds))
          _buildMCDMAnalysisCard(dataset)
        else
          _buildMissingSensorsWarning(dataset),

        // ... rest of your dashboard widgets
      ],
    );
  }

  Widget _buildMCDMAnalysisCard(DatasetConfig dataset) {
    // Get normalized values
    final normalizedValues =
        currentReadings.getNormalizedValues(dataset.sensors);

    // Calculate comfort score
    final comfortScore = FlexibleMCDMCalculator.calculateComfortScore(
      normalizedValues: normalizedValues,
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
            const Text(
              'MCDM Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Weight Method Selector
            _buildMethodSelector(
              'Weight Method',
              selectedWeightMethod.toString().split('.').last,
              (newMethod) {
                setState(() {
                  selectedWeightMethod = WeightMethod.values
                      .firstWhere((e) => e.toString() == 'WeightMethod.$newMethod');
                });
              },
            ),

            const SizedBox(height: 12),

            // Scoring Method Selector
            _buildMethodSelector(
              'Scoring Method',
              selectedScoringMethod.toString().split('.').last,
              (newMethod) {
                setState(() {
                  selectedScoringMethod = ScoringMethod.values
                      .firstWhere((e) => e.toString() == 'ScoringMethod.$newMethod');
                });
              },
            ),

            const SizedBox(height: 16),

            // Comfort Score Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(FlexibleMCDMCalculator.getScoreColor(comfortScore))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(FlexibleMCDMCalculator.getScoreColor(comfortScore)),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Comfort Score',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(comfortScore * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(
                        FlexibleMCDMCalculator.getScoreColor(comfortScore),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FlexibleMCDMCalculator.getScoreInterpretation(comfortScore),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Formula Display
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weights',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FlexibleMCDMCalculator.getWeightFormula(
                            selectedWeightMethod,
                            normalizedValues.length,
                          ),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scoring',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FlexibleMCDMCalculator.getScoringFormula(
                            selectedScoringMethod,
                          ),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
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

  Widget _buildMissingSensorsWarning(DatasetConfig dataset) {
    final missing = currentReadings.getMissingSensors(dataset.requiredSensorIds);
    final missingNames = missing
        .map((id) => dataset.getSensor(id)?.displayName ?? id)
        .join(', ');

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Missing Sensors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Please provide: $missingNames',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector(
    String label,
    String currentValue,
    Function(String) onChanged,
  ) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        DropdownButton<String>(
          value: currentValue,
          items: ['std', 'entropy', 'critic', 'merec', 'compromise']
              .map((method) => DropdownMenuItem(
                    value: method,
                    child: Text(method.toUpperCase()),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}
```

### Step 2: Connect Firebase Data

Update your data repository to populate readings from Firebase:

```dart
// Update in your data loading logic
void _loadFirebaseData() async {
  final firebaseData = await _getFromFirebase();
  
  // Create readings from Firebase
  final readings = SensorReadings.fromFirebase(
    temperature: firebaseData.temperature,
    humidity: firebaseData.humidity,
    noise: firebaseData.noise,
    lighting: firebaseData.lighting,
    co2: firebaseData.co2,
  );
  
  _onReadingsChanged(readings);
}
```

### Step 3: Switch Between Datasets

The `DatasetSelector` widget handles this automatically. Users can:
1. Tap "Change" button at top
2. See all 8 datasets in modal
3. Tap to switch

---

## Sensor Configurations

### Dataset 1: University Mental Health (4 sensors)
```
✓ Temperature (15-30°C, mean: 22.5) - Cost
✓ Humidity (20-80%, mean: 50%) - Cost  
✓ Noise Level (30-80 dB, mean: 55) - Cost
✓ Lighting (100-1000 lux, mean: 500) - Cost
```

### Dataset 2: Air Quality (4 sensors + optional)
```
✓ Temperature (15-35°C, mean: 24) - Cost
✓ Humidity (20-80%, mean: 50%) - Cost
✓ CO2 (300-2000 ppm, mean: 800) - Cost
✓ Lighting (100-1500 lux, mean: 750) - Profit
✗ Noise - Not available
```

### Dataset 3: Smart Library (5 sensors)
```
✓ Temperature (18-28°C, mean: 22) - Cost
✓ Humidity (30-70%, mean: 50%) - Cost
✓ CO2 (350-1500 ppm, mean: 800) - Cost
✓ Lighting (200-1000 lux, mean: 600) - Profit
✓ Noise (40-70 dB, mean: 55) - Cost
```

### Dataset 4: User Behavior - RAED (5 sensors)
```
✓ Temperature (15-30°C, mean: 22) - Cost
✓ Humidity (20-80%, mean: 50%) - Cost
✓ Noise (30-80 dB, mean: 55) - Cost
✓ Lighting (100-1000 lux, mean: 500) - Profit
✓ Motion Level (0-100, mean: 50) - Profit
```

... and 4 more! See `DatasetRepository.getAllDatasets()`

---

## Cost vs Profit Criteria

**Cost Criteria (↓ lower is better):**
- Temperature, Humidity, Noise, CO2
- These are minimized for comfort

**Profit Criteria (↑ higher is better):**
- Lighting, Soil Moisture, Motion Level
- These are maximized for comfort

**Flexible MCDM automatically adjusts** for each sensor type!

---

## Weight & Scoring Methods

### Weight Methods (All 5 Supported)
1. **STD**: Standard deviation based
2. **Entropy**: Shannon entropy based
3. **CRITIC**: Correlation & contrast based
4. **MEREC**: Removal effect based
5. **Compromise**: Average of all 4

### Scoring Methods (All 4 Supported)
1. **MABAC**: Boundary approximation
2. **MARCOS**: Weighted sum
3. **SPOTIS**: Distance-based
4. **COCOCOMET**: Hybrid approach

All methods work with **any number of sensors** (4, 5, or more)!

---

## Usage Example

```dart
// Select dataset
final dataset = DatasetRepository.getDataset('smart_library');

// Create sensor readings (manual)
final readings = SensorReadings.empty();
readings.setValue('temperature', 22.5);
readings.setValue('humidity', 55.0);
readings.setValue('co2', 750.0);
readings.setValue('lighting', 600.0);
readings.setValue('noise', 50.0);

// Normalize
final normalized = readings.getNormalizedValues(dataset!.sensors);

// Calculate score
final score = FlexibleMCDMCalculator.calculateComfortScore(
  normalizedValues: normalized,
  sensorConfigs: dataset.sensors,
  weightMethod: WeightMethod.compromise,
  scoringMethod: ScoringMethod.mabac,
);

print('Score: ${score * 100}% - ${FlexibleMCDMCalculator.getScoreInterpretation(score)}');
```

---

## Testing Checklist

- [ ] Dataset selector appears at dashboard top
- [ ] Can switch between all 8 datasets smoothly
- [ ] Manual input sliders work with min/max constraints
- [ ] Firebase toggle switches between modes
- [ ] Sensor values update MCDM score in real-time
- [ ] Weight methods dropdown works (5 options)
- [ ] Scoring methods dropdown works (4 options)
- [ ] Formulas display correctly for selected methods
- [ ] Missing sensors show warning
- [ ] Color coding matches score interpretation
- [ ] Works with 4, 5, and other sensor counts

---

## File Structure

```
lib/
├── models/
│   ├── sensor_config.dart              [NEW]
│   ├── dataset_config.dart             [NEW]
│   └── sensor_readings.dart            [NEW]
├── widgets/
│   ├── dataset_selector.dart           [NEW]
│   ├── multi_sensor_input_widget.dart  [NEW]
│   └── enhanced_mcdm_card.dart         [EXISTING - can keep or replace]
├── services/
│   ├── flexible_mcdm_calculator.dart   [NEW]
│   ├── mcdm_calculator_simple.dart     [OLD - keep for reference]
│   └── ...
└── screens/
    └── dashboard_screen.dart           [UPDATE with new widgets]
```

---

## Next Steps

1. **Integrate into Dashboard** - Copy the code from Step 1 above
2. **Test Each Dataset** - Switch between datasets and verify
3. **Verify Sensors** - Check that each dataset's sensors work
4. **Firebase Connection** - Connect real sensor data from Firebase
5. **Fine-tune Colors** - Adjust color thresholds to your preference
6. **Add Persistence** - Save user's selected dataset/method preferences

---

## Advanced: Custom Datasets

To add a 9th dataset:

```dart
// In dataset_config.dart, add to DatasetRepository:
static DatasetConfig _buildCustomDataset() {
  return DatasetConfig(
    id: 'custom_monitoring',
    name: '📊 Custom Monitoring',
    description: 'Your custom sensor setup',
    csvFileName: 'your_data.csv',
    notebookName: 'Your_Analysis.ipynb',
    requiredSensorIds: ['temperature', 'humidity', 'custom_sensor'],
    sensors: {
      'temperature': SensorConfig(...),
      'humidity': SensorConfig(...),
      'custom_sensor': SensorConfig(...),
    },
  );
}

// Then add to _datasets map:
'custom': _buildCustomDataset(),
```

Done! Your app now supports unlimited sensor configurations! 🎉
