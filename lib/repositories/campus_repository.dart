import 'dart:typed_data';

import '../models/campus_item.dart';

abstract class CampusRepository {
  String get uid;
  bool get isPreview;
  Stream<List<CampusItem>> watch(String path);
  Future<Map<String, dynamic>> mutate(
    String action,
    Map<String, dynamic> payload,
  );
  Future<Uint8List?> image(String path);
  void dispose();
}
