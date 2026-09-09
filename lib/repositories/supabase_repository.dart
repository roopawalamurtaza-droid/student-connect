import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/campus_item.dart';
import '../services/supabase_data_service.dart';
import 'campus_repository.dart';

class SupabaseCampusRepository implements CampusRepository {
  SupabaseCampusRepository(this.uid, this.service);
  final SupabaseDataService service;
  @override
  final String uid;
  @override
  bool get isPreview => false;
  final _refresh = StreamController<void>.broadcast();
  final _disposeCallbacks = <void Function()>[];
  bool _disposed = false;
  static CampusItem mapItem(String table, Map<String, dynamic> row) {
    if (table == 'saved_posts' && row['post'] is Map<String, dynamic>) {
      return mapItem('posts', row['post'] as Map<String, dynamic>);
    }
    final data = Map<String, dynamic>.from(row);
    const keys = {
      'created_at': 'createdAt',
      'updated_at': 'updatedAt',
      'starts_at': 'startsAt',
      'author_id': 'authorId',
      'owner_id': 'ownerId',
      'community_id': 'communityId',
      'user_id': 'userId',
      'avatar_path': 'photoPath',
      'target_kind': 'kind',
      'target_id': 'targetId',
      'target_summary': 'targetSummary',
      'reporter_id': 'reporterId',
      'image_path': 'imagePath',
      'banner_path': 'bannerPath',
    };
    for (final entry in keys.entries) {
      data[entry.value] = row[entry.key];
    }
    final author = row['author'] as Map<String, dynamic>?;
    if (author != null) {
      data['authorName'] = author['name'];
      data['department'] =
          (author['department'] as Map<String, dynamic>?)?['name'];
    }
    if (table == 'profiles') {
      data['department'] =
          (row['departments'] as Map<String, dynamic>?)?['name'];
      final roles = row['user_roles'];
      data['role'] = roles is Map<String, dynamic>
          ? roles['role']
          : roles is List && roles.isNotEmpty
          ? (roles.first as Map<String, dynamic>)['role']
          : 'student';
    }
    if (table == 'posts') {
      final media = row['post_media'] as List<dynamic>? ?? [];
      data['imagePath'] = media.isEmpty
          ? ''
          : ((media.first as Map<String, dynamic>)['media_assets']
                as Map<String, dynamic>?)?['path'];
    }
    final id =
        (row['id'] ?? row['blocked_id'] ?? row['user_id'] ?? row['post_id'])
            as String;
    return CampusItem(id, Map.unmodifiable(data));
  }

  @override
  Stream<List<CampusItem>> watch(String path) {
    late StreamController<List<CampusItem>> controller;
    StreamSubscription<void>? refresh;
    RealtimeChannel? channel;
    Timer? fallback;
    bool busy = false, again = false, closed = false;
    Future<void> fetch() async {
      if (closed || _disposed) return;
      if (busy) {
        again = true;
        return;
      }
      busy = true;
      try {
        final rows = await service.fetch(path, uid);
        if (!closed) {
          controller.add(
            rows.map((r) => mapItem(service.tableFor(path), r)).toList(),
          );
        }
      } catch (e, st) {
        if (!closed) controller.addError(e, st);
      } finally {
        busy = false;
        if (again) {
          again = false;
          unawaited(fetch());
        }
      }
    }

    void cleanup() {
      if (closed) return;
      closed = true;
      fallback?.cancel();
      unawaited(refresh?.cancel());
      if (channel != null) unawaited(service.client.removeChannel(channel!));
    }

    controller = StreamController<List<CampusItem>>(
      onListen: () {
        refresh = _refresh.stream.listen((_) => fetch());
        channel = service.client
            .channel('campus:${identityHashCode(controller)}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: service.tableFor(path),
              callback: (_) => fetch(),
            )
            .subscribe((status, error) {
              if (status == RealtimeSubscribeStatus.subscribed) {
                unawaited(fetch());
              }
            });
        // Recovers missed deletes, relation changes, and websocket reconnects.
        fallback = Timer.periodic(const Duration(seconds: 30), (_) => fetch());
        unawaited(fetch());
      },
      onCancel: cleanup,
    );
    _disposeCallbacks.add(() {
      cleanup();
      unawaited(controller.close());
    });
    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>> mutate(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final Object? result;
    if (action == 'uploadImage' || action == 'deleteAccount') {
      final response = await service.client.functions.invoke(
        action == 'uploadImage' ? 'campus-media' : 'delete-account',
        body: payload,
      );
      result = response.data;
    } else if (action == 'attachMedia') {
      await service.client.rpc<void>(
        'attach_media',
        params: {
          'p_target': payload['id'],
          'p_kind': payload['kind'],
          'p_path': payload['path'],
        },
      );
      result = <String, dynamic>{'ok': true};
    } else {
      result = await service.client.rpc(
        'campus_mutate',
        params: {'action': action, 'payload': payload},
      );
    }
    if (!_disposed) _refresh.add(null);
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<Uint8List?> image(String path) =>
      service.client.storage.from('campus-media').download(path);
  @override
  void dispose() {
    _disposed = true;
    for (final close in _disposeCallbacks) {
      close();
    }
    _disposeCallbacks.clear();
    unawaited(_refresh.close());
  }
}
