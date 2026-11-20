import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/base_item.dart';
import '../models/filter_state.dart';

abstract class ItemsState<T extends BaseItem> {
  final List<T> items;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final int page;
  final int pageSize;

  const ItemsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.page = 1,
    this.pageSize = 25,
  });

  List<T> get filteredItems => items;
}

class GenericItemsNotifier<T extends BaseItem> extends StateNotifier<AsyncValue<List<T>>> {
  final Stream<List<T>> Function() _streamSource;

  GenericItemsNotifier(this._streamSource) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _streamSource().listen(
      (data) {
        state = AsyncValue.data(data);
      },
      onError: (err, stack) {
        state = AsyncValue.error(err, stack);
      },
    );
  }

  void refresh() {
    state = const AsyncValue.loading();
    _init();
  }
}
