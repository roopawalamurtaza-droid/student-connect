import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';

class AccountControls extends StatelessWidget {
  const AccountControls({super.key, required this.repository});
  final CampusRepository repository;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      Text('Blocked accounts', style: Theme.of(context).textTheme.titleLarge),
      Items(
        repository: repository,
        path: 'blocked',
        builder: (items) => items.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('You haven’t blocked anyone.'),
              )
            : Column(
                children: items
                    .map(
                      (item) => ListTile(
                        title: const Text('Blocked student'),
                        subtitle: Text(item.id),
                        trailing: ActionButton(
                          label: 'Unblock',
                          onPressed: () async {
                            await repository.mutate('unblockUser', {
                              'id': item.id,
                            });
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
      const Divider(height: 32),
      ActionButton(
        label: 'Delete my account',
        icon: Icons.person_remove_outlined,
        onPressed: () async {
          await showDialog<void>(
            context: context,
            builder: (_) => _DeleteAccountDialog(repository: repository),
          );
        },
      ),
    ],
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.repository});
  final CampusRepository repository;
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final password = TextEditingController();
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete your account?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Your profile, posts, comments, registrations and uploaded photos will be permanently deleted. Moderation records may be retained without your profile. Enter your password to confirm.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ActionButton(
        label: 'Permanently delete',
        onPressed: () async {
          if (password.text.isEmpty) throw StateError('Enter your password.');
          await widget.repository.mutate('deleteAccount', {
            'confirmDelete': true,
            'password': password.text,
          });
          if (context.mounted) Navigator.pop(context);
          await Supabase.instance.client.auth.signOut(
            scope: SignOutScope.local,
          );
        },
      ),
    ],
  );
}
