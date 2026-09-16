import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/services/supabase_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('joined feed constrains membership and search before paging', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test-key',
    );
    final request = server.first.then((request) async {
      expect(
        request.uri.queryParameters['select'],
        contains('communities!inner(community_members!inner(user_id))'),
      );
      expect(
        request.uri.queryParameters['communities.community_members.user_id'],
        'eq.student-id',
      );
      expect(request.uri.queryParameters['body'], 'ilike.%hello%');
      expect(request.uri.queryParameters['offset'], '30');
      request.response.headers.contentType = ContentType.json;
      request.response.write('[]');
      await request.response.close();
    });
    try {
      expect(
        await SupabaseDataService(
          client,
        ).fetch('posts?joined=true&q=hello&offset=30&limit=30', 'student-id'),
        isEmpty,
      );
      await request;
    } finally {
      await client.dispose();
      await server.close(force: true);
    }
  });
}
