import 'package:flutter/material.dart';

import '../../core/config.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final support = AppConfig.supportEmail.isEmpty
        ? 'your campus administrator'
        : AppConfig.supportEmail;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and community safety')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Student Connect pilot notice',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Effective 10 September 2026'),
            const SizedBox(height: 24),
            const _PolicySection(
              title: 'Information we use',
              body: 'Student Connect uses your verified university email, profile details, posts, comments, reactions, club and event activity, reports, and device notification token. It uses this information to operate the campus community, protect accounts, moderate content, and deliver notifications.',
            ),
            const _PolicySection(
              title: 'Who can see it',
              body: 'Signed-in campus members can see the profile and content you choose to publish. Reports, blocked-account relationships, device tokens, and personal notifications are private. Authorized moderators may review reports and relevant content.',
            ),
            const _PolicySection(
              title: 'Storage and service providers',
              body: 'Supabase stores identity and application data. Firebase provides hosting, diagnostics, analytics, and device messaging. Student Connect does not sell student data. Access is limited to operating, securing, and improving the service.',
            ),
            const _PolicySection(
              title: 'Retention and deletion',
              body: 'Account data is kept while the account is active. You can permanently delete your account from Profile. The deletion process removes your profile, posts, comments, registrations, and uploaded media. De-identified moderation records and security logs may be retained for up to 24 months to protect the community and resolve abuse cases.',
            ),
            const _PolicySection(
              title: 'Acceptable use',
              body: 'Use your own university identity. Do not harass, threaten, impersonate, spam, discriminate, publish private information without permission, infringe intellectual property, or post unlawful or dangerous material. Do not attempt to bypass access controls or disrupt the service.',
            ),
            const _PolicySection(
              title: 'Reports and moderation',
              body: 'Use the report action on a post or account when content may violate these rules. Moderators may remove content, restrict accounts, or preserve relevant records. For an immediate threat, contact university security or local emergency services.',
            ),
            _PolicySection(
              title: 'Questions and requests',
              body:
                  'For privacy questions, corrections, appeals, or support, contact $support. University approval and an official support address are required before this pilot opens to the wider campus.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(height: 1.5)),
      ],
    ),
  );
}
