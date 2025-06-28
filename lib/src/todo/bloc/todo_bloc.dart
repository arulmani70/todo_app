import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:todo_app/src/todo/repo/todo_repository.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc({required TodoRepository repository}) : _repository = repository, super(TodoState.initial) {
    on<InitializeTodos>(_onInitializeTodos);
    on<CreateTodo>(_onCreateTodo);
    on<GetAllTodos>(_onGetAllTodos);
    on<UpdateTodo>(_onUpdateTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<RefreshTodos>(_onRefreshTodos);
  }

  final TodoRepository _repository;
  final _log = Logger();

  Future<void> _onInitializeTodos(InitializeTodos event, Emitter<TodoState> emit) async {
    _log.d("TodoBloc::_onInitializeTodos::Initializing todos");
    try {
      emit(state.copyWith(status: () => TodoStatus.loading));
      final todos = await _repository.getAllTodosWithSync();
      emit(state.copyWith(status: () => TodoStatus.loaded, message: () => 'Todos initialized successfully', todos: () => todos));
    } catch (e) {
      _log.e("TodoBloc::_onInitializeTodos::Error: $e");
      emit(state.copyWith(status: () => TodoStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onCreateTodo(CreateTodo event, Emitter<TodoState> emit) async {
    _log.d("TodoBloc::_onCreateTodo::Creating todo");
    try {
      emit(state.copyWith(status: () => TodoStatus.loading));
      await _repository.createTodo(event.todo);
      final todos = await _repository.getAllTodos();
      emit(state.copyWith(status: () => TodoStatus.success, message: () => 'Todo created successfully', todos: () => todos));
    } catch (e) {
      _log.e("TodoBloc::_onCreateTodo::Error: $e");
      emit(state.copyWith(status: () => TodoStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onGetAllTodos(GetAllTodos event, Emitter<TodoState> emit) async {
    _log.d("TodoBloc::_onGetAllTodos::Getting all todos");
    try {
      emit(state.copyWith(status: () => TodoStatus.loading));
      final todos = await _repository.getAllTodos();
      emit(state.copyWith(status: () => TodoStatus.loaded, message: () => 'Todos fetched successfully', todos: () => todos));
    } catch (e) {
      _log.e("TodoBloc::_onGetAllTodos::Error: $e");
      emit(state.copyWith(status: () => TodoStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onUpdateTodo(UpdateTodo event, Emitter<TodoState> emit) async {
    _log.d("TodoBloc::_onUpdateTodo::Updating todo");
    try {
      emit(state.copyWith(status: () => TodoStatus.loading));
      await _repository.updateTodo(event.todo['id'], event.todo);
      final todos = await _repository.getAllTodos();
      emit(state.copyWith(status: () => TodoStatus.success, message: () => 'Todo updated successfully', todos: () => todos));
    } catch (e) {
      _log.e("TodoBloc::_onUpdateTodo::Error: $e");
      emit(state.copyWith(status: () => TodoStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onDeleteTodo(DeleteTodo event, Emitter<TodoState> emit) async {
    _log.d("TodoBloc::_onDeleteTodo::Deleting todo");
    try {
      emit(state.copyWith(status: () => TodoStatus.loading));
      await _repository.deleteTodo(event.id);
      final todos = await _repository.getAllTodos();
      emit(state.copyWith(status: () => TodoStatus.success, message: () => 'Todo deleted successfully', todos: () => todos));
    } catch (e) {
      _log.e("TodoBloc::_onDeleteTodo::Error: $e");
      emit(state.copyWith(status: () => TodoStatus.failure, message: () => e.toString()));
    }
  }

  Future<void> _onRefreshTodos(RefreshTodos event, Emitter<TodoState> emit) async {
    _log.d("TodoBloc::_onRefreshTodos::Refreshing todos");
    try {
      emit(state.copyWith(status: () => TodoStatus.loading));
      final todos = await _repository.getAllTodosWithSync();
      emit(state.copyWith(status: () => TodoStatus.success, message: () => 'Todos refreshed successfully', todos: () => todos));
    } catch (e) {
      _log.e("TodoBloc::_onRefreshTodos::Error: $e");
      emit(state.copyWith(status: () => TodoStatus.failure, message: () => e.toString()));
    }
  }
}
