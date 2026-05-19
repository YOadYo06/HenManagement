# Machine Learning Model Integration Guide

## Overview

This guide explains how to integrate the stress prediction machine learning model from the Python notebook into the Flutter app. Currently, we use a simplified version with hardcoded weights, but this shows how to properly integrate a trained model.

## Current Implementation

The current implementation in `stress_prediction_model.dart` uses:
1. **Linear Regression Model** (fast, lightweight)
2. **Simplified Neural Network** (weights hardcoded)

### Linear Model Coefficients

From Python notebook analysis:
```
Model: y = 48.4104 + 2.3415*temp + 0.7299*humidity - 18.8254*noise - 2.3022*lighting
Performance: R² = 0.5892
```

## Option 1: Using TensorFlow Lite (Recommended for Production)

### Step 1: Prepare Model in Python

```python
import tensorflow as tf
from sklearn.preprocessing import MinMaxScaler

# Load or create your trained model
model = tf.keras.Sequential([
    tf.keras.layers.Dense(100, activation='relu', input_shape=(4,)),
    tf.keras.layers.Dense(50, activation='relu'),
    tf.keras.layers.Dense(1, activation='linear')
])

# Compile and train (if needed)
model.compile(optimizer='adam', loss='mse')
model.fit(X_train, y_train, epochs=100, batch_size=32)

# Convert to TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS
]
tflite_model = converter.convert()

# Save the model
with open('stress_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

### Step 2: Add TensorFlow Lite Flutter Dependency

```yaml
dependencies:
  tflite_flutter: ^0.11.0
```

### Step 3: Add Model to Flutter Assets

1. Create `assets/models/` folder
2. Copy `stress_model.tflite` there
3. Update `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/stress_model.tflite
```

### Step 4: Create TFLite Wrapper

```dart
import 'package:tflite_flutter/tflite_flutter.dart';

class StressPredictionModelTFLite {
  late Interpreter interpreter;

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/models/stress_model.tflite');
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  double predictStress(List<double> input) {
    if (input.length != 4) {
      throw Exception('Input must have 4 values');
    }

    // Prepare input
    var inputShape = [1, 4];
    var inputData = [input];

    // Prepare output
    var outputShape = [1, 1];
    var output = List<double>.filled(1, 0).reshape(outputShape);

    // Run inference
    interpreter.run(inputData, output);

    // Return normalized stress level (0-100)
    return (output[0][0] * 100).clamp(0, 100).toDouble();
  }

  void dispose() {
    interpreter.close();
  }
}
```

### Step 5: Usage in App

```dart
final model = StressPredictionModelTFLite();

// Load once
await model.loadModel();

// Use multiple times
final normalizedInput = [0.5, 0.6, 0.3, 0.7]; // Normalized values
final stress = model.predictStress(normalizedInput);

// Clean up
model.dispose();
```

## Option 2: Using ONNX Model (Cross-Platform)

### Step 1: Export Model from Python

```python
import torch
import onnx
import numpy as np

# Convert PyTorch model to ONNX
dummy_input = torch.randn(1, 4)
torch.onnx.export(model, dummy_input, 'stress_model.onnx',
    input_names=['input'],
    output_names=['output'],
    opset_version=12
)

# Verify model
onnx_model = onnx.load('stress_model.onnx')
onnx.checker.check_model(onnx_model)
```

### Step 2: Add ONNX Runtime

```yaml
dependencies:
  onnxruntime_flutter: ^1.14.0
```

### Step 3: Use ONNX Model

```dart
import 'package:onnxruntime/onnxruntime.dart' as ort;

class StressPredictionModelONNX {
  late ort.Session session;

  Future<void> loadModel() async {
    final options = ort.SessionOptions()..setGraphOptimizationLevel(
      ort.GraphOptimizationLevel.all
    );
    session = await ort.createSession(
      'assets/models/stress_model.onnx',
      sessionOptions: options,
    );
  }

  double predictStress(List<double> input) {
    final inputTensors = <String, ort.OrtValueMaps>{
      'input': ort.OrtValueMaps.singleMap(input),
    };

    final output = session.run(null, inputTensors);
    final predictions = output?[0].value as List<List<double>>?;
    
    if (predictions == null || predictions.isEmpty) {
      throw Exception('Invalid model output');
    }

    return (predictions[0][0] * 100).clamp(0, 100).toDouble();
  }

  void dispose() {
    session.release();
  }
}
```

## Option 3: Using Python Backend (for complex models)

### Setup Python Server

```python
# app.py
from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf

app = Flask(__name__)
model = tf.keras.models.load_model('stress_model.h5')

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    input_data = np.array([
        data['temperature'],
        data['humidity'],
        data['noise'],
        data['lighting']
    ]).reshape(1, 4)
    
    prediction = model.predict(input_data)
    stress_level = float(prediction[0][0] * 100)
    
    return jsonify({'stress_level': stress_level})

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5000)
```

### Flutter HTTP Client

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class StressPredictionAPI {
  final String serverUrl = 'http://your-server.com:5000';

  Future<double> predictStress(
    double temperature,
    double humidity,
    double noise,
    double lighting,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'temperature': temperature,
          'humidity': humidity,
          'noise': noise,
          'lighting': lighting,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['stress_level'] as num).toDouble();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to predict stress: $e');
    }
  }
}
```

