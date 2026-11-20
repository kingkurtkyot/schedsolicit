import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../config/app_config.dart';
import '../database/app_database.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'sync_state.dart';
import 'conflict_resolver.dart';

class SyncEngine {
  final AppDatabase _db;
  final ApiClient _apiClient;
  Timer? _syncTimer;

  final _syncStateController = StreamController<SyncState>.broadcast();
  SyncState _currentState = const SyncState();

  SyncEngine({required AppDatabase db, required ApiClient apiClient})
      : _db = db,
        _apiClient = apiClient {
    _syncStateController.add(_currentState);
  }

  Stream<SyncState> get stateStream => _syncStateController.stream;
  SyncState get currentState => _currentState;

  void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(AppConfig.syncInterval, (_) => sync());
    // Initial sync
    unawaited(sync());
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _updateState(SyncState newState) {
    _currentState = newState;
    _syncStateController.add(_currentState);
  }

  Future<void> sync() async {
    if (_currentState.isSyncing) return;

    final outboxEntries = await (_db.select(_db.syncOutboxTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    _updateState(_currentState.copyWith(
      status: SyncStatus.syncing,
      pendingCount: outboxEntries.length,
      errorMessage: null,
    ));

    try {
      // 1. Push dirty items from outbox
      if (outboxEntries.isNotEmpty) {
        final pushBatch = outboxEntries.take(AppConfig.syncBatchSize).map((e) {
          final payload = jsonDecode(e.payload) as Map<String, dynamic>;
          final updatedAt = payload['updated_at'] ?? e.createdAt.toIso8601String();
          return {
            'id': e.entityId,
            'module': e.entityType,
            'action': e.operation == 'delete' ? 'delete' : 'upsert',
            'data': payload,
            'updated_at': updatedAt,
          };
        }).toList();

        final response = await _apiClient.post(
          ApiEndpoints.syncPush,
          data: {'items': pushBatch},
        );

        if (response.statusCode == 200) {
          final processedIds = outboxEntries.take(AppConfig.syncBatchSize).map((e) => e.id).toList();
          await (_db.delete(_db.syncOutboxTable)..where((t) => t.id.isIn(processedIds))).go();
        }
      }

      // 2. Pull server changes since lastSyncedAt
      final lastSyncIso = _currentState.lastSyncedAt?.toIso8601String();
      final pullRes = await _apiClient.get(
        ApiEndpoints.syncPull,
        queryParameters: lastSyncIso != null ? {'since': lastSyncIso} : null,
      );

      if (pullRes.statusCode == 200 && pullRes.data != null) {
        final data = pullRes.data as Map<String, dynamic>;
        final schedules = (data['schedules'] as List<dynamic>?) ?? [];
        final solicitations = (data['solicitations'] as List<dynamic>?) ?? [];

        // Apply schedules
        for (final item in schedules) {
          final map = item as Map<String, dynamic>;
          final id = map['id'] as String;
          final existing = await (_db.select(_db.schedulesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

          if (existing != null) {
            final resolved = ConflictResolver.resolveLastWriteWins(
              clientData: existing.toJson(),
              serverData: map,
            );
            await _db.update(_db.schedulesTable).replace(ScheduleEntry.fromJson(resolved));
          } else {
            await _db.into(_db.schedulesTable).insert(ScheduleEntry.fromJson(map));
          }
        }

        // Apply deleted IDs
        final deletedIds = (data['deleted_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        for (final delId in deletedIds) {
          final s = await (_db.select(_db.schedulesTable)..where((t) => t.id.equals(delId))).getSingleOrNull();
          if (s != null) {
            await _db.update(_db.schedulesTable).replace(s.copyWith(isDeleted: true));
          }
          final sol = await (_db.select(_db.solicitationsTable)..where((t) => t.id.equals(delId))).getSingleOrNull();
          if (sol != null) {
            await _db.update(_db.solicitationsTable).replace(sol.copyWith(isDeleted: true));
          }
        }
        for (final item in solicitations) {
          final map = item as Map<String, dynamic>;
          final id = map['id'] as String;
          final existing = await (_db.select(_db.solicitationsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

          if (existing != null) {
            final resolved = ConflictResolver.resolveLastWriteWins(
              clientData: existing.toJson(),
              serverData: map,
            );
            await _db.update(_db.solicitationsTable).replace(SolicitationEntry.fromJson(resolved));
          } else {
            await _db.into(_db.solicitationsTable).insert(SolicitationEntry.fromJson(map));
          }
        }
      }

      final remaining = await (_db.select(_db.syncOutboxTable)).get();

      _updateState(_currentState.copyWith(
        status: SyncStatus.success,
        lastSyncedAt: DateTime.now().toUtc(),
        pendingCount: remaining.length,
        errorMessage: null,
      ));
    } catch (e) {
      _updateState(_currentState.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void dispose() {
    stopPeriodicSync();
    _syncStateController.close();
  }
}
