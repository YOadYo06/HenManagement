# Firebase Cloud Functions - ML Model Integration Guide

## Overview

This guide explains how to deploy your stress prediction ML model to Firebase Cloud Functions, making it available for:
- Real-time predictions from any client
- Batch processing on demand
- Scheduled predictions
- Mobile app API calls without model size limits

---

## Option 1: Firebase Cloud Functions (Recommended for Rapid Deployment)

### Architecture
```
Flutter App
    ↓
HTTP Request (sensor data)
    ↓
Firebase Cloud Function
    ↓
Python/Node.js ML Model
    ↓
HTTP Response (stress prediction)
```

### Step 1: Enable Cloud Functions

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Functions** in left sidebar
4. Click **Get Started** → **Create Function**
5. Or use CLI: `firebase functions:config:set`

### Step 2: Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
firebase login
firebase init functions
```

### Step 3: Create Cloud Function for Stress Prediction

In your Firebase project, create `functions/index.js`:

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});

admin.initializeApp();

// HTTP Cloud Function for stress prediction
exports.predictStress = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { temperature, humidity, noise, lighting } = req.body;

      // Input validation
      if (temperature === undefined || humidity === undefined || 
          noise === undefined || lighting === undefined) {
        return res.status(400).json({ 
          error: "Missing sensor inputs" 
        });
      }

      // Normalize inputs to [0, 1]
      const normTemp = (temperature - 18) / (30 - 18);
      const normHumidity = (humidity - 20) / (80 - 20);
      const normNoise = (noise - 30) / (80 - 30);
      const normLighting = (lighting - 100) / (1000 - 100);

      // Linear regression model from Python notebook
      // Model: y = 47.5577 + 2.5522*temp + 0.0150*humidity - 18.2843*noise - 1.1560*lighting
      const intercept = 47.5577;
      const coefficients = [2.5522, 0.0150, -18.2843, -1.1560];
      
      let stress = intercept;
      stress += coefficients[0] * normTemp;
      stress += coefficients[1] * normHumidity;
      stress += coefficients[2] * normNoise;
      stress += coefficients[3] * normLighting;

      // Clamp to [0, 100]
      stress = Math.max(0, Math.min(100, stress));

      // Get interpretation
      const interpretation = getStressInterpretation(stress);

      // Store prediction in Firebase
      const timestamp = new Date();
      await admin.database().ref('stress_predictions').push({
        temperature,
        humidity,
        noise,
        lighting,
        stress_level: stress,
        interpretation,
        timestamp: timestamp.toISOString(),
      });

      res.json({
        stress_level: stress,
        interpretation: interpretation,
        timestamp: timestamp.toISOString(),
      });

    } catch (error) {
      console.error("Error:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  });
});

function getStressInterpretation(stressLevel) {
  if (stressLevel < 15) return "Very Low (Relaxed)";
  if (stressLevel < 30) return "Low (Calm)";
  if (stressLevel < 45) return "Moderate (Normal)";
  if (stressLevel < 60) return "High (Stressed)";
  if (stressLevel < 75) return "Very High (Very Stressed)";
  return "Critical (Extremely Stressed)";
}

// Callable Cloud Function (for use within Flutter)
exports.predictStressCallable = functions.https.onCall(async (data, context) => {
  try {
    const { temperature, humidity, noise, lighting } = data;

    // Same prediction logic as above
    const normTemp = (temperature - 18) / (30 - 18);
    const normHumidity = (humidity - 20) / (80 - 20);
    const normNoise = (noise - 30) / (80 - 30);
    const normLighting = (lighting - 100) / (1000 - 100);

    const intercept = 47.5577;
    const coefficients = [2.5522, 0.0150, -18.2843, -1.1560];
    
    let stress = intercept;
    stress += coefficients[0] * normTemp;
    stress += coefficients[1] * normHumidity;
    stress += coefficients[2] * normNoise;
    stress += coefficients[3] * normLighting;

    stress = Math.max(0, Math.min(100, stress));

    return {
      stress_level: stress,
      interpretation: getStressInterpretation(stress),
    };
  } catch (error) {
    throw new functions.https.HttpsError(
      "internal",
      "Error predicting stress"
    );
  }
});

// Batch prediction function
exports.batchPredictStress = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { readings } = req.body;

      if (!Array.isArray(readings)) {
        return res.status(400).json({ error: "readings must be an array" });
      }

      const predictions = readings.map(r => {
        const normTemp = (r.temperature - 18) / (30 - 18);
        const normHumidity = (r.humidity - 20) / (80 - 20);
        const normNoise = (r.noise - 30) / (80 - 30);
        const normLighting = (r.lighting - 100) / (1000 - 100);

        const intercept = 47.5577;
        const coefficients = [2.5522, 0.0150, -18.2843, -1.1560];
        
        let stress = intercept;
        stress += coefficients[0] * normTemp;
        stress += coefficients[1] * normHumidity;
        stress += coefficients[2] * normNoise;
        stress += coefficients[3] * normLighting;

        stress = Math.max(0, Math.min(100, stress));

        return {
          ...r,
          stress_level: stress,
          interpretation: getStressInterpretation(stress),
        };
      });

      res.json(predictions);
    } catch (error) {
      res.status(500).json({ error: "Internal server error" });
    }
  });
});
```

