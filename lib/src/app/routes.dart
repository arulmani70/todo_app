import 'package:todo_app/src/common/widgets/file_not_found.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/src/app/route_names.dart';
import 'package:logger/logger.dart';
import 'package:todo_app/src/common/widgets/splashscreen.dart';
import 'package:todo_app/src/todo/views/todo_page.dart';

class Routes {
  final log = Logger();

  GoRouter router = GoRouter(
    routes: [
      GoRoute(
        name: RouteNames.splashscreen,
        path: "/",
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),

      GoRoute(name: RouteNames.dashboard, path: '/todo', builder: (context, state) => TodoPage()),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      return '/todo';
    },
    debugLogDiagnostics: true,
    errorBuilder: (contex, state) {
      return FileNotFound(message: "${state.error?.message}");
    },
  );
}
