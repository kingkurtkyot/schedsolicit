import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/theme_provider.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../core/network/api_client.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../ml/providers/ml_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _currentApiUrl = ApiClient.instance.baseUrl;

  void _showApiUrlDialog() {
    final controller = TextEditingController(text: _currentApiUrl);
    bool testing = false;
    String? testResult;
    bool testSuccess = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Backend API Server'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set your cloud deployment URL (e.g., Render) or local network address for sync & server OCR:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'https://schedsolicit.onrender.com',
                    prefixIcon: Icon(Icons.cloud_outlined),
                  ),
                ),
                if (testResult != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        testSuccess ? Icons.check_circle : Icons.error_outline,
                        color: testSuccess ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            color: testSuccess ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: testing
                    ? null
                    : () async {
                        setDialogState(() {
                          testing = true;
                          testResult = 'Pinging server...';
                        });
                        try {
                          final tempClient = ApiClient(baseUrl: controller.text.trim());
                          final res = await tempClient.get('/docs');
                          setDialogState(() {
                            testing = false;
                            testSuccess = res.statusCode == 200;
                            testResult = 'Server connected successfully (${res.statusCode})';
                          });
                        } catch (e) {
                          setDialogState(() {
                            testing = false;
                            testSuccess = false;
                            testResult = 'Connection failed: $e';
                          });
                        }
                      },
                child: testing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Test Connection'),
              ),
              FilledButton(
                onPressed: () {
                  final newUrl = controller.text.trim();
                  if (newUrl.isNotEmpty) {
                    ApiClient.instance.setBaseUrl(newUrl);
                    setState(() {
                      _currentApiUrl = newUrl;
                    });
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Cloud & Connectivity
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('CLOUD & BACKEND CONNECTIVITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Backend Server URL'),
            subtitle: Text(_currentApiUrl),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _showApiUrlDialog,
          ),
          const Divider(),

          // Appearance
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('APPEARANCE & THEME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
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
            leading: const Icon(Icons.eco_outlined),
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
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Enable Reminders'),
            value: notifState.enabled,
            onChanged: (val) => notifNotifier.setEnabled(val),
          ),
          ListTile(
            leading: const Icon(Icons.bedtime_outlined),
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
            secondary: const Icon(Icons.auto_awesome),
            title: const Text('OCR & Form Adaptation'),
            subtitle: const Text('Learn from your corrections to improve future suggestions'),
            value: mlState.learningEnabled,
            onChanged: (val) => mlNotifier.toggleLearning(val),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Reset Learned Corrections'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              mlNotifier.resetLearningData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset OCR learning data'), behavior: SnackBarBehavior.floating),
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
            leading: Icon(Icons.info_outline),
            title: Text('SchedSolicit Owner App'),
            subtitle: Text('Version 1.0.0 (Production Release)'),
          ),
        ],
      ),
    );
  }
}
