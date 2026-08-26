import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService(FirebaseFirestore.instance));

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  Stream<DocumentSnapshot> getDocumentStream(String path) {
    return _db.doc(path).snapshots();
  }

  Stream<QuerySnapshot> getCollectionStream(String path, {Query Function(Query)? queryBuilder}) {
    Query query = _db.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  Future<DocumentSnapshot> getDocument(String path) async {
    return await _db.doc(path).get();
  }

  Future<void> addDocument(String path, Map<String, dynamic> data) async {
    await _db.collection(path).add(data);
  }

  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    await _db.doc(path).update(data);
  }

  Future<void> deleteDocument(String path) async {
    await _db.doc(path).delete();
  }
}
