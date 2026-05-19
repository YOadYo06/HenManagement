# MCDM Jupyter Notebooks - Data Extraction Results

Extracted from all 8 MCDM analysis notebooks for Flutter app configuration.

---

## 1. IoT University Mental Health Analysis

**Dataset:** `university_mental_health_iot_dataset.csv`  
**Sensors:** 4 criteria  
**Target Prediction:** Sleep Hours and Stress Level

### Sensors/Criteria
- `temperature_celsius` (COST - lower is better)
- `humidity_percent` (COST - lower is better)
- `noise_level_db` (COST - lower is better)
- `lighting_lux` (COST - lower is better)

### Statistics (Min/Max/Mean)
| Sensor | Min | Max | Mean |
|--------|-----|-----|------|
| temperature_celsius | 15.2359 | 33.5793 | 24.2085 |
| humidity_percent | 29.8049 | 91.3775 | 60.1893 |
| noise_level_db | 24.5407 | 85.9264 | 54.7224 |
| lighting_lux | 155.2221 | 502.6275 | 301.5004 |

### Calculated Weights

#### STD Method
- temperature_celsius: 0.2543
- humidity_percent: 0.2548
- noise_level_db: 0.3155
- lighting_lux: 0.1754

#### Entropy Method
- temperature_celsius: 0.2509
- humidity_percent: 0.2921
- noise_level_db: 0.2983
- lighting_lux: 0.1587

#### CRITIC Method
- temperature_celsius: 0.3025
- humidity_percent: 0.3193
- noise_level_db: 0.2871
- lighting_lux: 0.0911

#### MEREC Method
- temperature_celsius: 0.2673
- humidity_percent: 0.3220
- noise_level_db: 0.3319
- lighting_lux: 0.0788

#### **Compromise (Average) - PRIMARY USE**
- temperature_celsius: **0.2683**
- humidity_percent: **0.2769**
- noise_level_db: **0.3078**
- lighting_lux: **0.1469**

---

## 2. IoT Air Quality Analysis (Occupancy Prediction)

**Dataset:** `IoT_Indoor_Air_Quality_Dataset.csv`  
**Sensors:** 4 criteria  
**Target Prediction:** Occupancy Count (Regression)  
**Data Points:** 97,458

### Sensors/Criteria
- `Temperature (?C)` (COST)
- `Humidity (%)` (COST)
- `CO2 (ppm)` (COST)
- `Light Intensity (lux)` (PROFIT - higher is better)

### Statistics (Min/Max/Mean)
| Sensor | Min | Max | Mean |
|--------|-----|-----|------|
| Temperature (?C) | 18.0000 | 28.0000 | 22.9966 |
| Humidity (%) | 30.0000 | 70.0000 | 50.0332 |
| CO2 (ppm) | 400.0000 | 999.9900 | 700.5109 |
| Light Intensity (lux) | 100.0400 | 999.9900 | 550.5081 |

### Calculated Weights

#### **Compromise (Average) - PRIMARY USE**
- Temperature (?C): **0.1871**
- Humidity (%): **0.2830**
- CO2 (ppm): **0.3278**
- Light Intensity (lux): **0.2021**

---

## 3. Green Building Energy Management

**Dataset:** `green_building_dataset.csv`  
**Sensors:** 4 criteria  
**Target Prediction:** Electricity Consumption (Regression)  
**Data Points:** 2,400

### Sensors/Criteria
- `indoor_temperature` (COST)
- `indoor_humidity` (COST)
- `indoor_lighting` (PROFIT)
- `indoor_noise` (COST)

### Statistics (Min/Max/Mean)
| Sensor | Min | Max | Mean |
|--------|-----|-----|------|
| indoor_temperature | 18.0188 | 29.9966 | 23.9839 |
| indoor_humidity | 30.0005 | 69.9823 | 49.7907 |
| indoor_lighting | 100.0475 | 999.0142 | 537.9388 |
| indoor_noise | 30.0079 | 79.9837 | 55.1571 |

### Calculated Weights

#### **Compromise (Average) - PRIMARY USE**
- indoor_temperature: **0.2154**
- indoor_humidity: **0.1988**
- indoor_lighting: **0.3219**
- indoor_noise: **0.2638**

---

## 4. Smart Library Environment Classification

