import 'package:drift/drift.dart';

@DataClassName('CategoryEntry')
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get module => text()(); // schedule | solicitation | both
  TextColumn get name => text()();
  TextColumn get color => text()(); // Hex string e.g. #2E7D32
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
