import pandas as pd
import numpy as np
import joblib
import os
import json
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LinearRegression
from sklearn.neural_network import MLPClassifier, MLPRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from xgboost import XGBRegressor

np.random.seed(42)
os.makedirs('trained_models', exist_ok=True)

def normalize_matrix(data, criteria_types):
    normalized_data = data.copy()
    norm_params = {}
    for criterion in data.columns:
        min_val = data[criterion].min()
        max_val = data[criterion].max()
        range_val = max_val - min_val
        norm_params[criterion] = {'min': float(min_val), 'max': float(max_val), 'range': float(range_val)}
        if range_val == 0:
            normalized_data[criterion] = 0.5
        else:
            if criteria_types[criterion] == 'cost':
                normalized_data[criterion] = (max_val - data[criterion]) / range_val
            else:
                normalized_data[criterion] = (data[criterion] - min_val) / range_val
    return normalized_data, norm_params

# ─────────────────────────────────────────────────────
# 1. Egg Production
# ─────────────────────────────────────────────────────
print("=" * 60)
print("1. Egg Production - XGBoost")
print("=" * 60)
df = pd.read_csv('Egg_Production.csv')
criteria_columns = ['Amount_of_chicken', 'Amount_of_Feeding', 'Temperature', 'Humidity', 'Light_Intensity', 'Noise']
target_column = 'Total_egg_production'
criteria_types = {
    'Amount_of_chicken': 'profit',
    'Amount_of_Feeding': 'profit',
    'Temperature': 'cost',
    'Humidity': 'cost',
    'Light_Intensity': 'profit',
    'Noise': 'cost',
}
X = df[criteria_columns].copy()
y = df[target_column].values
X_normalized, norm_params = normalize_matrix(X, criteria_types)