**Dataset:** `Library_Indoor_IoT_Dataset_1.csv`  
**Sensors:** 5 criteria  
**Target Prediction:** Environment State (Optimal/Sub-Optimal/Critical) - Classification  
**Data Points:** 2,745

### Sensors/Criteria
- `Temperature_C` (COST)
- `Humidity_%` (COST)
- `CO2_ppm` (COST)
- `Illuminance_lux` (PROFIT)
- `Noise_dB` (COST)

### Statistics (Min/Max/Mean)
| Sensor | Min | Max | Mean |
|--------|-----|-----|------|
| Temperature_C | 18.0000 | 30.0000 | 23.8698 |
| Humidity_% | 30.0500 | 69.9900 | 50.2326 |
| CO2_ppm | 400.0000 | 1599.0000 | 1014.3847 |
| Illuminance_lux | 100.0000 | 798.0000 | 444.3428 |
| Noise_dB | 30.0100 | 70.0000 | 49.9803 |

### Calculated Weights

#### **Compromise (Average) - PRIMARY USE**
- Temperature_C: **0.1496**
- Humidity_%: **0.1866**
- CO2_ppm: **0.2315**
- Illuminance_lux: **0.2361**
- Noise_dB: **0.1962**

---

## 5. Building Occupancy Detection

**Dataset:** `Occupancy.csv`  
**Sensors:** 5 criteria  
**Target Prediction:** Room Occupancy (Present/Absent) - Classification  
**Data Points:** 20,560

### Sensors/Criteria
- `Temperature` (COST)
- `Humidity` (COST)
- `Light` (PROFIT)
- `CO2` (COST)
- `HumidityRatio` (COST)

### Statistics (Min/Max/Mean)
| Sensor | Min | Max | Mean |
|--------|-----|-----|------|
| Temperature | 19.0000 | 24.4083 | 20.9062 |
| Humidity | 16.7450 | 39.5000 | 27.6559 |
| Light | 0.0000 | 1697.2500 | 130.7566 |
| CO2 | 412.7500 | 2076.5000 | 690.5533 |
| HumidityRatio | 0.0027 | 0.0065 | 0.0042 |

### Calculated Weights

#### **Compromise (Average) - PRIMARY USE**
- Temperature: **0.1453**
- Humidity: **0.1834**
- Light: **0.3904**
- CO2: **0.1094**
- HumidityRatio: **0.1716**

---

## 6. Herbal Plant Health Monitoring

**Dataset:** `herbal_plant_sensor_data.csv`  
**Sensors:** 4 criteria  
**Target Prediction:** Plant Health Status (Healthy/Unhealthy) - Classification  
**Data Points:** 500

### Sensors/Criteria
- `Soil_Moisture` (PROFIT - higher is better for plants)
- `Humidity` (COST - optimal range 40-60%)
- `Temperature` (COST - optimal range 18-24°C)
- `Light_Intensity` (PROFIT - more light = better)

### Statistics (Min/Max/Mean)
| Sensor | Min | Max | Mean |
|--------|-----|-----|------|
| Soil_Moisture | 20.3037 | 79.5779 | 49.9137 |
| Humidity | 30.2779 | 89.9831 | 58.9171 |
| Temperature | 15.1235 | 39.9853 | 27.9390 |
| Light_Intensity | 203.2183 | 1198.3475 | 696.4765 |

### Calculated Weights

#### **Compromise (Average) - PRIMARY USE**
- Soil_Moisture: **0.2859**
- Humidity: **0.1561**
- Temperature: **0.3374**
- Light_Intensity: **0.2205**

---

## 7. User Behavior & Activity Recognition (RAED)

**Dataset:** `RAED.csv`  
**Sensors:** 5 criteria  
**Target Prediction:** Behavior Classification (Stressed/Walking/Sleeping/Eating)  
**Data Points:** 30,000

### Sensors/Criteria
- `temperature` (COST)
- `humidity` (COST)
- `noise_db` (COST)
- `light_intensity` (PROFIT)
- `motion_level` (PROFIT)

### Statistics (Min/Max/Mean)
| Sensor | Min | Max | Mean |
|--------|-----|-----|------|
| temperature | 18.3600 | 39.2200 | 28.5890 |
| humidity | 34.7400 | 100.5400 | 63.4177 |
| noise_db | 3.3782 | 124.1371 | 59.7503 |
| light_intensity | -20.5502 | 973.1442 | 467.2676 |
| motion_level | -4.3600 | 14.5700 | 4.3964 |

