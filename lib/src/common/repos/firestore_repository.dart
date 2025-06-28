import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class FirestoreRepository {
  final Logger log = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _todosCollection = 'todos';

  Future<void> initialize() async {
    try {
      log.d("FirestoreRepository::initialize::Initializing Firestore");

      _firestore.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);

      log.d("FirestoreRepository::initialize::Firestore initialized successfully");
    } catch (error) {
      log.e("FirestoreRepository::initialize::Error: $error");
      rethrow;
    }
  }

  Future<String> createTodo(Map<String, dynamic> todoData) async {
    try {
      log.d("FirestoreRepository::createTodo::Creating todo in Firestore");

      final data = Map<String, dynamic>.from(todoData);
      if (data.containsKey('is_deleted')) {
        if (data['is_deleted'] == 0) {
          data['is_deleted'] = false;
        }
      } else {
        data['is_deleted'] = false;
      }

      final docRef = await _firestore.collection(_todosCollection).add(data);

      if (docRef.id.isEmpty) {
        throw Exception("Failed to get document ID from Firestore");
      }

      log.d("FirestoreRepository::createTodo::Todo created with ID: ${docRef.id}");
      return docRef.id;
    } catch (error) {
      log.e("FirestoreRepository::createTodo::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllTodos() async {
    try {
      log.d("FirestoreRepository::getAllTodos::Fetching todos from Firestore");

      final querySnapshot = await _firestore
          .collection(_todosCollection)
          .where('is_deleted', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .get();

      final todos = querySnapshot.docs.map((doc) {
        return doc.data();
      }).toList();

      log.d("FirestoreRepository::getAllTodos::Found ${todos.length} todos");
      return todos;
    } catch (error) {
      log.e("FirestoreRepository::getAllTodos::Error: $error");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTodoById(String todoId) async {
    try {
      log.d("FirestoreRepository::getTodoById::Fetching todo with ID: $todoId");

      final docSnapshot = await _firestore.collection(_todosCollection).doc(todoId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;

        if (data['is_deleted'] != true) {
          log.d("FirestoreRepository::getTodoById::Found todo: $data");
          return data;
        }
      }

      log.d("FirestoreRepository::getTodoById::Todo not found");
      return null;
    } catch (error) {
      log.e("FirestoreRepository::getTodoById::Error: $error");
      rethrow;
    }
  }

  Future<void> updateTodo(String todoId, Map<String, dynamic> todoData) async {
    try {
      log.d("FirestoreRepository::updateTodo::Updating todo $todoId");

      final data = Map<String, dynamic>.from(todoData);
      data['updated_at'] = FieldValue.serverTimestamp();
      if (data['is_deleted'] == 0) {
        data['is_deleted'] = false;
      }
      await _firestore.collection(_todosCollection).doc(todoId).update(data);

      log.d("FirestoreRepository::updateTodo::Todo updated successfully");
    } catch (error) {
      log.e("FirestoreRepository::updateTodo::Error: $error");
      rethrow;
    }
  }

  Future<void> deleteTodo(String todoId, Map<String, dynamic> todoData) async {
    try {
      log.d("FirestoreRepository::deleteTodo::Deleting todo: $todoId");

      final data = Map<String, dynamic>.from(todoData);
      data['is_deleted'] = true;
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection(_todosCollection).doc(todoId).update(data);

      log.d("FirestoreRepository::deleteTodo::Todo deleted successfully");
    } catch (error) {
      log.e("FirestoreRepository::deleteTodo::Error: $error");
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> listenToTodos() {
    return _firestore
        .collection(_todosCollection)
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }
}