model = XGBRegressor(n_estimators=100, random_state=42)
model.fit(X_normalized, y)
print(f"  R² = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/egg_production.pkl')
joblib.dump(norm_params, 'trained_models/egg_production_norm.pkl')
print("  Saved.")

# ─────────────────────────────────────────────────────
# 2. Green Building
# ─────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("2. Green Building - LinearRegression")
print("=" * 60)
df = pd.read_csv('green_building_dataset.csv')
criteria_columns = ['indoor_temperature', 'indoor_humidity', 'indoor_lighting', 'indoor_noise']
target_column = 'electricity_consumption'
criteria_types = {
    'indoor_temperature': 'cost',
    'indoor_humidity': 'cost',
    'indoor_lighting': 'profit',
    'indoor_noise': 'cost',
}
X = df[criteria_columns].copy()
y = df[target_column].values
X_normalized, norm_params = normalize_matrix(X, criteria_types)

model = LinearRegression()
model.fit(X_normalized, y)
print(f"  R² = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/green_building.pkl')
joblib.dump(norm_params, 'trained_models/green_building_norm.pkl')
print("  Saved.")

# ─────────────────────────────────────────────────────
# 3. Herbal Plant Health
# ─────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("3. Herbal Plant Health - Neural Network (Classifier)")
print("=" * 60)
df = pd.read_csv('herbal_plant_sensor_data.csv')
criteria_columns = ['Soil_Moisture', 'Humidity', 'Temperature', 'Light_Intensity']
criteria_types = {
    'Soil_Moisture': 'profit',
    'Humidity': 'cost',
    'Temperature': 'cost',
    'Light_Intensity': 'profit',
}
target_column = 'Label'
X = df[criteria_columns].copy()
y = df[target_column].values
X_normalized, norm_params = normalize_matrix(X, criteria_types)

model = MLPClassifier(hidden_layer_sizes=(64, 32), max_iter=500, random_state=42)
model.fit(X_normalized, y)
print(f"  Accuracy = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/herbal_plant_health.pkl')
joblib.dump(norm_params, 'trained_models/herbal_plant_health_norm.pkl')
# Save label mapping
label_map = {0: 'Healthy', 1: 'Unhealthy'}
joblib.dump(label_map, 'trained_models/herbal_plant_health_labels.pkl')
print("  Saved.")

# ─────────────────────────────────────────────────────
# 4. IoT Air Quality
# ─────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("4. IoT Air Quality - LinearRegression")
print("=" * 60)
df = pd.read_csv('IoT_Indoor_Air_Quality_Dataset.csv')
criteria_columns = ['Temperature (?C)', 'Humidity (%)', 'CO2 (ppm)', 'Light Intensity (lux)']
target_column = 'Occupancy Count'
criteria_types = {
    'Temperature (?C)': 'cost',
    'Humidity (%)': 'cost',
    'CO2 (ppm)': 'cost',
    'Light Intensity (lux)': 'profit',
}
df_mcdm = df[criteria_columns + [target_column]].dropna()
X = df_mcdm[criteria_columns].copy()
y = df_mcdm[target_column].values
X_normalized, norm_params = normalize_matrix(X, criteria_types)

model = LinearRegression()
model.fit(X_normalized, y)
print(f"  R² = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/iot_air_quality.pkl')
joblib.dump(norm_params, 'trained_models/iot_air_quality_norm.pkl')
print("  Saved.")

# ─────────────────────────────────────────────────────
# 5. Smart Library
# ─────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("5. Smart Library - Neural Network (Classifier)")
print("=" * 60)
df = pd.read_csv('Library_Indoor_IoT_Dataset_1.csv')
criteria_columns = ['Temperature_C', 'Humidity_%', 'CO2_ppm', 'Illuminance_lux', 'Noise_dB']
target_column = 'Overall_Environment_State'
criteria_types = {
    'Temperature_C': 'cost',
    'Humidity_%': 'cost',
    'CO2_ppm': 'cost',
    'Illuminance_lux': 'profit',
    'Noise_dB': 'cost',
}
X = df[criteria_columns].copy()
y_str = df[target_column].values
# Encode target
from sklearn.preprocessing import LabelEncoder
le = LabelEncoder()
y = le.fit_transform(y_str)
X_normalized, norm_params = normalize_matrix(X, criteria_types)

model = MLPClassifier(hidden_layer_sizes=(64, 32), max_iter=500, random_state=42)
model.fit(X_normalized, y)
print(f"  Accuracy = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/smart_library.pkl')
joblib.dump(norm_params, 'trained_models/smart_library_norm.pkl')
# Save classes
classes = le.classes_.tolist()
joblib.dump(classes, 'trained_models/smart_library_classes.pkl')
print(f"  Classes: {classes}")
print("  Saved.")

# ─────────────────────────────────────────────────────
# 6. Building Occupancy
# ─────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("6. Building Occupancy - RandomForest (Classifier)")
print("=" * 60)
df = pd.read_csv('Occupancy.csv')
criteria_columns = ['Temperature', 'Humidity', 'Light', 'CO2', 'HumidityRatio']
target_column = 'Occupancy'
criteria_types = {
    'Temperature': 'cost',
    'Humidity': 'cost',
    'Light': 'profit',
    'CO2': 'cost',
    'HumidityRatio': 'cost',
}
X = df[criteria_columns].copy()
y = df[target_column].values
X_normalized, norm_params = normalize_matrix(X, criteria_types)

model = RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1)
model.fit(X_normalized, y)
print(f"  Accuracy = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/building_occupancy.pkl')
joblib.dump(norm_params, 'trained_models/building_occupancy_norm.pkl')
classes = ['Absent', 'Present']
joblib.dump(classes, 'trained_models/building_occupancy_classes.pkl')
print("  Saved.")

# ─────────────────────────────────────────────────────
# 7. User Behavior RAED
# ─────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("7. User Behavior RAED - GradientBoosting (Classifier)")
print("=" * 60)
df = pd.read_csv('RAED.csv')
criteria_columns = ['temperature', 'humidity', 'noise_db', 'light_intensity', 'motion_level']
target_column = 'behaviour'
criteria_types = {
    'temperature': 'cost',
    'humidity': 'cost',
    'noise_db': 'cost',
    'light_intensity': 'profit',
    'motion_level': 'profit',
}
df_mcdm = df[criteria_columns + [target_column]].dropna()
X = df_mcdm[criteria_columns].copy()
y_str = df_mcdm[target_column].values
le = LabelEncoder()
y = le.fit_transform(y_str)
X_normalized, norm_params = normalize_matrix(X, criteria_types)

model = GradientBoostingClassifier(n_estimators=100, random_state=42)
model.fit(X_normalized, y)
print(f"  Accuracy = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/user_behavior_raed.pkl')
joblib.dump(norm_params, 'trained_models/user_behavior_raed_norm.pkl')
classes = le.classes_.tolist()
joblib.dump(classes, 'trained_models/user_behavior_raed_classes.pkl')
print(f"  Classes: {classes}")
print("  Saved.")

# ─────────────────────────────────────────────────────
# 8. IoT Mental Health
# ─────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("8. IoT Mental Health - RandomForest (Regressor)")
print("=" * 60)
df = pd.read_csv('university_mental_health_iot_dataset.csv')
criteria_columns = ['temperature_celsius', 'humidity_percent', 'noise_level_db', 'lighting_lux']
target_column = 'stress_level'
criteria_types = {
    'temperature_celsius': 'cost',
    'humidity_percent': 'cost',
    'noise_level_db': 'cost',
    'lighting_lux': 'cost',
}
df_mcdm = df[criteria_columns + [target_column]].copy()
# Remove outliers using IQR (matching notebook)
Q1 = df_mcdm[criteria_columns].quantile(0.25)
Q3 = df_mcdm[criteria_columns].quantile(0.75)
IQR = Q3 - Q1
mask = ~((df_mcdm[criteria_columns] < (Q1 - 1.5 * IQR)) | (df_mcdm[criteria_columns] > (Q3 + 1.5 * IQR))).any(axis=1)
df_clean = df_mcdm[mask]
X = df_clean[criteria_columns].copy()
y = df_clean[target_column].values
X_normalized, norm_params = normalize_matrix(X, criteria_types)

model = RandomForestRegressor(n_estimators=100, random_state=42, n_jobs=-1)
model.fit(X_normalized, y)
print(f"  R² = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/iot_mental_health.pkl')
joblib.dump(norm_params, 'trained_models/iot_mental_health_norm.pkl')
print("  Saved.")

print("\n" + "=" * 60)
print("ALL MODELS TRAINED SUCCESSFULLY!")
print("=" * 60)
