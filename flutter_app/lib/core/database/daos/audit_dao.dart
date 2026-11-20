import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';
import '../tables/audit_log_table.dart';

part 'audit_dao.g.dart';

@DriftAccessor(tables: [AuditLogTable])
class AuditDao extends DatabaseAccessor<AppDatabase> with _$AuditDaoMixin {
  final _uuid = const Uuid();

  AuditDao(AppDatabase db) : super(db);

  Stream<List<AuditLogEntry>> watchTimelineForItem(String itemId) {
    return (select(auditLogTable)
          ..where((tbl) => tbl.itemId.equals(itemId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
        .watch();
  }

  Stream<List<AuditLogEntry>> watchGlobalActivity({int limit = 100}) {
    return (select(auditLogTable)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)])
          ..limit(limit))
        .watch();
  }

  Future<List<AuditLogEntry>> getTimelineForItem(String itemId) {
    return (select(auditLogTable)
          ..where((tbl) => tbl.itemId.equals(itemId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]))
        .get();
  }

  Future<void> record({
    required String itemId,
    required String module,
    required String action,
    String? field,
    String? oldValue,
    String? newValue,
    String actor = 'owner',
    String source = 'app',
  }) {
    return into(auditLogTable).insert(
      AuditLogEntry(
        id: _uuid.v4(),
        itemId: itemId,
        module: module,
        action: action,
        field: field,
        oldValue: oldValue,
        newValue: newValue,
        timestamp: DateTime.now().toUtc(),
        actor: actor,
        source: source,
      ),
    );
  }
}
