import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:todo_app/src/common/repos/api_repository.dart';
import 'package:todo_app/src/common/services/network_service.dart';
import 'note_database_repository.dart';
import 'package:todo_app/src/common/common.dart';

class NoteRepository {
  final Logger log = Logger();
  final NoteDatabaseRepository _dbRepo = NoteDatabaseRepository();
  final ApiRepository _apiRepo = ApiRepository();
  final NetworkService _networkService = NetworkService();
  bool _isSyncing = false;

  final ValueNotifier<int> syncVersion = ValueNotifier<int>(0);

  Future<void> initialize() async {
    try {
      log.d("NoteRepository::initialize::Initializing repositories");
      await _apiRepo.initialize();
      await _networkService.initialize();

      _networkService.networkStatusStream.listen((isOnline) {
        if (isOnline) {
          log.d("NoteRepository::initialize::Network came online, triggering sync");
          _triggerSync();
        } else {
          log.d("NoteRepository::initialize::Network went offline");
        }
      });

      if (_networkService.isOnline) {
        log.d("NoteRepository::initialize::Already online, triggering initial sync");
        _triggerSync();
      }

      log.d("NoteRepository::initialize::Repositories initialized successfully");
    } catch (error) {
      log.e("NoteRepository::initialize::Error: $error");
    }
  }

