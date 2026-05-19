# Firebase Configuration Guide for MCDM Analysis

## Overview
This guide explains how to configure Firebase Realtime Database for the MCDM analysis system, including storing MCDM results and stress predictions.

## Firebase Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `env_reading` (or your preferred name)
4. Choose your region
5. Enable Google Analytics (optional)
6. Click "Create project"

### 2. Enable Realtime Database

1. In Firebase Console, go to "Realtime Database"
2. Click "Create Database"
3. Choose location (closest to your region)
4. Select "Start in test mode" (for development)
5. Click "Enable"

### 3. Configure Database Rules

Replace the default rules with these security rules for development:

```json
{
  "rules": {
    "study_desk_monitor": {
      ".read": true,
      ".write": true,
      "readings": {
        ".indexOn": ["timestamp"],
        "$uid": {
          ".validate": "newData.hasChildren(['timestamp', 'light', 'noise', 'temperature', 'humidity', 'comfort_score'])"
        }
      },
      "mcdm_analysis": {
        ".indexOn": ["timestamp", "weight_method"],
        "$uid": {
          ".validate": "newData.hasChildren(['timestamp', 'temperature', 'humidity', 'noise', 'lighting'])"
        }
      },
      "alerts": {
        ".indexOn": ["timestamp"],
        "$uid": {}
      },
      "settings": {
        "thresholds": {}
      }
    }
  }
}
```

### 4. Get Firebase Configuration

1. In Firebase Console, go to "Project Settings" (gear icon)
2. Go to "Your apps" section
3. For each platform (iOS, Android, Web), download/get credentials:

**For Android:**
- Download `google-services.json`
- Place it in `android/app/`

**For iOS:**
- Download `GoogleService-Info.plist`
- Add to Xcode project

**For Web:**
- Copy the Firebase config object

### 5. Firebase Flutter Setup

Already configured in `pubspec.yaml` and `firebase_options.dart`, but verify:

```yaml
dependencies:
  firebase_core: ^3.2.0
  firebase_database: ^11.1.0
```

Run:
```bash
flutter pub get
```

## Database Structure

### Root Path: `study_desk_monitor`

```
study_desk_monitor/
├── readings/
│   ├── reading_id_1/
│   │   ├── timestamp: "2024-05-01T08:00:00Z"
│   │   ├── temperature: 22.5
│   │   ├── humidity: 55.0
│   │   ├── noise: 45.0
│   │   ├── lighting: 400.0
│   │   └── comfort_score: 75
│   └── reading_id_2/
│       └── ...
│
├── mcdm_analysis/
│   ├── analysis_id_1/
│   │   ├── timestamp: "2024-05-01T08:00:00Z"
│   │   ├── temperature: 22.5
│   │   ├── humidity: 55.0
│   │   ├── noise: 45.0
│   │   ├── lighting: 400.0
│   │   ├── weight_method: "compromise"
│   │   ├── mabac_score: 0.85
│   │   ├── marcos_score: 0.78
│   │   ├── spotis_score: 0.82
│   │   ├── cococomet_score: 0.80
│   │   ├── average_score: 0.81
│   │   ├── stress_level: 35.5
│   │   └── stress_interpretation: "Moderate"
│   └── analysis_id_2/
│       └── ...
│
├── alerts/
│   ├── alert_id_1/
│   │   ├── timestamp: "2024-05-01T08:15:00Z"
│   │   ├── type: "high_noise"
│   │   └── message: "Noise level exceeds threshold"
│   └── alert_id_2/
│       └── ...
│
└── settings/
    └── thresholds/
        ├── temperature_min: 18.0
        ├── temperature_max: 28.0
        ├── humidity_min: 30.0
        ├── humidity_max: 70.0
        ├── noise_max: 60.0
        ├── lighting_min: 200.0
        └── lighting_max: 800.0
```

## MCDM Analysis Data Model

