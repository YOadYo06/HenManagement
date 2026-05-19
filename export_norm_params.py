import joblib
import json
import os

datasets = [
    'egg_production',
    'green_building',
    'herbal_plant_health',
    'iot_air_quality',
    'smart_library',
    'building_occupancy',
    'user_behavior_raed',
    'iot_mental_health',
]

norm_config = {}

for name in datasets:
    norm_params = joblib.load(f'trained_models/{name}_norm.pkl')
    # Convert numpy values to native Python types
    clean = {}
    for key, val in norm_params.items():
        clean[key] = {k: float(v) for k, v in val.items()}
    norm_config[name] = clean

# Load classes for classifiers
classifiers = ['herbal_plant_health', 'smart_library', 'building_occupancy', 'user_behavior_raed']
class_config = {}
for name in classifiers:
    try:
        classes = joblib.load(f'trained_models/{name}_classes.pkl')
        class_config[name] = classes if isinstance(classes, list) else classes
    except:
        pass

output = {
    'normalization': norm_config,
    'classes': class_config,
}

os.makedirs('assets', exist_ok=True)
with open('assets/model_normalization.json', 'w') as f:
    json.dump(output, f, indent=2)

print("Saved assets/model_normalization.json")
print(f"Datasets: {list(norm_config.keys())}")
for name, params in norm_config.items():
    print(f"  {name}: {list(params.keys())}")
for name, classes in class_config.items():
    print(f"  {name} classes: {classes}")
