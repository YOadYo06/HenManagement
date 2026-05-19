import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/metric_config_service.dart';
import 'services/firebase_data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final configJson = await rootBundle.loadString('mcdm_flutter_config.json');
    MetricConfigService().loadFromJson(configJson);
  } catch (e) {
    debugPrint('Failed to load mcdm_flutter_config.json: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    App(
      repository: FirebaseDataRepository(),
      firebaseReady: true,
    ),
  );
}
