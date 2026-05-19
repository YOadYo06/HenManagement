# Live Metrics System - Final Verification Checklist

## Pre-Integration Checklist

Before you integrate, verify these files exist:

### Core Files (6 New Dart Files)

- [ ] `lib/models/live_metric.dart` (220 lines)
  - [ ] Compiles without errors
  - [ ] Contains LiveMetricSensor class
  - [ ] Contains LiveMetricDataset class
  - [ ] Contains LiveMetricValue class
  - [ ] Contains LiveMetric class
  - [ ] Contains LiveMetricRepository class

- [ ] `lib/services/precalculated_mcdm_calculator.dart` (70 lines)
  - [ ] Compiles without errors
  - [ ] Contains calculateScore() method
  - [ ] Contains getInterpretation() method
  - [ ] Contains getColor() method

- [ ] `lib/services/metric_config_service.dart` (40 lines)
  - [ ] Compiles without errors
  - [ ] Singleton pattern implemented
  - [ ] loadFromJson() method exists
  - [ ] getAllDatasets() method exists

- [ ] `lib/widgets/last_metric_widget.dart` (200 lines)
  - [ ] Compiles without errors
  - [ ] Displays score card
  - [ ] Shows interpretation and color
  - [ ] Displays sensor breakdown

- [ ] `lib/widgets/metric_editor_widget.dart` (400 lines)
  - [ ] Compiles without errors
  - [ ] _SensorEditorCard widget exists
  - [ ] Toggle buttons work
  - [ ] Real-time calculation works

- [ ] `lib/screens/live_metrics_dashboard_screen.dart` (300 lines)
  - [ ] Compiles without errors
  - [ ] Contains all widgets integrated
  - [ ] Dataset selector works
  - [ ] Weight method selector works

### Configuration Files

- [ ] `mcdm_flutter_config.json` (20 KB)
  - [ ] Exists in project root
  - [ ] Valid JSON format
  - [ ] Contains 8 datasets
  - [ ] Each dataset has sensors
  - [ ] Each dataset has 5 weight methods

### Documentation Files

- [ ] `LIVE_METRICS_QUICK_START.md`
- [ ] `LIVE_METRICS_GUIDE.md`
- [ ] `LIVE_METRICS_ARCHITECTURE.md`
- [ ] `LIVE_METRICS_INTEGRATION_CODE.md`
- [ ] `DELIVERY_SUMMARY.md`
- [ ] `UI_LAYOUT_REFERENCE.md`
- [ ] `INTEGRATION_GUIDE.dart`

## Integration Checklist

### Step 1: Update pubspec.yaml

- [ ] Open `pubspec.yaml`
- [ ] Find `flutter:` section
- [ ] Find `uses-material-design: true`
- [ ] Add `assets:` section with:
  ```yaml
  assets:
    - mcdm_flutter_config.json
  ```
- [ ] Save file
- [ ] Verify file is valid YAML (no syntax errors)

### Step 2: Update main.dart

- [ ] Open `lib/main.dart`
- [ ] Add import:
  ```dart
  import 'package:flutter/services.dart';
  import 'package:env_reading/services/metric_config_service.dart';
  import 'package:env_reading/screens/live_metrics_dashboard_screen.dart';
  ```
- [ ] Make main() async:
  ```dart
  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    // ... config loading ...
    runApp(const MyApp());
  }
  ```
- [ ] Add config loading code
- [ ] Update MyApp to use LiveMetricsDashboardScreen()
- [ ] Save file
- [ ] Verify file has no syntax errors

### Step 3: Build & Run

