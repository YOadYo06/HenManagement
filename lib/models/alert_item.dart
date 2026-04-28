class AlertItem {
  AlertItem({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.severity,
    this.value,
  });

  final String id;
  final String type;
  final String message;
  final DateTime timestamp;
  final String severity;
  final double? value;

  factory AlertItem.fromMap(String id, Map<dynamic, dynamic> data) {
    return AlertItem(
      id: id,
      type: data['type']?.toString() ?? 'unknown',
      message: data['message']?.toString() ?? 'Alert',
      timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      severity: data['severity']?.toString() ?? 'info',
      value: (data['value'] as num?)?.toDouble(),
    );
  }
}
