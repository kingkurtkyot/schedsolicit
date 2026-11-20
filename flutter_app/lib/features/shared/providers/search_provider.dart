import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

class SearchState {
  final String query;
  final List<String> recentSearches;
  final List<String> suggestions;
  final bool isDebouncing;

  const SearchState({
    this.query = '',
    this.recentSearches = const [],
    this.suggestions = const [],
    this.isDebouncing = false,
  });

  SearchState copyWith({
    String? query,
    List<String>? recentSearches,
    List<String>? suggestions,
    bool? isDebouncing,
  }) {
    return SearchState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      suggestions: suggestions ?? this.suggestions,
      isDebouncing: isDebouncing ?? this.isDebouncing,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  static const String _recentKey = 'recent_search_queries';
  Timer? _debounceTimer;

  SearchNotifier() : super(const SearchState()) {
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    state = state.copyWith(recentSearches: list);
  }

  void onQueryChanged(String newQuery, {List<String> pool = const []}) {
    _debounceTimer?.cancel();
    state = state.copyWith(query: newQuery, isDebouncing: true);

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      final suggestions = pool
          .where((s) => s.toLowerCase().contains(newQuery.toLowerCase()))
          .take(10)
          .toList();

      state = state.copyWith(
        suggestions: suggestions,
        isDebouncing: false,
      );
    });
  }

  Future<void> addRecent(String query) async {
    if (query.trim().isEmpty) return;
    final updated = List<String>.from(state.recentSearches);
    updated.remove(query);
    updated.insert(0, query);
    if (updated.length > 10) updated.removeLast();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, updated);
    state = state.copyWith(recentSearches: updated);
  }

  Future<void> clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    state = state.copyWith(recentSearches: const []);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
