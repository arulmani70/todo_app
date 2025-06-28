import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:todo_app/src/common/services/services_locator.dart';
import 'package:todo_app/src/todo/bloc/todo_bloc.dart';

import 'mobile/todo_page_mobile.dart';
import 'todo_page_placeholder.dart';

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodoBloc(repository: ServicesLocator.todoRepository)..add(const InitializeTodos()),
      child: Builder(
        builder: (context) {
          return ResponsiveValue<Widget>(
            context,
            defaultValue: const TodoPagePlaceholder(),
            conditionalValues: [
              const Condition.equals(name: TABLET, value: TodoPageMobile()),
              const Condition.smallerThan(name: TABLET, value: TodoPageMobile()),
            ],
          ).value;
        },
      ),
    );
  }
}
