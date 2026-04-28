import 'package:firebase_database/firebase_database.dart';

import '../models/alert_item.dart';
import '../models/reading.dart';
import '../models/thresholds.dart';
import 'data_repository.dart';

class FirebaseDataRepository implements DataRepository {
  FirebaseDataRepository() : _database = FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  DatabaseReference get _root => _database.ref('study_desk_monitor');

  @override
  Stream<bool> connectionStatus() {
    return _database.ref('.info/connected').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is bool) return value;
      return false;
    });
  }

  @override
  Stream<List<Reading>> recentReadings({int limit = 50}) {
    final query = _root.child('readings').orderByKey().limitToLast(limit);
    return query.onValue.map((event) => _mapReadings(event.snapshot));
  }

  @override
  Stream<List<AlertItem>> recentAlerts({int limit = 10}) {
    final query = _root.child('alerts').orderByKey().limitToLast(limit);
    return query.onValue.map((event) => _mapAlerts(event.snapshot));
  }

  @override
  Stream<Thresholds> thresholds() {
    return _root.child('settings/thresholds').onValue.map((event) {
      if (event.snapshot.value is Map<dynamic, dynamic>) {
        return Thresholds.fromMap(event.snapshot.value as Map<dynamic, dynamic>);
      }
      return Thresholds.defaults;
    });
  }

  @override
  void dispose() {}

  List<Reading> _mapReadings(DataSnapshot snapshot) {
    final data = snapshot.value;
    if (data is! Map<dynamic, dynamic>) return [];

    final readings = <Reading>[];
    for (final entry in data.entries) {
      final id = entry.key.toString();
      final value = entry.value;
      if (value is Map<dynamic, dynamic>) {
        readings.add(Reading.fromMap(id, value));
      }
    }

    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return readings;
  }

  List<AlertItem> _mapAlerts(DataSnapshot snapshot) {
    final data = snapshot.value;
    if (data is! Map<dynamic, dynamic>) return [];

    final alerts = <AlertItem>[];
    for (final entry in data.entries) {
      final id = entry.key.toString();
      final value = entry.value;
      if (value is Map<dynamic, dynamic>) {
        alerts.add(AlertItem.fromMap(id, value));
      }
    }

    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return alerts;
  }
}
