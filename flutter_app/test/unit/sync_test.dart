import 'package:flutter_test/flutter_test.dart';
import 'package:schedsolicit/core/sync/conflict_resolver.dart';

void main() {
  group('ConflictResolver Tests', () {
    test('resolveLastWriteWins selects newer updated_at timestamp', () {
      final client = {
        'id': '1',
        'title': 'Client newer title',
        'updated_at': '2026-11-20T12:00:00Z',
      };
      final server = {
        'id': '1',
        'title': 'Server older title',
        'updated_at': '2026-11-20T11:00:00Z',
      };

      final resolved = ConflictResolver.resolveLastWriteWins(
        clientData: client,
        serverData: server,
      );

      expect(resolved['title'], 'Client newer title');
    });

    test('field level merge preserves client non-conflicting field edits', () {
      final base = {
        'title': 'Initial Title',
        'location': 'Initial Location',
        'updated_at': '2026-11-20T10:00:00Z',
      };
      final client = {
        'title': 'Initial Title',
        'location': 'New Client Location',
        'updated_at': '2026-11-20T10:30:00Z',
      };
      final server = {
        'title': 'Updated Server Title',
        'location': 'Initial Location',
        'updated_at': '2026-11-20T10:45:00Z',
      };

      final merged = ConflictResolver.resolveFieldLevelMerge(
        baseData: base,
        clientData: client,
        serverData: server,
      );

      expect(merged['title'], 'Updated Server Title');
      expect(merged['location'], 'New Client Location');
    });
  });
}
