import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/app_tokens.dart';
import '../features/account/presentation/account_page.dart';
import '../features/auth/presentation/auth_flow_store.dart';
import '../features/auth/presentation/auth_session.dart';
import '../features/auth/presentation/authenticated_page.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/login_view_model.dart';
import '../features/auth/presentation/recovery_view_model.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/register_view_model.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/auth/presentation/verification_page.dart';
import '../features/auth/presentation/verification_view_model.dart';
import '../features/checkin/presentation/checkin_pages.dart';
import '../features/invitations/data/invitation.dart';
import '../features/invitations/data/invitations_repository.dart';
import '../features/invitations/presentation/invitations_pages.dart';
import '../features/invitations/presentation/invitations_view_model.dart';
import '../features/participants/data/participants_repository.dart';
import '../features/participants/presentation/participants_pages.dart';
import '../features/participants/presentation/participants_view_model.dart';
import '../features/profile/data/avatar_picker.dart';
import '../features/profile/presentation/avatar_view_model.dart';
import '../features/profile/presentation/profile_details_page.dart';
import '../features/profile/presentation/profile_form_pages.dart';
import '../features/profile/presentation/profile_forms_view_model.dart';
import '../features/staff_events/data/staff_events_repository.dart';
import '../features/staff_events/presentation/event_pages.dart';
import '../features/staff_events/presentation/events_page.dart';
import '../features/staff_events/presentation/events_view_model.dart';
import '../features/welcome/presentation/welcome_page.dart';

bool _privatePath(String path) =>
    path == '/events' ||
    path.startsWith('/events/') ||
    path == '/account' ||
    path.startsWith('/account/') ||
    path == '/invitations' ||
    path.startsWith('/invitations/');

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);
  final flow = ref.watch(authFlowStoreProvider);
  void clearPrivateState() {
    if (session.status != SessionStatus.unauthenticated) return;
    ref.invalidate(eventsViewModelProvider);
    ref.invalidate(eventAccessProvider);
    ref.invalidate(eventDetailsProvider);
    ref.invalidate(pendingInvitationsProvider);
    ref.invalidate(invitationsViewModelProvider);
    ref.invalidate(participantsViewModelProvider);
    ref.invalidate(participantDetailsProvider);
    ref.invalidate(detailsViewModelProvider);
    ref.invalidate(securityViewModelProvider);
    ref.invalidate(avatarViewModelProvider);
    ref.read(avatarPickerProvider).takeRecovered();
    ref.invalidate(loginViewModelProvider);
    ref.invalidate(registerViewModelProvider);
    ref.invalidate(recoveryViewModelProvider);
    ref.invalidate(verificationViewModelProvider);
    flow.notice = null;
    flow.clearRegistration();
    flow.clearRecovery();
  }

  session.addListener(clearPrivateState);
  ref.onDispose(() => session.removeListener(clearPrivateState));
  final router = GoRouter(
    refreshListenable: session,
    redirect: (context, state) {
      final path = state.uri.path;
      final status = session.status;
      if (status == SessionStatus.authenticated &&
          !_privatePath(path) &&
          path != '/loading') {
        return '/events';
      }
      if (_privatePath(path) && status == SessionStatus.unauthenticated) {
        return '/';
      }
      if (_privatePath(path) && status != SessionStatus.authenticated) {
        return '/loading?next=${Uri.encodeComponent(path)}';
      }
      if (path == '/loading' && status == SessionStatus.authenticated) {
        final next = state.uri.queryParameters['next'];
        return next != null && _privatePath(next) ? next : '/events';
      }
      if (path == '/loading' && status == SessionStatus.unauthenticated) {
        return '/';
      }
      if (path == '/' && status == SessionStatus.loading) return '/loading';
      if (path == '/verify/register' && flow.registration == null) {
        return '/register';
      }
      if (path == '/verify/reset' && flow.recoveryEmail == null) {
        return '/forgot-password';
      }
      if (path == '/reset-password' &&
          (flow.recoveryEmail == null || flow.recoveryCode == null)) {
        return '/forgot-password';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        pageBuilder: (_, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const WelcomePage(),
        ),
      ),
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (_, _) => const SessionLoadingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (_, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (_, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: '/verify/register',
        name: 'verifyRegister',
        pageBuilder: (context, state) => _fade(
          context,
          state,
          const VerificationPage(mode: VerificationMode.register),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        pageBuilder: (context, state) =>
            _fade(context, state, const ForgotPasswordPage()),
      ),
      GoRoute(
        path: '/verify/reset',
        name: 'verifyReset',
        pageBuilder: (context, state) => _fade(
          context,
          state,
          const VerificationPage(mode: VerificationMode.reset),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'resetPassword',
        pageBuilder: (context, state) =>
            _fade(context, state, const ResetPasswordPage()),
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (_, _) => const EventsPage(),
      ),
      GoRoute(
        path: '/events/:id',
        name: 'event',
        pageBuilder: (context, state) => _fade(
          context,
          state,
          EventDashboardPage(eventId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/events/:id/info',
        pageBuilder: (context, state) => _fade(
          context,
          state,
          EventInfoPage(eventId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/events/:id/participants',
        pageBuilder: (context, state) => _fade(
          context,
          state,
          ParticipantsPage(eventId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/events/:id/participants/:userId',
        pageBuilder: (context, state) => _fade(
          context,
          state,
          ParticipantDetailsPage(
            eventId: state.pathParameters['id']!,
            userId: state.pathParameters['userId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/events/:id/scan',
        builder: (_, state) =>
            CheckinPage(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:id/totem-setup',
        pageBuilder: (context, state) => _fade(
          context,
          state,
          TotemSetupPage(eventId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/events/:id/totem',
        builder: (_, state) =>
            CheckinPage(eventId: state.pathParameters['id']!, totem: true),
      ),
      GoRoute(
        path: '/invitations',
        name: 'invitations',
        pageBuilder: (context, state) =>
            _fade(context, state, const InvitationsPage()),
      ),
      GoRoute(
        path: '/invitations/:id',
        redirect: (_, state) =>
            state.extra is Invitation ? null : '/invitations',
        pageBuilder: (context, state) => _fade(
          context,
          state,
          InvitationPage(invitation: state.extra! as Invitation),
        ),
      ),
      GoRoute(
        path: '/account/details',
        name: 'accountDetails',
        pageBuilder: (context, state) =>
            _fade(context, state, const ProfileDetailsPage()),
      ),
      GoRoute(
        path: '/account/security',
        name: 'accountSecurity',
        pageBuilder: (context, state) =>
            _fade(context, state, const ProfileSecurityPage()),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        pageBuilder: (context, state) =>
            _fade(context, state, const AccountPage()),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

CustomTransitionPage<void> _fade(
  BuildContext context,
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: AppMotion.duration(context, AppMotion.standard),
  reverseTransitionDuration: AppMotion.duration(context, AppMotion.standard),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppMotion.curve),
        child: child,
      ),
);
