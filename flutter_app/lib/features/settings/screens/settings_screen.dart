import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/theme_provider.dart';
import '../../../core/theme/color_schemes.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../ml/providers/ml_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    final notifState = ref.watch(notificationSettingsProvider);
    final notifNotifier = ref.read(notificationSettingsProvider.notifier);

    final mlState = ref.watch(mlProvider);
    final mlNotifier = ref.read(mlProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('APPEARANCE & THEME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(themeState.themeMode.name.toUpperCase()),
            trailing: DropdownButton<ThemeMode>(
              value: themeState.themeMode,
              underline: const SizedBox(),
              items: ThemeMode.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase())))
                  .toList(),
              onChanged: (mode) => mode != null ? themeNotifier.setThemeMode(mode) : null,
            ),
          ),
          ListTile(
            title: const Text('Green Brand Shade'),
            subtitle: Text(themeState.greenShade.name.toUpperCase()),
            trailing: DropdownButton<GreenShade>(
              value: themeState.greenShade,
              underline: const SizedBox(),
              items: GreenShade.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())))
                  .toList(),
              onChanged: (shade) => shade != null ? themeNotifier.setGreenShade(shade) : null,
            ),
          ),
          const Divider(),

          // Notifications
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('NOTIFICATIONS & DIGESTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('Enable Reminders'),
            value: notifState.enabled,
            onChanged: (val) => notifNotifier.setEnabled(val),
          ),
          ListTile(
            title: const Text('Quiet Hours'),
            subtitle: Text('${notifState.quietHoursStart}:00 to ${notifState.quietHoursEnd}:00'),
          ),
          const Divider(),

          // ML Insights & Intelligence
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('INTELLIGENCE & OCR LEARNING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('OCR & Form Adaptation'),
            subtitle: const Text('Learn from your corrections to improve future suggestions'),
            value: mlState.learningEnabled,
            onChanged: (val) => mlNotifier.toggleLearning(val),
          ),
          ListTile(
            title: const Text('Reset Learned Corrections'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () {
              mlNotifier.resetLearningData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset OCR learning data')),
              );
            },
          ),
          const Divider(),

          // About
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ABOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          const ListTile(
            title: Text('SchedSolicit Owner App'),
            subtitle: Text('Version 1.0.0 (Build 1)'),
          ),
        ],
      ),
    );
  }
}
