import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/schedule_dao.dart';
import '../../../core/database/daos/solicitation_dao.dart';
import '../../../core/database/daos/audit_dao.dart';

class CrudResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const CrudResult.success(this.data)
      : isSuccess = true,
        error = null;

  const CrudResult.failure(this.error)
      : isSuccess = false,
        data = null;
}

class CrudService {
  final AppDatabase _db;
  final ScheduleDao _scheduleDao;
  final SolicitationDao _solicitationDao;
  final AuditDao _auditDao;
  final _uuid = const Uuid();

  CrudService(this._db)
      : _scheduleDao = ScheduleDao(_db),
        _solicitationDao = SolicitationDao(_db),
        _auditDao = AuditDao(_db);

  // Schedules
  Future<CrudResult<ScheduleEntry>> createSchedule(ScheduleEntry entry, {String source = 'app'}) async {
    try {
      if (entry.title.trim().isEmpty) {
        return const CrudResult.failure('Title is required');
      }

      // Check overlap
      final hasConflict = await checkScheduleOverlap(
        eventDate: entry.eventDate,
        startTime: entry.startTime,
        endTime: entry.endTime,
        excludeId: entry.id,
      );

      await _scheduleDao.insertSchedule(entry, source: source);
      return CrudResult.success(entry);
    } catch (e) {
      return CrudResult.failure(e.toString());
    }
  }

  Future<CrudResult<ScheduleEntry>> updateSchedule(ScheduleEntry entry, {String source = 'app'}) async {
    try {
      if (entry.title.trim().isEmpty) {
        return const CrudResult.failure('Title is required');
      }
      await _scheduleDao.updateSchedule(entry, source: source);
      return CrudResult.success(entry);
    } catch (e) {
      return CrudResult.failure(e.toString());
    }
  }

  Future<CrudResult<void>> deleteSchedule(String id) async {
    try {
      await _scheduleDao.softDelete(id);
      return const CrudResult.success(null);
    } catch (e) {
      return CrudResult.failure(e.toString());
    }
  }

  Future<bool> checkScheduleOverlap({
    required DateTime eventDate,
    String? startTime,
    String? endTime,
    String? excludeId,
  }) async {
    if (startTime == null || endTime == null) return false;
    final all = await _scheduleDao.getAllActive();
    for (final s in all) {
      if (excludeId != null && s.id == excludeId) continue;
      if (s.eventDate.year == eventDate.year &&
          s.eventDate.month == eventDate.month &&
          s.eventDate.day == eventDate.day) {
        if (s.startTime != null && s.endTime != null) {
          // Check overlap if both have times
          if (startTime.compareTo(s.endTime!) < 0 && endTime.compareTo(s.startTime!) > 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Solicitations
  Future<CrudResult<SolicitationEntry>> createSolicitation(SolicitationEntry entry, {String source = 'app'}) async {
    try {
      if (entry.title.trim().isEmpty) {
        return const CrudResult.failure('Title is required');
      }
      await _solicitationDao.insertSolicitation(entry, source: source);
      return CrudResult.success(entry);
    } catch (e) {
      return CrudResult.failure(e.toString());
    }
  }

  Future<CrudResult<SolicitationEntry>> updateSolicitation(SolicitationEntry entry, {String source = 'app'}) async {
    try {
      if (entry.title.trim().isEmpty) {
        return const CrudResult.failure('Title is required');
      }
      await _solicitationDao.updateSolicitation(entry, source: source);
      return CrudResult.success(entry);
    } catch (e) {
      return CrudResult.failure(e.toString());
    }
  }

  Future<CrudResult<void>> deleteSolicitation(String id) async {
    try {
      await _solicitationDao.softDelete(id);
      return const CrudResult.success(null);
    } catch (e) {
      return CrudResult.failure(e.toString());
    }
  }
}
