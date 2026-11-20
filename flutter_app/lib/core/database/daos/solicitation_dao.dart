import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';
import '../tables/solicitations_table.dart';
import '../tables/sync_outbox_table.dart';
import '../tables/audit_log_table.dart';

part 'solicitation_dao.g.dart';

@DriftAccessor(tables: [SolicitationsTable, SyncOutboxTable, AuditLogTable])
class SolicitationDao extends DatabaseAccessor<AppDatabase> with _$SolicitationDaoMixin {
  final _uuid = const Uuid();

  SolicitationDao(AppDatabase db) : super(db);

  Stream<List<SolicitationEntry>> watchActive() {
    return (select(solicitationsTable)
          ..where((tbl) =>
              tbl.isDeleted.equals(false) &
              tbl.status.isIn(['Draft', 'Sent', 'Pending']))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.deadline)]))
        .watch();
  }

  Stream<List<SolicitationEntry>> watchHistory() {
    return (select(solicitationsTable)
          ..where((tbl) =>
              tbl.isDeleted.equals(false) &
              tbl.status.isIn(['Done', 'Approved', 'Declined', 'Given', 'Cancelled']))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
        .watch();
  }

  Stream<SolicitationEntry?> watchById(String id) {
    return (select(solicitationsTable)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  Stream<List<SolicitationEntry>> watchByOrganization(String organization) {
    return (select(solicitationsTable)
          ..where((tbl) =>
              tbl.isDeleted.equals(false) &
              tbl.organization.equals(organization))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  Future<List<SolicitationEntry>> getAllActive() {
    return (select(solicitationsTable)
          ..where((tbl) =>
              tbl.isDeleted.equals(false) &
              tbl.status.isIn(['Draft', 'Sent', 'Pending']))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.deadline)]))
        .get();
  }

  Future<SolicitationEntry?> getById(String id) {
    return (select(solicitationsTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<List<SolicitationEntry>> getByOrganization(String organization) {
    return (select(solicitationsTable)
          ..where((tbl) =>
              tbl.isDeleted.equals(false) &
              tbl.organization.equals(organization))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  Future<void> insertSolicitation(SolicitationEntry entry, {String source = 'app'}) {
    return transaction(() async {
      await into(solicitationsTable).insert(entry);

      await into(auditLogTable).insert(
        AuditLogEntry(
          id: _uuid.v4(),
          itemId: entry.id,
          module: 'solicitation',
          action: 'created',
          field: null,
          oldValue: null,
          newValue: jsonEncode(entry.toJson()),
          timestamp: DateTime.now().toUtc(),
          actor: 'owner',
          source: source,
        ),
      );

      await into(syncOutboxTable).insert(
        SyncOutboxEntry(
          id: _uuid.v4(),
          entityType: 'solicitation',
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

  Future<void> updateSolicitation(SolicitationEntry entry, {String source = 'app'}) {
    return transaction(() async {
      final old = await getById(entry.id);
      await update(solicitationsTable).replace(entry);

      await into(auditLogTable).insert(
        AuditLogEntry(
          id: _uuid.v4(),
          itemId: entry.id,
          module: 'solicitation',
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
          entityType: 'solicitation',
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
      await update(solicitationsTable).replace(updated);

      await into(auditLogTable).insert(
        AuditLogEntry(
          id: _uuid.v4(),
          itemId: id,
          module: 'solicitation',
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
          entityType: 'solicitation',
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
      await update(solicitationsTable).replace(updated);

      await into(auditLogTable).insert(
        AuditLogEntry(
          id: _uuid.v4(),
          itemId: id,
          module: 'solicitation',
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
          entityType: 'solicitation',
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

  Future<SolicitationEntry?> duplicate(String id) async {
    final original = await getById(id);
    if (original == null) return null;

    final now = DateTime.now().toUtc();
    final newId = _uuid.v4();
    final duplicated = original.copyWith(
      id: newId,
      title: '${original.title} (Copy)',
      createdAt: now,
      updatedAt: now,
      status: 'Draft',
      givenDate: Value(null),
      givenAmount: Value(null),
      givenItem: Value(null),
      givenBy: Value(null),
      givenTo: Value(null),
      completedAt: Value(null),
    );

    await insertSolicitation(duplicated, source: 'app');
    return duplicated;
  }

  Future<void> bulkUpdateStatus(List<String> ids, String newStatus) {
    return transaction(() async {
      final now = DateTime.now().toUtc();
      for (final id in ids) {
        final item = await getById(id);
        if (item != null) {
          final isDone = newStatus == 'Done' || newStatus == 'Given';
          final updated = item.copyWith(
            status: newStatus,
            updatedAt: now,
            completedAt: isDone ? Value(now) : Value(null),
          );
          await update(solicitationsTable).replace(updated);

          await into(auditLogTable).insert(
            AuditLogEntry(
              id: _uuid.v4(),
              itemId: id,
              module: 'solicitation',
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
              entityType: 'solicitation',
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

  Future<List<SolicitationEntry>> search(String query) {
    final pattern = '%$query%';
    return (select(solicitationsTable)
          ..where((tbl) =>
              tbl.isDeleted.equals(false) &
              (tbl.title.like(pattern) |
                  tbl.organization.like(pattern) |
                  tbl.contactPerson.like(pattern) |
                  tbl.purpose.like(pattern) |
                  tbl.notes.like(pattern))))
        .get();
  }
}
