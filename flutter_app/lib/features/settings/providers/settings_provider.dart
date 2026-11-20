import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsState {
  final bool offlineMode;
  final String syncInterval;

  const AppSettingsState({
    this.offlineMode = false,
    this.syncInterval = '5m',
  });
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(const AppSettingsState());

  Future<void> toggleOfflineMode(bool offline) async {
    state = AppSettingsState(offlineMode: offline, syncInterval: state.syncInterval);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', offline);
  }
}
