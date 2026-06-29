import 'package:flutter/material.dart';
import 'package:todo_app/src/common/common.dart';
import 'package:todo_app/src/notes/bloc/note_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NoteFormBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? note;

  const NoteFormBottomSheet({super.key, this.note});

  @override
  State<NoteFormBottomSheet> createState() => _NoteFormBottomSheetState();
}

class _NoteFormBottomSheetState extends State<NoteFormBottomSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      _titleController.text = widget.note![Constants.database.COLUMN_TITLE] ?? '';
      _bodyController.text = widget.note![Constants.database.COLUMN_BODY] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.note != null ? 'Edit Note' : 'New Note',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title *',
                              hintText: 'Enter note title',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Title is required';
                              if (value.trim().length < 3) return 'Title must be at least 3 characters';
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bodyController,
                            decoration: const InputDecoration(
                              labelText: 'Body',
                              hintText: 'Start writing your note...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 8,
                            minLines: 4,
                            textInputAction: TextInputAction.newline,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                    )
                                  : Text(
                                      widget.note != null ? 'Update Note' : 'Create Note',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final noteData = <String, dynamic>{
          Constants.database.COLUMN_TITLE: _titleController.text.trim(),
          Constants.database.COLUMN_BODY: _bodyController.text.trim(),
        };

        if (widget.note != null) {
          context.read<NoteBloc>().add(UpdateNote(note: {...widget.note!, ...noteData}));
        } else {
          context.read<NoteBloc>().add(CreateNote(note: noteData));
        }

        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

void showNoteFormBottomSheet(BuildContext context, NoteBloc bloc, {Map<String, dynamic>? note}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BlocProvider.value(
      value: bloc,
      child: NoteFormBottomSheet(note: note),
    ),
  );
}
