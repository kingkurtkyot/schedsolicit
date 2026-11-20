import 'package:drift/drift.dart';

@DataClassName('AttachmentEntry')
class AttachmentsTable extends Table {
  @override
  String get tableName => 'attachments';

  TextColumn get id => text()();
  TextColumn get itemId => text()();
  TextColumn get module => text()(); // schedule | solicitation
  TextColumn get filePath => text()();
  TextColumn get fileType => text()(); // image, pdf, etc.
  TextColumn get purpose => text().withDefault(const Constant('general'))(); // receipt, document, proof
  TextColumn get ocrText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
