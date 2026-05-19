/// Dataset Configuration Model
/// Defines all available datasets with their sensor configurations

import 'package:env_reading/models/sensor_config.dart';

class DatasetConfig {
  final String id;
  final String name;
  final String description;
  final String csvFileName;
  final String notebookName;
  final Map<String, SensorConfig> sensors; // Key: sensor ID, Value: SensorConfig
  final List<String> requiredSensorIds;

  DatasetConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.csvFileName,
    required this.notebookName,
    required this.sensors,
    required this.requiredSensorIds,
  });

  /// Get all available sensors
  List<SensorConfig> getAvailableSensors() {
    return sensors.values.where((s) => s.isAvailable).toList();
  }

  /// Get only required sensors
  List<SensorConfig> getRequiredSensors() {
    return sensors.values.where((s) => s.isRequired && s.isAvailable).toList();
  }

  /// Get sensor by ID
  SensorConfig? getSensor(String sensorId) => sensors[sensorId];

  @override
  String toString() => name;
}

/// Pre-defined Dataset Configurations from all MCDM notebooks
class DatasetRepository {
  static final Map<String, DatasetConfig> _datasets = {
    'iot_mental_health': _buildMentalHealthDataset(),
    'iot_air_quality': _buildAirQualityDataset(),
    'green_building': _buildGreenBuildingDataset(),
    'smart_library': _buildSmartLibraryDataset(),
    'occupancy': _buildOccupancyDataset(),
    'egg_production': _buildEggProductionDataset(),
    'herbal_plant': _buildHerbalPlantDataset(),
    'user_behavior': _buildUserBehaviorDataset(),
  };

  static List<DatasetConfig> getAllDatasets() => _datasets.values.toList();

  static DatasetConfig? getDataset(String id) => _datasets[id];

  static String getDefaultDatasetId() => 'iot_mental_health';

  // ==================== Dataset Builders ====================

