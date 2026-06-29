part of 'note_bloc.dart';

enum NoteStatus { initial, loading, loaded, success, failure }

class NoteState extends Equatable {
  final NoteStatus status;
  final String message;
  final List<Map<String, dynamic>> notes;

  const NoteState({required this.status, required this.message, required this.notes});

  static const NoteState initial = NoteState(status: NoteStatus.initial, message: '', notes: []);

  NoteState copyWith({NoteStatus Function()? status, String Function()? message, List<Map<String, dynamic>> Function()? notes}) {
    return NoteState(
      status: status != null ? status() : this.status,
      message: message != null ? message() : this.message,
      notes: notes != null ? notes() : this.notes,
    );
  }

  @override
  List<Object> get props => [status, message, notes];
}
