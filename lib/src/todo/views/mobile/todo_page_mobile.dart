import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_app/src/common/utils/utils.dart';
import 'package:todo_app/src/todo/bloc/todo_bloc.dart';
import 'package:todo_app/src/todo/views/mobile/widgets/todo_form_bottom_sheet.dart';

import 'widgets/todo_list_item.dart';

class TodoPageMobile extends StatefulWidget {
  const TodoPageMobile({super.key});

  @override
  State<TodoPageMobile> createState() => _TodoPageMobileState();
}

class _TodoPageMobileState extends State<TodoPageMobile> {
  late TodoBloc _todoBloc;

  @override
  void initState() {
    super.initState();
    _todoBloc = context.read<TodoBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Todos'),
          actions: [IconButton(onPressed: () => _todoBloc.add(const RefreshTodos()), icon: const Icon(Icons.sync))],
        ),
        body: BlocConsumer<TodoBloc, TodoState>(
          listener: (context, state) {
            if (state.status == TodoStatus.failure) {
              ToastUtil.showErrorToast(context, state.message);
            }
            if (state.status == TodoStatus.success) {
              ToastUtil.showSuccessToast(context, state.message);
            }
          },
          builder: (context, state) {
            return Container(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Column(
                children: [
                  if (state.status == TodoStatus.loading)
                    const LinearProgressIndicator(color: Colors.blue, backgroundColor: Colors.grey, minHeight: 5),
                  Expanded(
                    child: BlocBuilder<TodoBloc, TodoState>(
                      builder: (context, state) {
                        if (state.todos.isEmpty && state.status != TodoStatus.loading) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.task_alt, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No todos yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                SizedBox(height: 8),
                                Text('Tap the + button to add your first todo', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.todos.length,
                          itemBuilder: (context, index) {
                            final todo = state.todos[index];
                            return TodoListItem(todo: todo, todoBloc: _todoBloc);
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
            showTodoFormBottomSheet(context, _todoBloc);
          },
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
