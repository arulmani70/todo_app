part of 'note_bloc.dart';

sealed class NoteEvent extends Equatable {
  const NoteEvent();

  @override
  List<Object> get props => [];
}

class InitializeNotes extends NoteEvent {
  const InitializeNotes();
}

class CreateNote extends NoteEvent {
  final Map<String, dynamic> note;
  const CreateNote({required this.note});

  @override
  List<Object> get props => [note];
}

class GetAllNotes extends NoteEvent {
  const GetAllNotes();
}

class UpdateNote extends NoteEvent {
  final Map<String, dynamic> note;
  const UpdateNote({required this.note});

  @override
  List<Object> get props => [note];
}

class DeleteNote extends NoteEvent {
  final int id;
  const DeleteNote({required this.id});

  @override
  List<Object> get props => [id];
}

class RefreshNotes extends NoteEvent {
  const RefreshNotes();
}

class ResolveConflict extends NoteEvent {
  final int noteId;
  final String resolution;
  const ResolveConflict({required this.noteId, required this.resolution});

  @override
  List<Object> get props => [noteId, resolution];
}
