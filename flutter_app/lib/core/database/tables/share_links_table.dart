import 'package:drift/drift.dart';

@DataClassName('ShareLinkEntry')
class ShareLinksTable extends Table {
  @override
  String get tableName => 'share_links';

  TextColumn get id => text()();
  TextColumn get token => text()();
  TextColumn get label => text()();
  TextColumn get scope => text()(); // JSON string with scope config
  TextColumn get privacyControls => text().nullable()(); // JSON string
  DateTimeColumn get expiresAt => dateTime().nullable()();
  IntColumn get viewLimit => integer().nullable()();
  IntColumn get viewCount => integer().withDefault(const Constant(0))();
  BoolColumn get allowExport => boolean().withDefault(const Constant(true))();
  BoolColumn get isRevoked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