  static DatasetConfig _buildMentalHealthDataset() {
    return DatasetConfig(
      id: 'iot_mental_health',
      name: '🏫 University Mental Health',
      description: 'IoT environmental monitoring in university buildings for mental health analysis',
      csvFileName: 'university_mental_health_iot_dataset.csv',
      notebookName: 'MCDM_IoT_University_Mental_Health_Analysis.ipynb',
      requiredSensorIds: ['temperature', 'humidity', 'noise', 'lighting'],
      sensors: {
        'temperature': SensorConfig(
          id: 'temperature',
          displayName: 'Temperature',
          unit: '°C',
          minValue: 15.0,
          maxValue: 30.0,
          meanValue: 22.5,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'humidity': SensorConfig(
          id: 'humidity',
          displayName: 'Humidity',
          unit: '%',
          minValue: 20.0,
          maxValue: 80.0,
          meanValue: 50.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'noise': SensorConfig(
          id: 'noise',
          displayName: 'Noise Level',
          unit: 'dB',
          minValue: 30.0,
          maxValue: 80.0,
          meanValue: 55.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'lighting': SensorConfig(
          id: 'lighting',
          displayName: 'Lighting',
          unit: 'lux',
          minValue: 100.0,
          maxValue: 1000.0,
          meanValue: 500.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
      },
    );
  }

  static DatasetConfig _buildAirQualityDataset() {
    return DatasetConfig(
      id: 'iot_air_quality',
      name: '💨 Indoor Air Quality',
      description: 'IoT air quality monitoring with temperature, humidity, CO2, and lighting',
      csvFileName: 'IoT_Indoor_Air_Quality_Dataset.csv',
      notebookName: 'MCDM_IoT_Air_Quality_Analysis.ipynb',
      requiredSensorIds: ['temperature', 'humidity', 'co2', 'lighting'],
      sensors: {
        'temperature': SensorConfig(
          id: 'temperature',
          displayName: 'Temperature',
          unit: '°C',
          minValue: 15.0,
          maxValue: 35.0,
          meanValue: 24.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'humidity': SensorConfig(
          id: 'humidity',
          displayName: 'Humidity',
          unit: '%',
          minValue: 20.0,
          maxValue: 80.0,
          meanValue: 50.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'co2': SensorConfig(
          id: 'co2',
          displayName: 'CO2 Level',
          unit: 'ppm',
          minValue: 300.0,
          maxValue: 2000.0,
          meanValue: 800.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'lighting': SensorConfig(
          id: 'lighting',
          displayName: 'Lighting',
          unit: 'lux',
          minValue: 100.0,
          maxValue: 1500.0,
          meanValue: 750.0,
          criteriaType: CriteriaType.profit,
          isRequired: true,
          isAvailable: true,
        ),
        'noise': SensorConfig(
          id: 'noise',
          displayName: 'Noise Level',
          unit: 'dB',
          minValue: 30.0,
          maxValue: 80.0,
          meanValue: 55.0,
          criteriaType: CriteriaType.cost,
          isRequired: false,
          isAvailable: false,
        ),
      },
    );
  }

  static DatasetConfig _buildGreenBuildingDataset() {
    return DatasetConfig(
      id: 'green_building',
      name: '🏢 Green Building',
      description: 'Sustainable building environmental monitoring',
      csvFileName: 'green_building_dataset.csv',
      notebookName: 'MCDM_Green_Building_Analysis.ipynb',
      requiredSensorIds: ['temperature', 'humidity', 'lighting', 'noise'],
      sensors: {
        'temperature': SensorConfig(
          id: 'temperature',
          displayName: 'Indoor Temperature',
          unit: '°C',
          minValue: 18.0,
          maxValue: 28.0,
          meanValue: 23.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'humidity': SensorConfig(
          id: 'humidity',
          displayName: 'Indoor Humidity',
          unit: '%',
          minValue: 25.0,
          maxValue: 75.0,
          meanValue: 50.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'lighting': SensorConfig(
          id: 'lighting',
          displayName: 'Indoor Lighting',
          unit: 'lux',
          minValue: 200.0,
          maxValue: 1200.0,
          meanValue: 700.0,
          criteriaType: CriteriaType.profit,
          isRequired: true,
          isAvailable: true,
        ),
        'noise': SensorConfig(
          id: 'noise',
          displayName: 'Indoor Noise',
          unit: 'dB',
          minValue: 35.0,
          maxValue: 75.0,
          meanValue: 55.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'co2': SensorConfig(
          id: 'co2',
          displayName: 'CO2 Level',
          unit: 'ppm',
          minValue: 300.0,
          maxValue: 1500.0,
          meanValue: 700.0,
          criteriaType: CriteriaType.cost,
          isRequired: false,
          isAvailable: false,
        ),
      },
    );
  }

  static DatasetConfig _buildSmartLibraryDataset() {
    return DatasetConfig(
      id: 'smart_library',
      name: '📚 Smart Library',
      description: 'Library environmental conditions with CO2 monitoring',
      csvFileName: 'Library_Indoor_IoT_Dataset_1.csv',
      notebookName: 'MCDM_Library_Analysis.ipynb',
      requiredSensorIds: ['temperature', 'humidity', 'co2', 'lighting', 'noise'],
      sensors: {
        'temperature': SensorConfig(
          id: 'temperature',
          displayName: 'Temperature',
          unit: '°C',
          minValue: 18.0,
          maxValue: 28.0,
          meanValue: 22.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'humidity': SensorConfig(
          id: 'humidity',
          displayName: 'Humidity',
          unit: '%',
          minValue: 30.0,
          maxValue: 70.0,
          meanValue: 50.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'co2': SensorConfig(
          id: 'co2',
          displayName: 'CO2 Level',
          unit: 'ppm',
          minValue: 350.0,
          maxValue: 1500.0,
          meanValue: 800.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'lighting': SensorConfig(
          id: 'lighting',
          displayName: 'Illuminance',
          unit: 'lux',
          minValue: 200.0,
          maxValue: 1000.0,
          meanValue: 600.0,
          criteriaType: CriteriaType.profit,
          isRequired: true,
          isAvailable: true,
        ),
        'noise': SensorConfig(
          id: 'noise',
          displayName: 'Noise Level',
          unit: 'dB',
          minValue: 40.0,
          maxValue: 70.0,
          meanValue: 55.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
      },
    );
  }

  static DatasetConfig _buildOccupancyDataset() {
    return DatasetConfig(
      id: 'occupancy',
      name: '👥 Building Occupancy',
      description: 'Occupancy levels with environmental and air quality sensors',
      csvFileName: 'Occupancy.csv',
      notebookName: 'MCDM_Occupancy_Analysis.ipynb',
      requiredSensorIds: ['temperature', 'humidity', 'lighting', 'co2'],
      sensors: {
        'temperature': SensorConfig(
          id: 'temperature',
          displayName: 'Temperature',
          unit: '°C',
          minValue: 19.0,
          maxValue: 27.0,
          meanValue: 23.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'humidity': SensorConfig(
          id: 'humidity',
          displayName: 'Humidity',
          unit: '%',
          minValue: 25.0,
          maxValue: 75.0,
          meanValue: 50.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'lighting': SensorConfig(
          id: 'lighting',
          displayName: 'Light Level',
          unit: 'lux',
          minValue: 0.0,
          maxValue: 1500.0,
          meanValue: 500.0,
          criteriaType: CriteriaType.profit,
          isRequired: true,
          isAvailable: true,
        ),
        'co2': SensorConfig(
          id: 'co2',
          displayName: 'CO2 Level',
          unit: 'ppm',
          minValue: 300.0,
          maxValue: 2000.0,
          meanValue: 800.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'noise': SensorConfig(
          id: 'noise',
          displayName: 'Noise Level',
          unit: 'dB',
          minValue: 30.0,
          maxValue: 80.0,
          meanValue: 55.0,
          criteriaType: CriteriaType.cost,
          isRequired: false,
          isAvailable: false,
        ),
      },
    );
  }

  static DatasetConfig _buildEggProductionDataset() {
    return DatasetConfig(
      id: 'egg_production',
      name: '🐔 Egg Production',
      description: 'Environmental monitoring for poultry farming and egg production',
      csvFileName: 'Egg_Production.csv',
      notebookName: 'MCDM_Egg_Production_Analysis.ipynb',
      requiredSensorIds: ['temperature', 'humidity', 'lighting'],
      sensors: {
        'temperature': SensorConfig(
          id: 'temperature',
          displayName: 'Temperature',
          unit: '°C',
          minValue: 10.0,
          maxValue: 35.0,
          meanValue: 22.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'humidity': SensorConfig(
          id: 'humidity',
          displayName: 'Humidity',
          unit: '%',
          minValue: 20.0,
          maxValue: 80.0,
          meanValue: 50.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'lighting': SensorConfig(
          id: 'lighting',
          displayName: 'Lighting',
          unit: 'lux',
          minValue: 0.0,
          maxValue: 500.0,
          meanValue: 250.0,
          criteriaType: CriteriaType.profit,
          isRequired: true,
          isAvailable: true,
        ),
        'noise': SensorConfig(
          id: 'noise',
          displayName: 'Noise Level',
          unit: 'dB',
          minValue: 30.0,
          maxValue: 80.0,
          meanValue: 55.0,
          criteriaType: CriteriaType.cost,
          isRequired: false,
          isAvailable: false,
        ),
        'co2': SensorConfig(
          id: 'co2',
          displayName: 'CO2 Level',
          unit: 'ppm',
          minValue: 300.0,
          maxValue: 2000.0,
          meanValue: 800.0,
          criteriaType: CriteriaType.cost,
          isRequired: false,
          isAvailable: false,
        ),
      },
    );
  }

  static DatasetConfig _buildHerbalPlantDataset() {
    return DatasetConfig(
      id: 'herbal_plant',
      name: '🌿 Herbal Plant Health',
      description: 'Sensor monitoring for herbal plant cultivation',
      csvFileName: 'herbal_plant_sensor_data.csv',
      notebookName: 'MCDM_Herbal_Plant_Analysis.ipynb',
      requiredSensorIds: ['soil_moisture', 'humidity', 'temperature', 'lighting'],
      sensors: {
        'temperature': SensorConfig(
          id: 'temperature',
          displayName: 'Temperature',
          unit: '°C',
          minValue: 15.0,
          maxValue: 30.0,
          meanValue: 22.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'humidity': SensorConfig(
          id: 'humidity',
          displayName: 'Humidity',
          unit: '%',
          minValue: 30.0,
          maxValue: 80.0,
          meanValue: 55.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'soil_moisture': SensorConfig(
          id: 'soil_moisture',
          displayName: 'Soil Moisture',
          unit: '%',
          minValue: 20.0,
          maxValue: 80.0,
          meanValue: 50.0,
          criteriaType: CriteriaType.profit,
          isRequired: true,
          isAvailable: true,
        ),
        'lighting': SensorConfig(
          id: 'lighting',
          displayName: 'Light Intensity',
          unit: 'lux',
          minValue: 100.0,
          maxValue: 1000.0,
          meanValue: 500.0,
          criteriaType: CriteriaType.profit,
          isRequired: true,
          isAvailable: true,
        ),
        'co2': SensorConfig(
          id: 'co2',
          displayName: 'CO2 Level',
          unit: 'ppm',
          minValue: 300.0,
          maxValue: 2000.0,
          meanValue: 800.0,
          criteriaType: CriteriaType.cost,
          isRequired: false,
          isAvailable: false,
        ),
        'noise': SensorConfig(
          id: 'noise',
          displayName: 'Noise Level',
          unit: 'dB',
          minValue: 30.0,
          maxValue: 80.0,
          meanValue: 55.0,
          criteriaType: CriteriaType.cost,
          isRequired: false,
          isAvailable: false,
        ),
      },
    );
  }

  static DatasetConfig _buildUserBehaviorDataset() {
    return DatasetConfig(
      id: 'user_behavior',
      name: '👤 User Behavior (RAED)',
      description: 'User behavior analysis with environmental sensors and motion detection',
      csvFileName: 'RAED.csv',
      notebookName: 'MCDM_RAED_Analysis.ipynb',
      requiredSensorIds: ['temperature', 'humidity', 'noise', 'lighting', 'motion'],
      sensors: {
        'temperature': SensorConfig(
          id: 'temperature',
          displayName: 'Temperature',
          unit: '°C',
          minValue: 15.0,
          maxValue: 30.0,
          meanValue: 22.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'humidity': SensorConfig(
          id: 'humidity',
          displayName: 'Humidity',
          unit: '%',
          minValue: 20.0,
          maxValue: 80.0,
          meanValue: 50.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'noise': SensorConfig(
          id: 'noise',
          displayName: 'Noise Level',
          unit: 'dB',
          minValue: 30.0,
          maxValue: 80.0,
          meanValue: 55.0,
          criteriaType: CriteriaType.cost,
          isRequired: true,
          isAvailable: true,
        ),
        'lighting': SensorConfig(
          id: 'lighting',
          displayName: 'Light Intensity',
          unit: 'lux',
          minValue: 100.0,
          maxValue: 1000.0,
          meanValue: 500.0,
          criteriaType: CriteriaType.profit,
          isRequired: true,
          isAvailable: true,
        ),
        'motion': SensorConfig(
          id: 'motion',
          displayName: 'Motion Level',
          unit: 'Activity',
          minValue: 0.0,
          maxValue: 100.0,
          meanValue: 50.0,
          criteriaType: CriteriaType.profit,
          isRequired: true,
          isAvailable: true,
        ),
        'co2': SensorConfig(
          id: 'co2',
          displayName: 'CO2 Level',
          unit: 'ppm',
          minValue: 300.0,
          maxValue: 2000.0,
          meanValue: 800.0,
          criteriaType: CriteriaType.cost,
          isRequired: false,
          isAvailable: false,
        ),
      },
    );
  }
}
