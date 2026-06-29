import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:todo_app/src/notes/repo/note_repository.dart';

part 'note_event.dart';
part 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  NoteBloc({required NoteRepository repository})
      : _repository = repository,
        super(NoteState.initial) {
    on<InitializeNotes>(_onInitializeNotes);
    on<CreateNote>(_onCreateNote);
    on<GetAllNotes>(_onGetAllNotes);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
    on<RefreshNotes>(_onRefreshNotes);
    on<ResolveConflict>(_onResolveConflict);

    _repository.syncVersion.addListener(_onSyncCompleted);
    if (_repository.syncVersion.value > 0) {
      _log.d("NoteBloc::Sync already completed before subscription, refreshing UI");
      add(const RefreshNotes());
    }
  }

  final NoteRepository _repository;
  final _log = Logger();

  void _onSyncCompleted() {
    if (!isClosed) {
      _log.d("NoteBloc::Background sync completed, refreshing UI");
      add(const GetAllNotes());
    }
  }

  @override
  Future<void> close() {
    _repository.syncVersion.removeListener(_onSyncCompleted);
    return super.close();
  }

  Future<void> _onInitializeNotes(InitializeNotes event, Emitter<NoteState> emit) async {
    _log.d("NoteBloc::_onInitializeNotes::Initializing notes");
    try {
      emit(state.copyWith(status: () => NoteStatus.loading));
      final notes = await _repository.getAllNotesWithSync();
      emit(state.copyWith(status: () => NoteStatus.loaded, message: () => 'Notes initialized successfully', notes: () => notes));
    } catch (e) {
      _log.e("NoteBloc::_onInitializeNotes::Error: $e");
      emit(state.copyWith(status: () => NoteStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onCreateNote(CreateNote event, Emitter<NoteState> emit) async {
    _log.d("NoteBloc::_onCreateNote::Creating note");
    try {
      emit(state.copyWith(status: () => NoteStatus.loading));
      await _repository.createNote(event.note);
      final notes = await _repository.getAllNotes();
      emit(state.copyWith(status: () => NoteStatus.success, message: () => 'Note created successfully', notes: () => notes));
    } catch (e) {
      _log.e("NoteBloc::_onCreateNote::Error: $e");
      emit(state.copyWith(status: () => NoteStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onGetAllNotes(GetAllNotes event, Emitter<NoteState> emit) async {
    _log.d("NoteBloc::_onGetAllNotes::Getting all notes");
    try {
      emit(state.copyWith(status: () => NoteStatus.loading));
      final notes = await _repository.getAllNotes();
      emit(state.copyWith(status: () => NoteStatus.loaded, message: () => 'Notes fetched successfully', notes: () => notes));
    } catch (e) {
      _log.e("NoteBloc::_onGetAllNotes::Error: $e");
      emit(state.copyWith(status: () => NoteStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onUpdateNote(UpdateNote event, Emitter<NoteState> emit) async {
    _log.d("NoteBloc::_onUpdateNote::Updating note");
    try {
      emit(state.copyWith(status: () => NoteStatus.loading));
      await _repository.updateNote(event.note['id'], event.note);
      final notes = await _repository.getAllNotes();
      emit(state.copyWith(status: () => NoteStatus.success, message: () => 'Note updated successfully', notes: () => notes));
    } catch (e) {
      _log.e("NoteBloc::_onUpdateNote::Error: $e");
      emit(state.copyWith(status: () => NoteStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onDeleteNote(DeleteNote event, Emitter<NoteState> emit) async {
    _log.d("NoteBloc::_onDeleteNote::Deleting note");
    try {
      emit(state.copyWith(status: () => NoteStatus.loading));
      await _repository.deleteNote(event.id);
      final notes = await _repository.getAllNotes();
      emit(state.copyWith(status: () => NoteStatus.success, message: () => 'Note deleted successfully', notes: () => notes));
    } catch (e) {
      _log.e("NoteBloc::_onDeleteNote::Error: $e");
      emit(state.copyWith(status: () => NoteStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onRefreshNotes(RefreshNotes event, Emitter<NoteState> emit) async {
    _log.d("NoteBloc::_onRefreshNotes::Refreshing notes");
    try {
      emit(state.copyWith(status: () => NoteStatus.loading));
      final notes = await _repository.getAllNotesWithSync();
      emit(state.copyWith(status: () => NoteStatus.success, message: () => 'Notes refreshed successfully', notes: () => notes));
    } catch (e) {
      _log.e("NoteBloc::_onRefreshNotes::Error: $e");
      emit(state.copyWith(status: () => NoteStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onResolveConflict(ResolveConflict event, Emitter<NoteState> emit) async {
    _log.d("NoteBloc::_onResolveConflict::Resolving conflict for note ${event.noteId}");
    try {
      emit(state.copyWith(status: () => NoteStatus.loading));
      await _repository.resolveConflict(event.noteId, event.resolution);
      final notes = await _repository.getAllNotes();
      emit(state.copyWith(status: () => NoteStatus.success, message: () => 'Conflict resolved', notes: () => notes));

      if (event.resolution == 'local') {
        _log.d("NoteBloc::_onResolveConflict::Local resolution, triggering sync");
        await _repository.syncAllData();
      }
    } catch (e) {
      _log.e("NoteBloc::_onResolveConflict::Error: $e");
      emit(state.copyWith(status: () => NoteStatus.failure, message: () => e.toString()));
    }
  }
}
