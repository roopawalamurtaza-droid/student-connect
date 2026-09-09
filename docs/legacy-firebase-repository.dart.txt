import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/campus_item.dart';
import 'campus_repository.dart';

class FirebaseCampusRepository implements CampusRepository {
  FirebaseCampusRepository(this.uid);
  @override
  final String uid;
  @override
  bool get isPreview => false;
  @override
  Stream<List<CampusItem>> watch(String path) {
    if (path.endsWith('/registrations')) {
      return FirebaseFirestore.instance
          .doc('$path/$uid')
          .snapshots()
          .map(
            (snapshot) => snapshot.exists
                ? [CampusItem(snapshot.id, snapshot.data()!)]
                : <CampusItem>[],
          );
    }
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      path,
    );
    if (['posts', 'announcements', 'reports'].contains(path) ||
        path.endsWith('/notifications') ||
        path.endsWith('/comments')) {
      query = query.orderBy('createdAt', descending: true);
    }
    if (path == 'events') query = query.orderBy('startsAt');
    return query
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) => CampusItem(d.id, d.data())).toList());
  }

  @override
  Future<Map<String, dynamic>> mutate(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final result = await FirebaseFunctions.instanceFor(region: 'asia-south1')
        .httpsCallable('mutate')
        .call<Object?>({'action': action, 'payload': payload});
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Future<Uint8List?> image(String path) =>
      FirebaseStorage.instance.ref(path).getData(4 * 1024 * 1024);
  @override
  void dispose() {}
}
