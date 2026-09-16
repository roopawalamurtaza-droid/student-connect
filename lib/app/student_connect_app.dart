import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_data_service.dart';
import '../features/auth/reset_password_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../features/auth/auth_screen.dart';
import '../features/profile/profile_screen.dart';
import '../models/campus_item.dart';
import '../repositories/campus_repository.dart';
import '../repositories/supabase_repository.dart';
import '../repositories/preview_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'workspace.dart';
import '../routes/shared_content.dart';

class StudentConnectApp extends StatefulWidget {
  const StudentConnectApp({
    super.key,
    this.startupError,
    this.initialRecovery = false,
    this.allowPreview = AppConfig.allowPreview,
    this.initialLocation,
  });
  final bool allowPreview, initialRecovery;
  final String? startupError;
  final String? initialLocation;
  @override
  State<StudentConnectApp> createState() => _StudentConnectAppState();
}

class _StudentConnectAppState extends State<StudentConnectApp> {
  ThemeMode mode = ThemeMode.light;
  CampusRepository? preview;
  final navigatorKey = GlobalKey<NavigatorState>();
  final gateRevision = ValueNotifier<int>(0);
  Widget _gate(ContentTarget? target) => ValueListenableBuilder<int>(
    valueListenable: gateRevision,
    builder: (_, _, _) => _sessionGate(target),
  );
  late final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: widget.initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, state) => _gate(null)),
      GoRoute(
        path: '/:kind/:id',
        builder: (_, state) {
          final target = ContentTarget.parse(state.uri);
          return target == null ? _unknownLink() : _gate(target);
        },
      ),
    ],
    errorBuilder: (_, _) => _unknownLink(),
  );
  Widget _unknownLink() => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('This link is not available.'),
          TextButton(
            onPressed: () => router.go('/'),
            child: const Text('Go to campus home'),
          ),
        ],
      ),
    ),
  );
  StreamSubscription<AuthState>? authSubscription;
  late bool recoveryPending = widget.initialRecovery;
  String? previousUser;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    if (AppConfig.supabaseEnabled && widget.startupError == null) {
      previousUser = Supabase.instance.client.auth.currentUser?.id;
      authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (state) {
          final changed = previousUser != state.session?.user.id;
          previousUser = state.session?.user.id;
          if (state.event == AuthChangeEvent.passwordRecovery) {
            recoveryPending = true;
          }
          if (state.event == AuthChangeEvent.signedOut) recoveryPending = false;
          if (changed || state.event == AuthChangeEvent.passwordRecovery) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                navigatorKey.currentState?.popUntil((route) => route.isFirst);
              }
            });
          }
        },
        onError: (Object error, StackTrace stack) {},
      );
    }
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
    authSubscription?.cancel();
    preview?.dispose();
    router.dispose();
    gateRevision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: router,
    title: 'Student Connect',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.build(Brightness.light),
    darkTheme: AppTheme.build(Brightness.dark),
    themeMode: mode,
  );
  Widget _sessionGate(ContentTarget? target) => preview != null
      ? SessionGate(
          repository: preview!,
          target: target,
          onTheme: toggleTheme,
          onExit: () async {
            setState(() {
              preview?.dispose();
              preview = null;
            });
            gateRevision.value++;
          },
        )
      : AppConfig.supabaseEnabled && widget.startupError == null
      ? StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          initialData: AuthState(
            AuthChangeEvent.initialSession,
            Supabase.instance.client.auth.currentSession,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final state = snapshot.data;
            final user = state?.session?.user;
            if (recoveryPending && user != null) {
              return ResetPasswordScreen(
                onDone: () => setState(() {
                  recoveryPending = false;
                  gateRevision.value++;
                }),
              );
            }
            if (user == null || user.emailConfirmedAt == null) {
              return AuthScreen(
                onPreview: widget.allowPreview ? _preview : null,
                onTheme: toggleTheme,
              );
            }
            return SupabaseSession(
              key: ValueKey(user.id),
              uid: user.id,
              onTheme: toggleTheme,
              target: target,
            );
          },
        )
      : AuthScreen(
          onPreview: widget.allowPreview ? _preview : null,
          onTheme: toggleTheme,
          error: widget.startupError,
        );
  void _preview() {
    setState(() => preview = PreviewRepository());
    gateRevision.value++;
  }
}

class SupabaseSession extends StatefulWidget {
  const SupabaseSession({
    super.key,
    required this.uid,
    required this.onTheme,
    this.target,
  });
  final ContentTarget? target;
  final String uid;
  final VoidCallback onTheme;
  @override
  State<SupabaseSession> createState() => _SupabaseSessionState();
}

class _SupabaseSessionState extends State<SupabaseSession> {
  late final repository = SupabaseCampusRepository(
    widget.uid,
    SupabaseDataService(Supabase.instance.client),
  );
  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SessionGate(
    repository: repository,
    target: widget.target,
    onTheme: widget.onTheme,
    onExit: () => Supabase.instance.client.auth.signOut(),
  );
}

class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.repository,
    required this.onTheme,
    required this.onExit,
    this.target,
  });
  final CampusRepository repository;
  final VoidCallback onTheme;
  final Future<void> Function() onExit;
  final ContentTarget? target;
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final stream = widget.repository.watch(
    widget.repository.isPreview ? 'users' : 'profile',
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
      if (widget.target != null) {
        return SharedContentScreen(
          repository: widget.repository,
          me: me,
          target: widget.target!,
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
