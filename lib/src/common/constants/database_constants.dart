// ignore_for_file: constant_identifier_names, non_constant_identifier_names

class DatabaseConstants {
  const DatabaseConstants();

  final String DATABASE_NAME = "todo_app.db";
  final int DATABASE_VERSION = 2;

  final String TABLE_TODOS = "todos";

  final String COLUMN_ID = "id";
  final String COLUMN_CREATED_AT = "created_at";
  final String COLUMN_UPDATED_AT = "updated_at";
  final String COLUMN_IS_DELETED = "is_deleted";

  final String COLUMN_TODO_TITLE = "title";
  final String COLUMN_TODO_DESCRIPTION = "description";
  final String COLUMN_TODO_IS_COMPLETED = "is_completed";
  final String COLUMN_TODO_PRIORITY = "priority";
  final String COLUMN_TODO_DUE_DATE = "due_date";

  final String COLUMN_FIRESTORE_ID = "firestore_id";
  final String COLUMN_NEEDS_SYNC = "needs_sync";

  final String PRIORITY_LOW = "low";
  final String PRIORITY_MEDIUM = "medium";
  final String PRIORITY_HIGH = "high";
}
