part of 'todo_bloc.dart';

enum TodoStatus { initial, loading, loaded, success, failure }

class TodoState extends Equatable {
  final TodoStatus status;
  final String message;
  final List<Map<String, dynamic>> todos;

  const TodoState({required this.status, required this.message, required this.todos});

  static const TodoState initial = TodoState(status: TodoStatus.initial, message: '', todos: []);

  TodoState copyWith({TodoStatus Function()? status, String Function()? message, List<Map<String, dynamic>> Function()? todos}) {
    return TodoState(
      status: status != null ? status() : this.status,
      message: message != null ? message() : this.message,
      todos: todos != null ? todos() : this.todos,
    );
  }

  @override
  List<Object> get props => [status, message, todos];
}
