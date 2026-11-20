import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';
import '../tables/schedules_table.dart';
import '../tables/sync_outbox_table.dart';
import '../tables/audit_log_table.dart';

part 'schedule_dao.g.dart';

@DriftAccessor(tables: [SchedulesTable, SyncOutboxTable, AuditLogTable])
class ScheduleDao extends DatabaseAccessor<AppDatabase> with _$ScheduleDaoMixin {
  final _uuid = const Uuid();

  ScheduleDao(AppDatabase db) : super(db);

  // Reactive Watchers
  Stream<List<ScheduleEntry>> watchActive() {
    return (select(schedulesTable)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.status.equals('Active'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.eventDate)]))
        .watch();
  }

  Stream<List<ScheduleEntry>> watchHistory() {
    return (select(schedulesTable)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.status.isNotIn(['Active']))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.eventDate)]))
        .watch();
  }

  Stream<ScheduleEntry?> watchById(String id) {
    return (select(schedulesTable)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  Stream<List<ScheduleEntry>> watchByDateRange(DateTime start, DateTime end) {
    return (select(schedulesTable)
          ..where((tbl) =>
              tbl.isDeleted.equals(false) &
              tbl.eventDate.isBiggerOrEqualValue(start) &
              tbl.eventDate.isSmallerOrEqualValue(end))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.eventDate)]))
        .watch();
  }

  Future<List<ScheduleEntry>> getAllActive() {
    return (select(schedulesTable)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.status.equals('Active'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.eventDate)]))
        .get();
  }

  Future<ScheduleEntry?> getById(String id) {
    return (select(schedulesTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // Mutations with Outbox and Audit
  Future<void> insertSchedule(ScheduleEntry entry, {String source = 'app'}) {
    return transaction(() async {
      await into(schedulesTable).insert(entry);

      // Audit Log
      await into(auditLogTable).insert(
        AuditLogEntry(
          id: _uuid.v4(),
          itemId: entry.id,
          module: 'schedule',
          action: 'created',
          field: null,
          oldValue: null,
          newValue: jsonEncode(entry.toJson()),
          timestamp: DateTime.now().toUtc(),
          actor: 'owner',
          source: source,
        ),
      );

      // Sync Outbox
      await into(syncOutboxTable).insert(
        SyncOutboxEntry(
          id: _uuid.v4(),
          entityType: 'schedule',
          entityId: entry.id,
          operation: 'create',
          payload: jsonEncode(entry.toJson()),
          createdAt: DateTime.now().toUtc(),
          retryCount: 0,
          lastError: null,
        ),
      );
    });
  }

  Future<void> updateSchedule(ScheduleEntry entry, {String source = 'app'}) {
    return transaction(() async {
      final old = await getById(entry.id);
      await update(schedulesTable).replace(entry);

      await into(auditLogTable).insert(
        AuditLogEntry(
          id: _uuid.v4(),
          itemId: entry.id,
          module: 'schedule',
          action: 'updated',
          field: null,
          oldValue: old != null ? jsonEncode(old.toJson()) : null,
          newValue: jsonEncode(entry.toJson()),
          timestamp: DateTime.now().toUtc(),
          actor: 'owner',
          source: source,
        ),
      );

      await into(syncOutboxTable).insert(
        SyncOutboxEntry(
          id: _uuid.v4(),
          entityType: 'schedule',
          entityId: entry.id,
          operation: 'update',
          payload: jsonEncode(entry.toJson()),
          createdAt: DateTime.now().toUtc(),
          retryCount: 0,
          lastError: null,
        ),
      );
    });
  }

  Future<void> softDelete(String id) {
    return transaction(() async {
      final old = await getById(id);
      if (old == null) return;

      final updated = old.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now().toUtc(),
      );
      await update(schedulesTable).replace(updated);

      await into(auditLogTable).insert(
        AuditLogEntry(
          id: _uuid.v4(),
          itemId: id,
          module: 'schedule',
          action: 'soft_deleted',
          field: 'is_deleted',
          oldValue: 'false',
          newValue: 'true',
          timestamp: DateTime.now().toUtc(),
          actor: 'owner',
          source: 'app',
        ),
      );

      await into(syncOutboxTable).insert(
        SyncOutboxEntry(
          id: _uuid.v4(),
          entityType: 'schedule',
          entityId: id,
          operation: 'delete',
          payload: jsonEncode(updated.toJson()),
          createdAt: DateTime.now().toUtc(),
          retryCount: 0,
          lastError: null,
        ),
      );
    });
  }

  Future<void> restore(String id) {
    return transaction(() async {
      final old = await getById(id);
      if (old == null) return;

      final updated = old.copyWith(
        isDeleted: false,
        updatedAt: DateTime.now().toUtc(),
      );
      await update(schedulesTable).replace(updated);

      await into(auditLogTable).insert(
        AuditLogEntry(
          id: _uuid.v4(),
          itemId: id,
          module: 'schedule',
          action: 'restored',
          field: 'is_deleted',
          oldValue: 'true',
          newValue: 'false',
          timestamp: DateTime.now().toUtc(),
          actor: 'owner',
          source: 'app',
        ),
      );

      await into(syncOutboxTable).insert(
        SyncOutboxEntry(
          id: _uuid.v4(),
          entityType: 'schedule',
          entityId: id,
          operation: 'update',
          payload: jsonEncode(updated.toJson()),
          createdAt: DateTime.now().toUtc(),
          retryCount: 0,
          lastError: null,
        ),
      );
    });
  }

  Future<ScheduleEntry?> duplicate(String id) async {
    final original = await getById(id);
    if (original == null) return null;

    final now = DateTime.now().toUtc();
    final newId = _uuid.v4();
    final duplicated = original.copyWith(
      id: newId,
      title: '${original.title} (Copy)',
      createdAt: now,
      updatedAt: now,
      status: 'Active',
      completedAt: Value(null),
    );

    await insertSchedule(duplicated, source: 'app');
    return duplicated;
  }

  Future<void> bulkUpdateStatus(List<String> ids, String newStatus) {
    return transaction(() async {
      final now = DateTime.now().toUtc();
      for (final id in ids) {
        final item = await getById(id);
        if (item != null) {
          final isDone = newStatus == 'Done';
          final updated = item.copyWith(
            status: newStatus,
            updatedAt: now,
            completedAt: isDone ? Value(now) : Value(null),
          );
          await update(schedulesTable).replace(updated);

          await into(auditLogTable).insert(
            AuditLogEntry(
              id: _uuid.v4(),
              itemId: id,
              module: 'schedule',
              action: 'status_changed',
              field: 'status',
              oldValue: item.status,
              newValue: newStatus,
              timestamp: now,
              actor: 'owner',
              source: 'app',
            ),
          );

          await into(syncOutboxTable).insert(
            SyncOutboxEntry(
              id: _uuid.v4(),
              entityType: 'schedule',
              entityId: id,
              operation: 'update',
              payload: jsonEncode(updated.toJson()),
              createdAt: now,
              retryCount: 0,
              lastError: null,
            ),
          );
        }
      }
    });
  }

  Future<void> bulkDelete(List<String> ids) {
    return transaction(() async {
      for (final id in ids) {
        await softDelete(id);
      }
    });
  }

  Future<List<ScheduleEntry>> search(String query) {
    final pattern = '%$query%';
    return (select(schedulesTable)
          ..where((tbl) =>
              tbl.isDeleted.equals(false) &
              (tbl.title.like(pattern) |
                  tbl.description.like(pattern) |
                  tbl.location.like(pattern) |
                  tbl.notes.like(pattern))))
        .get();
  }
}
