part of 'todo_bloc.dart';

sealed class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object> get props => [];
}

class InitializeTodos extends TodoEvent {
  const InitializeTodos();
}

class CreateTodo extends TodoEvent {
  final Map<String, dynamic> todo;
  const CreateTodo({required this.todo});

  @override
  List<Object> get props => [todo];
}

class GetAllTodos extends TodoEvent {
  const GetAllTodos();

  @override
  List<Object> get props => [];
}

class UpdateTodo extends TodoEvent {
  final Map<String, dynamic> todo;
  const UpdateTodo({required this.todo});

  @override
  List<Object> get props => [todo];
}

class DeleteTodo extends TodoEvent {
  final int id;
  const DeleteTodo({required this.id});

  @override
  List<Object> get props => [id];
}

class RefreshTodos extends TodoEvent {
  const RefreshTodos();

  @override
  List<Object> get props => [];
}
