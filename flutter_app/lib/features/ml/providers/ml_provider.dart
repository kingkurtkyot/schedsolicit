import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final mlProvider = StateNotifierProvider<MlNotifier, MlState>((ref) {
  return MlNotifier();
});

class MlState {
  final bool learningEnabled;
  final int samplesLearned;

  const MlState({
    this.learningEnabled = true,
    this.samplesLearned = 0,
  });

  MlState copyWith({bool? learningEnabled, int? samplesLearned}) {
    return MlState(
      learningEnabled: learningEnabled ?? this.learningEnabled,
      samplesLearned: samplesLearned ?? this.samplesLearned,
    );
  }
}

class MlNotifier extends StateNotifier<MlState> {
  static const String _enabledKey = 'ml_learning_enabled';

  MlNotifier() : super(const MlState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(learningEnabled: prefs.getBool(_enabledKey) ?? true);
  }

  Future<void> toggleLearning(bool enabled) async {
    state = state.copyWith(learningEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> resetLearningData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ocr_user_corrections');
    state = state.copyWith(samplesLearned: 0);
  }
}
