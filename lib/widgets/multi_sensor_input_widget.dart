import 'package:flutter/material.dart';
import 'package:env_reading/models/sensor_config.dart';
import 'package:env_reading/models/sensor_readings.dart';
import 'package:env_reading/models/dataset_config.dart';

/// Multi-Sensor Input Widget
/// Allows switching between Firebase and manual sensor input modes
/// Displays all sensors with their ranges and allows manual value editing
class MultiSensorInputWidget extends StatefulWidget {
  final DatasetConfig dataset;
  final SensorReadings initialReadings;
  final Function(SensorReadings) onReadingsChanged;
  final bool isFirebaseConnected;

  const MultiSensorInputWidget({
    Key? key,
    required this.dataset,
    required this.initialReadings,
    required this.onReadingsChanged,
    this.isFirebaseConnected = true,
  }) : super(key: key);

  @override
  State<MultiSensorInputWidget> createState() => _MultiSensorInputWidgetState();
}

class _MultiSensorInputWidgetState extends State<MultiSensorInputWidget> {
  late SensorReadings currentReadings;
  late InputMode currentInputMode;

  @override
  void initState() {
    super.initState();
    currentReadings = widget.initialReadings;
    currentInputMode = widget.initialReadings.inputMode;
  }

  void _updateInputMode(InputMode newMode) {
    setState(() {
      currentInputMode = newMode;
      currentReadings = currentReadings.copyWith(inputMode: newMode);
      widget.onReadingsChanged(currentReadings);
    });
  }

  void _updateSensorValue(String sensorId, double? value) {
    setState(() {
      currentReadings.setValue(sensorId, value);
      widget.onReadingsChanged(currentReadings);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sensor Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(widget.dataset.name),
                  avatar: const Icon(Icons.sensors),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Input Mode Toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Firebase Mode
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.isFirebaseConnected
                          ? () => _updateInputMode(InputMode.firebase)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: currentInputMode == InputMode.firebase
                              ? Colors.blue.shade50
                              : Colors.transparent,
                          border: currentInputMode == InputMode.firebase
                              ? Border(
                                  right: BorderSide(
                                    color: Colors.blue,
                                    width: 3,
                                  ),
                                )
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud,
                              color: widget.isFirebaseConnected
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Firebase',
                              style: TextStyle(
                                fontWeight: currentInputMode == InputMode.firebase
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: widget.isFirebaseConnected
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Manual Mode
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateInputMode(InputMode.manual),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: currentInputMode == InputMode.manual
                              ? Colors.green.shade50
                              : Colors.transparent,
                          border: currentInputMode == InputMode.manual
                              ? Border(
                                  right: BorderSide(
                                    color: Colors.green,
                                    width: 3,
                                  ),
                                )
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manual',
                              style: TextStyle(
                                fontWeight:
                                    currentInputMode == InputMode.manual
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sensors List
            if (currentInputMode == InputMode.manual)
              ..._buildManualSensorInputs()
            else
              _buildFirebaseStatus(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildManualSensorInputs() {
    final sensors = widget.dataset.getAvailableSensors();
    return [
      Text(
        'Edit Sensor Values (Min - Max)',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
      const SizedBox(height: 12),
      ...sensors.map((sensor) => _buildSensorInput(sensor)).toList(),
    ];
  }

  Widget _buildSensorInput(SensorConfig sensor) {
    final currentValue = currentReadings.getValue(sensor.id) ?? sensor.meanValue;
    final normalizedValue = sensor.normalize(currentValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name, unit, and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${sensor.minValue.toStringAsFixed(1)} - ${sensor.maxValue.toStringAsFixed(1)} ${sensor.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(sensor.getColor(normalizedValue)).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Color(sensor.getColor(normalizedValue)),
                  ),
                ),
                child: Text(
                  sensor.getStatus(normalizedValue),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(sensor.getColor(normalizedValue)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Slider
          Slider(
            value: currentValue.clamp(sensor.minValue, sensor.maxValue),
            min: sensor.minValue,
            max: sensor.maxValue,
            divisions: 50,
            activeColor: Color(sensor.getColor(normalizedValue)),
            label: currentValue.toStringAsFixed(1),
            onChanged: (value) => _updateSensorValue(sensor.id, value),
          ),

          // Statistics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Min', sensor.minValue.toStringAsFixed(1), Colors.blue),
              _buildStatItem(
                'Mean',
                sensor.meanValue.toStringAsFixed(1),
                Colors.orange,
              ),
              _buildStatItem(
                'Current',
                currentValue.toStringAsFixed(1),
                Colors.green,
              ),
              _buildStatItem('Max', sensor.maxValue.toStringAsFixed(1), Colors.red),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFirebaseStatus() {
    final sensors = widget.dataset.getAvailableSensors();
    final missingCount =
        sensors.where((s) => currentReadings.getValue(s.id) == null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (missingCount == 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All sensors connected to Firebase',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$missingCount sensor(s) not yet connected',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected Sensors:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...sensors.map((sensor) {
                final value = currentReadings.getValue(sensor.id);
                final isConnected = value != null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: isConnected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isConnected
                            ? '${sensor.displayName}: ${value.toStringAsFixed(1)} ${sensor.unit}'
                            : '${sensor.displayName}: Waiting...',
                        style: TextStyle(
                          fontSize: 13,
                          color: isConnected ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
