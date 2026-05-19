import pandas as pd
import numpy as np
import joblib
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.preprocessing import LabelEncoder

np.random.seed(42)

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

# ── Building Occupancy (compact RF) ──
print("Building Occupancy - Compact RF")
df = pd.read_csv('Occupancy.csv')
criteria_columns = ['Temperature', 'Humidity', 'Light', 'CO2', 'HumidityRatio']
target_column = 'Occupancy'
criteria_types = {'Temperature': 'cost', 'Humidity': 'cost', 'Light': 'profit', 'CO2': 'cost', 'HumidityRatio': 'cost'}
X = df[criteria_columns].copy()
y = df[target_column].values
X_normalized, norm_params = normalize_matrix(X, criteria_types)
model = RandomForestClassifier(n_estimators=20, max_depth=8, random_state=42, n_jobs=-1)
model.fit(X_normalized, y)
print(f"  Accuracy = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/building_occupancy.pkl')
joblib.dump(norm_params, 'trained_models/building_occupancy_norm.pkl')
classes = ['Absent', 'Present']
joblib.dump(classes, 'trained_models/building_occupancy_classes.pkl')
print("  Saved.")

# ── User Behavior RAED (RF instead of GB) ──
print("\nUser Behavior RAED - RF (GB not supported by m2cgen)")
df = pd.read_csv('RAED.csv')
criteria_columns = ['temperature', 'humidity', 'noise_db', 'light_intensity', 'motion_level']
target_column = 'behaviour'
criteria_types = {'temperature': 'cost', 'humidity': 'cost', 'noise_db': 'cost', 'light_intensity': 'profit', 'motion_level': 'profit'}
df_mcdm = df[criteria_columns + [target_column]].dropna()
X = df_mcdm[criteria_columns].copy()
y_str = df_mcdm[target_column].values
le = LabelEncoder()
y = le.fit_transform(y_str)
X_normalized, norm_params = normalize_matrix(X, criteria_types)
model = RandomForestClassifier(n_estimators=10, max_depth=8, random_state=42, n_jobs=-1)
model.fit(X_normalized, y)
print(f"  Accuracy = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/user_behavior_raed.pkl')
joblib.dump(norm_params, 'trained_models/user_behavior_raed_norm.pkl')
classes = le.classes_.tolist()
joblib.dump(classes, 'trained_models/user_behavior_raed_classes.pkl')
print(f"  Classes: {classes}")
print("  Saved.")

# ── IoT Mental Health (compact RF) ──
print("\nIoT Mental Health - Compact RF")
df = pd.read_csv('university_mental_health_iot_dataset.csv')
criteria_columns = ['temperature_celsius', 'humidity_percent', 'noise_level_db', 'lighting_lux']
target_column = 'stress_level'
criteria_types = {'temperature_celsius': 'cost', 'humidity_percent': 'cost', 'noise_level_db': 'cost', 'lighting_lux': 'cost'}
df_mcdm = df[criteria_columns + [target_column]].copy()
Q1 = df_mcdm[criteria_columns].quantile(0.25)
Q3 = df_mcdm[criteria_columns].quantile(0.75)
IQR = Q3 - Q1
mask = ~((df_mcdm[criteria_columns] < (Q1 - 1.5 * IQR)) | (df_mcdm[criteria_columns] > (Q3 + 1.5 * IQR))).any(axis=1)
df_clean = df_mcdm[mask]
X = df_clean[criteria_columns].copy()
y = df_clean[target_column].values
X_normalized, norm_params = normalize_matrix(X, criteria_types)
model = RandomForestRegressor(n_estimators=20, max_depth=10, random_state=42, n_jobs=-1)
model.fit(X_normalized, y)
print(f"  R² = {model.score(X_normalized, y):.4f}")
joblib.dump(model, 'trained_models/iot_mental_health.pkl')
joblib.dump(norm_params, 'trained_models/iot_mental_health_norm.pkl')
print("  Saved.")

print("\nDone! All compact models saved.")
