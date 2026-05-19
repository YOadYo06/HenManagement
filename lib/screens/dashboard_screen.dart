import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reading.dart';
import '../models/live_metric.dart';
import '../services/data_repository.dart';
import '../services/metric_config_service.dart';
import '../widgets/connection_pill.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/enhanced_mcdm_card.dart';
import 'history_screen.dart';

// --- Sensor helpers ---

const _liveSensorIds = {'temp', 'temperature', 'humidity', 'noise', 'light', 'lighting', 'illuminance', 'light_intensity'};

bool _hasLiveData(LiveMetricSensor sensor) => _liveSensorIds.contains(sensor.id);

double? _liveValueFromReading(LiveMetricSensor sensor, Reading? reading) {
  if (reading == null) return null;
  switch (sensor.id) {
    case 'temp':
    case 'temperature':
      return reading.temperature;
    case 'humidity':
      return reading.humidity;
    case 'noise':
      return reading.noise;
    case 'light':
    case 'lighting':
    case 'illuminance':
    case 'light_intensity':
      return reading.light;
    default:
      return null;
  }
}

IconData _sensorIcon(LiveMetricSensor sensor) {
  switch (sensor.id) {
    case 'temp':
    case 'temperature':
      return Icons.thermostat;
    case 'humidity':
      return Icons.water_drop;
    case 'noise':
      return Icons.graphic_eq;
    case 'light':
    case 'lighting':
    case 'illuminance':
    case 'light_intensity':
      return Icons.light_mode;
    case 'chicken_count':
    case 'chicken_amount':
      return Icons.pets;
    case 'feed_amount':
    case 'feeding_amount':
      return Icons.restaurant;
    case 'egg_count':
      return Icons.egg;
    case 'co2':
    case 'co2_level':
      return Icons.air;
    case 'occupancy':
    case 'people_count':
      return Icons.people;
    case 'book_count':
    case 'books_borrowed':
      return Icons.menu_book;
    case 'gate_entries':
      return Icons.input;
    case 'usage_hours':
      return Icons.access_time;
    case 'study_hours':
    case 'screen_time':
      return Icons.schedule;
    case 'steps':
      return Icons.directions_walk;
    case 'calories':
      return Icons.local_fire_department;
    case 'heart_rate':
    case 'bpm':
      return Icons.favorite;
    case 'sleep_hours':
      return Icons.bedtime;
    case 'mood':
    case 'stress_level':
      return Icons.mood;
    case 'soil_moisture':
    case 'moisture':
      return Icons.grass;
    case 'ph':
      return Icons.science;
    case 'rainfall':
      return Icons.umbrella;
    case 'energy':
    case 'power':
      return Icons.bolt;
    case 'wind_speed':
      return Icons.air;
    case 'solar':
      return Icons.wb_sunny;
    default:
      return Icons.sensors;
  }
}

Color _sensorAccent(LiveMetricSensor sensor) {
  switch (sensor.id) {
    case 'temp':
    case 'temperature':
      return const Color(0xFFE76F51);
    case 'humidity':
      return const Color(0xFF457B9D);
    case 'noise':
      return const Color(0xFF2A9D8F);
    case 'light':
    case 'lighting':
    case 'illuminance':
    case 'light_intensity':
      return const Color(0xFFFFB703);
    default:
      return Colors.teal;
  }
}

List<LiveMetricSensor> _liveSensorsNotInDataset(LiveMetricDataset dataset) {
  final datasetIds = dataset.sensors.map((s) => s.id).toSet();
  // If dataset has any light-equivalent sensor, don't add extra 'light'
  final hasLightEquivalent = datasetIds.any((id) =>
    ['light', 'lighting', 'illuminance', 'light_intensity'].contains(id));
  // Standard live reading sensor IDs
  const standardLive = ['temp', 'humidity', 'noise'];
  const standardLiveWithLight = ['temp', 'humidity', 'noise', 'light'];
  final result = <LiveMetricSensor>[];
  for (final id in (hasLightEquivalent ? standardLive : standardLiveWithLight)) {
    if (!datasetIds.contains(id)) {
      result.add(LiveMetricSensor(
        id: id,
        name: id,
        displayName: _displayNameForId(id),
        unit: _unitForId(id),
        type: id == 'light' ? 'PROFIT' : 'COST',
        minValue: 0,
        maxValue: 100,
        meanValue: 50,
        weight: 0.25,
      ));
    }
  }
  return result;
}

String _displayNameForId(String id) {
  switch (id) {
    case 'temp': return 'Temperature';
    case 'humidity': return 'Humidity';
    case 'noise': return 'Noise';
    case 'light': return 'Light';
    default: return id;
  }
}