## Model Architecture Reference

### Input Normalization
All inputs should be normalized to [0, 1]:

```python
from sklearn.preprocessing import MinMaxScaler

scaler = MinMaxScaler()
X_normalized = scaler.fit_transform(X_raw)
```

### Expected Model Architecture

```
Input Layer (4 neurons)
    ↓
Dense Layer (100 neurons, ReLU)
    ↓
Dropout (0.2)
    ↓
Dense Layer (50 neurons, ReLU)
    ↓
Dropout (0.1)
    ↓
Output Layer (1 neuron, Linear)
    ↓
Output Range: [0-100] stress level
```

### Training Script

```python
import tensorflow as tf
from tensorflow.keras import layers
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler

# Load data
X = load_sensor_data()  # Shape: (n_samples, 4)
y = load_stress_labels()  # Shape: (n_samples,)

# Normalize
scaler = MinMaxScaler()
X_normalized = scaler.fit_transform(X)

# Split
X_train, X_test, y_train, y_test = train_test_split(
    X_normalized, y, test_size=0.2, random_state=42
)

# Build model
model = tf.keras.Sequential([
    layers.Dense(100, activation='relu', input_shape=(4,)),
    layers.Dropout(0.2),
    layers.Dense(50, activation='relu'),
    layers.Dropout(0.1),
    layers.Dense(1, activation='linear')
])

model.compile(
    optimizer='adam',
    loss='mse',
    metrics=['mae']
)

# Train
history = model.fit(
    X_train, y_train,
    epochs=100,
    batch_size=32,
    validation_data=(X_test, y_test),
    callbacks=[
        tf.keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=10,
            restore_best_weights=True
        )
    ]
)

# Save
model.save('stress_model.h5')

# Evaluate
loss, mae = model.evaluate(X_test, y_test)
print(f'Test MAE: {mae:.2f}')
```

## Converting Between Formats

### Keras to TFLite
```python
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
```

### Keras to ONNX
```python
import tf2onnx
import tensorflow as tf

model = tf.keras.models.load_model('model.h5')
spec = (tf.TensorSpec((None, 4), tf.float32, name="input"),)
output_path = "stress_model.onnx"
model_proto, _ = tf2onnx.convert.from_keras(model, input_signature=spec)
tf2onnx.utils.save_model(model_proto, output_path)
```

### PyTorch to ONNX
```python
import torch
model = torch.load('model.pt')
dummy_input = torch.randn(1, 4)
torch.onnx.export(model, dummy_input, 'stress_model.onnx')
```

## Integration Testing

### Test Script

```dart
void testStressPrediction() async {
  // Test with known inputs
  final testCases = [
    // (temp, humidity, noise, lighting, expected_approximate_stress)
    (22.0, 50.0, 30.0, 500.0, 25.0), // Good conditions
    (28.0, 30.0, 70.0, 100.0, 65.0), // Poor conditions
    (20.0, 60.0, 45.0, 400.0, 35.0), // Average conditions
  ];

  for (final (temp, hum, noise, light, expectedStress) in testCases) {
    final stress = StressPredictionModel.predictStress(
      temp, hum, noise, light
    );

    print('Input: $temp°C, $hum%, $noise dB, $light lux');
    print('Predicted stress: $stress (expected ~$expectedStress)');
    
    assert(
      (stress - expectedStress).abs() < 20,
      'Prediction too far from expected'
    );
  }
}
```

## Performance Optimization

### Batch Processing

```dart
List<double> predictBatch(List<List<double>> inputs) {
  return inputs.map((input) => predictStress(
    input[0], input[1], input[2], input[3]
  )).toList();
}
```

### Caching Predictions

```dart
final cache = <String, double>{};

double predictWithCache(double t, double h, double n, double l) {
  final key = '$t|$h|$n|$l';
  return cache.putIfAbsent(
    key,
    () => StressPredictionModel.predictStress(t, h, n, l)
  );
}
```

## Deployment Checklist

- [ ] Model trained on representative data
- [ ] Model quantized for mobile (if using TFLite)
- [ ] Model size < 10MB
- [ ] Inference time < 100ms
- [ ] Input validation implemented
- [ ] Output range validation (0-100)
- [ ] Unit tests written
- [ ] Firebase storage configured
- [ ] Error handling in place
- [ ] Model versioning strategy defined

## Troubleshooting

### Model loads but predictions are wrong
- Verify input normalization matches training
- Check output scale matches expected (0-100)
- Validate against original Python model

### Model too slow
- Consider quantization
- Use batch processing
- Cache predictions
- Reduce model complexity

### Model file too large
- Quantize to int8
- Prune weights
- Use TFLite converter optimization
- Consider cloud inference

## References

- [TensorFlow Lite Flutter](https://github.com/tensorflow/flutter-mediapipe)
- [ONNX Runtime](https://onnxruntime.ai/)
- [TensorFlow Model Optimization](https://www.tensorflow.org/model_optimization)
- [Model Deployment Best Practices](https://firebase.google.com/docs/ml/model-management)
