import joblib
import numpy as np

def export_mlp_to_dart(model, input_names, class_names, function_name):
    """Export sklearn MLPClassifier/MLPRegressor weights to pure Dart."""
    weights = model.coefs_
    biases = model.intercepts_
    activation = model.activation  # 'relu' for hidden, output depends
    is_classifier = hasattr(model, 'classes_')

    lines = []
    lines.append(f'// Auto-generated from sklearn MLP')
    lines.append(f'import "dart:math";')
    lines.append(f'')
    lines.append(f'double {function_name}(List<double> input) {{')

    # Store weights and biases as lists
    for i, (w, b) in enumerate(zip(weights, biases)):
        w_str = ',\n    '.join([f'[{",".join(str(round(v, 10)) for v in row)}]' for row in w])
        b_str = ','.join(str(round(v, 10)) for v in b)
        lines.append(f'  final weights{i} = <List<double>>[')
        lines.append(f'    {w_str}')
        lines.append(f'  ];')
        lines.append(f'  final biases{i} = <double>[{b_str}];')
        lines.append('')

    lines.append(f'  List<double> x = input;')
    lines.append('')

    # Forward pass through hidden layers
    num_hidden = len(weights) - 1
    for i in range(num_hidden):
        lines.append(f'  // Layer {i}: {weights[i].shape[0]} -> {weights[i].shape[1]}')
        lines.append(f'  List<double> h{i+1} = List.filled({weights[i].shape[1]}, 0.0);')
        lines.append(f'  for (int j = 0; j < {weights[i].shape[1]}; j++) {{')
        lines.append(f'    double s = biases{i}[j];')
        lines.append(f'    for (int k = 0; k < x.length; k++) {{')
        lines.append(f'      s += x[k] * weights{i}[k][j];')
        lines.append(f'    }}')
        lines.append(f'    h{i+1}[j] = s > 0 ? s : 0.0;  // ReLU')
        lines.append(f'  }}')
        lines.append(f'  x = h{i+1};')
        lines.append('')

    # Output layer
    last = len(weights) - 1
    lines.append(f'  // Output layer: {weights[last].shape[1]} outputs')
    lines.append(f'  List<double> output = List.filled({weights[last].shape[1]}, 0.0);')
    lines.append(f'  for (int j = 0; j < {weights[last].shape[1]}; j++) {{')
    lines.append(f'    double s = biases{last}[j];')
    lines.append(f'    for (int k = 0; k < x.length; k++) {{')
    lines.append(f'      s += x[k] * weights{last}[k][j];')
    lines.append(f'    }}')
    lines.append(f'    output[j] = s;')
    lines.append(f'  }}')

    if is_classifier and len(class_names) > 1:
        if len(class_names) == 2:
            lines.append(f'  // Sigmoid for binary classification')
            lines.append(f'  double p = 1.0 / (1.0 + exp(-output[0]));')
            lines.append(f'  return p >= 0.5 ? 1.0 : 0.0;')
        else:
            lines.append(f'  // Softmax for multi-class')
            lines.append(f'  double max = output.reduce((a, b) => a > b ? a : b);')
            lines.append(f'  double sum = 0;')
            lines.append(f'  for (int j = 0; j < output.length; j++) {{')
            lines.append(f'    output[j] = exp(output[j] - max);')
            lines.append(f'    sum += output[j];')
            lines.append(f'  }}')
            lines.append(f'  double bestP = 0;')
            lines.append(f'  int bestIdx = 0;')
            lines.append(f'  for (int j = 0; j < output.length; j++) {{')
            lines.append(f'    output[j] /= sum;')
            lines.append(f'    if (output[j] > bestP) {{ bestP = output[j]; bestIdx = j; }}')
            lines.append(f'  }}')
            lines.append(f'  return bestIdx.toDouble();')
    elif is_classifier:
        lines.append(f'  return output[0];')
    else:
        lines.append(f'  return output[0];')

    lines.append(f'}}')
    lines.append('')
    lines.append(f'String predictLabel(List<double> input) {{')
    if is_classifier:
        lines.append(f'  int idx = {function_name}(input).toInt();')
        lines.append(f'  const labels = <int, String>{{')
        for i, name in enumerate(class_names):
            lines.append(f'    {i}: "{name}",')
        lines.append(f'  }};')
        lines.append(f'  return labels[idx] ?? "Unknown";')
    else:
        lines.append(f'  double val = {function_name}(input);')
        lines.append(f'  return val.toStringAsFixed(2);')
    lines.append(f'}}')

    return '\n'.join(lines)


# ── Herbal Plant Health (MLPClassifier: 4 inputs, 64→32 hidden, 2 outputs) ──
print("Exporting herbal_plant_health MLP to Dart...")
model = joblib.load('trained_models/herbal_plant_health.pkl')
classes = joblib.load('trained_models/herbal_plant_health_labels.pkl')
# classes is {0: 'Healthy', 1: 'Unhealthy'}
class_names = [classes[i] for i in range(len(classes))]
code = export_mlp_to_dart(model,
    input_names=['Soil_Moisture', 'Humidity', 'Temperature', 'Light_Intensity'],
    class_names=class_names,
    function_name='predictHerbalPlantHealth')
with open('lib/generated_models/herbal_plant_health.dart', 'w') as f:
    f.write(code)
print(f"  -> herbal_plant_health.dart ({len(code)} chars)")

# ── Smart Library (MLPClassifier: 5 inputs, 64→32 hidden, 3 outputs) ──
print("Exporting smart_library MLP to Dart...")
model = joblib.load('trained_models/smart_library.pkl')
classes = joblib.load('trained_models/smart_library_classes.pkl')
# classes is ['Critical', 'Optimal', 'Sub Optimal']
code = export_mlp_to_dart(model,
    input_names=['Temperature_C', 'Humidity_%', 'CO2_ppm', 'Illuminance_lux', 'Noise_dB'],
    class_names=classes,
    function_name='predictSmartLibrary')
with open('lib/generated_models/smart_library.dart', 'w') as f:
    f.write(code)
print(f"  -> smart_library.dart ({len(code)} chars)")

print("\nDone!")
