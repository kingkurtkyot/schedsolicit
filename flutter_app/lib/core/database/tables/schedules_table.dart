import 'package:drift/drift.dart';

@DataClassName('ScheduleEntry')
class SchedulesTable extends Table {
  @override
  String get tableName => 'schedules';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get eventDate => dateTime()();
  TextColumn get startTime => text().nullable()(); // HH:mm or ISO
  TextColumn get endTime => text().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get location => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get repeatRule => text().nullable()(); // JSON string or RRULE
  TextColumn get reminderOffsets => text().nullable()(); // JSON list of seconds e.g. [3600]
  TextColumn get status => text().withDefault(const Constant('Active'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get actualStart => dateTime().nullable()();
  DateTimeColumn get actualEnd => dateTime().nullable()();
  DateTimeColumn get sourceDate => dateTime().nullable()();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get customFieldValues => text().nullable()(); // JSON encoded map
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
