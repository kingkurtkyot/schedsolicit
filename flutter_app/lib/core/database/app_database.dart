import 'package:drift/drift.dart';
import 'connection/connection.dart';

import 'tables/schedules_table.dart';
import 'tables/solicitations_table.dart';
import 'tables/custom_fields_table.dart';
import 'tables/audit_log_table.dart';
import 'tables/sync_outbox_table.dart';
import 'tables/attachments_table.dart';
import 'tables/categories_table.dart';
import 'tables/share_links_table.dart';

import 'daos/schedule_dao.dart';
import 'daos/solicitation_dao.dart';
import 'daos/audit_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SchedulesTable,
    SolicitationsTable,
    CustomFieldsTable,
    AuditLogTable,
    SyncOutboxTable,
    AttachmentsTable,
    CategoriesTable,
    ShareLinksTable,
  ],
  daos: [
    ScheduleDao,
    SolicitationDao,
    AuditDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Migration strategies for schema evolution (e.g. v1 -> v2)
          if (from < 2) {
            // Future migration steps
          }
        },
      );
}