### Step 4: Deploy Cloud Function

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Step 5: Call from Flutter App

Create `lib/services/cloud_function_service.dart`:

```dart
import 'package:firebase_functions/firebase_functions.dart';

class CloudFunctionService {
  static final _functions = FirebaseFunctions.instance;

  // Call stress prediction from cloud
  static Future<Map<String, dynamic>> predictStressCloud({
    required double temperature,
    required double humidity,
    required double noise,
    required double lighting,
  }) async {
    try {
      final result = await _functions.httpsCallable('predictStressCallable').call({
        'temperature': temperature,
        'humidity': humidity,
        'noise': noise,
        'lighting': lighting,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('Error calling predictStressCallable: $e');
      rethrow;
    }
  }

  // Batch prediction
  static Future<List<Map<String, dynamic>>> batchPredictStress(
    List<Map<String, dynamic>> readings,
  ) async {
    try {
      final response = await _functions.httpsCallable('batchPredictStress').call({
        'readings': readings,
      });

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error calling batchPredictStress: $e');
      rethrow;
    }
  }
}
```

Add to `pubspec.yaml`:
```yaml
firebase_functions: ^4.5.0
```

Usage in your Flutter app:
```dart
// Single prediction
final result = await CloudFunctionService.predictStressCloud(
  temperature: 22.5,
  humidity: 55.0,
  noise: 45.0,
  lighting: 400.0,
);
print('Stress: ${result['stress_level']}');

// Batch predictions
final readings = [
  {'temperature': 22.5, 'humidity': 55.0, 'noise': 45.0, 'lighting': 400.0},
  {'temperature': 23.0, 'humidity': 60.0, 'noise': 50.0, 'lighting': 450.0},
];
final predictions = await CloudFunctionService.batchPredictStress(readings);
```

---

## Option 2: Using Python with Firebase Admin SDK

### Advantages
- More ML flexibility (use TensorFlow, scikit-learn, etc.)
- Better for complex models
- Can use full ML pipeline

### Step 1: Create Python Cloud Function

Create `functions/requirements.txt`:
```
functions-framework==3.3.0
firebase-admin==6.2.0
numpy==1.24.0
scikit-learn==1.3.0
```

Create `functions/main.py`:
```python
import functions_framework
import firebase_admin
from firebase_admin import credentials, db
import numpy as np
from datetime import datetime

# Initialize Firebase
firebase_admin.initialize_app()

@functions_framework.http
def predict_stress(request):
    """HTTP Cloud Function for stress prediction"""
    request_json = request.get_json()
    
    try:
        temperature = float(request_json.get('temperature'))
        humidity = float(request_json.get('humidity'))
        noise = float(request_json.get('noise'))
        lighting = float(request_json.get('lighting'))
        
        # Normalize inputs
        norm_temp = (temperature - 18) / (30 - 18)
        norm_humidity = (humidity - 20) / (80 - 20)
        norm_noise = (noise - 30) / (80 - 30)
        norm_lighting = (lighting - 100) / (1000 - 100)
        
        # Linear regression model
        intercept = 47.5577
        coefficients = [2.5522, 0.0150, -18.2843, -1.1560]
        
        inputs = [norm_temp, norm_humidity, norm_noise, norm_lighting]
        stress = intercept + sum(c * x for c, x in zip(coefficients, inputs))
        stress = max(0, min(100, stress))
        
        # Get interpretation
        interpretation = get_stress_interpretation(stress)
        
        # Store in Firebase
        ref = db.reference('stress_predictions').push({
            'temperature': temperature,
            'humidity': humidity,
            'noise': noise,
            'lighting': lighting,
            'stress_level': stress,
            'interpretation': interpretation,
            'timestamp': datetime.now().isoformat(),
        })
        
        return {
            'stress_level': stress,
            'interpretation': interpretation,
            'timestamp': datetime.now().isoformat(),
        }, 200
        
    except Exception as e:
        return {'error': str(e)}, 500

def get_stress_interpretation(stress_level):
    if stress_level < 15:
        return "Very Low (Relaxed)"
    elif stress_level < 30:
        return "Low (Calm)"
    elif stress_level < 45:
        return "Moderate (Normal)"
    elif stress_level < 60:
        return "High (Stressed)"
    elif stress_level < 75:
        return "Very High (Very Stressed)"
    else:
        return "Critical (Extremely Stressed)"
```

### Step 2: Deploy

```bash
cd functions
gcloud functions deploy predict_stress \
  --runtime python39 \
  --trigger-http \
  --allow-unauthenticated
```

