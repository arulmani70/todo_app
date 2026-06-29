// ignore_for_file: constant_identifier_names, non_constant_identifier_names

class DatabaseConstants {
  const DatabaseConstants();

  final String DATABASE_NAME = "notes_app.db";
  final int DATABASE_VERSION = 1;

  final String TABLE_NOTES = "notes";

  final String COLUMN_ID = "id";
  final String COLUMN_REMOTE_ID = "remote_id";
  final String COLUMN_TITLE = "title";
  final String COLUMN_BODY = "body";
  final String COLUMN_SYNC_STATUS = "sync_status";
  final String COLUMN_LOCAL_VERSION = "local_version";
  final String COLUMN_SERVER_UPDATED_AT = "server_updated_at";
  final String COLUMN_CREATED_AT = "created_at";
  final String COLUMN_UPDATED_AT = "updated_at";
  final String COLUMN_IS_DELETED = "is_deleted";

  final String SYNC_STATUS_SYNCED = "synced";
  final String SYNC_STATUS_PENDING = "pending_sync";
  final String SYNC_STATUS_CONFLICT = "conflict";
}
