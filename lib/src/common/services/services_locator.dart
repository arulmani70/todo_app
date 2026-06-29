import 'package:get_it/get_it.dart';
import 'package:todo_app/src/common/repos/database_repository.dart';
import 'package:todo_app/src/common/repos/api_repository.dart';
import 'package:todo_app/src/common/services/network_service.dart';
import 'package:todo_app/src/notes/repo/note_repository.dart';

final GetIt serviceLocator = GetIt.instance;

class ServicesLocator {
  static Future<void> initialize() async {
    serviceLocator.registerLazySingleton<DatabaseRepository>(() => DatabaseRepository());

    serviceLocator.registerLazySingleton<ApiRepository>(() => ApiRepository());

    serviceLocator.registerLazySingleton<NetworkService>(() => NetworkService());

    serviceLocator.registerLazySingleton<NoteRepository>(() => NoteRepository());

    await serviceLocator<ApiRepository>().initialize();
    await serviceLocator<NetworkService>().initialize();
    await serviceLocator<NoteRepository>().initialize();
  }

  static DatabaseRepository get databaseRepository => serviceLocator<DatabaseRepository>();
  static ApiRepository get apiRepository => serviceLocator<ApiRepository>();
  static NetworkService get networkService => serviceLocator<NetworkService>();
  static NoteRepository get noteRepository => serviceLocator<NoteRepository>();
}
