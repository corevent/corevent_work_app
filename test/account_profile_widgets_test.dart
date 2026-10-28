import 'dart:async';

import 'package:corevent_work_app/core/design_system/profile_avatar.dart';
import 'package:corevent_work_app/core/storage/token_store.dart';
import 'package:corevent_work_app/core/theme/app_theme.dart';
import 'package:corevent_work_app/features/account/presentation/account_page.dart';
import 'package:corevent_work_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_work_app/features/auth/data/auth_repository.dart';
import 'package:corevent_work_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_work_app/features/profile/data/profile_repository.dart';
import 'package:corevent_work_app/features/profile/presentation/profile_details_page.dart';
import 'package:corevent_work_app/features/profile/presentation/profile_form_pages.dart';
import 'package:corevent_work_app/features/profile/presentation/profile_forms_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _AuthRepository extends Mock implements AuthRepository {}

class _ProfileRepository extends Mock implements ProfileRepository {}

void main() {
  const user = UserProfile(
    id: 'user',
    name: 'Ana Silva',
    email: 'ana@example.com',
    phoneNumber: '+5511999999999',
    birthDate: '2000-01-01',
  );
  setUpAll(() => initializeDateFormatting('pt_BR'));
  late TokenStore tokens;
  late AuthSession session;
  setUp(() {
    tokens = TokenStore(const FlutterSecureStorage());
    session = AuthSession(_AuthRepository(), tokens)
      ..status = SessionStatus.authenticated
      ..user = user;
  });
  tearDown(() {
    session.dispose();
    tokens.dispose();
  });

  testWidgets(
    'conta oferece dados e seguranca e reflete alteracoes da sessao',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authSessionProvider.overrideWithValue(session)],
          child: MaterialApp(theme: AppTheme.light, home: const AccountPage()),
        ),
      );
      expect(find.text('Dados pessoais'), findsOneWidget);
      expect(find.text('Segurança'), findsOneWidget);
      expect(find.text('Ana Silva'), findsOneWidget);
      session.updateUser(
        const UserProfile(
          id: 'user',
          name: 'Ana Souza',
          email: 'ana@example.com',
        ),
      );
      await tester.pump();
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(
        tester
            .widget<CoreventProfileAvatar>(find.byType(CoreventProfileAvatar))
            .name,
        'Ana Souza',
      );
    },
  );

  for (final scale in [1.5, 2.0]) {
    testWidgets('conta permite rolagem com fonte $scale em celular estreito', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authSessionProvider.overrideWithValue(session)],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const AccountPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dados pessoais bloqueiam campos e voltar enquanto salva', (
    tester,
  ) async {
    final repository = _ProfileRepository();
    final save = Completer<UserProfile>();
    when(() => repository.updateFields(any())).thenAnswer((_) => save.future);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWithValue(session),
          profileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProfileDetailsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ana Souza');
    await tester.pump();
    await tester.ensureVisible(find.text('Salvar alterações'));
    await tester.tap(find.text('Salvar alterações'));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Voltar',
            ),
          )
          .onPressed,
      isNull,
    );
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.enabled, isFalse);
    }
    save.complete(
      const UserProfile(
        id: 'user',
        name: 'Ana Souza',
        email: 'ana@example.com',
        phoneNumber: '+5511999999999',
      ),
    );
    await tester.pumpAndSettle();
    expect(session.user?.name, 'Ana Souza');
    expect(find.text('Dados atualizados.'), findsOneWidget);
  });

  testWidgets(
    'seguranca bloqueia formulario durante envio e permite corrigir erro',
    (tester) async {
      final repository = _ProfileRepository();
      final save = Completer<void>();
      when(() => repository.changePassword(any(), any()))
          .thenAnswer((_) => save.future);
      final container = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfileSecurityPage(),
          ),
        ),
      );
      await tester.pump();
      final model = container.read(securityViewModelProvider.notifier);
      final operation = model.change('Atual!123', 'Nova!1234', 'Nova!1234');
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) => widget is IconButton && widget.tooltip == 'Voltar',
              ),
            )
            .onPressed,
        isNull,
      );
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.enabled, isFalse);
      }
      save.completeError(Exception('offline'));
      await operation;
      await tester.pump();
      expect(
        find.text('Não foi possível alterar a senha. Confira a senha atual.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) => widget is IconButton && widget.tooltip == 'Voltar',
              ),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
}
