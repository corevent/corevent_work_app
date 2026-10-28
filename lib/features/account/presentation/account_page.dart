import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/profile_avatar.dart';
import '../../../core/design_system/work_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_session.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});
  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _busy = false;
  Future<void> _logout() async {
    if (_busy) return;
    final confirmed = await confirmDestructive(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar seus eventos.',
      action: 'Sair',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(authSessionProvider).logout();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final user = session.user;
        return PopScope(
          canPop: !_busy,
          child: WorkScaffold(
            title: 'Minha conta',
            backEnabled: !_busy,
            onBack: _busy ? () {} : null,
            body: AbsorbPointer(
              absorbing: _busy,
              child: WorkScroll(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: 'Editar perfil',
                        child: InkWell(
                          onTap: _busy
                              ? null
                              : () => context.push('/account/details'),
                          customBorder: const CircleBorder(),
                          child: CoreventProfileAvatar(
                            name: user?.name ?? '',
                            url: user?.avatarUrl,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Conta Corevent',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _AccountAction(
                    title: 'Dados pessoais',
                    description: 'Nome, telefone e foto de perfil.',
                    icon: RemixIcons.contacts_line,
                    onTap: () => context.push('/account/details'),
                  ),
                  const SizedBox(height: 14),
                  _AccountAction(
                    title: 'Segurança',
                    description: 'Alterar sua senha de acesso.',
                    icon: RemixIcons.lock_password_line,
                    onTap: () => context.push('/account/security'),
                  ),
                  const SizedBox(height: 28),
                  const WorkNotice(
                    title: 'Permissões por evento',
                    description: 'Você pode ter acesso somente leitura em um evento e permissão de check-in em outro.',
                  ),
                  const SizedBox(height: 32),
                  Image.asset(
                    'assets/images/logo_corevent_full.png',
                    height: 28,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'para Equipes',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            footer: TextButton.icon(
              onPressed: _busy ? null : _logout,
              icon: const Icon(RemixIcons.logout_box_r_line),
              label: Text(_busy ? 'Saindo…' : 'Sair da conta'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => WorkCard(
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          RemixIcons.arrow_right_s_line,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ],
    ),
  );
}
