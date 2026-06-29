import 'package:todo_app/src/common/repos/database_repository.dart';
import 'package:todo_app/src/common/common.dart';
import 'package:logger/logger.dart';

class NoteDatabaseRepository {
  final Logger log = Logger();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  Future<int> createNote(Map<String, dynamic> noteData) async {
    try {
      log.d("NoteDatabaseRepository::createNote::Creating note: $noteData");

      if (noteData[Constants.database.COLUMN_TITLE] == null) {
        throw Exception("Note title is required");
      }

      final id = await _dbRepo.insert(Constants.database.TABLE_NOTES, noteData);
      log.d("NoteDatabaseRepository::createNote::Note created with ID: $id");

      return id;
    } catch (error) {
      log.e("NoteDatabaseRepository::createNote::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    try {
      log.d("NoteDatabaseRepository::getAllNotes::Fetching notes");

      final notes = await _dbRepo.query(
        Constants.database.TABLE_NOTES,
        where: "${Constants.database.COLUMN_IS_DELETED} = 0",
        orderBy: "${Constants.database.COLUMN_UPDATED_AT} DESC",
      );

      log.d("NoteDatabaseRepository::getAllNotes::Found ${notes.length} notes");
      return notes;
    } catch (error) {
      log.e("NoteDatabaseRepository::getAllNotes::Error: $error");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getNoteById(int noteId) async {
    try {
      log.d("NoteDatabaseRepository::getNoteById::Fetching note with ID: $noteId");

      final notes = await _dbRepo.query(
        Constants.database.TABLE_NOTES,
        where: "${Constants.database.COLUMN_ID} = ? AND ${Constants.database.COLUMN_IS_DELETED} = 0",
        whereArgs: [noteId],
        limit: 1,
      );

      if (notes.isNotEmpty) {
        log.d("NoteDatabaseRepository::getNoteById::Found note: ${notes.first}");
        return notes.first;
      } else {
        log.d("NoteDatabaseRepository::getNoteById::Note not found");
        return null;
      }
    } catch (error) {
      log.e("NoteDatabaseRepository::getNoteById::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNotesBySyncStatus(String status) async {
    try {
      log.d("NoteDatabaseRepository::getNotesBySyncStatus::Fetching notes with status: $status");

      final notes = await _dbRepo.query(
        Constants.database.TABLE_NOTES,
        where: "${Constants.database.COLUMN_SYNC_STATUS} = ? AND ${Constants.database.COLUMN_IS_DELETED} = 0",
        whereArgs: [status],
      );

      log.d("NoteDatabaseRepository::getNotesBySyncStatus::Found ${notes.length} notes");
      return notes;
    } catch (error) {
      log.e("NoteDatabaseRepository::getNotesBySyncStatus::Error: $error");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getNoteByRemoteId(String remoteId) async {
    try {
      log.d("NoteDatabaseRepository::getNoteByRemoteId::Fetching note with remote ID: $remoteId");

      final notes = await _dbRepo.query(
        Constants.database.TABLE_NOTES,
        where: "${Constants.database.COLUMN_REMOTE_ID} = ? AND ${Constants.database.COLUMN_IS_DELETED} = 0",
        whereArgs: [remoteId],
        limit: 1,
      );

      if (notes.isNotEmpty) {
        return notes.first;
      }
      return null;
    } catch (error) {
      log.e("NoteDatabaseRepository::getNoteByRemoteId::Error: $error");
      rethrow;
    }
  }

  Future<int> updateNote(int noteId, Map<String, dynamic> noteData) async {
    try {
      log.d("NoteDatabaseRepository::updateNote::Updating note $noteId: $noteData");

      final count = await _dbRepo.update(
        Constants.database.TABLE_NOTES,
        noteData,
        where: "${Constants.database.COLUMN_ID} = ?",
        whereArgs: [noteId],
      );

      log.d("NoteDatabaseRepository::updateNote::Updated $count notes");
      return count;
    } catch (error) {
      log.e("NoteDatabaseRepository::updateNote::Error: $error");
      rethrow;
    }
  }

  Future<int> deleteNote(int noteId) async {
    try {
      log.d("NoteDatabaseRepository::deleteNote::Deleting note: $noteId");

      final count = await _dbRepo.softDelete(
        Constants.database.TABLE_NOTES,
        where: "${Constants.database.COLUMN_ID} = ?",
        whereArgs: [noteId],
      );

      log.d("NoteDatabaseRepository::deleteNote::Deleted $count notes");
      return count;
    } catch (error) {
      log.e("NoteDatabaseRepository::deleteNote::Error: $error");
      rethrow;
    }
  }

  Future<int> deleteNotePermanently(int noteId) async {
    try {
      log.d("NoteDatabaseRepository::deleteNotePermanently::Permanently deleting note: $noteId");

      final count = await _dbRepo.delete(
        Constants.database.TABLE_NOTES,
        where: "${Constants.database.COLUMN_ID} = ?",
        whereArgs: [noteId],
      );

      log.d("NoteDatabaseRepository::deleteNotePermanently::Permanently deleted $count notes");
      return count;
    } catch (error) {
      log.e("NoteDatabaseRepository::deleteNotePermanently::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingDeletions() async {
    try {
      log.d("NoteDatabaseRepository::getPendingDeletions::Fetching notes marked for deletion");

      final notes = await _dbRepo.query(
        Constants.database.TABLE_NOTES,
        where: "${Constants.database.COLUMN_IS_DELETED} = 1 AND ${Constants.database.COLUMN_REMOTE_ID} IS NOT NULL",
      );

      log.d("NoteDatabaseRepository::getPendingDeletions::Found ${notes.length} notes to delete remotely");
      return notes;
    } catch (error) {
      log.e("NoteDatabaseRepository::getPendingDeletions::Error: $error");
      rethrow;
    }
  }
}