String _unitForId(String id) {
  switch (id) {
    case 'temp': return '°C';
    case 'humidity': return '%';
    case 'noise': return 'dB';
    case 'light': return 'lux';
    default: return '';
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.firebaseReady,
  });

  final DataRepository repository;
  final bool firebaseReady;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _selectedDatasetId;
  final Map<String, double> _editedSensorValues = {};
  int _editVersion = 0;


  @override
  void initState() {
    super.initState();
    final datasets = MetricConfigService().getAllDatasets();
    _selectedDatasetId = datasets.isNotEmpty ? datasets.first.id : '';
    _initPredictor();
  }

  Future<void> _initPredictor() async {
    await MetricConfigService().initModelPredictor();
    if (mounted) setState(() {});
  }

  LiveMetricDataset? get _selectedDataset {
    try {
      return MetricConfigService().getDataset(_selectedDatasetId);
    } catch (e) {
      return null;
    }
  }

  void _handleEditSensor(String sensorId, double? value) {
    setState(() {
      if (value == null) {
        _editedSensorValues.remove(sensorId);
      } else {
        _editedSensorValues[sensorId] = value;
      }
      _editVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: StreamBuilder<List<Reading>>(
              stream: widget.repository.recentReadings(limit: 50),
              builder: (context, snapshot) {
                final readings = snapshot.data ?? [];
                final latest = readings.isNotEmpty ? readings.last : null;

                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 550),
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          repository: widget.repository,
                          firebaseReady: widget.firebaseReady,
                          latest: latest,
                          datasetName: _selectedDataset?.name ?? 'Smart Study Desk Monitor',
                        ),
                        const SizedBox(height: 12),
                        _DatasetSelector(
                          selectedId: _selectedDatasetId,
                          onChanged: (id) {
                            setState(() {
                              _selectedDatasetId = id;
                              _editedSensorValues.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Live metrics',
                          subtitle: 'Current environmental sensor readings.',
                        ),
                        _StatGrid(
                          latest: latest,
                          dataset: _selectedDataset,
                          editedValues: _editedSensorValues,
                          onEditSensor: _handleEditSensor,
                        ),
                        const SizedBox(height: 26),
                        SectionHeader(
                          title: 'MCDM Analysis',
                          subtitle: 'Multi-criteria decision making with stress prediction.',
                        ),
                        if (_selectedDataset != null)
                          EnhancedMCDMCard(
                            dataset: _selectedDataset!,
                            latestReading: latest,
                            editedValues: _editedSensorValues,
                            editVersion: _editVersion,
                            onEditSensor: _handleEditSensor,
                          )
                        else
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Waiting for sensor data...'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.repository,
    required this.firebaseReady,
    required this.latest,
    required this.datasetName,
  });

  final DataRepository repository;
  final bool firebaseReady;
  final Reading? latest;
  final String datasetName;

  @override
  Widget build(BuildContext context) {
    final time = latest?.timestamp.toLocal();
    final formatted = time != null
        ? DateFormat('MMM d, HH:mm:ss').format(time)
        : 'Waiting for data...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    datasetName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Realtime dashboard',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.history, size: 22),
                  tooltip: 'View history',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryScreen(repository: repository),
                      ),
                    );
                  },
                ),
                StreamBuilder<bool>(
                  stream: repository.connectionStatus(),
                  builder: (context, snapshot) {
                    return ConnectionPill(
                      connected: snapshot.data ?? false,
                      showMock: !firebaseReady,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Last update: $formatted',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.latest,
    required this.dataset,
    required this.editedValues,
    required this.onEditSensor,
  });

  final Reading? latest;
  final LiveMetricDataset? dataset;
  final Map<String, double> editedValues;
  final void Function(String, double?) onEditSensor;

  @override
  Widget build(BuildContext context) {
    if (dataset == null) return const SizedBox.shrink();

    final datasetSensors = dataset!.sensors;
    final extraSensors = _liveSensorsNotInDataset(dataset!);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        final cols = isWide ? 4 : 2;
        final itemWidth = (constraints.maxWidth - (cols - 1) * 8) / cols;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Dataset sensors — all tappable to edit
            for (final sensor in datasetSensors) ...[
              SizedBox(
                width: itemWidth,
                child: _SensorStatCard(
                  sensor: sensor,
                  reading: latest,
                  editedValues: editedValues,
                  onEditSensor: onEditSensor,
                ),
              ),
            ],
            // Extra live sensors not in dataset (grayed out)
            for (final sensor in extraSensors) ...[
              SizedBox(
                width: itemWidth,
                child: Stack(
                  children: [
                    StatCard(
                      title: sensor.displayName,
                      value: '—',
                      unit: sensor.unit,
                      icon: _sensorIcon(sensor),
                      accentColor: Colors.grey,
                      isLive: false,
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.withOpacity(0.4)),
                        ),
                        child: Text(sensor.type == 'PROFIT' ? 'P' : 'C',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SensorStatCard extends StatelessWidget {
  const _SensorStatCard({
    required this.sensor,
    required this.reading,
    required this.editedValues,
    required this.onEditSensor,
  });

  final LiveMetricSensor sensor;
  final Reading? reading;
  final Map<String, double> editedValues;
  final void Function(String, double?) onEditSensor;

  double _currentValue() {
    if (editedValues.containsKey(sensor.id)) return editedValues[sensor.id]!;
    final liveValue = _liveValueFromReading(sensor, reading);
    return liveValue ?? sensor.meanValue;
  }

  @override
  Widget build(BuildContext context) {
    final value = _currentValue();
    final live = _hasLiveData(sensor);
    final liveValue = _liveValueFromReading(sensor, reading);
    final isLive = live && liveValue != null && !editedValues.containsKey(sensor.id);
    final isEdited = editedValues.containsKey(sensor.id);

    final typeLabel = sensor.type == 'PROFIT' ? 'P' : 'C';
    final typeColor = sensor.type == 'PROFIT' ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () => _showEditDialog(context),
      child: Stack(
        children: [
          StatCard(
            title: sensor.displayName,
            value: value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
            unit: sensor.unit,
            icon: _sensorIcon(sensor),
            accentColor: isLive ? _sensorAccent(sensor) : (isEdited ? Colors.orange : Colors.grey),
            isLive: isLive,
            bottom: !isLive && sensor.maxValue > sensor.minValue
                ? _RangeBar(sensor: sensor, currentValue: value)
                : null,
          ),
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: typeColor.withOpacity(0.4)),
              ),
              child: Text(typeLabel,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: typeColor)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final liveValue = _liveValueFromReading(sensor, reading);
    final isCurrentlyEdited = editedValues.containsKey(sensor.id);

    if (!isCurrentlyEdited && liveValue != null) {
      // Has live data and not edited: offer live-use or manual
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
                  _showManualEditDialog(context);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      // Already edited or no live data: show manual edit + revert option
      _showManualEditDialog(context);
    }
  }

  void _showManualEditDialog(BuildContext context) {
    final initial = _currentValue();
    final controller = TextEditingController(text: initial.toStringAsFixed(1));
    final liveValue = _liveValueFromReading(sensor, reading);
    final hasLiveData = liveValue != null;

    showDialog(
      context: context,
      builder: (ctx) {
        double sliderValue = initial.clamp(sensor.minValue, sensor.maxValue);
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
                    onEditSensor(sensor.id, null);
                    Navigator.pop(ctx);
                  },
                  child: Text('Use live (${liveValue.toStringAsFixed(1)})',
                      style: const TextStyle(color: Colors.green)),
                ),
              TextButton(
                onPressed: () {
                  final parsed = double.tryParse(controller.text);
                  if (parsed != null) {
                    onEditSensor(sensor.id, parsed);
                  }
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
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.sensor, required this.currentValue});

  final LiveMetricSensor sensor;
  final double currentValue;

  @override
  Widget build(BuildContext context) {
    final fraction = (currentValue - sensor.minValue) / (sensor.maxValue - sensor.minValue);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(sensor.minValue),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
              Text(_fmt(sensor.maxValue),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v.abs() < 0.01) return v.toStringAsFixed(4);
    if (v.abs() < 1) return v.toStringAsFixed(2);
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }
}

class _DatasetSelector extends StatelessWidget {
  const _DatasetSelector({
    required this.selectedId,
    required this.onChanged,
  });

  final String selectedId;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final datasets = MetricConfigService().getAllDatasets();
    final selectedDataset = datasets.where((d) => d.id == selectedId).firstOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.dataset, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedDataset?.name ?? 'No dataset',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          PopupMenuButton<String>(
            initialValue: selectedId,
            onSelected: onChanged,
            itemBuilder: (context) {
              return datasets
                  .map(
                    (dataset) => PopupMenuItem(
                      value: dataset.id,
                      child: Text(dataset.name),
                    ),
                  )
                  .toList();
            },
            child: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF4F7F4), Color(0xFFE5EEF0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _BlurCircle(color: const Color(0xFFB7E4C7)),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: _BlurCircle(color: const Color(0xFFFFE8A1)),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.35),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 80,
          ),
        ],
      ),
    );
  }
}
