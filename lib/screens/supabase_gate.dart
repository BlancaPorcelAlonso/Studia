import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/agenda_repository.dart';
import '../theme/cottagecore_theme.dart';
import 'app_shell.dart';
import 'auth_screen.dart';

class SupabaseGate extends StatefulWidget {
  const SupabaseGate({super.key});

  @override
  State<SupabaseGate> createState() => _SupabaseGateState();
}

class _SupabaseGateState extends State<SupabaseGate> {
  StreamSubscription<AuthState>? _subscription;
  User? _user;
  String? _loadedUserId;
  Object? _loadError;
  bool _loading = true;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _user = auth.currentUser;
    _subscription = auth.onAuthStateChange.listen(
      (state) => _handleUser(state.session?.user),
      onError: (Object error, StackTrace stackTrace) {
        if (mounted) setState(() => _loadError = error);
      },
    );
    if (_user == null) {
      _loading = false;
    } else {
      unawaited(_handleUser(_user));
    }
  }

  Future<void> _handleUser(User? user) async {
    final requestId = ++_requestId;
    if (user == null) {
      await AgendaRepository.instance.resetForSignedOut();
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _user = null;
        _loadedUserId = null;
        _loading = false;
        _loadError = null;
      });
      return;
    }

    if (user.id == _loadedUserId && !_loading) return;
    setState(() {
      _user = user;
      _loading = true;
      _loadError = null;
    });
    try {
      await AgendaRepository.instance.initialize(useCloud: true);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadedUserId = user.id;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const AuthScreen();
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 42, color: CottagecoreColors.terracotta),
                const SizedBox(height: 12),
                const Text('No se pudieron cargar tus datos.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _handleUser(_user),
                  child: const Text('Reintentar'),
                ),
                TextButton(
                  onPressed: () => Supabase.instance.client.auth.signOut(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const AppShell();
  }
}