### Calculated Weights

#### **Compromise (Average) - PRIMARY USE**
- temperature: **0.1827**
- humidity: **0.1182**
- noise_db: **0.1978**
- light_intensity: **0.2825**
- motion_level: **0.2189**

---

## Prediction Models Found in Notebooks

### IoT University Mental Health
- **Sleep Hours Prediction:** Linear Regression, Random Forest, Gradient Boosting, MLP
- **Stress Level Prediction:** Linear Regression, Random Forest, Gradient Boosting, MLP

### IoT Air Quality
- **Occupancy Count:** Linear Regression, Random Forest Regressor, Gradient Boosting Regressor, MLP Regressor

### Green Building
- **Electricity Consumption:** Linear Regression, Random Forest Regressor, Gradient Boosting Regressor, MLP Regressor

### Smart Library
- **Environment Classification:** Logistic Regression, Random Forest Classifier, Gradient Boosting Classifier, MLP Classifier

### Building Occupancy
- **Occupancy Detection:** Logistic Regression, Random Forest Classifier, Gradient Boosting Classifier, MLP Classifier

### Herbal Plant Health
- **Plant Health Status:** Logistic Regression, Random Forest Classifier, Gradient Boosting Classifier, MLP Classifier

### User Behavior (RAED)
- **Behavior Classification:** Logistic Regression, Random Forest Classifier, Gradient Boosting Classifier, MLP Classifier

---

## Summary Table - Compromise Weights

```
Dataset                          | Criteria Count | Primary Sensors
---------------------------------|----------------|--------------------------------------------------
IoT University Mental Health     | 4              | Temp, Humidity, Noise, Light
IoT Air Quality                  | 4              | Temp, Humidity, CO2, Light
Green Building                   | 4              | Temp, Humidity, Lighting, Noise
Smart Library                    | 5              | Temp, Humidity, CO2, Illuminance, Noise
Building Occupancy               | 5              | Temp, Humidity, Light, CO2, HumidityRatio
Herbal Plant Health              | 4              | Moisture, Humidity, Temp, Light
User Behavior (RAED)             | 5              | Temp, Humidity, Noise, Light, Motion
```

---

## Flutter App Configuration Template

```json
{
  "datasets": [
    {
      "id": "iot_mental_health",
      "name": "IoT University Mental Health",
      "description": "Mental health monitoring through environmental sensors",
      "sensors": [
        {
          "name": "temperature_celsius",
          "displayName": "Temperature (°C)",
          "type": "COST",
          "min": 15.24,
          "max": 33.58,
          "mean": 24.21,
          "weight": 0.2683
        },
        ...
      ],
      "weights": {
        "STD": {...},
        "Entropy": {...},
        "CRITIC": {...},
        "MEREC": {...},
        "Compromise": {
          "temperature_celsius": 0.2683,
          "humidity_percent": 0.2769,
          "noise_level_db": 0.3078,
          "lighting_lux": 0.1469
        }
      }
    },
    ...
  ]
}
```

---

## Key Findings

1. **Most Important Sensors Across Datasets:**
   - **Noise/Behavior:** Noise is heavily weighted in mental health (0.3078) and occupancy (0.1094)
   - **Light/Illumination:** Consistently important for building environments and plant health (0.22-0.39)
   - **CO2/Air Quality:** Significant in air quality (0.3278) and library environments (0.2315)
   - **Temperature:** Important baseline in all datasets (0.14-0.27)

2. **Weight Method Variations:**
   - STD Method: Focuses on data variability
   - Entropy Method: Accounts for data distribution
   - CRITIC Method: Considers correlation between criteria
   - MEREC Method: Uses removal effects
   - **Compromise:** Average of all methods provides balanced perspective

3. **Prediction Types:**
   - **Regression Models:** Air Quality (Occupancy Count), Green Building (Energy)
   - **Classification Models:** Library (State), Occupancy (Present/Absent), Plant Health, Behavior

4. **Data Quality:**
   - All datasets properly normalized to [0, 1] range
   - COST criteria: Lower values are better (inverted normalization)
   - PROFIT criteria: Higher values are better (standard normalization)