  Future<int> createNote(Map<String, dynamic> noteData) async {
    try {
      log.d("NoteRepository::createNote::Creating note");

      noteData[Constants.database.COLUMN_SYNC_STATUS] = Constants.database.SYNC_STATUS_PENDING;
      noteData[Constants.database.COLUMN_LOCAL_VERSION] = 1;

      final localId = await _dbRepo.createNote(noteData);
      log.d("NoteRepository::createNote::Created in local database with ID: $localId");

      if (await _networkService.checkConnectivity()) {
        await _syncSingleNoteToServer(localId);
      }

      return localId;
    } catch (error) {
      log.e("NoteRepository::createNote::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    try {
      log.d("NoteRepository::getAllNotes::Fetching all notes");

      final localNotes = await _dbRepo.getAllNotes();
      log.d("NoteRepository::getAllNotes::Found ${localNotes.length} notes in local database");

      return localNotes;
    } catch (error) {
      log.e("NoteRepository::getAllNotes::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllNotesWithSync() async {
    try {
      log.d("NoteRepository::getAllNotesWithSync::Fetching all notes with sync");

      final localNotes = await _dbRepo.getAllNotes();
      log.d("NoteRepository::getAllNotesWithSync::Found ${localNotes.length} notes in local database");

      if (await _networkService.checkConnectivity()) {
        try {
          await _pushPendingChanges();
          await _pullRemoteChanges();
          return await _dbRepo.getAllNotes();
        } catch (error) {
          log.w("NoteRepository::getAllNotesWithSync::Failed to sync: $error");
          return localNotes;
        }
      } else {
        log.d("NoteRepository::getAllNotesWithSync::Offline mode, returning local data");
        return localNotes;
      }
    } catch (error) {
      log.e("NoteRepository::getAllNotesWithSync::Error: $error");
      rethrow;
    }
  }

  Future<int> updateNote(int noteId, Map<String, dynamic> noteData) async {
    try {
      log.d("NoteRepository::updateNote::Updating note: $noteId");

      noteData[Constants.database.COLUMN_SYNC_STATUS] = Constants.database.SYNC_STATUS_PENDING;

      final existingNote = await _dbRepo.getNoteById(noteId);
      final currentVersion = existingNote?[Constants.database.COLUMN_LOCAL_VERSION] ?? 1;
      noteData[Constants.database.COLUMN_LOCAL_VERSION] = (currentVersion as int) + 1;

      final count = await _dbRepo.updateNote(noteId, noteData);
      log.d("NoteRepository::updateNote::Updated in local database");

      if (await _networkService.checkConnectivity()) {
        await _syncSingleNoteToServer(noteId);
      }

      return count;
    } catch (error) {
      log.e("NoteRepository::updateNote::Error: $error");
      rethrow;
    }
  }

  Future<int> deleteNote(int noteId) async {
    try {
      log.d("NoteRepository::deleteNote::Deleting note: $noteId");

      final localNote = await _dbRepo.getNoteById(noteId);
      final count = await _dbRepo.deleteNote(noteId);
      log.d("NoteRepository::deleteNote::Deleted from local database");

      if (await _networkService.checkConnectivity()) {
        if (localNote != null && localNote[Constants.database.COLUMN_REMOTE_ID] != null) {
          final remoteId = localNote[Constants.database.COLUMN_REMOTE_ID].toString();
          final result = await _apiRepo.deleteNote(remoteId);
          if (result) {
            log.d("NoteRepository::deleteNote::Synced deletion with server");
          }
        }
      }

      return count;
    } catch (error) {
      log.e("NoteRepository::deleteNote::Error: $error");
      rethrow;
    }
  }

  Future<void> resolveConflict(int noteId, String resolution) async {
    try {
      log.d("NoteRepository::resolveConflict::Resolving conflict for note $noteId with resolution: $resolution");

      final localNote = await _dbRepo.getNoteById(noteId);
      if (localNote == null) return;

      if (resolution == 'local') {
        await _dbRepo.updateNote(noteId, {
          Constants.database.COLUMN_SYNC_STATUS: Constants.database.SYNC_STATUS_PENDING,
        });

        if (await _networkService.checkConnectivity()) {
          await _syncSingleNoteToServer(noteId);
        }
      } else if (resolution == 'remote') {
        final remoteId = localNote[Constants.database.COLUMN_REMOTE_ID]?.toString();
        if (remoteId != null) {
          try {
            final remoteNote = await _apiRepo.getNoteById(remoteId);
            if (remoteNote != null) {
              await _dbRepo.updateNote(noteId, {
                Constants.database.COLUMN_TITLE: remoteNote['title'] ?? '',
                Constants.database.COLUMN_BODY: remoteNote['body'] ?? '',
                Constants.database.COLUMN_SYNC_STATUS: Constants.database.SYNC_STATUS_SYNCED,
                Constants.database.COLUMN_SERVER_UPDATED_AT: remoteNote['updatedAt']?.toString(),
              });
            }
          } catch (error) {
            log.e("NoteRepository::resolveConflict::Error fetching remote: $error");
          }
        }
      }
    } catch (error) {
      log.e("NoteRepository::resolveConflict::Error: $error");
      rethrow;
    }
  }

  Future<void> syncAllData() async {
    if (_isSyncing) {
      log.d("NoteRepository::syncAllData::Sync already in progress, skipping");
      return;
    }

    try {
      _isSyncing = true;
      log.d("NoteRepository::syncAllData::Starting full sync");

      if (!await _networkService.checkConnectivity()) {
        log.w("NoteRepository::syncAllData::No network connection, skipping sync");
        return;
      }

      await _pushPendingChanges();
      await _pullRemoteChanges();

      log.d("NoteRepository::syncAllData::Sync completed");
      syncVersion.value++;
    } catch (error) {
      log.e("NoteRepository::syncAllData::Error: $error");
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushPendingChanges() async {
    try {
      log.d("NoteRepository::_pushPendingChanges::Pushing pending changes to server");

      final pendingNotes = await _dbRepo.getNotesBySyncStatus(Constants.database.SYNC_STATUS_PENDING);

      for (final note in pendingNotes) {
        final noteId = note[Constants.database.COLUMN_ID] as int;
        await _syncSingleNoteToServer(noteId);
      }

      final deletedNotes = await _dbRepo.getPendingDeletions();
      for (final note in deletedNotes) {
        try {
          final remoteId = note[Constants.database.COLUMN_REMOTE_ID].toString();
          await _apiRepo.deleteNote(remoteId);
          await _dbRepo.deleteNotePermanently(note[Constants.database.COLUMN_ID] as int);
          log.d("NoteRepository::_pushPendingChanges::Deleted remotely: $remoteId");
        } catch (error) {
          log.w("NoteRepository::_pushPendingChanges::Failed to delete remotely: $error");
        }
      }

      log.d("NoteRepository::_pushPendingChanges::Pending changes pushed");
    } catch (error) {
      log.e("NoteRepository::_pushPendingChanges::Error: $error");
    }
  }

  Future<void> _syncSingleNoteToServer(int noteId) async {
    try {
      final localNote = await _dbRepo.getNoteById(noteId);
      if (localNote == null) return;

      final remoteId = localNote[Constants.database.COLUMN_REMOTE_ID]?.toString();

      final data = {
        'title': localNote[Constants.database.COLUMN_TITLE] ?? '',
        'body': localNote[Constants.database.COLUMN_BODY] ?? '',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      bool syncSuccess = false;

      if (remoteId != null && remoteId.isNotEmpty) {
        final result = await _apiRepo.updateNote(remoteId, data);
        if (result) {
          log.d("NoteRepository::_syncSingleNoteToServer::Updated remote note: $remoteId");
          syncSuccess = true;
        }
      } else {
        final response = await _apiRepo.createNote(data);
        if (response != null) {
          final newRemoteId = response['id']?.toString();
          if (newRemoteId != null) {
            await _dbRepo.updateNote(noteId, {
              Constants.database.COLUMN_REMOTE_ID: newRemoteId,
            });
            log.d("NoteRepository::_syncSingleNoteToServer::Created remote note with ID: $newRemoteId");
            syncSuccess = true;
          }
        }
      }

      if (syncSuccess) {
        await _dbRepo.updateNote(noteId, {
          Constants.database.COLUMN_SYNC_STATUS: Constants.database.SYNC_STATUS_SYNCED,
          Constants.database.COLUMN_SERVER_UPDATED_AT: data['updatedAt'],
        });
      }
    } catch (error) {
      log.w("NoteRepository::_syncSingleNoteToServer::Failed to sync note $noteId: $error");
    }
  }

  Future<void> _pullRemoteChanges() async {
    try {
      log.d("NoteRepository::_pullRemoteChanges::Pulling remote changes");

      final remoteNotes = await _apiRepo.getAllNotes();
      log.d("NoteRepository::_pullRemoteChanges::Fetched ${remoteNotes.length} remote notes");

      final remoteIds = remoteNotes.map((n) => n['id']?.toString()).whereType<String>().toSet();

      for (final remoteNote in remoteNotes) {
        final remoteId = remoteNote['id']?.toString();
        if (remoteId == null) continue;

        final localNote = await _dbRepo.getNoteByRemoteId(remoteId);

        if (localNote == null) {
          await _createLocalFromRemote(remoteNote, remoteId);
        } else {
          await _mergeNoteIfNeeded(localNote, remoteNote);
        }
      }

      final allLocalNotes = await _dbRepo.getAllNotes();
      for (final localNote in allLocalNotes) {
        final remoteId = localNote[Constants.database.COLUMN_REMOTE_ID]?.toString();
        if (remoteId == null || remoteId.isEmpty) continue;

        if (!remoteIds.contains(remoteId)) {
          final syncStatus = localNote[Constants.database.COLUMN_SYNC_STATUS]?.toString();
          if (syncStatus == Constants.database.SYNC_STATUS_SYNCED) {
            await _dbRepo.deleteNotePermanently(localNote[Constants.database.COLUMN_ID] as int);
            log.d("NoteRepository::_pullRemoteChanges::Removed local note deleted from server: $remoteId");
          }
        }
      }
    } catch (error) {
      log.w("NoteRepository::_pullRemoteChanges::Error: $error");
    }
  }

  Future<void> _createLocalFromRemote(Map<String, dynamic> remoteNote, String remoteId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final serverUpdatedAt = remoteNote['updatedAt']?.toString() ?? now;

      await _dbRepo.createNote({
        Constants.database.COLUMN_REMOTE_ID: remoteId,
        Constants.database.COLUMN_TITLE: remoteNote['title'] ?? '',
        Constants.database.COLUMN_BODY: remoteNote['body'] ?? '',
        Constants.database.COLUMN_SYNC_STATUS: Constants.database.SYNC_STATUS_SYNCED,
        Constants.database.COLUMN_LOCAL_VERSION: 1,
        Constants.database.COLUMN_SERVER_UPDATED_AT: serverUpdatedAt,
        Constants.database.COLUMN_CREATED_AT: now,
        Constants.database.COLUMN_UPDATED_AT: now,
      });

      log.d("NoteRepository::_createLocalFromRemote::Created local note from remote: $remoteId");
    } catch (error) {
      log.w("NoteRepository::_createLocalFromRemote::Error: $error");
    }
  }

  Future<void> _mergeNoteIfNeeded(Map<String, dynamic> localNote, Map<String, dynamic> remoteNote) async {
    try {
      final localId = localNote[Constants.database.COLUMN_ID] as int;
      final localSyncStatus = localNote[Constants.database.COLUMN_SYNC_STATUS]?.toString();
      final localServerUpdatedAt = localNote[Constants.database.COLUMN_SERVER_UPDATED_AT]?.toString();
      final remoteUpdatedAt = remoteNote['updatedAt']?.toString();

      if (remoteUpdatedAt == null) return;

      bool hasRemoteNewerChanges = _isDateNewer(remoteUpdatedAt, localServerUpdatedAt);
      bool hasLocalPendingChanges = localSyncStatus == Constants.database.SYNC_STATUS_PENDING;

      if (hasRemoteNewerChanges && hasLocalPendingChanges) {
        await _dbRepo.updateNote(localId, {
          Constants.database.COLUMN_SYNC_STATUS: Constants.database.SYNC_STATUS_CONFLICT,
        });
        log.d("NoteRepository::_mergeNoteIfNeeded::Conflict detected for note $localId");
      } else if (hasRemoteNewerChanges) {
        await _dbRepo.updateNote(localId, {
          Constants.database.COLUMN_TITLE: remoteNote['title'] ?? '',
          Constants.database.COLUMN_BODY: remoteNote['body'] ?? '',
          Constants.database.COLUMN_SYNC_STATUS: Constants.database.SYNC_STATUS_SYNCED,
          Constants.database.COLUMN_SERVER_UPDATED_AT: remoteUpdatedAt,
        });
        log.d("NoteRepository::_mergeNoteIfNeeded::Updated local note $localId from remote");
      }
    } catch (error) {
      log.w("NoteRepository::_mergeNoteIfNeeded::Error: $error");
    }
  }

  bool _isDateNewer(String? dateA, String? dateB) {
    if (dateA == null) return false;
    if (dateB == null) return true;

    try {
      final parsedA = DateTime.parse(dateA);
      final parsedB = DateTime.parse(dateB);
      return parsedA.isAfter(parsedB);
    } catch (e) {
      return false;
    }
  }

  Future<void> _triggerSync() async {
    try {
      log.d("NoteRepository::_triggerSync::Network came online, starting sync");

      await Future.delayed(const Duration(seconds: 2));

      await syncAllData();

      log.d("NoteRepository::_triggerSync::Sync completed after network recovery");
    } catch (error) {
      log.e("NoteRepository::_triggerSync::Error: $error");
    }
  }

  void dispose() {
    syncVersion.dispose();
    _networkService.dispose();
  }
}
