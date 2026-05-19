import 'package:flutter/material.dart';
import 'package:env_reading/models/live_metric.dart';
import 'package:env_reading/services/precalculated_mcdm_calculator.dart';

/// Metric Editor Widget
/// Allows users to:
/// 1. Choose between dataset sensors or custom values
/// 2. Select min/max/mean or enter custom value
/// 3. Calculate MCDM score in real-time
class MetricEditorWidget extends StatefulWidget {
  final LiveMetricDataset dataset;
  final String weightMethod;
  final ValueChanged<LiveMetric>? onMetricChanged;

  const MetricEditorWidget({
    Key? key,
    required this.dataset,
    this.weightMethod = 'Compromise',
    this.onMetricChanged,
  }) : super(key: key);

  @override
  State<MetricEditorWidget> createState() => _MetricEditorWidgetState();
}

class _MetricEditorWidgetState extends State<MetricEditorWidget> {
  late Map<String, _SensorEditState> sensorStates;
  late LiveMetric currentMetric;

  @override
  void initState() {
    super.initState();
    _initializeSensorStates();
  }

  void _initializeSensorStates() {
    sensorStates = {};
    for (final sensor in widget.dataset.sensors) {
      sensorStates[sensor.id] = _SensorEditState(
        sensor: sensor,
        useDatasetValue: true,
        sourceType: 'mean', // Default to mean
        customValue: sensor.meanValue,
      );
    }
    _calculateMetric();
  }

  void _calculateMetric() {
    final sensorValues = <LiveMetricValue>[];

    for (final sensor in widget.dataset.sensors) {
      final state = sensorStates[sensor.id];
      if (state != null) {
        double value;

        if (state.useDatasetValue) {
          // Use dataset value (min/max/mean)
          switch (state.sourceType) {
            case 'min':
              value = sensor.minValue;
              break;
            case 'max':
              value = sensor.maxValue;
              break;
            case 'mean':
            default:
              value = sensor.meanValue;
          }
        } else {
          // Use custom value
          value = state.customValue ?? sensor.meanValue;
        }

        // Clamp to valid range
        value = value.clamp(sensor.minValue, sensor.maxValue);

        sensorValues.add(
          LiveMetricValue(
            sensor: sensor,
            value: value,
            isFromDataset: state.useDatasetValue,
            sourceType: state.useDatasetValue ? state.sourceType : 'custom',
          ),
        );
      }
    }

    final score = PreCalculatedMCDMCalculator.calculateScore(
      sensorValues: sensorValues,
      dataset: widget.dataset,
      weightMethod: widget.weightMethod,
    );

    currentMetric = LiveMetric(
      id: '${widget.dataset.id}_${DateTime.now().millisecondsSinceEpoch}',
      dataset: widget.dataset,
      sensorValues: sensorValues,
      weightMethod: widget.weightMethod,
      calculatedScore: score,
    );

    widget.onMetricChanged?.call(currentMetric);
  }

  void _updateSensorState(String sensorId, _SensorEditState newState) {
    setState(() {
      sensorStates[sensorId] = newState;
      _calculateMetric();
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
              children: [
                const Icon(Icons.tune, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Metrics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.dataset.name} - ${widget.weightMethod} Weights',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sensors List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.dataset.sensors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sensor = widget.dataset.sensors[index];
                final state = sensorStates[sensor.id];

                if (state == null) return const SizedBox.shrink();

                return _SensorEditorCard(
                  sensor: sensor,
                  state: state,
                  onStateChanged: (newState) => _updateSensorState(sensor.id, newState),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Stores edit state for a single sensor
class _SensorEditState {
  final LiveMetricSensor sensor;
  final bool useDatasetValue;
  final String sourceType; // 'min', 'max', 'mean'
  final double? customValue;

  _SensorEditState({
    required this.sensor,
    required this.useDatasetValue,
    required this.sourceType,
    this.customValue,
  });

  _SensorEditState copyWith({
    bool? useDatasetValue,
    String? sourceType,
    double? customValue,
  }) {
    return _SensorEditState(
      sensor: sensor,
      useDatasetValue: useDatasetValue ?? this.useDatasetValue,
      sourceType: sourceType ?? this.sourceType,
      customValue: customValue ?? this.customValue,
    );
  }
}

/// Individual sensor editor card
class _SensorEditorCard extends StatefulWidget {
  final LiveMetricSensor sensor;
  final _SensorEditState state;
  final ValueChanged<_SensorEditState> onStateChanged;

  const _SensorEditorCard({
    required this.sensor,
    required this.state,
    required this.onStateChanged,
  });

  @override
  State<_SensorEditorCard> createState() => _SensorEditorCardState();
}

class _SensorEditorCardState extends State<_SensorEditorCard> {
  late TextEditingController customValueController;

  @override
  void initState() {
    super.initState();
    customValueController = TextEditingController(
      text: (widget.state.customValue ?? widget.sensor.meanValue).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    customValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sensor Name & Weight
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sensor.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Weight: ${(widget.sensor.weight * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  '${widget.sensor.unit}',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: Colors.blue.shade100,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dataset vs Custom Toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onStateChanged(
                      widget.state.copyWith(useDatasetValue: true),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: widget.state.useDatasetValue ? Colors.blue.shade100 : Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                      border: Border.all(
                        color: widget.state.useDatasetValue ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                    child: const Text(
                      'Use Dataset',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onStateChanged(
                      widget.state.copyWith(useDatasetValue: false),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: !widget.state.useDatasetValue ? Colors.green.shade100 : Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                      border: Border.all(
                        color: !widget.state.useDatasetValue ? Colors.green : Colors.grey.shade300,
                      ),
                    ),
                    child: const Text(
                      'Custom',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dataset Options or Custom Input
          if (widget.state.useDatasetValue)
            _buildDatasetOptions()
          else
            _buildCustomInput(),
        ],
      ),
    );
  }

  Widget _buildDatasetOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Value:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildOptionButton('Min', 'min', widget.sensor.minValue),
            const SizedBox(width: 8),
            _buildOptionButton('Mean', 'mean', widget.sensor.meanValue),
            const SizedBox(width: 8),
            _buildOptionButton('Max', 'max', widget.sensor.maxValue),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Selected: ${_formatValue(widget.state.sourceType)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Value (${widget.sensor.minValue.toStringAsFixed(2)} - ${widget.sensor.maxValue.toStringAsFixed(2)} ${widget.sensor.unit}):',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: customValueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  hintText: widget.sensor.meanValue.toStringAsFixed(2),
                  isDense: true,
                ),
                onChanged: (value) {
                  final numValue = double.tryParse(value);
                  if (numValue != null) {
                    widget.onStateChanged(
                      widget.state.copyWith(customValue: numValue),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.sensor.unit,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton(String label, String type, double value) {
    final isSelected = widget.state.sourceType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.onStateChanged(
            widget.state.copyWith(sourceType: type),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(String type) {
    switch (type) {
      case 'min':
        return 'Min: ${widget.sensor.minValue.toStringAsFixed(1)} ${widget.sensor.unit}';
      case 'max':
        return 'Max: ${widget.sensor.maxValue.toStringAsFixed(1)} ${widget.sensor.unit}';
      case 'mean':
      default:
        return 'Mean: ${widget.sensor.meanValue.toStringAsFixed(1)} ${widget.sensor.unit}';
    }
  }
}
