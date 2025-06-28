import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_app/src/common/repos/firestore_repository.dart';
import 'package:todo_app/src/common/services/network_service.dart';
import 'todo_database_repository.dart';

class TodoRepository {
  final Logger log = Logger();
  final TodoDatabaseRepository _dbRepo = TodoDatabaseRepository();
  final FirestoreRepository _firestoreRepo = FirestoreRepository();
  final NetworkService _networkService = NetworkService();
  bool _isSyncing = false;

  Future<void> initialize() async {
    try {
      log.d("TodoRepository::initialize::Initializing repositories");
      await _firestoreRepo.initialize();
      await _networkService.initialize();

      await _cleanupDuplicates();

      _networkService.networkStatusStream.listen((isOnline) {
        if (isOnline) {
          log.d("TodoRepository::initialize::Network came online, triggering sync");
          _triggerSync();
        } else {
          log.d("TodoRepository::initialize::Network went offline");
        }
      });

      log.d("TodoRepository::initialize::Repositories initialized successfully");
    } catch (error) {
      log.e("TodoRepository::initialize::Error: $error");
    }
  }

  Future<int> createTodo(Map<String, dynamic> todoData) async {
    try {
      log.d("TodoRepository::createTodo::Creating todo");

      final localId = await _dbRepo.createTodo(todoData);
      log.d("TodoRepository::createTodo::Created in local database with ID: $localId");

      if (await _networkService.checkConnectivity()) {
        try {
          todoData['id'] = localId;
          final firestoreId = await _firestoreRepo.createTodo(todoData);
          log.d("TodoRepository::createTodo::Synced with Firestore with ID: $firestoreId");

          await _dbRepo.updateTodo(localId, {'firestore_id': firestoreId});
          await _firestoreRepo.updateTodo(firestoreId, {...todoData, 'firestore_id': firestoreId});
        } catch (error) {
          log.w("TodoRepository::createTodo::Failed to sync with Firestore: $error");

          await _dbRepo.updateTodo(localId, {'needs_sync': true});
        }
      } else {
        log.d("TodoRepository::createTodo::Offline mode, marking for later sync");
        await _dbRepo.updateTodo(localId, {'needs_sync': true});
      }

      return localId;
    } catch (error) {
      log.e("TodoRepository::createTodo::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTodos() async {
    try {
      log.d("TodoRepository::getAllTodos::Fetching all todos");

      final localTodos = await _dbRepo.getAllTodos();
      log.d("TodoRepository::getAllTodos::Found ${localTodos.length} todos in local database");

      return localTodos;
    } catch (error) {
      log.e("TodoRepository::getAllTodos::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTodosWithSync() async {
    try {
      log.d("TodoRepository::getAllTodosWithSync::Fetching all todos with sync");

      final localTodos = await _dbRepo.getAllTodos();
      log.d("TodoRepository::getAllTodosWithSync::Found ${localTodos.length} todos in local database");

      if (await _networkService.checkConnectivity()) {
        try {
          final firestoreTodos = await _firestoreRepo.getAllTodos();
          log.d("TodoRepository::getAllTodosWithSync::Found ${firestoreTodos.length} todos in Firestore");

          await _mergeAndSyncTodos(localTodos, firestoreTodos);

          return await _dbRepo.getAllTodos();
        } catch (error) {
          log.w("TodoRepository::getAllTodosWithSync::Failed to fetch from Firestore: $error");
          return localTodos;
        }
      } else {
        log.d("TodoRepository::getAllTodosWithSync::Offline mode, returning local data");
        return localTodos;
      }
    } catch (error) {
      log.e("TodoRepository::getAllTodosWithSync::Error: $error");
      rethrow;
    }
  }

  Future<int> updateTodo(int todoId, Map<String, dynamic> todoData) async {
    try {
      log.d("TodoRepository::updateTodo::Updating todo: $todoId");

      final count = await _dbRepo.updateTodo(todoId, todoData);
      log.d("TodoRepository::updateTodo::Updated in local database");

      if (await _networkService.checkConnectivity()) {
        try {
          final localTodo = await _dbRepo.getTodoById(todoId);
          if (localTodo != null && localTodo['firestore_id'] != null) {
            await _firestoreRepo.updateTodo(localTodo['firestore_id'], todoData);
            log.d("TodoRepository::updateTodo::Synced with Firestore");
          } else {
            await _dbRepo.updateTodo(todoId, {'needs_sync': true});
            log.d("TodoRepository::updateTodo::Marked for later sync");
          }
        } catch (error) {
          log.w("TodoRepository::updateTodo::Failed to sync with Firestore: $error");
          await _dbRepo.updateTodo(todoId, {'needs_sync': true});
        }
      } else {
        log.d("TodoRepository::updateTodo::Offline mode, marking for later sync");
        await _dbRepo.updateTodo(todoId, {'needs_sync': true});
      }

      return count;
    } catch (error) {
      log.e("TodoRepository::updateTodo::Error: $error");
      rethrow;
    }
  }

  Future<int> deleteTodo(int todoId) async {
    try {
      log.d("TodoRepository::deleteTodo::Deleting todo: $todoId");

      final localTodo = await _dbRepo.getTodoById(todoId);
      final count = await _dbRepo.deleteTodo(todoId);
      log.d("TodoRepository::deleteTodo::Deleted from local database");

      if (await _networkService.checkConnectivity()) {
        try {
          if (localTodo != null && localTodo['firestore_id'] != null) {
            await _firestoreRepo.deleteTodo(localTodo['firestore_id'], localTodo);
            log.d("TodoRepository::deleteTodo::Synced with Firestore");
          }
        } catch (error) {
          log.w("TodoRepository::deleteTodo::Failed to sync with Firestore: $error");
        }
      }

      return count;
    } catch (error) {
      log.e("TodoRepository::deleteTodo::Error: $error");
      rethrow;
    }
  }

  Future<void> syncAllData() async {
    if (_isSyncing) {
      log.d("TodoRepository::syncAllData::Sync already in progress, skipping");
      return;
    }

    try {
      _isSyncing = true;
      log.d("TodoRepository::syncAllData::Starting full sync");

      if (!await _networkService.checkConnectivity()) {
        log.w("TodoRepository::syncAllData::No network connection, skipping sync");
        return;
      }

      await _cleanupDuplicates();

      final localTodos = await _dbRepo.getAllTodos();
      log.d("TodoRepository::syncAllData::Found ${localTodos.length} local todos");

      try {
        final firestoreTodos = await _firestoreRepo.getAllTodos();
        log.d("TodoRepository::syncAllData::Found ${firestoreTodos.length} Firestore todos");

        await _mergeAndSyncTodos(localTodos, firestoreTodos);
        log.d("TodoRepository::syncAllData::Sync completed");
      } catch (error) {
        log.w("TodoRepository::syncAllData::Failed to sync with Firestore: $error");
      }
    } catch (error) {
      log.e("TodoRepository::syncAllData::Error: $error");
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _cleanupDuplicates() async {
    try {
      log.d("TodoRepository::_cleanupDuplicates::Cleaning up duplicate entries based on firestore_id");

      final allTodos = await _dbRepo.getAllTodos();
      final seenFirestoreIds = <String, int>{};
      final duplicatesToRemove = <int>[];

      for (final todo in allTodos) {
        final firestoreId = todo['firestore_id']?.toString();
        final todoId = todo['id'] as int;

        if (firestoreId != null && firestoreId.isNotEmpty) {
          if (seenFirestoreIds.containsKey(firestoreId)) {
            final existingId = seenFirestoreIds[firestoreId]!;

            log.d("TodoRepository::_cleanupDuplicates::Found duplicate firestore_id: $firestoreId");
            log.d("TodoRepository::_cleanupDuplicates::Existing todo ID: $existingId, Current todo ID: $todoId");

            // Keep the one with the lower ID (older one) and remove the newer one
            if (todoId > existingId) {
              duplicatesToRemove.add(todoId);
              log.d("TodoRepository::_cleanupDuplicates::Removing current todo (newer ID)");
            } else {
              duplicatesToRemove.add(existingId);
              seenFirestoreIds[firestoreId] = todoId;
              log.d("TodoRepository::_cleanupDuplicates::Removing existing todo (newer ID)");
            }
          } else {
            seenFirestoreIds[firestoreId] = todoId;
          }
        } else {
          // For todos without firestore_id, check by title and description
          final title = todo['title']?.toString().toLowerCase() ?? '';
          final description = todo['description']?.toString().toLowerCase() ?? '';
          final key = '$title|$description';

          if (seenFirestoreIds.containsKey(key)) {
            final existingId = seenFirestoreIds[key]!;

            log.d("TodoRepository::_cleanupDuplicates::Found duplicate by content - Title: $title");
            log.d("TodoRepository::_cleanupDuplicates::Existing todo ID: $existingId, Current todo ID: $todoId");

            // Keep the one with the lower ID (older one) and remove the newer one
            if (todoId > existingId) {
              duplicatesToRemove.add(todoId);
              log.d("TodoRepository::_cleanupDuplicates::Removing current todo (newer ID)");
            } else {
              duplicatesToRemove.add(existingId);
              seenFirestoreIds[key] = todoId;
              log.d("TodoRepository::_cleanupDuplicates::Removing existing todo (newer ID)");
            }
          } else {
            seenFirestoreIds[key] = todoId;
          }
        }
      }

      for (final todoId in duplicatesToRemove) {
        log.d("TodoRepository::_cleanupDuplicates::Permanently deleting duplicate todo: $todoId");
        await _dbRepo.deleteTodoPermanently(todoId);
      }

      log.d("TodoRepository::_cleanupDuplicates::Cleaned up ${duplicatesToRemove.length} duplicates");
    } catch (error) {
      log.e("TodoRepository::_cleanupDuplicates::Error: $error");
    }
  }

  Future<void> _triggerSync() async {
    try {
      log.d("TodoRepository::_triggerSync::Network came online, starting sync");

      await Future.delayed(const Duration(seconds: 2));

      await syncAllData();

      log.d("TodoRepository::_triggerSync::Sync completed after network recovery");
    } catch (error) {
      log.e("TodoRepository::_triggerSync::Error: $error");
    }
  }

  Future<void> _mergeAndSyncTodos(List<Map<String, dynamic>> localTodos, List<Map<String, dynamic>> firestoreTodos) async {
    try {
      if (localTodos.isEmpty && firestoreTodos.isEmpty) {
        log.d("TodoRepository::_mergeAndSyncTodos::No todos to merge");
        return;
      }
      if (firestoreTodos.isEmpty) {
        return;
      }
      if (localTodos.isEmpty && firestoreTodos.isNotEmpty) {
        for (final firestoreTodo in firestoreTodos) {
          final localData = Map<String, dynamic>.from(firestoreTodo);
          localData['needs_sync'] = false;
          localData.remove('id');
          await _dbRepo.createTodo(localData);
        }
        return;
      } else {
        log.d("TodoRepository::_mergeAndSyncTodos::Starting merge - Local: ${localTodos.length}, Firestore: ${firestoreTodos.length}");

        final localMap = <String, Map<String, dynamic>>{};
        final firestoreMap = <String, Map<String, dynamic>>{};

        for (final todo in localTodos) {
          localMap[todo['id'].toString()] = todo;
        }

        for (final todo in firestoreTodos) {
          firestoreMap[todo['firestore_id'].toString()] = todo;
        }

        // First, handle existing Firestore todos that need to be synced to local
        int createdCount = 0;
        int updatedCount = 0;
        int linkedCount = 0;

        for (final firestoreTodo in firestoreTodos) {
          final firestoreId = firestoreTodo['firestore_id'].toString();
          log.d("TodoRepository::_mergeAndSyncTodos::Processing Firestore todo: $firestoreId");

          Map<String, dynamic>? existingLocalTodo;
          for (final localTodo in localTodos) {
            if (localTodo['firestore_id'] == firestoreId) {
              existingLocalTodo = localTodo;
              log.d("TodoRepository::_mergeAndSyncTodos::Found existing local todo with matching firestore_id: ${localTodo['id']}");
              break;
            }
          }

          if (existingLocalTodo == null) {
            final firestoreTitle = firestoreTodo['title']?.toString().toLowerCase() ?? '';
            final firestoreDescription = firestoreTodo['description']?.toString().toLowerCase() ?? '';

            log.d("TodoRepository::_mergeAndSyncTodos::No direct match found, checking by content - Title: $firestoreTitle");

            // Try to find a local todo by content (title+description) and no firestore_id
            final possibleMatches = localTodos.where((localTodo) {
              final localTitle = localTodo['title']?.toString().toLowerCase() ?? '';
              final localDescription = localTodo['description']?.toString().toLowerCase() ?? '';
              return localTitle == firestoreTitle &&
                  localDescription == firestoreDescription &&
                  (localTodo['firestore_id'] == null || localTodo['firestore_id'].toString().isEmpty);
            }).toList();

            if (possibleMatches.length == 1) {
              final matchedLocalTodo = possibleMatches.first;
              await _dbRepo.updateTodo(matchedLocalTodo['id'], {'firestore_id': firestoreId, 'needs_sync': false});
              linkedCount++;
              log.d("TodoRepository::_mergeAndSyncTodos::Linked local todo ${matchedLocalTodo['id']} to Firestore: $firestoreId");
            } else {
              // No match found, create a new local entry
              final localData = Map<String, dynamic>.from(firestoreTodo);
              localData['firestore_id'] = firestoreId;
              localData['needs_sync'] = false;
              localData.remove('id');
              if (firestoreTodo['created_at'] != null) {
                localData['created_at'] = firestoreTodo['created_at'] is Timestamp
                    ? firestoreTodo['created_at'].toDate().toIso8601String()
                    : firestoreTodo['created_at'].toString();
              }
              if (firestoreTodo['updated_at'] != null) {
                localData['updated_at'] = firestoreTodo['updated_at'] is Timestamp
                    ? firestoreTodo['updated_at'].toDate().toIso8601String()
                    : firestoreTodo['updated_at'].toString();
              }
              await _dbRepo.createTodo(localData);
              createdCount++;
              log.d("TodoRepository::_mergeAndSyncTodos::Created local todo from Firestore: $firestoreId");
            }
          } else {
            final localUpdatedAt = existingLocalTodo['updated_at'];
            final firestoreUpdatedAt = firestoreTodo['updated_at'];

            bool shouldUpdate = false;

            if (firestoreUpdatedAt != null) {
              if (localUpdatedAt == null) {
                shouldUpdate = true;
              } else {
                DateTime? localDateTime;
                DateTime? firestoreDateTime;

                try {
                  if (localUpdatedAt is String) {
                    localDateTime = DateTime.parse(localUpdatedAt);
                  } else if (localUpdatedAt is DateTime) {
                    localDateTime = localUpdatedAt;
                  }

                  if (firestoreUpdatedAt is Timestamp) {
                    firestoreDateTime = firestoreUpdatedAt.toDate();
                  } else if (firestoreUpdatedAt is String) {
                    firestoreDateTime = DateTime.parse(firestoreUpdatedAt);
                  } else if (firestoreUpdatedAt is DateTime) {
                    firestoreDateTime = firestoreUpdatedAt;
                  }

                  if (localDateTime != null && firestoreDateTime != null) {
                    shouldUpdate = firestoreDateTime.isAfter(localDateTime);
                  }
                } catch (e) {
                  log.w("TodoRepository::_mergeAndSyncTodos::Error comparing timestamps: $e");
                  shouldUpdate = true;
                }
              }
            }

            if (shouldUpdate) {
              log.d("TodoRepository::_mergeAndSyncTodos::Updating local todo from Firestore: ${existingLocalTodo['id']}");
              try {
                final localData = Map<String, dynamic>.from(firestoreTodo);
                localData['firestore_id'] = firestoreId;
                localData['needs_sync'] = false;

                localData.remove('id');

                if (firestoreTodo['created_at'] != null) {
                  localData['created_at'] = firestoreTodo['created_at'] is Timestamp
                      ? firestoreTodo['created_at'].toDate().toIso8601String()
                      : firestoreTodo['created_at'].toString();
                }

                if (firestoreTodo['updated_at'] != null) {
                  localData['updated_at'] = firestoreTodo['updated_at'] is Timestamp
                      ? firestoreTodo['updated_at'].toDate().toIso8601String()
                      : firestoreTodo['updated_at'].toString();
                }

                await _dbRepo.updateTodo(existingLocalTodo['id'], localData);
                updatedCount++;
                log.d("TodoRepository::_mergeAndSyncTodos::Updated local todo from Firestore: ${existingLocalTodo['id']}");
              } catch (error) {
                log.w("TodoRepository::_mergeAndSyncTodos::Failed to update local todo ${existingLocalTodo['id']}: $error");
              }
            } else {
              if (existingLocalTodo['firestore_id'] == null) {
                log.d("TodoRepository::_mergeAndSyncTodos::Linking local todo to Firestore: ${existingLocalTodo['id']} -> $firestoreId");
                try {
                  await _dbRepo.updateTodo(existingLocalTodo['id'], {'firestore_id': firestoreId, 'needs_sync': false});
                  linkedCount++;
                  log.d("TodoRepository::_mergeAndSyncTodos::Linked local todo ${existingLocalTodo['id']} to Firestore: $firestoreId");
                } catch (error) {
                  log.w("TodoRepository::_mergeAndSyncTodos::Failed to link local todo ${existingLocalTodo['id']}: $error");
                }
              }
            }
          }
        }

        // Now handle local todos that need to be synced to Firestore
        // Get fresh local todos after the above operations
        final updatedLocalTodos = await _dbRepo.getAllTodos();
        log.d("TodoRepository::_mergeAndSyncTodos::Got updated local todos: ${updatedLocalTodos.length}");

        for (final localTodo in updatedLocalTodos) {
          final localId = localTodo['id'].toString();
          final firestoreId = localTodo['firestore_id'];
          final needsSync = localTodo['needs_sync'] == true;

          log.d("TodoRepository::_mergeAndSyncTodos::Processing local todo: $localId, Firestore ID: $firestoreId, Needs sync: $needsSync");

          if (needsSync || firestoreId == null) {
            try {
              if (firestoreId != null) {
                log.d("TodoRepository::_mergeAndSyncTodos::Updating existing Firestore document: $firestoreId");
                await _firestoreRepo.updateTodo(firestoreId, localTodo);
              } else {
                log.d("TodoRepository::_mergeAndSyncTodos::Creating new Firestore document for local todo: $localId");
                final newFirestoreId = await _firestoreRepo.createTodo(localTodo);
                await _firestoreRepo.updateTodo(newFirestoreId, {...localTodo, 'firestore_id': newFirestoreId});
                await _dbRepo.updateTodo(int.parse(localId), {'firestore_id': newFirestoreId, 'needs_sync': false});
                log.d("TodoRepository::_mergeAndSyncTodos::Created Firestore document: $newFirestoreId for local todo: $localId");
              }
            } catch (error) {
              log.w("TodoRepository::_mergeAndSyncTodos::Failed to sync local todo $localId: $error");
            }
          }
        }

        log.d("TodoRepository::_mergeAndSyncTodos::Merge completed - Created: $createdCount, Updated: $updatedCount, Linked: $linkedCount");
      }
    } catch (error) {
      log.e("TodoRepository::_mergeAndSyncTodos::Error: $error");
      rethrow;
    }
  }

  void dispose() {
    _networkService.dispose();
  }

  Future<void> cleanupDuplicates() async {
    await _cleanupDuplicates();
  }
}
