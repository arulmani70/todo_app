import 'package:get_it/get_it.dart';
import 'package:todo_app/src/common/repos/database_repository.dart';
import 'package:todo_app/src/common/repos/firestore_repository.dart';
import 'package:todo_app/src/common/services/network_service.dart';
import 'package:todo_app/src/todo/repo/todo_repository.dart';

final GetIt serviceLocator = GetIt.instance;

class ServicesLocator {
  static Future<void> initialize() async {
    serviceLocator.registerLazySingleton<DatabaseRepository>(() => DatabaseRepository());

    serviceLocator.registerLazySingleton<FirestoreRepository>(() => FirestoreRepository());

    serviceLocator.registerLazySingleton<NetworkService>(() => NetworkService());

    serviceLocator.registerLazySingleton<TodoRepository>(() => TodoRepository());

    await serviceLocator<FirestoreRepository>().initialize();
    await serviceLocator<NetworkService>().initialize();
    await serviceLocator<TodoRepository>().initialize();
  }

  static DatabaseRepository get databaseRepository => serviceLocator<DatabaseRepository>();
  static FirestoreRepository get firestoreRepository => serviceLocator<FirestoreRepository>();
  static NetworkService get networkService => serviceLocator<NetworkService>();
  static TodoRepository get todoRepository => serviceLocator<TodoRepository>();
}
