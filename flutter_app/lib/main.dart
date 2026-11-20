import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app.dart';
import 'features/notifications/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezones
  tz.initializeTimeZones();

  // Initialize local notifications
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: SchedSolicitApp(),
    ),
  );
}
