import 'package:drift/drift.dart';

@DataClassName('SolicitationEntry')
class SolicitationsTable extends Table {
  @override
  String get tableName => 'solicitations';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get organization => text().nullable()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get purpose => text().nullable()();
  RealColumn get amountRequested => real().nullable()();
  TextColumn get quantityRequested => text().nullable()();
  DateTimeColumn get requestedDate => dateTime().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get followUpDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('Draft'))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get category => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();

  // Fulfillment / Given fields
  DateTimeColumn get givenDate => dateTime().nullable()();
  RealColumn get givenAmount => real().nullable()();
  TextColumn get givenItem => text().nullable()();
  TextColumn get givenBy => text().nullable()();
  TextColumn get givenTo => text().nullable()();

  DateTimeColumn get sourceDate => dateTime().nullable()();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get customFieldValues => text().nullable()(); // JSON map
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
