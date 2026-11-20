import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsState {
  final bool enabled;
  final int quietHoursStart;
  final int quietHoursEnd;
  final bool morningDigest;
  final int defaultReminderOffset;

  const NotificationSettingsState({
    this.enabled = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    this.morningDigest = true,
    this.defaultReminderOffset = 3600,
  });

  NotificationSettingsState copyWith({
    bool? enabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? morningDigest,
    int? defaultReminderOffset,
  }) {
    return NotificationSettingsState(
      enabled: enabled ?? this.enabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      morningDigest: morningDigest ?? this.morningDigest,
      defaultReminderOffset: defaultReminderOffset ?? this.defaultReminderOffset,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettingsState> {
  static const String _enabledKey = 'notif_enabled';
  static const String _quietStartKey = 'notif_quiet_start';
  static const String _quietEndKey = 'notif_quiet_end';

  NotificationSettingsNotifier() : super(const NotificationSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettingsState(
      enabled: prefs.getBool(_enabledKey) ?? true,
      quietHoursStart: prefs.getInt(_quietStartKey) ?? 22,
      quietHoursEnd: prefs.getInt(_quietEndKey) ?? 7,
    );
  }

  Future<void> setEnabled(bool val) async {
    state = state.copyWith(enabled: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, val);
  }

  Future<void> setQuietHours(int start, int end) async {
    state = state.copyWith(quietHoursStart: start, quietHoursEnd: end);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quietStartKey, start);
    await prefs.setInt(_quietEndKey, end);
  }
}
