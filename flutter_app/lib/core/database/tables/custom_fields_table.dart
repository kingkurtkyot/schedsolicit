import 'package:drift/drift.dart';

@DataClassName('CustomFieldEntry')
class CustomFieldsTable extends Table {
  @override
  String get tableName => 'custom_fields';

  TextColumn get id => text()();
  TextColumn get module => text()(); // schedule | solicitation
  TextColumn get name => text()();
  TextColumn get fieldType => text()(); // text, number, date, dropdown, checkbox
  TextColumn get options => text().nullable()(); // JSON array for dropdown
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
