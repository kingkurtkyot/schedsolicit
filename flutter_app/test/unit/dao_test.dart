import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:schedsolicit/core/database/app_database.dart';
import 'package:schedsolicit/core/database/daos/schedule_dao.dart';
import 'package:schedsolicit/core/database/daos/solicitation_dao.dart';

void main() {
  late AppDatabase db;
  late ScheduleDao scheduleDao;
  late SolicitationDao solicitationDao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    scheduleDao = ScheduleDao(db);
    solicitationDao = SolicitationDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ScheduleDao Tests', () {
    test('insert, get, softDelete, and restore schedule', () async {
      final now = DateTime.now().toUtc();
      final schedule = ScheduleEntry(
        id: 'test-1',
        title: 'Strategy Meeting',
        eventDate: now,
        priority: 'high',
        status: 'Active',
        createdAt: now,
        updatedAt: now,
        allDay: false,
        visibility: 'private',
        isDeleted: false,
      );

      await scheduleDao.insertSchedule(schedule);

      final fetched = await scheduleDao.getById('test-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Strategy Meeting');

      // Soft delete
      await scheduleDao.softDelete('test-1');
      final deleted = await scheduleDao.getById('test-1');
      expect(deleted!.isDeleted, true);

      // Restore
      await scheduleDao.restore('test-1');
      final restored = await scheduleDao.getById('test-1');
      expect(restored!.isDeleted, false);
    });

    test('duplicate schedule', () async {
      final now = DateTime.now().toUtc();
      final schedule = ScheduleEntry(
        id: 'dup-1',
        title: 'Original Event',
        eventDate: now,
        priority: 'medium',
        status: 'Active',
        createdAt: now,
        updatedAt: now,
        allDay: false,
        visibility: 'private',
        isDeleted: false,
      );

      await scheduleDao.insertSchedule(schedule);
      final dup = await scheduleDao.duplicate('dup-1');

      expect(dup, isNotNull);
      expect(dup!.title, 'Original Event (Copy)');
      expect(dup.id, isNot('dup-1'));
    });
  });

  group('SolicitationDao Tests', () {
    test('insert and search solicitations by organization', () async {
      final now = DateTime.now().toUtc();
      final solicitation = SolicitationEntry(
        id: 'sol-1',
        title: 'Winter Campaign Support',
        organization: 'Acme Charity Org',
        amountRequested: 5000.0,
        status: 'Draft',
        priority: 'urgent',
        createdAt: now,
        updatedAt: now,
        visibility: 'private',
        isDeleted: false,
      );

      await solicitationDao.insertSolicitation(solicitation);

      final results = await solicitationDao.search('Acme');
      expect(results.length, 1);
      expect(results.first.organization, 'Acme Charity Org');
    });
  });
}
