import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart';
import '../models/request.dart';


class DataRepository {
  // 1
  final CollectionReference collection =
  FirebaseFirestore.instance.collection('request');

  // 2
  Stream<QuerySnapshot> getStream() {
    return collection.snapshots();
  }
  // 3
  Future<DocumentReference> addRequest(RequestInstaller request) {
    return collection.add(request.toJson());
  }
  // 4
  void updateRequest(RequestInstaller request) async {
    await collection.doc(request.referenceId).update(request.toJson());
  }
  // 5
  void deleteRequest(RequestInstaller request) async {
    await collection.doc(request.referenceId).delete();
  }
}