---

## Option 3: Firebase ML Kit (Built-in ML)

Firebase offers built-in ML capabilities for edge ML models:

### Benefits
- No separate backend needed
- On-device predictions
- Lower latency
- Better privacy

### Using TensorFlow Lite in Flutter

```dart
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter interpreter;

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('models/stress_model.tflite');
  }

  Future<double> predictStress(
    double temperature,
    double humidity,
    double noise,
    double lighting,
  ) async {
    // Normalize inputs
    final input = [
      [(temperature - 18) / (30 - 18)],
      [(humidity - 20) / (80 - 20)],
      [(noise - 30) / (80 - 30)],
      [(lighting - 100) / (1000 - 100)],
    ];

    var output = List.filled(1, 0.0);
    interpreter.run(input, output);

    return output[0] * 100; // Scale to 0-100
  }
}
```

---

## Security Rules for Predictions Storage

Update your Firebase Realtime Database rules:

```json
{
  "rules": {
    "study_desk_monitor": {
      "stress_predictions": {
        ".read": "auth != null",
        ".write": "root.child('functions/predictStress').val() == true || auth != null",
        "$prediction_id": {
          ".validate": "newData.hasChildren(['temperature', 'humidity', 'noise', 'lighting', 'stress_level'])"
        }
      }
    }
  }
}
```

---

## Performance Considerations

| Option | Latency | Cost | Flexibility |
|--------|---------|------|-------------|
| Cloud Functions (JS) | 100-500ms | Low ($6/month free) | Medium |
| Cloud Functions (Python) | 200-800ms | Low-Medium | High |
| TensorFlow Lite (Mobile) | <1ms | None | Medium |
| Cloud ML | 500-2000ms | Medium | Very High |

### Recommendations

- **Development**: Use local Dart implementation in Flutter
- **Production**: Deploy to Cloud Functions for:
  - Batch processing
  - Scheduled predictions
  - Advanced analytics
  - Model versioning
- **Real-time**: Use TensorFlow Lite for immediate feedback
- **Hybrid**: Use local model + Cloud Functions for model updates

---

## Model Versioning in Firebase

### Store multiple model versions:

```javascript
// In Cloud Function
exports.predictStressV2 = functions.https.onRequest((req, res) => {
  // Updated model with better coefficients
  const intercept = 48.4104;
  const coefficients = [2.3415, 0.7299, -18.8254, -2.3022];
  // ... rest of logic
});

// In Firebase Database
/model_versions/
  v1/
    intercept: 47.5577
    coefficients: [2.5522, 0.0150, -18.2843, -1.1560]
    deployed_date: ...
  v2/
    intercept: 48.4104
    coefficients: [2.3415, 0.7299, -18.8254, -2.3022]
    deployed_date: ...
  current: "v2"
```

---

## Monitoring and Debugging

### Enable Cloud Function logs:

```bash
firebase functions:log
```

### Monitor performance:

```javascript
exports.predictStress = functions.https.onRequest((req, res) => {
  const startTime = Date.now();
  
  // ... prediction logic
  
  const duration = Date.now() - startTime;
  console.log(`Prediction took ${duration}ms`);
  
  // Log to Firebase
  admin.database().ref('metrics/prediction_times').push({
    duration,
    timestamp: admin.database.ServerValue.TIMESTAMP,
  });
});
```

---

## Quick Deployment Checklist

- [ ] Install firebase-tools (`npm install -g firebase-tools`)
- [ ] Run `firebase init functions`
- [ ] Add Cloud Function code (JavaScript or Python)
- [ ] Test locally: `firebase emulators:start`
- [ ] Deploy: `firebase deploy --only functions`
- [ ] Update Flutter app with Cloud Function service
- [ ] Test API calls from Flutter
- [ ] Monitor logs and performance
- [ ] Set up error alerts

---

## Troubleshooting

### "Exceeded cloud function execution timeout"
- Optimize model complexity
- Use caching for repeated predictions
- Consider batch processing

### "Permission denied" errors
- Update Firebase security rules
- Ensure authentication is configured
- Check region permissions

### "CORS issues"
- Use `cors` package in Node.js
- Set proper CORS headers in Python
- Test with different client origins

---

## Next Steps

1. **Start Simple**: Deploy JavaScript version first
2. **Monitor**: Track prediction latency and accuracy
3. **Optimize**: Profile and optimize hot paths
4. **Scale**: Add model versioning and A/B testing
5. **Integrate**: Connect Flutter app to Cloud Function
6. **Monitor**: Set up logging and alerts

For advanced ML:
- [TensorFlow.js Documentation](https://www.tensorflow.org/js)
- [Google Cloud ML Documentation](https://cloud.google.com/products/ai)
- [Firebase Functions Best Practices](https://firebase.google.com/docs/functions/get-started/write-deploy-functions)
