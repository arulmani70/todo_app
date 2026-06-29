import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiRepository {
  final Logger log = Logger();
  late final Dio _dio;

  static const String _baseUrl = 'https://6a4204947602860e6520abd5.mockapi.io';
  static const String _notesEndpoint = '/notes';

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (_) => true,
    ));
    log.d("ApiRepository::initialize::Dio initialized with baseUrl: $_baseUrl");
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    try {
      log.d("ApiRepository::getAllNotes::Fetching all notes");
      final response = await _dio.get(_notesEndpoint);

      if (response.statusCode == 404) {
        log.w("ApiRepository::getAllNotes::Resource not found (404) - returning empty list");
        return [];
      }

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        log.w("ApiRepository::getAllNotes::Unexpected status: ${response.statusCode}");
        return [];
      }

      final data = response.data;
      if (data is! List) {
        log.w("ApiRepository::getAllNotes::Response is not a list: $data");
        return [];
      }

      log.d("ApiRepository::getAllNotes::Fetched ${data.length} notes");
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (error) {
      log.w("ApiRepository::getAllNotes::Error: $error");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getNoteById(String id) async {
    try {
      log.d("ApiRepository::getNoteById::Fetching note: $id");
      final response = await _dio.get('$_notesEndpoint/$id');

      if (response.statusCode == 404) {
        log.w("ApiRepository::getNoteById::Note not found: $id");
        return null;
      }

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        log.w("ApiRepository::getNoteById::Unexpected status: ${response.statusCode}");
        return null;
      }

      log.d("ApiRepository::getNoteById::Fetched note");
      return response.data as Map<String, dynamic>;
    } catch (error) {
      log.w("ApiRepository::getNoteById::Error: $error");
      return null;
    }
  }

  Future<Map<String, dynamic>?> createNote(Map<String, dynamic> data) async {
    try {
      log.d("ApiRepository::createNote::Creating note");
      final response = await _dio.post(_notesEndpoint, data: data);

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        log.w("ApiRepository::createNote::Unexpected status: ${response.statusCode}");
        return null;
      }

      log.d("ApiRepository::createNote::Created note with ID: ${response.data['id']}");
      return response.data as Map<String, dynamic>;
    } catch (error) {
      log.w("ApiRepository::createNote::Error: $error");
      return null;
    }
  }

  Future<bool> updateNote(String id, Map<String, dynamic> data) async {
    try {
      log.d("ApiRepository::updateNote::Updating note: $id");
      final response = await _dio.put('$_notesEndpoint/$id', data: data);

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        log.w("ApiRepository::updateNote::Unexpected status: ${response.statusCode}");
        return false;
      }

      log.d("ApiRepository::updateNote::Updated note: $id");
      return true;
    } catch (error) {
      log.w("ApiRepository::updateNote::Error: $error");
      return false;
    }
  }

  Future<bool> deleteNote(String id) async {
    try {
      log.d("ApiRepository::deleteNote::Deleting note: $id");
      final response = await _dio.delete('$_notesEndpoint/$id');

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        log.w("ApiRepository::deleteNote::Unexpected status: ${response.statusCode}");
        return false;
      }

      log.d("ApiRepository::deleteNote::Deleted note: $id");
      return true;
    } catch (error) {
      log.w("ApiRepository::deleteNote::Error: $error");
      return false;
    }
  }
}
