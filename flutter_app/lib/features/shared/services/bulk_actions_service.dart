import '../../../core/database/app_database.dart';
import '../../../core/database/daos/schedule_dao.dart';
import '../../../core/database/daos/solicitation_dao.dart';

class BulkActionsService {
  final AppDatabase _db;
  final ScheduleDao _scheduleDao;
  final SolicitationDao _solicitationDao;

  final Set<String> _selectedIds = {};

  BulkActionsService(this._db)
      : _scheduleDao = ScheduleDao(_db),
        _solicitationDao = SolicitationDao(_db);

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get hasSelection => _selectedIds.isNotEmpty;
  int get count => _selectedIds.length;

  void toggleSelect(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
  }

  void selectAll(Iterable<String> ids) {
    _selectedIds.addAll(ids);
  }

  void clearSelection() {
    _selectedIds.clear();
  }

  Future<void> bulkDeleteSchedules() async {
    if (_selectedIds.isEmpty) return;
    await _scheduleDao.bulkDelete(_selectedIds.toList());
    _selectedIds.clear();
  }

  Future<void> bulkUpdateScheduleStatus(String status) async {
    if (_selectedIds.isEmpty) return;
    await _scheduleDao.bulkUpdateStatus(_selectedIds.toList(), status);
    _selectedIds.clear();
  }

  Future<void> bulkDeleteSolicitations() async {
    if (_selectedIds.isEmpty) return;
    await _solicitationDao.bulkDelete(_selectedIds.toList());
    _selectedIds.clear();
  }

  Future<void> bulkUpdateSolicitationStatus(String status) async {
    if (_selectedIds.isEmpty) return;
    await _solicitationDao.bulkUpdateStatus(_selectedIds.toList(), status);
    _selectedIds.clear();
  }
}
