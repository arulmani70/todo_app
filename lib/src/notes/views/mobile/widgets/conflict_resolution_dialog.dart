import 'package:flutter/material.dart';
import 'package:todo_app/src/common/common.dart';
import 'package:todo_app/src/notes/bloc/note_bloc.dart';

void showConflictResolutionDialog(BuildContext context, NoteBloc bloc, Map<String, dynamic> note) {
  final localTitle = note[Constants.database.COLUMN_TITLE] ?? '';
  final localBody = note[Constants.database.COLUMN_BODY] ?? '';
  final noteId = note[Constants.database.COLUMN_ID] as int;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          const Expanded(child: Text('Conflict Detected', style: TextStyle(fontSize: 18))),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The note "$localTitle" has been modified on both this device and the server.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('Choose which version to keep:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.withValues(alpha: 0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_android, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      const Text('Local Version', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(localTitle.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (localBody.toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(localBody.toString(), style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text('vs', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.green.withValues(alpha: 0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      const Text('Server Version', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('(fetching from server...)',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            bloc.add(ResolveConflict(noteId: noteId, resolution: 'local'));
          },
          child: const Text('Keep Local'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            bloc.add(ResolveConflict(noteId: noteId, resolution: 'remote'));
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          child: const Text('Keep Server'),
        ),
      ],
    ),
  );
}
