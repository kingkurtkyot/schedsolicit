import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/filter_state.dart';
import '../../shared/providers/filter_provider.dart';
import '../models/solicitation_item.dart';

final solicitationListProvider =
    StateNotifierProvider<SolicitationListNotifier, AsyncValue<List<SolicitationItem>>>((ref) {
  return SolicitationListNotifier(ref);
});

class SolicitationListNotifier extends StateNotifier<AsyncValue<List<SolicitationItem>>> {
  final Ref ref;
  List<SolicitationItem> _allSolicitations = [];

  SolicitationListNotifier(this.ref) : super(const AsyncValue.loading()) {
    ref.listen<FilterState>(filterProvider, (_, __) {
      _applyFilter();
    });
    _loadSampleData();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    _allSolicitations = [
      SolicitationItem(
        id: 'sol-1',
        title: 'Tech Education Grant Application',
        organization: 'FutureTech Foundation',
        contactPerson: 'Sarah Jenkins',
        email: 'sarah.j@futuretech.org',
        phone: '+1 555-0192',
        purpose: 'Funding for 30 student laptops and coding curriculum licenses.',
        amountRequested: 15000.0,
        deadline: now.add(const Duration(days: 12)),
        status: 'Sent',
        priority: 'high',
        category: 'Grant',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      SolicitationItem(
        id: 'sol-2',
        title: 'Youth Sports Sponsorship 2026',
        organization: 'Metro Athletics Club',
        contactPerson: 'David Miller',
        phone: '+1 555-0144',
        purpose: 'Jersey sponsorship for 4 youth soccer teams.',
        amountRequested: 3500.0,
        deadline: now.add(const Duration(days: 20)),
        status: 'Approved',
        priority: 'medium',
        category: 'Sponsorship',
        givenDate: now.subtract(const Duration(days: 1)),
        givenAmount: 3500.0,
        givenBy: 'Owner Fund',
        givenTo: 'Metro Athletics',
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
    _applyFilter();
  }

  void _applyFilter() {
    final filter = ref.read(filterProvider);
    var filtered = _allSolicitations.where((item) {
      if (item.isDeleted) return false;

      // Scope
      if (filter.scope == FilterScope.active && item.isDone) return false;
      if (filter.scope == FilterScope.history && !item.isDone) return false;

      // Status
      if (filter.statuses.isNotEmpty && !filter.statuses.contains(item.status)) return false;

      // Priority
      if (filter.priorities.isNotEmpty && !filter.priorities.contains(item.priority)) return false;

      // Category
      if (filter.categories.isNotEmpty && item.category != null && !filter.categories.contains(item.category)) {
        return false;
      }

      // Search Query
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        final match = item.title.toLowerCase().contains(q) ||
            (item.organization?.toLowerCase().contains(q) ?? false) ||
            (item.contactPerson?.toLowerCase().contains(q) ?? false) ||
            (item.purpose?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      final dateA = a.deadline ?? a.createdAt;
      final dateB = b.deadline ?? b.createdAt;
      return filter.sortOrder == SortOrder.asc ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    state = AsyncValue.data(filtered);
  }

  void addItem(SolicitationItem item) {
    _allSolicitations.insert(0, item);
    _applyFilter();
  }

  void updateItem(SolicitationItem item) {
    final index = _allSolicitations.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _allSolicitations[index] = item;
      _applyFilter();
    }
  }

  void deleteItem(String id) {
    _allSolicitations.removeWhere((i) => i.id == id);
    _applyFilter();
  }

  SolicitationItem? getById(String id) {
    return _allSolicitations.where((i) => i.id == id).firstOrNull;
  }
}
