# MCDM Analysis Strategy for All IoT Datasets

## 📊 Dataset Analysis & Prediction Targets

### 1. ✅ University Mental Health (DONE)
**Columns**: temperature_celsius, humidity_percent, noise_level_db, lighting_lux
**Predict**: sleep_hours, stress_level
**Why**: Mental health directly correlates with environmental comfort. These 4 sensors create optimal settings (temperature 20-24°C, moderate humidity, low noise, adequate light)

---

### 2. 🏢 Green Building Dataset
**Sensors**: indoor_temperature, indoor_humidity, co2_concentration, indoor_lighting, indoor_noise + outdoor factors
**Available Targets**: predicted_energy_demand, predicted_comfort_index

**PREDICT: Energy Consumption (electricity_consumption + heating_energy + cooling_energy)**

**Why**:
- Green buildings focus on energy optimization
- More sensors = better prediction (temp, humidity, CO2, lighting, noise all affect HVAC load)
- Direct business value: energy savings = cost reduction
- MCDM evaluates building zones by energy efficiency score

**Key Criteria**: indoor_temp (cost), humidity (cost), CO2 (cost), lighting (cost), noise (cost)
- All are "cost" because excess = wasted energy

---

### 3. 🌱 Herbal Plant Sensor Data
**Columns**: Soil_Moisture, Humidity, Temperature, Light_Intensity, PHI (Plant Health Index), APHI, Label
**Available Targets**: Label (0/1 - healthy/unhealthy), PHI, APHI

**PREDICT: Plant Health Status (Label) - Binary Classification (Healthy=1, Unhealthy=0)**

**Why**:
- Indoor farming of herbs is growing (culinary, medicinal uses)
- Early disease/stress detection prevents crop loss
- These 4 sensors are optimal for plant health monitoring
- PHI/APHI already provide health indices - use them to validate predictions
- MCDM ranks locations by plant health score

**Key Criteria**: Soil_Moisture (profit ↑), Humidity (cost ↓ extremes), Temperature (cost ↓ extremes), Light_Intensity (profit ↑)
- Soil moisture: more is generally better for plants
- Light intensity: more light = better photosynthesis (profit)

---

### 4. 🌾 Smart Farming Crop Yield 2024
**Sensors**: soil_moisture, soil_pH, temperature, rainfall, humidity, sunlight_hours, NDVI_index
**Available Targets**: yield_kg_per_hectare, crop_disease_status

**PREDICT: Crop Yield (kg/hectare) - Regression**

**Why**:
- Farmers need yield predictions for planning/financing
- More sensor data = more accurate forecasting
- NDVI (vegetation index) + environmental factors = excellent yield predictor
- Different crop types (wheat, soybean, maize) have different optimal ranges

**Key Criteria**: soil_moisture (profit ↑), soil_pH (target range ~6-7, cost), temperature (target crop-specific), rainfall (profit ↑), sunlight_hours (profit ↑)

---

### 5. 📚 Library Indoor IoT Dataset
**Columns**: Temperature, Humidity, CO2, Illuminance, Noise, Occupancy, PM2.5, VOC, HVAC_Setpoint, Ventilation_Level, Lighting_Level
**Available Target**: Overall_Environment_State (Optimal, Sub-Optimal, Critical)

**PREDICT: Environment State Classification (Optimal/Sub-Optimal/Critical)**

**Why**:
- Libraries are knowledge spaces - environment affects study/work performance
- Multi-zone monitoring (Stack Area, Reading Hall, Discussion Zone)
- Optimal conditions vary by zone and occupancy
- MCDM helps identify which zones have best environmental scores

**Key Criteria**: Temperature (cost - extreme), Humidity (cost - extremes), CO2 (cost ↓), Noise (cost ↓), PM2.5 (cost ↓)
- All represent air quality and comfort

---

