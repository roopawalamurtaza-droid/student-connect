import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/campus_item.dart';
import '../repositories/campus_repository.dart';

void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
String readableError(Object error) {
  if (error is AuthException) {
    if (error.code == 'over_email_send_rate_limit' ||
        error.message.toLowerCase().contains('email rate limit')) {
      return 'Email delivery is temporarily busy. Wait before requesting another email. If this keeps happening, contact your campus administrator.';
    }
    if (error.code == 'captcha_failed') {
      return 'The security check expired or could not be verified. Complete a fresh check and try again.';
    }
    if (error.code == 'invalid_credentials') {
      return 'That email and password do not match. Try again or reset your password.';
    }
    if (error.code == 'email_address_not_authorized') {
      return 'Email delivery is still being set up. Contact your campus administrator.';
    }
    return error.message;
  }
  if (error is PostgrestException) {
    if (error.code == '23505') {
      return 'That enrollment number or name is already in use.';
    }
    if (error.code == '23514' || error.code == '23502') {
      return 'Check the required fields and try again.';
    }
    return error.message;
  }
  if (error is FunctionException) {
    final details = error.details;
    if (details is Map<String, dynamic> && details['error'] is String) {
      return details['error'] as String;
    }
    return 'This request could not be completed. Please try again.';
  }
  return error
      .toString()
      .replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '')
      .replaceFirst('Bad state: ', '');
}

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });
  final String label;
  final Future<void> Function()? onPressed;
  final IconData? icon;
  final bool secondary;
  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: busy || widget.onPressed == null
          ? null
          : () async {
              setState(() => busy = true);
              try {
                await widget.onPressed!();
              } catch (e) {
                if (context.mounted) showMessage(context, readableError(e));
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon ?? Icons.arrow_forward, size: 18),
      label: Text(busy ? 'Please wait…' : widget.label),
    );
    return widget.secondary
        ? TextButton(
            onPressed: button.onPressed,
            child: Text(busy ? 'Please wait…' : widget.label),
          )
        : button;
  }
}

class Items extends StatefulWidget {
  const Items({
    super.key,
    required this.repository,
    required this.path,
    required this.builder,
  });
  final CampusRepository repository;
  final String path;
  final Widget Function(List<CampusItem>) builder;
  @override
  State<Items> createState() => _ItemsState();
}

class _ItemsState extends State<Items> {
  late Stream<List<CampusItem>> stream;
  @override
  void initState() {
    super.initState();
    stream = widget.repository.watch(widget.path);
  }

  @override
  void didUpdateWidget(Items old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.repository != widget.repository) {
      stream = widget.repository.watch(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<CampusItem>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Column(
          children: [
            EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Couldn’t load this right now',
              body: readableError(snapshot.error!),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => stream = widget.repository.watch(widget.path)),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return widget.builder(snapshot.data!);
    },
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
      ],
    ),
  );
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {super.key, this.radius = 22});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final initials = words.take(2).map((s) => s[0]).join().toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8EBD9),
      foregroundColor: const Color(0xFF344A39),
      child: Text(
        initials.isEmpty ? 'S' : initials,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: radius * .6),
      ),
    );
  }
}

class CampusImage extends StatefulWidget {
  const CampusImage({
    super.key,
    required this.repository,
    required this.path,
    this.height = 240,
  });
  final CampusRepository repository;
  final String path;
  final double height;
  @override
  State<CampusImage> createState() => _CampusImageState();
}

class _CampusImageState extends State<CampusImage> {
  late Future<Uint8List?> bytes;
  @override
  void initState() {
    super.initState();
    bytes = widget.repository.image(widget.path);
  }

  @override
  void didUpdateWidget(CampusImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) bytes = widget.repository.image(widget.path);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: bytes,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            snapshot.data!,
            height: widget.height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => const Text('Image unavailable'),
          ),
        );
      }
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            snapshot.hasError ? 'Image unavailable' : 'Loading image…',
          ),
        ),
      );
    },
  );
}

Future<bool> confirmDelete(BuildContext context, String label) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $label?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;

class PageHeading extends StatelessWidget {
  const PageHeading(this.eyebrow, this.title, this.subtitle, {super.key});
  final String eyebrow, title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
