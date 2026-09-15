import 'package:supabase_flutter/supabase_flutter.dart';

/// Stateless transport. PostgreSQL policies apply to every request.
class SupabaseDataService {
  SupabaseDataService(this.client);
  final SupabaseClient client;
  static const tables = {
    'users': 'profiles',
    'profile': 'profiles',
    'members': 'community_members',
    'registrations': 'event_registrations',
    'blocked': 'blocked_users',
    'saved': 'saved_posts',
    'savedFeed': 'saved_posts',
  };
  String tableFor(String path) {
    final part = path.split('/').last.split('?').first;
    return tables[part] ?? part;
  }

  Future<List<Map<String, dynamic>>> fetch(String path, String uid) async {
    final uri = Uri.parse(path);
    final parts = uri.path.split('/');
    final table = tableFor(uri.path);
    if (table == 'likes' && parts.length == 3) {
      final total = await client
          .from('likes')
          .count(CountOption.exact)
          .eq('post_id', parts[1]);
      final own = await client
          .from('likes')
          .select('user_id')
          .eq('post_id', parts[1])
          .eq('user_id', uid)
          .maybeSingle();
      return [
        {'id': own == null ? 'like-summary' : uid, 'total': total},
      ];
    }
    final select = switch (table) {
      'events' when uri.queryParameters['mine'] == 'true' =>
        '*,event_registrations!inner(user_id)',
      'profiles' => '*,departments(name),user_roles(role)',
      'posts' => '*,author:profiles!posts_author_id_fkey(name,department:departments(name)),post_media(media_assets(path))',
      'comments' => '*,author:profiles!comments_author_id_fkey(name)',
      'saved_posts' => '*,post:posts(*,author:profiles!posts_author_id_fkey(name,department:departments(name)),post_media(media_assets(path)))',
      _ => '*',
    };
    var query = client.from(table).select(select);
    if (table == 'events') {
      final boundary = uri.queryParameters['from'];
      final before = uri.queryParameters['before'];
      if (boundary != null) query = query.gte('starts_at', boundary);
      if (before != null) query = query.lt('starts_at', before);
      if (uri.queryParameters['mine'] == 'true') {
        query = query.eq('event_registrations.user_id', uid);
      }
    }
    if (uri.path == 'profile') query = query.eq('id', uid);
    if (parts.length == 3) {
      final column = switch (parts.first) {
        'posts' => 'post_id',
        'communities' => 'community_id',
        'events' => 'event_id',
        _ => 'user_id',
      };
      query = query.eq(column, parts[1]);
    }
    if (table == 'event_registrations' || table == 'saved_posts') {
      query = query.eq('user_id', uid);
    }
    if (table == 'community_members') query = query.eq('user_id', uid);
    final community = uri.queryParameters['community'];
    if (table == 'posts' && community != null) {
      query = query.eq('community_id', community);
    }
    if (table == 'saved_posts') query = query.not('post', 'is', null);
    final search = uri.queryParameters['q']?.trim() ?? '';
    if (search.isNotEmpty) {
      // Server filtering scans the entire category before limiting results.
      final column = switch (table) {
        'profiles' || 'communities' => 'name',
        'events' => 'title',
        _ => 'body',
      };
      query = query.ilike(
        column,
        '%${search.replaceAll('%', r'\%').replaceAll('_', r'\_')}%',
      );
    }
    final count = int.tryParse(uri.queryParameters['limit'] ?? '') ?? 100;
    final order = table == 'events'
        ? 'starts_at'
        : table == 'user_roles' || table == 'device_tokens'
        ? 'updated_at'
        : 'created_at';
    final offset = (int.tryParse(uri.queryParameters['offset'] ?? '') ?? 0)
        .clamp(0, 100000);
    return await query
        .order(
          order,
          ascending: table == 'events' && uri.queryParameters['before'] == null,
        )
        .range(offset, offset + count.clamp(1, 500) - 1);
  }
}
