import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_app/src/common/utils/utils.dart';
import 'package:todo_app/src/notes/bloc/note_bloc.dart';
import 'package:todo_app/src/notes/views/mobile/widgets/note_form_bottom_sheet.dart';

import 'widgets/note_list_item.dart';

class NotePageMobile extends StatefulWidget {
  const NotePageMobile({super.key});

  @override
  State<NotePageMobile> createState() => _NotePageMobileState();
}

class _NotePageMobileState extends State<NotePageMobile> {
  late NoteBloc _noteBloc;

  @override
  void initState() {
    super.initState();
    _noteBloc = context.read<NoteBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Notes'),
          actions: [
            IconButton(onPressed: () => _noteBloc.add(const RefreshNotes()), icon: const Icon(Icons.sync)),
          ],
        ),
        body: BlocConsumer<NoteBloc, NoteState>(
          listener: (context, state) {
            if (state.status == NoteStatus.failure) {
              ToastUtil.showErrorToast(context, state.message);
            }
            if (state.status == NoteStatus.success) {
              ToastUtil.showSuccessToast(context, state.message);
            }
          },
          builder: (context, state) {
            return Container(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Column(
                children: [
                  if (state.status == NoteStatus.loading)
                    const LinearProgressIndicator(color: Colors.blue, backgroundColor: Colors.grey, minHeight: 5),
                  Expanded(
                    child: BlocBuilder<NoteBloc, NoteState>(
                      builder: (context, state) {
                        if (state.notes.isEmpty && state.status != NoteStatus.loading) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No notes yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                SizedBox(height: 8),
                                Text('Tap the + button to add your first note', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.notes.length,
                          itemBuilder: (context, index) {
                            final note = state.notes[index];
                            return NoteListItem(note: note, noteBloc: _noteBloc);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showNoteFormBottomSheet(context, _noteBloc);
          },
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