### MCDMAnalysisResult Fields

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | String (ISO 8601) | When the analysis was performed |
| `temperature` | Number | Sensor temperature in Celsius |
| `humidity` | Number | Sensor humidity in percentage (0-100) |
| `noise` | Number | Sensor noise level in dB |
| `lighting` | Number | Sensor lighting in Lux |
| `weight_method` | String | Weight calculation method: `std`, `entropy`, `critic`, `merec`, `compromise` |
| `mabac_score` | Number | MABAC scoring result (0-1) |
| `marcos_score` | Number | MARCOS scoring result (0-1) |
| `spotis_score` | Number | SPOTIS scoring result (0-1) |
| `cococomet_score` | Number | COCOCOMET scoring result (0-1) |
| `average_score` | Number | Average of all four MCDM scores (0-1) |
| `stress_level` | Number | Predicted stress level (0-100) |
| `stress_interpretation` | String | Human-readable stress interpretation |

## Weight Methods

### STD (Standard Deviation)
- Based on variability of each criterion
- Higher variability = higher weight
- Formula: $w_j = \frac{\sigma_j}{\sum \sigma_k}$

### Entropy
- Based on information content
- Higher entropy = lower weight, higher divergence = higher weight
- Formula: $w_j = \frac{d_j}{\sum d_k}$ where $d_j = 1 - e_j$

### CRITIC (Correlation-based)
- Considers standard deviation and correlations
- High variance + low correlation with others = higher weight
- Formula: $w_j = \frac{\sigma_j \sum |r_{jk}|}{\sum_j \sigma_j \sum |r_{jk}|}$

### MEREC (Removal Effects)
- Based on impact when criterion is removed
- Higher removal effect = higher weight
- Formula: $w_j = \frac{RE_j - RE_{min}}{\sum (RE_k - RE_{min})}$

### Compromise
- Average of all four methods
- Balanced, robust weights
- Formula: $w_j = \frac{1}{4}(w_j^{STD} + w_j^{Entropy} + w_j^{CRITIC} + w_j^{MEREC})$

## Scoring Methods

### MABAC (Multi-Attributive Border Approximation area Comparison)
- Compares alternatives to border area
- Result range: [0, 1] where 1 = best
- Formula: $Score_i = \sum (v_{ij} - BA_j)$ normalized to [0,1]

### MARCOS (Measurement of Alternatives and Ranking according to COmpromise Solution)
- Combines ideal and anti-ideal solutions
- Result range: [0, 1] where 1 = best
- Formula: $Score_i = \frac{K_i^+ + K_i^-}{2}$ normalized to [0,1]

### SPOTIS (Stable Preference Ordering Towards Ideal Solution)
- Distance-based method
- Lower distance = better score
- Result range: [0, 1] where 1 = best
- Formula: $Score_i = 1 - \frac{Distance_i - min(Distance)}{max(Distance) - min(Distance)}$

### COCOCOMET (Combined Compromise Method)
- Hybrid approach combining power and linear aggregation
- Result range: [0, 1] where 1 = best
- Formula: $Score_i = 0.5 \times S_i^{Power} + 0.5 \times S_i^{Linear}$ normalized to [0,1]

## Stress Prediction Model

### Model Type: Neural Network (MLP)
- **Architecture**: Input(4) → Hidden(100, 50) → Output(1)
- **Inputs**: Normalized temperature, humidity, noise, lighting
- **Output**: Stress level (0-100)
- **Training Data**: 10,000+ samples from university mental health dataset

### Stress Level Interpretation

| Range | Level | Color |
|-------|-------|-------|
| 0-15 | Very Low (Relaxed) | 🟢 Green |
| 15-30 | Low (Calm) | 🟢 Light Green |
| 30-45 | Moderate (Normal) | 🟡 Amber |
| 45-60 | High (Stressed) | 🟠 Orange |
| 60-75 | Very High (Very Stressed) | 🟠 Deep Orange |
| 75-100 | Critical (Extremely Stressed) | 🔴 Red |

