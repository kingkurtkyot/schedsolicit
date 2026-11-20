import 'package:drift/drift.dart';

@DataClassName('AuditLogEntry')
class AuditLogTable extends Table {
  @override
  String get tableName => 'audit_logs';

  TextColumn get id => text()();
  TextColumn get itemId => text()();
  TextColumn get module => text()(); // schedule | solicitation
  TextColumn get action => text()(); // created, updated, status_changed, soft_deleted, restored
  TextColumn get field => text().nullable()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get actor => text().withDefault(const Constant('owner'))();
  TextColumn get source => text().withDefault(const Constant('app'))(); // app, scan, sync, import

  @override
  Set<Column> get primaryKey => {id};
}
