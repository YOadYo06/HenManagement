import json

with open('mcdm_flutter_config.json', 'r') as f:
    config = json.load(f)

# Map dataset ID -> [sensor_id -> model_feature_name]
feature_maps = {
    'egg_production': {
        'chicken_count': 'Amount_of_chicken',
        'feed_amount': 'Amount_of_Feeding',
        'temp': 'Temperature',
        'humidity': 'Humidity',
        'light': 'Light_Intensity',
        'noise': 'Noise',
    },
    'green_building': {
        'temp': 'indoor_temperature',
        'humidity': 'indoor_humidity',
        'light': 'indoor_lighting',
        'noise': 'indoor_noise',
    },
    'herbal_plant_health': {
        'soil_moisture': 'Soil_Moisture',
        'humidity': 'Humidity',
        'temp': 'Temperature',
        'light': 'Light_Intensity',
    },
    'iot_air_quality': {
        'temp': 'Temperature (?C)',
        'humidity': 'Humidity (%)',
        'co2': 'CO2 (ppm)',
        'light': 'Light Intensity (lux)',
    },
    'smart_library': {
        'temp': 'Temperature_C',
        'humidity': 'Humidity_%',
        'co2': 'CO2_ppm',
        'illuminance': 'Illuminance_lux',
        'noise': 'Noise_dB',
    },
    'building_occupancy': {
        'temp': 'Temperature',
        'humidity': 'Humidity',
        'light': 'Light',
        'co2': 'CO2',
        'humidity_ratio': 'HumidityRatio',
    },
    'user_behavior_raed': {
        'temp': 'temperature',
        'humidity': 'humidity',
        'noise': 'noise_db',
        'light': 'light_intensity',
        'motion': 'motion_level',
    },
    'iot_mental_health': {
        'temp': 'temperature_celsius',
        'humidity': 'humidity_percent',
        'noise': 'noise_level_db',
        'light': 'lighting_lux',
    },
}

class_info = {
    'herbal_plant_health': {'type': 'model', 'target': 'health_status', 'modelClasses': ['Healthy', 'Unhealthy']},
    'smart_library': {'type': 'model', 'target': 'environment_state', 'modelClasses': ['Critical', 'Optimal', 'Sub Optimal']},
    'building_occupancy': {'type': 'model', 'target': 'occupancy', 'modelClasses': ['Absent', 'Present']},
    'user_behavior_raed': {'type': 'model', 'target': 'behaviour', 'modelClasses': ['eating', 'sleeping', 'stressed', 'studying', 'walking']},
    'egg_production': {'type': 'model', 'target': 'total_egg_production', 'unit': 'eggs', 'targetMin': 0, 'targetMax': 500, 'invertScore': True},
    'green_building': {'type': 'model', 'target': 'electricity_consumption', 'unit': 'kWh', 'targetMin': 0, 'targetMax': 800, 'invertScore': False},
    'iot_air_quality': {'type': 'model', 'target': 'occupancy_count', 'unit': 'people', 'targetMin': 0, 'targetMax': 50, 'invertScore': False},
    'iot_mental_health': {'type': 'model', 'target': 'stress_level', 'unit': 'score'},
}

# Update each dataset
for ds in config['datasets']:
    ds_id = ds['id']
    mapping = feature_maps.get(ds_id, {})

    # Add modelFeature to each sensor
    for sensor in ds['sensors']:
        sid = sensor['id']
        if sid in mapping:
            sensor['modelFeature'] = mapping[sid]

    # Update modelConfig
    if ds_id in class_info:
        new_config = class_info[ds_id].copy()
        # Build modelFeatures in the order of the sensors (which should match training order)
        model_features = []
        for sensor in ds['sensors']:
            if 'modelFeature' in sensor:
                model_features.append(sensor['modelFeature'])
        if model_features:
            new_config['modelFeatures'] = model_features
        ds['modelConfig'] = new_config

with open('mcdm_flutter_config.json', 'w') as f:
    json.dump(config, f, indent=2)

print("Config updated with modelFeature and modelConfig")
