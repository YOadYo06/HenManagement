import json

path = r'C:\Users\YOadYo\AndroidStudioProjects\env_reading\mcdm_flutter_config.json'
with open(path, 'r', encoding='utf-8') as f:
    config = json.load(f)

model_configs = {
    'egg_production': {
        'type': 'regression_complex',
        'target': 'total_egg_production',
        'unit': 'eggs',
        'note': 'XGBoost model - requires full model for on-device prediction'
    },
    'green_building': {
        'type': 'linear_regression',
        'target': 'electricity_consumption',
        'unit': 'kWh',
        'coeffs': {'temperature': 0, 'humidity': 0, 'lighting': 0, 'noise': 0},
        'intercept': 0,
        'r2': 0.0015,
        'note': 'Linear Regression (R\u00b2=0.0015) - weak predictor'
    },
    'herbal_plant_health': {
        'type': 'classification_heuristic',
        'target': 'health_status',
        'classes': ['Unhealthy', 'Healthy'],
        'note': 'Neural Network classifier - using MCDM score proxy'
    },
    'iot_air_quality': {
        'type': 'linear_regression',
        'target': 'occupancy_count',
        'unit': 'people',
        'coeffs': {'temperature': 0, 'humidity': 0, 'co2': 0, 'lighting': 0},
        'intercept': 0,
        'r2': -0.0002,
        'note': 'Linear Regression (R\u00b2=-0.0002) - very weak'
    },
    'smart_library': {
        'type': 'classification_heuristic',
        'target': 'environment_state',
        'classes': ['Critical', 'SubOptimal', 'Optimal'],
        'note': 'Neural Network classifier - using MCDM score proxy'
    },
    'building_occupancy': {
        'type': 'classification_heuristic',
        'target': 'occupancy',
        'classes': ['Absent', 'Present'],
        'note': 'Random Forest classifier - using MCDM score proxy'
    },
    'user_behavior_raed': {
        'type': 'classification_heuristic',
        'target': 'behaviour',
        'classes': ['Sleeping', 'Eating', 'Walking', 'Stressed'],
        'note': 'Gradient Boosting classifier - using MCDM score proxy'
    },
    'iot_mental_health': {
        'type': 'linear_regression',
        'target': 'stress_level',
        'unit': 'score',
        'coeffs': {'temperature': 2.5522, 'humidity': 0.0150, 'noise': -18.2843, 'lighting': -1.1560},
        'intercept': 47.5577,
        'r2': 0.0604,
        'threshold': 50,
        'classes': ['Low Stress', 'High Stress'],
        'note': 'Linear regression from university notebook - predicts stress level'
    }
}

for ds in config['datasets']:
    ds_id = ds['id']
    if ds_id in model_configs:
        ds['modelConfig'] = model_configs[ds_id]

with open(path, 'w', encoding='utf-8') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

print('Updated!')
for ds in config['datasets']:
    mc = ds.get('modelConfig', {})
    print(f'  {ds["id"]}: type={mc.get("type","none")} target={mc.get("target","")}')
