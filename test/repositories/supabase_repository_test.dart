import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/core/config.dart';
import 'package:student_connect/repositories/supabase_repository.dart';

void main() {
  test('university domain matching is exact and case insensitive', () {
    expect(AppConfig.isUniversityEmail('25IC05IT050@PPSU.AC.IN'), isTrue);
    expect(AppConfig.isUniversityEmail('person@evilppsu.ac.in'), isFalse);
    expect(AppConfig.isUniversityEmail('person@ppsu.ac.in.evil.test'), isFalse);
  });
  test('normalized profile maps to existing UI and role capabilities', () {
    final profile = SupabaseCampusRepository.mapItem('profiles', {
      'id': 'user',
      'name': 'Student',
      'departments': {'name': 'Engineering'},
      'user_roles': {'role': 'club_admin'},
      'semester': 2,
      'created_at': '2026-09-09T00:00:00Z',
    });
    expect(profile.text('department'), 'Engineering');
    expect(profile.canManage, isTrue);
    expect(profile.isModerator, isFalse);
    expect(profile.date('createdAt').year, 2026);
  });
  test('post joins retain author and private image path', () {
    final post = SupabaseCampusRepository.mapItem('posts', {
      'id': 'post',
      'author_id': 'author',
      'body': 'Hello',
      'author': {
        'name': 'Student',
        'avatar_path': 'author/avatar/photo.jpg',
        'department': {'name': 'IT'},
      },
      'post_media': [
        {
          'media_assets': {'path': 'author/post/image.jpg'},
        },
      ],
    });
    expect(post.text('authorId'), 'author');
    expect(post.text('authorName'), 'Student');
    expect(post.text('authorPhotoPath'), 'author/avatar/photo.jpg');
    expect(post.text('department'), 'IT');
    expect(post.text('imagePath'), 'author/post/image.jpg');
  });
  test('reports retain content target separately from report id', () {
    final report = SupabaseCampusRepository.mapItem('reports', {
      'id': 'report',
      'target_id': 'post',
      'target_kind': 'posts',
      'target_summary': 'Reported text',
    });
    expect(report.id, 'report');
    expect(report.text('targetId'), 'post');
    expect(report.text('kind'), 'posts');
    expect(report.text('targetSummary'), 'Reported text');
  });
}
