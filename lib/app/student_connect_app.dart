import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../features/auth/auth_screen.dart';
import '../features/profile/profile_screen.dart';
import '../models/campus_item.dart';
import '../repositories/campus_repository.dart';
import '../repositories/firebase_repository.dart';
import '../repositories/preview_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'workspace.dart';

class StudentConnectApp extends StatefulWidget {
  const StudentConnectApp({super.key, this.startupError});
  final String? startupError;
  @override
  State<StudentConnectApp> createState() => _StudentConnectAppState();
}

class _StudentConnectAppState extends State<StudentConnectApp> {
  ThemeMode mode = ThemeMode.light;
  CampusRepository? preview;
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => mode = prefs.getBool('darkMode') == true
            ? ThemeMode.dark
            : ThemeMode.light,
      );
    }
  }

  Future<void> toggleTheme() async {
    setState(
      () => mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', mode == ThemeMode.dark);
  }

  @override
  void dispose() {
    preview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Student Connect',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.build(Brightness.light),
    darkTheme: AppTheme.build(Brightness.dark),
    themeMode: mode,
    home: preview != null
        ? SessionGate(
            repository: preview!,
            onTheme: toggleTheme,
            onExit: () async {
              setState(() {
                preview?.dispose();
                preview = null;
              });
            },
          )
        : AppConfig.firebaseEnabled && widget.startupError == null
        ? StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final user = snapshot.data;
              if (user == null || !user.emailVerified) {
                return AuthScreen(
                  onPreview: _preview,
                  onTheme: toggleTheme,
                  user: user,
                );
              }
              return FirebaseSession(
                key: ValueKey(user.uid),
                uid: user.uid,
                onTheme: toggleTheme,
              );
            },
          )
        : AuthScreen(
            onPreview: _preview,
            onTheme: toggleTheme,
            error: widget.startupError,
          ),
  );
  void _preview() => setState(() => preview = PreviewRepository());
}

class FirebaseSession extends StatefulWidget {
  const FirebaseSession({super.key, required this.uid, required this.onTheme});
  final String uid;
  final VoidCallback onTheme;
  @override
  State<FirebaseSession> createState() => _FirebaseSessionState();
}

class _FirebaseSessionState extends State<FirebaseSession> {
  late final repository = FirebaseCampusRepository(widget.uid);
  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SessionGate(
    repository: repository,
    onTheme: widget.onTheme,
    onExit: () => FirebaseAuth.instance.signOut(),
  );
}

class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.repository,
    required this.onTheme,
    required this.onExit,
  });
  final CampusRepository repository;
  final VoidCallback onTheme;
  final Future<void> Function() onExit;
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final stream = widget.repository.isPreview
      ? widget.repository.watch('users')
      : FirebaseFirestore.instance
            .doc('users/${widget.repository.uid}')
            .snapshots()
            .map(
              (d) => d.exists ? [CampusItem(d.id, d.data()!)] : <CampusItem>[],
            );
  @override
  Widget build(BuildContext context) => StreamBuilder<List<CampusItem>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your profile could not be loaded.'),
                ActionButton(label: 'Sign out', onPressed: widget.onExit),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final profiles = snapshot.data!.where(
        (p) => p.id == widget.repository.uid,
      );
      if (profiles.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete your profile'),
            actions: [
              TextButton(
                onPressed: widget.onExit,
                child: const Text('Sign out'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ProfileEditor(repository: widget.repository),
          ),
        );
      }
      final me = profiles.first;
      if (me.flag('suspended')) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your account is suspended. Contact your university.',
                ),
                ActionButton(label: 'Sign out', onPressed: widget.onExit),
              ],
            ),
          ),
        );
      }
      return Workspace(
        repository: widget.repository,
        me: me,
        onTheme: widget.onTheme,
        onExit: widget.onExit,
      );
    },
  );
}
