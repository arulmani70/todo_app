import 'package:flutter/material.dart';
import 'package:todo_app/src/common/common.dart';
import 'package:todo_app/src/common/repos/api_repository.dart';
import 'package:todo_app/src/notes/bloc/note_bloc.dart';
import 'package:todo_app/src/common/services/services_locator.dart';

void showConflictResolutionDialog(BuildContext context, NoteBloc bloc, Map<String, dynamic> note) {
  final localTitle = note[Constants.database.COLUMN_TITLE] ?? '';
  final localBody = note[Constants.database.COLUMN_BODY] ?? '';
  final noteId = note[Constants.database.COLUMN_ID] as int;
  final remoteId = note[Constants.database.COLUMN_REMOTE_ID]?.toString();
  final api = ServicesLocator.apiRepository;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _ConflictDialog(
      localTitle: localTitle.toString(),
      localBody: localBody.toString(),
      noteId: noteId,
      remoteId: remoteId,
      bloc: bloc,
      api: api,
    ),
  );
}

class _ConflictDialog extends StatefulWidget {
  final String localTitle;
  final String localBody;
  final int noteId;
  final String? remoteId;
  final NoteBloc bloc;
  final ApiRepository api;

  const _ConflictDialog({
    required this.localTitle,
    required this.localBody,
    required this.noteId,
    required this.remoteId,
    required this.bloc,
    required this.api,
  });

  @override
  State<_ConflictDialog> createState() => _ConflictDialogState();
}

class _ConflictDialogState extends State<_ConflictDialog> {
  String? _serverTitle;
  String? _serverBody;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchServer();
  }

  Future<void> _fetchServer() async {
    if (widget.remoteId == null) {
      setState(() {
        _loading = false;
        _error = 'No remote ID available';
      });
      return;
    }

    try {
      final remote = await widget.api.getNoteById(widget.remoteId!);
      if (!mounted) return;
      if (remote == null) {
        setState(() {
          _loading = false;
          _error = 'Note was deleted from server';
        });
      } else {
        setState(() {
          _serverTitle = remote['title']?.toString() ?? '';
          _serverBody = remote['body']?.toString() ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to fetch server version';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              'The note "${widget.localTitle}" has been modified on both this device and the server.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('Choose which version to keep:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildVersionBox(
              icon: Icons.phone_android,
              color: Colors.blue,
              label: 'Local Version',
              title: widget.localTitle,
              body: widget.localBody,
            ),
            const SizedBox(height: 8),
            Center(child: Text('vs', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500))),
            const SizedBox(height: 8),
            _buildServerBox(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.bloc.add(ResolveConflict(noteId: widget.noteId, resolution: 'local'));
          },
          child: const Text('Keep Local'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () {
                  Navigator.pop(context);
                  widget.bloc.add(ResolveConflict(noteId: widget.noteId, resolution: 'remote'));
                },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          child: const Text('Keep Server'),
        ),
      ],
    );
  }

  Widget _buildVersionBox({
    required IconData icon,
    required MaterialColor color,
    required String label,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(body, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildServerBox() {
    if (_loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.green.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text('Fetching server version...', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.orange.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Colors.orange),
            const SizedBox(width: 6),
            Expanded(child: Text(_error!, style: TextStyle(color: Colors.orange[700], fontSize: 13))),
          ],
        ),
      );
    }

    return _buildVersionBox(
      icon: Icons.cloud,
      color: Colors.green,
      label: 'Server Version',
      title: _serverTitle ?? '',
      body: _serverBody ?? '',
    );
  }
}
