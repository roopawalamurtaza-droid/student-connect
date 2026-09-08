import 'package:cloud_firestore/cloud_firestore.dart';

/// A typed document envelope shared by the campus collections.
class CampusItem {
  const CampusItem(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String text(String key) => data[key] is String ? data[key] as String : '';
  bool flag(String key) => data[key] == true;
  int number(String key) => (data[key] as num?)?.toInt() ?? 0;
  List<String> strings(String key) =>
      (data[key] as List?)?.whereType<String>().toList() ?? [];
  DateTime date(String key) {
    final value = data[key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String get name => text('name');
  String get role => text('role');
  bool get isModerator => ['moderator', 'administrator'].contains(role);
  bool get canManage =>
      ['representative', 'moderator', 'administrator'].contains(role);
}
