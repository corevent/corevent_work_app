import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_session.dart';
import '../features/profile/data/avatar_picker.dart';
import 'router.dart';

class CoreventWorkApp extends ConsumerStatefulWidget {
  const CoreventWorkApp({super.key});
  @override
  ConsumerState<CoreventWorkApp> createState() => _CoreventWorkAppState();
}

class _CoreventWorkAppState extends ConsumerState<CoreventWorkApp> {
  late final AuthSession _session;
  bool _pendingAvatarRecovery = false;
  @override
  void initState() {
    super.initState();
    _session = ref.read(authSessionProvider)
      ..addListener(_resumeAvatarRecovery);
    unawaited(_recoverAvatar());
  }

  Future<void> _recoverAvatar() async {
    try {
      final recovered = await ref.read(avatarPickerProvider).recover();
      if (!mounted || !recovered) return;
      _pendingAvatarRecovery = true;
      _resumeAvatarRecovery();
    } catch (_) {
      /* A cancelled/failed image picker must not block app startup. */
    }
  }

  void _resumeAvatarRecovery() {
    if (!mounted || !_pendingAvatarRecovery) return;
    if (_session.status == SessionStatus.unauthenticated) {
      _pendingAvatarRecovery = false;
      ref.read(avatarPickerProvider).takeRecovered();
      return;
    }
    if (_session.status != SessionStatus.authenticated) return;
    _pendingAvatarRecovery = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _session.status == SessionStatus.authenticated) {
        ref.read(routerProvider).go('/account/details');
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    _session.removeListener(_resumeAvatarRecovery);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Corevent para Equipes',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: ref.watch(routerProvider),
  );
}
