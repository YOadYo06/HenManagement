import '../models/alert_item.dart';
import '../models/reading.dart';
import '../models/thresholds.dart';

abstract class DataRepository {
  Stream<bool> connectionStatus();
  Stream<List<Reading>> recentReadings({int limit});
  Stream<List<AlertItem>> recentAlerts({int limit});
  Stream<Thresholds> thresholds();
  void dispose();
}