## Integration with Flutter App

### 1. Using MCDMService

```dart
// Initialize service
final mcdmService = MCDMService(
  database: FirebaseDatabase.instance,
);

// Analyze and store
final result = await mcdmService.analyzeAndStore(
  temperature: 22.5,
  humidity: 55.0,
  noise: 45.0,
  lighting: 400.0,
  weightMethod: 'compromise',
);

// Get recent analyses
mcdmService.recentAnalysis(limit: 20).listen((results) {
  // Handle results
});
```

### 2. Using MCDMCalculator Directly

```dart
// Normalize sensor data
final normalized = MCDMCalculator.normalizeSensorMatrix(sensorData);

// Calculate weights
final weights = MCDMCalculator.getWeights(
  normalized,
  WeightMethod.compromise,
);

// Calculate scores
final scores = MCDMCalculator.getScores(
  normalized,
  weights,
  ScoringMethod.mabac,
);
```

### 3. Using Stress Prediction

```dart
// Simple prediction
final stress = StressPredictionModel.predictStress(
  temperature: 22.5,
  humidity: 55.0,
  noise: 45.0,
  lighting: 400.0,
  useNeuralNetwork: true,
);

// Get interpretation
final interpretation = StressPredictionModel.getStressInterpretation(stress);
final color = StressPredictionModel.getStressColor(stress);
```

## Security Considerations

### For Production:

1. **Enable Authentication**:
   - Go to Firebase → Authentication
   - Enable desired auth methods (Email, Google, etc.)

2. **Update Security Rules**:
   ```json
   {
     "rules": {
       "study_desk_monitor": {
         ".read": "auth != null",
         ".write": "auth != null",
         "$uid": {
           ".read": "$uid === auth.uid",
           ".write": "$uid === auth.uid"
         }
       }
     }
   }
   ```

3. **Enable HTTPS** for all connections

4. **Limit data retention**: Set up automatic deletion of old records

## Performance Optimization

### 1. Indexing
Already configured in database rules for:
- `timestamp` - for time-based queries
- `weight_method` - for filtering by method

### 2. Pagination
Limit queries:
```dart
mcdmService.recentAnalysis(limit: 20) // Get last 20 results
```

### 3. Offline Support
Firebase Realtime Database automatically caches data locally in Flutter

## Troubleshooting

### Issue: "Permission Denied" errors
**Solution**: Check Firebase security rules and ensure user is authenticated

### Issue: Data not appearing in app
**Solution**: 
1. Check Firebase console for data presence
2. Verify database path matches configuration
3. Check network connectivity

### Issue: Slow performance
**Solution**:
1. Reduce limit parameter in queries
2. Add proper indexes to database
3. Consider archiving old data

## Example: Complete Flow

```dart
// 1. Read sensor data from device
final temperature = await sensor.readTemperature();
final humidity = await sensor.readHumidity();
final noise = await sensor.readNoise();
final lighting = await sensor.readLighting();

// 2. Initialize MCDM Service
final mcdmService = MCDMService(
  database: FirebaseDatabase.instance,
);

// 3. Perform analysis and store to Firebase
final result = await mcdmService.analyzeAndStore(
  temperature: temperature,
  humidity: humidity,
  noise: noise,
  lighting: lighting,
  weightMethod: 'compromise',
);

// 4. Display results in UI
setState(() {
  mcdmScore = result.averageScore;
  stressLevel = result.stressLevel;
  interpretation = result.stressInterpretation;
});

// 5. Listen for historical data
mcdmService.recentAnalysis(limit: 10).listen((results) {
  // Update UI with historical trends
});
```

## References

- [Firebase Realtime Database Documentation](https://firebase.google.com/docs/database)
- [Flutter Firebase Integration](https://firebase.flutter.dev/)
- [MCDM Methods Literature](https://scholar.google.com)
- [Stress Prediction Models](https://scholar.google.com)