### 6. 🏢 IoT Indoor Air Quality Dataset
**Columns**: Temperature, Humidity, CO2, PM2.5, PM10, TVOC, CO, Light_Intensity, Occupancy_Count, Ventilation_Status
**Available Target**: IMPLIED - Air quality classification (good/moderate/poor based on pollutants)

**PREDICT: Occupancy Count Estimation - Regression**

**Why**:
- CO2 and particle levels are directly tied to occupancy
- More people = more CO2 + VOCs + body heat
- Facility managers need to know occupancy for HVAC/lighting optimization
- Alternative: Predict air quality category directly

**Key Criteria**: CO2 (cost ↓), PM2.5 (cost ↓), PM10 (cost ↓), TVOC (cost ↓)

---

### 7. 🪑 Occupancy Dataset (Simple)
**Columns**: Temperature, Humidity, Light, CO2, HumidityRatio
**Available Target**: Occupancy (binary 0/1)

**PREDICT: Room Occupancy - Binary Classification**

**Why**:
- Simplest IoT use case - detect if room is occupied
- Enables smart HVAC/lighting (reduce energy if unoccupied)
- Good baseline MCDM for sensor evaluation
- 5 sensors suffice for occupancy detection

**Key Criteria**: Temperature (cost), Humidity (cost), Light (cost), CO2 (profit ↑ - more CO2 = occupied)

---

### 8. 😊 RAED Dataset (Behavior/Emotions)
**Columns**: location, behaviour, temperature, humidity, noise_db, light_intensity, motion_level
**Available Target**: behaviour (stressed, walking, sleeping, eating, calm, etc.)

**PREDICT: Human Behavior/Emotional State Classification**

**Why**:
- Behavioral IoT combines wearables + ambient sensors
- Predicting stress/activity helps with health monitoring
- Use case: workplace wellness, campus mental health, smart homes
- Location context matters (campus vs bedroom behavior differs)

**Key Criteria**: noise_db (cost ↓), temperature (cost), humidity (cost), light_intensity (cost), motion_level (varies by behavior)

---

## 🔧 Handling Missing Sensors

| Dataset | Missing from 4-sensor baseline | Default Value | Reasoning |
|---------|-------------------------------|---------------|-----------|
| Green Building | ✓ Has all + more | N/A | Use all available sensors |
| Herbal Plant | ✓ Has all 4 | N/A | Perfect match to template |
| Farming | Noise | 40-50 dB | Assume quiet farm environment |
| Library | ✓ Has all + more | N/A | Use core 4 (temp, humidity, CO2, noise) |
| Air Quality | No noise data | 45 dB | Assume library/indoor baseline |
| Occupancy | ✓ Has all 4 | N/A | Perfect match |
| RAED | Missing standard 4 | Use available | Temperature, humidity, noise, light available |

---

## 📋 Summary Table

| # | Dataset | Sensors Used | Predict | Type | Business Value |
|---|---------|--------------|---------|------|-----------------|
| 1 | University Mental Health | 4 standard | Sleep/Stress | Regression | Health/Wellness |
| 2 | Green Building | 5+ | Energy Use | Regression | Cost Savings |
| 3 | Herbal Plant | 4 optimal | Health Status | Classification | Crop Quality |
| 4 | Farming | 5 | Crop Yield | Regression | Revenue Planning |
| 5 | Library | 5 core | Environment State | Classification | User Experience |
| 6 | Air Quality | 4 pollutants | Occupancy | Regression | HVAC Control |
| 7 | Occupancy | 4 standard | Occupancy | Classification | Energy Savings |
| 8 | RAED | 5 behavioral | Behavior/Stress | Classification | Health Monitoring |

---

## 🚀 Next Steps
1. Create MCDM notebook for Herbal Plant (complete template)
2. Create for Green Building (energy focus)
3. Create for Farming (crop yield)
4. Create for Library (environment state)
5. Create for Occupancy (simple baseline)
6. Create for RAED (behavioral analytics)
7. Optional: Air Quality & IoT Air Quality notebooks
