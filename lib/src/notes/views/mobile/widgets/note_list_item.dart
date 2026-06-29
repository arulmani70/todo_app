import 'package:flutter/material.dart';
import 'package:todo_app/src/common/common.dart';
import 'package:todo_app/src/notes/bloc/note_bloc.dart';
import 'package:todo_app/src/notes/views/mobile/widgets/note_form_bottom_sheet.dart';
import 'package:todo_app/src/notes/views/mobile/widgets/conflict_resolution_dialog.dart';

class NoteListItem extends StatelessWidget {
  final NoteBloc _noteBloc;
  final Map<String, dynamic> note;
  const NoteListItem({super.key, required this.note, required NoteBloc noteBloc}) : _noteBloc = noteBloc;

  @override
  Widget build(BuildContext context) {
    final syncStatus = note[Constants.database.COLUMN_SYNC_STATUS]?.toString() ?? Constants.database.SYNC_STATUS_SYNCED;
    final isConflict = syncStatus == Constants.database.SYNC_STATUS_CONFLICT;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (isConflict) {
            showConflictResolutionDialog(context, _noteBloc, note);
          } else {
            showNoteFormBottomSheet(context, _noteBloc, note: note);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note[Constants.database.COLUMN_TITLE] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildSyncStatusIcon(syncStatus),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              showNoteFormBottomSheet(context, _noteBloc, note: note);
                            } else if (value == 'delete') {
                              _showDeleteDialog(context);
                            } else if (value == 'resolve') {
                              showConflictResolutionDialog(context, _noteBloc, note);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                            if (syncStatus == Constants.database.SYNC_STATUS_CONFLICT)
                              const PopupMenuItem(value: 'resolve', child: Row(children: [Icon(Icons.compare_arrows, size: 18), SizedBox(width: 8), Text('Resolve Conflict')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                          ],
                        ),
                      ],
                    ),
                    if (note[Constants.database.COLUMN_BODY] != null && note[Constants.database.COLUMN_BODY].toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note[Constants.database.COLUMN_BODY] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSyncStatusLabel(syncStatus),
                        const Spacer(),
                        Text(
                          _formatDate(note[Constants.database.COLUMN_UPDATED_AT]),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusIcon(String status) {
    switch (status) {
      case 'synced':
        return const Icon(Icons.cloud_done, size: 18, color: Colors.green);
      case 'pending_sync':
        return const Icon(Icons.cloud_upload, size: 18, color: Colors.orange);
      case 'conflict':
        return const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red);
      default:
        return const Icon(Icons.cloud_done, size: 18, color: Colors.green);
    }
  }

  Widget _buildSyncStatusLabel(String status) {
    Color color;
    String label;

    switch (status) {
      case 'synced':
        color = Colors.green;
        label = 'Synced';
      case 'pending_sync':
        color = Colors.orange;
        label = 'Pending Sync';
      case 'conflict':
        color = Colors.red;
        label = 'Conflict';
      default:
        color = Colors.green;
        label = 'Synced';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note[Constants.database.COLUMN_TITLE]}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _noteBloc.add(DeleteNote(id: note[Constants.database.COLUMN_ID]));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