- [ ] Open terminal in project root
- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter run`
- [ ] Check for errors
- [ ] Wait for app to fully load (30-60 seconds)

## Runtime Verification

### App Load Success

- [ ] App starts without crashes
- [ ] Console shows: `✅ MCDM Config loaded successfully`
- [ ] Console shows: `📊 Datasets available: 8`
- [ ] Dashboard screen appears with blue header
- [ ] No "No Dataset Loaded" error

### Header Section Works

- [ ] [ ] See dataset name: "IoT University Mental Health"
- [ ] See dataset description
- [ ] See "4 Sensors" chip
- [ ] See "Weights: Compromise" chip
- [ ] See "[CHANGE DATASET]" button is clickable
- [ ] See "[WEIGHT METHOD]" button is clickable

### Change Dataset Button

- [ ] Click "[CHANGE DATASET]"
- [ ] Modal opens showing 8 datasets
- [ ] Each shows sensor count
- [ ] Current dataset has checkmark
- [ ] Click different dataset
- [ ] Modal closes
- [ ] Header updates with new dataset
- [ ] New sensor count shows

### Change Weight Method Button

- [ ] Click "[WEIGHT METHOD]"
- [ ] Modal opens showing 5 methods:
  - [ ] STD
  - [ ] Entropy
  - [ ] CRITIC
  - [ ] MEREC
  - [ ] Compromise (checked by default)
- [ ] Click different method
- [ ] Modal closes
- [ ] Header updates with new method

### Edit Metrics Section

- [ ] See "Edit Metrics" card
- [ ] See 4 sensor cards (for Mental Health dataset)
- [ ] Each sensor shows:
  - [ ] Display name (Temperature, Humidity, etc.)
  - [ ] Unit (°C, %, dB, Lux)
  - [ ] Weight percentage
  - [ ] Toggle buttons: "Use Dataset" / "Custom"

### Dataset Mode (Toggle)

- [ ] See each sensor default to "Use Dataset" ✓
- [ ] Under "Use Dataset" see:
  - [ ] "Choose Value:" label
  - [ ] Three buttons: Min, Mean, Max
  - [ ] Mean button selected by default
  - [ ] "Selected: Mean: 24.21 °C" text
- [ ] Click "Min" button
- [ ] Updates to show min value
- [ ] Click "Max" button
- [ ] Updates to show max value

### Custom Mode (Toggle)

- [ ] Click "[Custom]" button on first sensor
- [ ] "Use Dataset" becomes unselected
- [ ] "Custom" becomes selected (highlighted)
- [ ] Shows text input field
- [ ] Input shows current value (e.g., "24.21")
- [ ] Can type in field
- [ ] Only accepts numbers

### Real-Time Calculation

- [ ] Change first sensor to custom value
- [ ] Score should update instantly (within 1-2ms)
- [ ] "Last Metric" card updates with new score
- [ ] Color changes if score changes significantly
- [ ] Interpretation text updates

### Last Metric Display

- [ ] See "Last Metric" card
- [ ] Shows large score (e.g., "75.3%")
- [ ] Score has colored chip in top right
- [ ] Color matches interpretation:
  - [ ] Red for 0-20% (Critical)
  - [ ] Orange for 20-40% (Poor)
  - [ ] Amber for 40-60% (Fair)
  - [ ] Light Green for 60-80% (Good)
  - [ ] Green for 80-100% (Excellent)
- [ ] Shows dataset name
- [ ] Shows "Weights: Compromise"
- [ ] Shows main score in large box
- [ ] Interpretation text matches score level

### Sensor Breakdown

- [ ] See "Sensor Values" section
- [ ] Each sensor shows mini progress bar
- [ ] Bar color matches sensor status
- [ ] Shows sensor name, value, unit
- [ ] 4 bars for 4 sensors

### Formula Section

- [ ] See blue "Weight Formula" section
- [ ] Shows formula explanation
- [ ] Text matches selected weight method:
  - [ ] STD: "Weight = σ(sensor) / Σσ"
  - [ ] Entropy: "Weight = (1 - H) / Σ(1 - H)"
  - [ ] CRITIC: "Weight = C·C / ΣC·C"
  - [ ] MEREC: "Weight = (1 - v) / Σ(1 - v)"
  - [ ] Compromise: "Weight = (STD+Entropy+CRITIC+MEREC) / 4"

### Timestamp

- [ ] See "Calculated: YYYY-MM-DD HH:MM:SS" at bottom
- [ ] Time is recent (matches when score was calculated)

### Help Section

- [ ] See "How to Use" section
- [ ] See 4 bulleted items
- [ ] Each has checkmark icon
- [ ] Text explains each step

## Feature Testing

### Test 1: Change Dataset and Sensors Update

1. Open app (on IoT Mental Health with 4 sensors)
2. Click "[CHANGE DATASET]"
3. Select "Air Quality Analysis"
4. Verify:
   - [ ] Header updates to "Air Quality Analysis"
   - [ ] Shows "5 Sensors" (instead of 4)
   - [ ] Edit Metrics section updates
   - [ ] Shows 5 sensor cards instead of 4
   - [ ] Sensor names change (CO2, NO2, PM2.5 visible)
   - [ ] Last Metric shows "No Metric Calculated Yet"

### Test 2: Compare Weight Methods

1. Set Temperature to custom value: 28.5
2. Note score and color (e.g., 72%, Good, Light Green)
3. Click "[WEIGHT METHOD]"
4. Select "STD"
5. Verify:
   - [ ] Score updates (may change significantly)
   - [ ] Formula text changes
   - [ ] Color updates if score crossed threshold
   - [ ] Header shows "Weights: STD"
6. Try other methods:
   - [ ] Entropy (should show different score)
   - [ ] CRITIC (may emphasize different sensors)
   - [ ] MEREC
   - [ ] Compromise (compare with all)

### Test 3: Dataset Value Selection

1. Click on a sensor's "[Use Dataset]" button (ensure selected)
2. Verify three option buttons appear: Min, Mean, Max
3. Click "Min"
4. Verify:
   - [ ] Button highlights
   - [ ] "Selected:" text updates
   - [ ] Last Metric score changes
5. Click "Max"
6. Verify:
   - [ ] Button highlights
   - [ ] Score changes again
   - [ ] Usually larger change than Min→Mean
7. Click "Mean"
8. Verify score returns to original

### Test 4: Custom Value Input

1. Click "[Custom]" on first sensor
2. See text input with current value
3. Clear input and type: 30.0
4. Verify:
   - [ ] Input accepts numeric input
   - [ ] Score updates in real-time
   - [ ] Last Metric updates instantly
5. Type: 15.24 (minimum value)
6. Verify:
   - [ ] Score changes
   - [ ] Still valid (no errors)
7. Type: 33.58 (maximum value)
8. Verify:
   - [ ] Score changes again
   - [ ] Valid range works
9. Try typing: 50.0 (out of range)
10. Verify:
    - [ ] Value is clamped to max (33.58)
    - [ ] Score reflects clamped value

### Test 5: Mixed Mode

1. Set Temperature: Custom 28.5
2. Set Humidity: Dataset, Mean
3. Set Noise: Custom 60.0
4. Set Lighting: Dataset, Max
5. Verify:
   - [ ] Score calculates with mixed values
   - [ ] Each sensor shows correct source
   - [ ] All 4 values in "Sensor Values" section
   - [ ] No errors

### Test 6: Rapid Changes

1. Click Custom on Temperature
2. Rapidly type: 25, 26, 27, 28, 29, 30
3. Verify:
   - [ ] No lag
   - [ ] Score updates smoothly
   - [ ] No crashes or errors
   - [ ] UI remains responsive

### Test 7: Switch Datasets and Methods

1. Start with IoT Mental Health, Compromise
2. Change to Green Building
3. Change to STD weights
4. Change to Air Quality
5. Change to Entropy weights
6. Change to Occupancy
7. Change to Compromise
8. Verify:
   - [ ] No crashes
   - [ ] All transitions smooth
   - [ ] Data loads correctly each time
   - [ ] Sensors update per dataset

## Error Handling Tests

### Test: JSON Loading Failure

1. Rename mcdm_flutter_config.json temporarily
2. Run app
3. Verify:
   - [ ] App doesn't crash
   - [ ] Shows "No Dataset Loaded" error
   - [ ] Error message is helpful
4. Rename file back
5. Restart app
6. Verify:
   - [ ] Works normally again

### Test: Corrupted JSON

1. Open mcdm_flutter_config.json
2. Remove closing bracket (corrupt it)
3. Run app
4. Verify:
   - [ ] App starts (doesn't crash)
   - [ ] Shows error in console or UI
5. Fix JSON
6. Restart app
7. Verify:
   - [ ] Works normally again

## Performance Tests

### Test: Score Calculation Speed

- [ ] Change sensor value and measure time to Last Metric update
- [ ] Should be <5ms
- [ ] Imperceptible to user
- [ ] No noticeable lag

### Test: UI Responsiveness

- [ ] Rapidly tap buttons
- [ ] App remains responsive
- [ ] No frame drops
- [ ] No ANR (Application Not Responding) errors

### Test: Memory Usage

- [ ] Open DevTools Memory profiler
- [ ] Switch between datasets multiple times
- [ ] Memory should remain stable
- [ ] No memory leaks
- [ ] Should not exceed 50 MB

## Compilation Check

Before deployment:

- [ ] `flutter analyze` returns no issues
- [ ] `flutter build apk` succeeds (if building APK)
- [ ] No deprecation warnings
- [ ] All imports are used
- [ ] No null safety issues

## Final Verification

- [ ] All 6 Dart files present
- [ ] All 5 documentation files present
- [ ] mcdm_flutter_config.json present
- [ ] pubspec.yaml updated correctly
- [ ] main.dart updated correctly
- [ ] App compiles without errors
- [ ] App runs without crashes
- [ ] All features work as described
- [ ] UI displays correctly
- [ ] Responsiveness is smooth
- [ ] Colors are appropriate
- [ ] Documentation is clear

## Sign-Off

When all items are checked, you can sign off:

```
Project: Live Metrics System
Status: ✅ READY FOR PRODUCTION
Date: ________________
Verified By: ________________

All features tested: ✅
All files present: ✅
Documentation complete: ✅
No errors: ✅
Performance verified: ✅
```

## Troubleshooting Quick Links

If you encounter issues during verification:

- **Config not loading**: See LIVE_METRICS_INTEGRATION_CODE.md - Troubleshooting section
- **Compilation errors**: Check all 6 Dart files are in correct directories
- **UI issues**: Check pubspec.yaml has assets section
- **Score not calculating**: Verify sensors have values in all 4 fields
- **Color not displaying**: Check device supports 32-bit color

---

**You're ready! 🎉 Use this checklist to verify your integration is complete and correct.**
