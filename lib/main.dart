import 'package:flutter/material.dart';
import 'package:todo_app/src/app/app.dart';
import 'package:todo_app/src/common/services/services_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServicesLocator.initialize();

  runApp(const App());
}
