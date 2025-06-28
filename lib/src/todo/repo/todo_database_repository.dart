import 'package:todo_app/src/common/repos/database_repository.dart';
import 'package:todo_app/src/common/common.dart';
import 'package:logger/logger.dart';

class TodoDatabaseRepository {
  final Logger log = Logger();
  final DatabaseRepository _dbRepo = DatabaseRepository();

  Future<int> createTodo(Map<String, dynamic> todoData) async {
    try {
      log.d("TodoDatabaseRepository::createTodo::Creating todo: $todoData");

      if (todoData[Constants.database.COLUMN_TODO_TITLE] == null) {
        throw Exception("Todo title is required");
      }

      final id = await _dbRepo.insert(Constants.database.TABLE_TODOS, todoData);
      log.d("TodoDatabaseRepository::createTodo::Todo created with ID: $id");

      return id;
    } catch (error) {
      log.e("TodoDatabaseRepository::createTodo::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTodos({int? userId}) async {
    try {
      log.d("TodoDatabaseRepository::getAllTodos::Fetching todos for user: $userId");

      String? whereClause;
      List<Object?>? whereArgs;

      whereClause = "${Constants.database.COLUMN_IS_DELETED} = 0";

      final todos = await _dbRepo.query(
        Constants.database.TABLE_TODOS,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: "${Constants.database.COLUMN_CREATED_AT} DESC",
      );

      log.d("TodoDatabaseRepository::getAllTodos::Found ${todos.length} todos");
      return todos;
    } catch (error) {
      log.e("TodoDatabaseRepository::getAllTodos::Error: $error");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTodoById(int todoId) async {
    try {
      log.d("TodoDatabaseRepository::getTodoById::Fetching todo with ID: $todoId");

      final todos = await _dbRepo.query(
        Constants.database.TABLE_TODOS,
        where: "${Constants.database.COLUMN_ID} = ? AND ${Constants.database.COLUMN_IS_DELETED} = 0",
        whereArgs: [todoId],
        limit: 1,
      );

      if (todos.isNotEmpty) {
        log.d("TodoDatabaseRepository::getTodoById::Found todo: ${todos.first}");
        return todos.first;
      } else {
        log.d("TodoDatabaseRepository::getTodoById::Todo not found");
        return null;
      }
    } catch (error) {
      log.e("TodoDatabaseRepository::getTodoById::Error: $error");
      rethrow;
    }
  }

  Future<int> updateTodo(int todoId, Map<String, dynamic> todoData) async {
    try {
      log.d("TodoDatabaseRepository::updateTodo::Updating todo $todoId: $todoData");

      final count = await _dbRepo.update(Constants.database.TABLE_TODOS, todoData, where: "${Constants.database.COLUMN_ID} = ?", whereArgs: [todoId]);

      log.d("TodoDatabaseRepository::updateTodo::Updated $count todos");
      return count;
    } catch (error) {
      log.e("TodoDatabaseRepository::updateTodo::Error: $error");
      rethrow;
    }
  }

  Future<int> deleteTodo(int todoId) async {
    try {
      log.d("TodoDatabaseRepository::deleteTodo::Deleting todo: $todoId");

      final count = await _dbRepo.softDelete(Constants.database.TABLE_TODOS, where: "${Constants.database.COLUMN_ID} = ?", whereArgs: [todoId]);

      log.d("TodoDatabaseRepository::deleteTodo::Deleted $count todos");
      return count;
    } catch (error) {
      log.e("TodoDatabaseRepository::deleteTodo::Error: $error");
      rethrow;
    }
  }

  Future<int> deleteTodoPermanently(int todoId) async {
    try {
      log.d("TodoDatabaseRepository::deleteTodoPermanently::Permanently deleting todo: $todoId");

      final count = await _dbRepo.delete(Constants.database.TABLE_TODOS, where: "${Constants.database.COLUMN_ID} = ?", whereArgs: [todoId]);

      log.d("TodoDatabaseRepository::deleteTodoPermanently::Permanently deleted $count todos");
      return count;
    } catch (error) {
      log.e("TodoDatabaseRepository::deleteTodoPermanently::Error: $error");
      rethrow;
    }
  }
}
