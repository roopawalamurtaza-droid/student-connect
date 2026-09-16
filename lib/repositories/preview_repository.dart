import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../models/campus_item.dart';
import 'campus_repository.dart';

/// An explicitly local, temporary preview. Never used for real authentication.
class PreviewRepository implements CampusRepository {
  PreviewRepository() {
    _seed();
  }
  @override
  String get uid => 'preview-student';
  @override
  bool get isPreview => true;
  final _changes = StreamController<void>.broadcast();
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};
  final Map<String, Uint8List> _images = {};
  int _counter = 0;
  Map<String, Map<String, dynamic>> _collection(String path) =>
      _data.putIfAbsent(path, () => {});
  String _add(String path, Map<String, dynamic> data) {
    final id = 'local-${++_counter}';
    _collection(path)[id] = {...data, 'createdAt': DateTime.now()};
    return id;
  }

  void _seed() {
    _collection('users')[uid] = {
      'name': 'Alex Morgan',
      'enrollment': 'SC2026001',
      'department': 'Computer Science',
      'semester': 3,
      'bio': 'Building things, finding my people, and making the most of campus life.',
      'skills': ['Design', 'Flutter', 'Photography'],
      'role': 'student',
      'suspended': false,
      'photoPath': '',
    };
    _collection('users')['maya'] = {
      'name': 'Maya Patel',
      'department': 'Design',
      'semester': 5,
      'role': 'representative',
      'bio': 'Design club coordinator',
      'skills': ['Design', 'Illustration'],
    };
    _collection('users')['noah'] = {
      'name': 'Noah Williams',
      'department': 'Engineering',
      'semester': 3,
      'role': 'student',
      'bio': 'Robotics and weekend hikes',
      'skills': ['Robotics'],
    };
    _collection('communities')['design'] = {
      'name': 'The Design Collective',
      'description': 'A space to sketch, share, and make something that matters. All skill levels welcome.',
      'kind': 'Club',
      'ownerId': 'maya',
    };
    _collection('communities')['builders'] = {
      'name': 'Campus Builders',
      'description':
          'From your first line of code to your next big idea. Build together.',
      'kind': 'Community',
      'ownerId': 'noah',
    };
    _collection('communities')['photo'] = {
      'name': 'Through the Lens',
      'description':
          'Campus stories, one frame at a time. Join our weekly photo walks.',
      'kind': 'Club',
      'ownerId': 'maya',
    };
    _collection('communities/design/members')[uid] = {};
    _add('posts', {
      'authorId': 'maya',
      'authorName': 'Maya Patel',
      'department': 'Design · The Design Collective',
      'body': 'Good ideas start with a conversation. ✨\n\nWe’re opening the studio this Friday for a relaxed design jam. Bring a sketch, a half-built idea, or just your curiosity. Who’s in?',
      'communityId': 'design',
      'imagePath': '',
    });
    _add('posts', {
      'authorId': 'noah',
      'authorName': 'Noah Williams',
      'department': 'Engineering',
      'body': 'Looking for two teammates for the campus hackathon! We’re exploring a way to make finding study groups easier. Designers and first-time builders are very welcome.',
      'communityId': '',
      'imagePath': '',
    });
    _add('events', {
      'title': 'Ideas into action',
      'description': 'An evening of quick talks, fresh perspectives, and people who love to build. Meet collaborators for your next project.',
      'location': 'Innovation Hub · Block A',
      'startsAt': DateTime.now().add(const Duration(days: 2)),
      'ownerId': 'maya',
      'communityId': 'builders',
    });
    _add('events', {
      'title': 'The Friday design jam',
      'description': 'Bring your curiosity. We’ll provide the space, prompts, and a friendly community.',
      'location': 'Design Studio · Floor 2',
      'startsAt': DateTime.now().add(const Duration(days: 4)),
      'ownerId': 'maya',
      'communityId': 'design',
    });
    _add('announcements', {
      'title': 'A little more connected.',
      'body': 'Welcome to your campus community. Find your people, share an idea, and make this semester yours.',
    });
  }

  List<CampusItem> _items(String path) {
    final uri = Uri.parse(path);
    final items = _collection(uri.path).entries
        .map((e) => CampusItem(e.key, Map<String, dynamic>.from(e.value)))
        .toList()
        .reversed
        .toList();
    final targetId = uri.queryParameters['id'];
    if (targetId != null) {
      return items.where((item) => item.id == targetId).toList();
    }
    if (uri.path == 'posts') {
      final query = uri.queryParameters['q']?.toLowerCase() ?? '';
      return items
          .where(
            (post) =>
                post.text('body').toLowerCase().contains(query) &&
                (uri.queryParameters['joined'] != 'true' ||
                    _collection(
                      'communities/${post.text('communityId')}/members',
                    ).containsKey(uid)),
          )
          .toList();
    }
    if (uri.path == 'users') {
      final query = uri.queryParameters['q']?.toLowerCase() ?? '';
      final department = uri.queryParameters['department'];
      final semester = int.tryParse(uri.queryParameters['semester'] ?? '');
      return items
          .where(
            (item) =>
                '${item.name} ${item.text('bio')} ${item.text('department')} ${item.strings('skills').join(' ')}'
                    .toLowerCase()
                    .contains(query) &&
                (department == null || item.text('department') == department) &&
                (semester == null || item.number('semester') == semester),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }
    if (uri.path == 'savedFeed') {
      final saved = _collection('users/$uid/saved');
      return _items('posts')
          .where((post) => saved.containsKey(post.id))
          .toList();
    }
    if (uri.path != 'events') return items;
    final from = DateTime.tryParse(uri.queryParameters['from'] ?? '');
    final before = DateTime.tryParse(uri.queryParameters['before'] ?? '');
    final query = uri.queryParameters['q']?.toLowerCase() ?? '';
    final filtered = items
        .where(
          (event) =>
              event.text('title').toLowerCase().contains(query) &&
              (from == null || !event.date('startsAt').isBefore(from)) &&
              (before == null || event.date('startsAt').isBefore(before)) &&
              (uri.queryParameters['mine'] != 'true' ||
                  _collection('events/${event.id}/registrations')
                      .containsKey(uid)),
        )
        .toList();
    filtered.sort(
      (a, b) => before == null
          ? a.date('startsAt').compareTo(b.date('startsAt'))
          : b.date('startsAt').compareTo(a.date('startsAt')),
    );
    return filtered;
  }

  @override
  Stream<List<CampusItem>> watch(String path) async* {
    yield _items(path);
    yield* _changes.stream.map((_) => _items(path));
  }

  @override
  Future<Map<String, dynamic>> mutate(
    String action,
    Map<String, dynamic> p,
  ) async {
    final me = _collection('users')[uid]!;
    final itemId = p['id'] as String? ?? '';
    switch (action) {
      case 'saveProfile':
        _collection('users')[uid] = {...me, ...p};
      case 'createPost':
        if ((p['body'] as String).trim().isEmpty) {
          throw StateError('Write something first.');
        }
        _add('posts', {
          ...p,
          'authorId': uid,
          'authorName': me['name'],
          'department': me['department'],
        });
      case 'editPost':
        if (_collection('posts')[itemId]?['authorId'] != uid) {
          throw StateError('You can only edit your own posts.');
        }
        _collection(
          'posts',
        )[itemId]!.addAll(Map<String, dynamic>.from(p['post'] as Map));
      case 'deletePost':
        if (_collection('posts')[itemId]?['authorId'] != uid) {
          throw StateError('You can only delete your own posts.');
        }
        _collection('posts').remove(itemId);
      case 'likePost':
        _toggle('posts/$itemId/likes');
      case 'savePost':
        final saved = _collection('users/$uid/saved');
        if (saved.containsKey(itemId)) {
          saved.remove(itemId);
        } else {
          saved[itemId] = {'createdAt': DateTime.now()};
        }
      case 'joinCommunity':
        _toggle('communities/$itemId/members');
      case 'registerEvent':
        _toggle('events/$itemId/registrations');
      case 'comment':
        _add('posts/$itemId/comments', {
          'body': p['body'],
          'authorName': me['name'],
          'authorId': uid,
        });
      case 'report':
        _add('reports', {...p, 'reporterId': uid, 'status': 'open'});
      case 'readNotification':
        _collection('users/$uid/notifications')[itemId]?['read'] = true;
      case 'uploadImage':
        final path = 'preview/image-${++_counter}';
        _images[path] = base64Decode(p['base64'] as String);
        if (p['purpose'] == 'avatar') me['photoPath'] = path;
        _changes.add(null);
        return {'path': path};
      default:
        throw UnsupportedError(
          'This action requires a configured university account.',
        );
    }
    _changes.add(null);
    return {'ok': true};
  }

  void _toggle(String path) {
    final data = _collection(path);
    if (data.containsKey(uid)) {
      data.remove(uid);
    } else {
      data[uid] = {'createdAt': DateTime.now()};
    }
  }

  @override
  Future<Uint8List?> image(String path) async => _images[path];
  @override
  void dispose() => _changes.close();
}
