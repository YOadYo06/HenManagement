import 'dart:async';
import 'dart:math';

import '../models/alert_item.dart';
import '../models/reading.dart';
import '../models/thresholds.dart';
import '../utils/comfort_score.dart';
import 'data_repository.dart';

class MockDataRepository implements DataRepository {
  MockDataRepository() {
    _start();
  }

  final _random = Random();
  final _readingsController = StreamController<List<Reading>>.broadcast();
  final _alertsController = StreamController<List<AlertItem>>.broadcast();
  final _thresholdsController =
      StreamController<Thresholds>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  final _readings = <Reading>[];
  final _alerts = <AlertItem>[];
  final _thresholds = Thresholds.defaults;
  Timer? _timer;

  @override
  Stream<bool> connectionStatus() => _connectionController.stream;

  @override
  Stream<List<Reading>> recentReadings({int limit = 50}) =>
      _readingsController.stream;

  @override
  Stream<List<AlertItem>> recentAlerts({int limit = 10}) =>
      _alertsController.stream;

  @override
  Stream<Thresholds> thresholds() => _thresholdsController.stream;

  @override
  void dispose() {
    _timer?.cancel();
    _readingsController.close();
    _alertsController.close();
    _thresholdsController.close();
    _connectionController.close();
  }

  void _start() {
    _thresholdsController.add(_thresholds);
    _connectionController.add(true);
    _seed();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pushReading();
    });
  }

  void _seed() {
    final now = DateTime.now().toUtc();
    for (var i = 15; i >= 1; i--) {
      _pushReading(timestamp: now.subtract(Duration(seconds: 5 * i)));
    }
  }

  void _pushReading({DateTime? timestamp}) {
    final light = 250 + _random.nextDouble() * 350;
    final noise = 30 + _random.nextDouble() * 45;
    final temperature = 19 + _random.nextDouble() * 7;
    final humidity = 40 + _random.nextDouble() * 30;
    final comfortScore = calculateComfortScore(
      light: light,
      noise: noise,
      temperature: temperature,
    );

    final reading = Reading(
      id: timestamp?.millisecondsSinceEpoch.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: timestamp ?? DateTime.now().toUtc(),
      light: light,
      noise: noise,
      temperature: temperature,
      humidity: humidity,
      comfortScore: comfortScore,
    );

    _readings.add(reading);
    if (_readings.length > 60) {
      _readings.removeAt(0);
    }

    _readingsController.add(List.unmodifiable(_readings));
    _checkAlerts(reading);
  }

  void _checkAlerts(Reading reading) {
    final alerts = <AlertItem>[];

    if (reading.light < _thresholds.lightMin) {
      alerts.add(_buildAlert(
        type: 'low_light',
        message: 'Light level is below the recommended range.',
        value: reading.light,
        severity: 'warning',
      ));
    }

    if (reading.noise > _thresholds.noiseMax) {
      alerts.add(_buildAlert(
        type: 'high_noise',
        message: 'Noise level is above the focus threshold.',
        value: reading.noise,
        severity: 'warning',
      ));
    }

    if (reading.temperature < _thresholds.tempMin) {
      alerts.add(_buildAlert(
        type: 'low_temp',
        message: 'Temperature is below the comfort range.',
        value: reading.temperature,
        severity: 'info',
      ));
    } else if (reading.temperature > _thresholds.tempMax) {
      alerts.add(_buildAlert(
        type: 'high_temp',
        message: 'Temperature is above the comfort range.',
        value: reading.temperature,
        severity: 'warning',
      ));
    }

    if (alerts.isNotEmpty) {
      _alerts.insertAll(0, alerts);
      if (_alerts.length > 20) {
        _alerts.removeRange(20, _alerts.length);
      }
      _alertsController.add(List.unmodifiable(_alerts));
    }
  }

  AlertItem _buildAlert({
    required String type,
    required String message,
    required double value,
    required String severity,
  }) {
    return AlertItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      message: message,
      timestamp: DateTime.now().toUtc(),
      severity: severity,
      value: value,
    );
  }
}
