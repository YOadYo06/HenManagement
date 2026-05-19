import 'package:flutter/material.dart';
import '../models/live_metric.dart';
import '../models/reading.dart';
import '../services/precalculated_mcdm_calculator.dart';

class EnhancedMCDMCard extends StatefulWidget {
  final LiveMetricDataset dataset;
  final Reading? latestReading;
  final Map<String, double> editedValues;
  final int editVersion;
  final void Function(String, double?)? onEditSensor;

  const EnhancedMCDMCard({
    super.key,
    required this.dataset,
    this.latestReading,
    this.editedValues = const {},
    this.editVersion = 0,
    this.onEditSensor,
  });

  @override
  State<EnhancedMCDMCard> createState() => _EnhancedMCDMCardState();
}

class _EnhancedMCDMCardState extends State<EnhancedMCDMCard> {
  late String _selectedWeightMethod;
  late String _selectedScoringMethod;
  late Map<String, double> _sensorValues;
  late double _score;

  @override
  void initState() {
    super.initState();
    final methods = widget.dataset.getWeightMethods();
    _selectedWeightMethod = methods.isNotEmpty ? methods.first : 'Compromise';
    _selectedScoringMethod = 'MABAC';
    _sensorValues = {};
    _recalculate();
  }

  @override
  void didUpdateWidget(EnhancedMCDMCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataset.id != widget.dataset.id ||
        oldWidget.editVersion != widget.editVersion ||
        oldWidget.latestReading?.temperature != widget.latestReading?.temperature ||
        oldWidget.latestReading?.humidity != widget.latestReading?.humidity ||
        oldWidget.latestReading?.noise != widget.latestReading?.noise ||
        oldWidget.latestReading?.light != widget.latestReading?.light) {
      _recalculate();
    }
  }

  void _recalculate() {
    _sensorValues = {};
    final reading = widget.latestReading;

    for (final sensor in widget.dataset.sensors) {
      double value;
      // 1. Check for user-edited value (shared from stat grid)
      if (widget.editedValues.containsKey(sensor.id)) {
        value = widget.editedValues[sensor.id]!;
      } else {
        // 2. Check for live reading
        switch (sensor.id) {
          case 'temp':
          case 'temperature':
            value = reading?.temperature ?? sensor.meanValue;
            break;
          case 'humidity':
            value = reading?.humidity ?? sensor.meanValue;
            break;
          case 'noise':
            value = reading?.noise ?? sensor.meanValue;
            break;
          case 'light':
          case 'lighting':
          case 'illuminance':
          case 'light_intensity':
            value = reading?.light ?? sensor.meanValue;
            break;
          default:
            value = sensor.meanValue;
        }
      }
      _sensorValues[sensor.id] = value;
    }

    _updateScore();
  }

  void _updateScore() {
    final sensorValues = <LiveMetricValue>[];
    for (final sensor in widget.dataset.sensors) {
      final val = _sensorValues[sensor.id] ?? sensor.meanValue;
      sensorValues.add(LiveMetricValue(
        sensor: sensor,
        value: val,
        isFromDataset: false,
        sourceType: 'custom',
      ));
    }

    _score = PreCalculatedMCDMCalculator.calculateScore(
      sensorValues: sensorValues,
      dataset: widget.dataset,
      weightMethod: _selectedWeightMethod,
      scoringMethod: _selectedScoringMethod,
    );

    setState(() {});
  }

  void _changeWeightMethod(String method) {
    setState(() {
      _selectedWeightMethod = method;
      _updateScore();
    });
  }

  void _changeScoringMethod(String method) {
    setState(() {
      _selectedScoringMethod = method;
      _updateScore();
    });
  }

  void _editSensorValue(String sensorId) {
    final sensor = widget.dataset.sensors.firstWhere(
      (s) => s.id == sensorId,
      orElse: () => widget.dataset.sensors.first,
    );
    final currentValue = _sensorValues[sensorId] ?? sensor.meanValue;
    final reading = widget.latestReading;
    final liveValue = _liveValueFromReading(sensor, reading);
    final isCurrentlyEdited = widget.editedValues.containsKey(sensorId);

    if (!isCurrentlyEdited && liveValue != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(sensor.displayName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sensors, color: Colors.green),
                title: const Text('Use live value'),
                subtitle: Text('${liveValue.toStringAsFixed(1)} ${sensor.unit}'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Enter manually'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showManualEdit(context, sensor, currentValue, liveValue);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      _showManualEdit(context, sensor, currentValue, liveValue);
    }
  }

  void _showManualEdit(BuildContext context, LiveMetricSensor sensor,
      double currentValue, double? liveValue) {
    final controller = TextEditingController(text: currentValue.toStringAsFixed(1));
    final hasLiveData = liveValue != null;

    showDialog(
      context: context,
      builder: (ctx) {
        double sliderValue = currentValue.clamp(sensor.minValue, sensor.maxValue);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(sensor.displayName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Value (${sensor.unit})',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null && parsed >= sensor.minValue && parsed <= sensor.maxValue) {
                      setDialogState(() => sliderValue = parsed);
                    }
                  },
                  onSubmitted: (v) {
                    _applySensorValue(sensorId: sensor.id, text: v);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(sensor.minValue.toStringAsFixed(1),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    Expanded(
                      child: Slider(
                        value: sliderValue,
                        min: sensor.minValue,
                        max: sensor.maxValue,
                        divisions: ((sensor.maxValue - sensor.minValue) / 0.5).round().clamp(1, 200),
                        label: sliderValue.toStringAsFixed(1),
                        onChanged: (v) {
                          setDialogState(() {
                            sliderValue = v;
                            controller.text = v.toStringAsFixed(1);
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length));
                          });
                        },
                      ),
                    ),
                    Text(sensor.maxValue.toStringAsFixed(1),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Drag slider or type any value',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              if (hasLiveData)
                TextButton(
                  onPressed: () {
                    _revertSensor(sensor.id);
                    Navigator.pop(ctx);
                  },
                  child: Text('Use live (${liveValue.toStringAsFixed(1)})',
                      style: const TextStyle(color: Colors.green)),
                ),
              TextButton(
                onPressed: () {
                  _applySensorValue(sensorId: sensor.id, text: controller.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Set'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applySensorValue({required String sensorId, required String text}) {
    final parsed = double.tryParse(text);
    if (parsed != null) {
      _sensorValues[sensorId] = parsed;
      widget.onEditSensor?.call(sensorId, parsed);
      _updateScore();
    }
  }

  void _revertSensor(String sensorId) {
    _sensorValues.remove(sensorId);
    widget.onEditSensor?.call(sensorId, null);
    _updateScore();
  }

  double? _liveValueFromReading(LiveMetricSensor sensor, Reading? reading) {
    if (reading == null) return null;
    switch (sensor.id) {
      case 'temp': return reading.temperature;
      case 'humidity': return reading.humidity;
      case 'noise': return reading.noise;
      case 'light': return reading.light;
      default: return null;
    }
  }

  bool _isLiveSensor(String id) {
    return ['temp', 'temperature', 'humidity', 'noise', 'light', 'lighting', 'illuminance', 'light_intensity'].contains(id);
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = PreCalculatedMCDMCalculator.getColor(_score);
    final scoreInterpretation = PreCalculatedMCDMCalculator.getInterpretation(_score);
    final weightMethods = widget.dataset.getWeightMethods();
    final weights = widget.dataset.getWeights(_selectedWeightMethod);
    final modelConfig = widget.dataset.modelConfig;
    final isStress = widget.dataset.id == 'iot_mental_health';

    // Compute model prediction
    final sensorValues = widget.dataset.sensors.map((s) {
      final v = _sensorValues[s.id] ?? s.meanValue;
      return LiveMetricValue(sensor: s, value: v, isFromDataset: false, sourceType: 'custom');
    }).toList();
    final isClassification = widget.dataset.isClassification;
    final modelPrediction = isClassification
        ? null
        : PreCalculatedMCDMCalculator.computeModelPrediction(
            sensorValues: sensorValues, dataset: widget.dataset, mcdmScore: _score);
    final predictedClass = PreCalculatedMCDMCalculator.predictClassLabel(
      sensorValues: sensorValues, dataset: widget.dataset, mcdmScore: _score);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with best model badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MCDM Analysis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(widget.dataset.name,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (widget.dataset.bestModel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Text(widget.dataset.bestModel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Model Prediction Section
            if (modelConfig != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isStress ? Colors.red.shade50 : Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isStress ? Colors.red.shade200 : Colors.deepPurple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Icon(isStress ? Icons.favorite : Icons.auto_graph,
                            size: 16, color: isStress ? Colors.red.shade600 : Colors.deepPurple.shade600),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(isStress ? 'Stress Level' : 'Model Prediction', overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isStress ? 16 : 13,
                                color: isStress ? Colors.red.shade800 : Colors.deepPurple.shade800,
                              )),
                          ),
                          if (!isStress) ...[
                            const Spacer(),
                            Flexible(
                              child: Text(modelConfig['target'] as String? ?? '', overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, color: Colors.deepPurple.shade400)),
                            ),
                          ],
                          if (isStress)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('PREDICTION',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (modelPrediction != null)
                      Row(
                        children: [
                          Text(
                            modelPrediction.toStringAsFixed(1),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                              color: isStress ? Colors.red.shade700 : Colors.deepPurple.shade700),
                          ),
                          if (modelConfig['unit'] != null) ...[
                            const SizedBox(width: 4),
                            Text(modelConfig['unit'] as String,
                              style: TextStyle(fontSize: 12,
                                color: isStress ? Colors.red.shade400 : Colors.deepPurple.shade400)),
                          ],
                          const Spacer(),
                          if (predictedClass != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(predictedClass,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepPurple.shade800)),
                            ),
                        ],
                      )
                    else if (predictedClass != null)
                      Row(
                        children: [
                          Icon(Icons.troubleshoot, size: 16, color: Colors.deepPurple.shade400),
                          const SizedBox(width: 6),
                          Text('Class: ',
                            style: TextStyle(fontSize: 13, color: Colors.deepPurple.shade600)),
                          Text(predictedClass,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade800)),
                        ],
                      )
                    else
                      Text(modelConfig['note'] as String? ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.deepPurple.shade400, fontStyle: FontStyle.italic)),
                    if (isStress && modelPrediction != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('This is the predicted stress level, not the MCDM score below',
                          style: TextStyle(fontSize: 10, color: Colors.red.shade400, fontStyle: FontStyle.italic)),
                      ),
                    if (modelPrediction != null || predictedClass != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          PreCalculatedMCDMCalculator.getPredictionDescription(widget.dataset.id),
                          style: TextStyle(fontSize: 10, color: Colors.deepPurple.shade500),
                        ),
                      ),
                    if (modelPrediction != null || predictedClass != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          PreCalculatedMCDMCalculator.getPredictionRange(widget.dataset.id),
                          style: TextStyle(fontSize: 10, color: Colors.deepPurple.shade300),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Weight Method Selector
            if (weightMethods.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weight Method',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  Text(PreCalculatedMCDMCalculator.getWeightFormula(_selectedWeightMethod),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: weightMethods.map((method) {
                  final sel = method == _selectedWeightMethod;
                  return GestureDetector(
                    onTap: () => _changeWeightMethod(method),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? Colors.blue.shade500 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: sel ? Colors.blue.shade700 : Colors.grey.shade300),
                      ),
                      child: Text(method,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.grey.shade700)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Scoring Method Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scoring Formula',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: PreCalculatedMCDMCalculator.scoringMethods.map((method) {
                    final sel = method == _selectedScoringMethod;
                    return GestureDetector(
                      onTap: () => _changeScoringMethod(method),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? Colors.teal.shade500 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: sel ? Colors.teal.shade700 : Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Text(method,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : Colors.grey.shade700)),
                            if (sel)
                              Text(PreCalculatedMCDMCalculator.getScoringFormula(method),
                                style: TextStyle(fontSize: 8, color: Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // MCDM Score
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(scoreColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(scoreColor)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MCDM Score ($_selectedScoringMethod)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${(_score * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: Color(scoreColor))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _score, minHeight: 22,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(Color(scoreColor)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(scoreInterpretation,
                    style: TextStyle(color: Color(scoreColor), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Sensor Values with Weights
            Text('Sensors & Weights',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            ...widget.dataset.sensors.map((sensor) {
              final value = _sensorValues[sensor.id] ?? sensor.meanValue;
              final w = weights[sensor.name] ?? (1.0 / widget.dataset.sensors.length);
              final isLive = _isLiveSensor(sensor.id) && widget.latestReading != null;
              final isProfit = sensor.type == 'PROFIT';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    // Priority indicator
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: isLive ? Colors.green : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Sensor name with type badge
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                            decoration: BoxDecoration(
                              color: isProfit ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: isProfit ? Colors.green.shade200 : Colors.orange.shade200, width: 0.5),
                            ),
                            child: Text(isProfit ? 'P' : 'C',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold,
                                color: isProfit ? Colors.green.shade700 : Colors.orange.shade700)),
                          ),
                          Expanded(
                            child: Text(sensor.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isLive ? Colors.grey.shade700 : Colors.grey.shade500,
                                fontWeight: isLive ? FontWeight.w500 : FontWeight.normal,
                              )),
                          ),
                        ],
                      ),
                    ),
                    // Value (tap to edit)
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _editSensorValue(sensor.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLive ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isLive ? Colors.green.shade200 : Colors.orange.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            value.toStringAsFixed(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLive ? Colors.green.shade700 : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(sensor.unit, overflow: TextOverflow.clip,
                        style: TextStyle(fontSize: 9, color: isLive ? Colors.grey.shade500 : Colors.grey.shade400)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('w=${(w * 100).toStringAsFixed(1)}%', overflow: TextOverflow.clip,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            // ML Models info
            if (widget.dataset.models.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.smart_toy, size: 16, color: Colors.indigo.shade300),
                  const SizedBox(width: 6),
                  Text('ML Models: ',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(widget.dataset.models.join(', '),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (widget.dataset.predictions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.track_changes, size: 16, color: Colors.amber.shade300),
                      const SizedBox(width: 6),
                      Text('Target: ',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                      Text(widget.dataset.predictions.join(', '),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
