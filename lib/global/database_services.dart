import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  DatabaseReference get dbRef => _dbRef;

  Future<void> writeData(String path, Map<String, dynamic>? data) async {
    await _dbRef.child(path).set(data);
  }

  DatabaseReference readData(String path) {
    return _dbRef.child(path);
  }

  Future<void> updateData(String path, Map<String, dynamic>? data) async {
    await _dbRef.child(path).update(data!);
  }

  Future<void> deleteData(String path) async {
    await _dbRef.child(path).remove();
  }
}
