import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/corevent_field.dart';
import '../../../core/design_system/work_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/password_requirements.dart';
import 'profile_forms_view_model.dart';

class ProfileSubpage extends StatelessWidget {
  const ProfileSubpage({
    super.key,
    required this.title,
    required this.child,
    this.busy = false,
    this.onBack,
  });
  final String title;
  final Widget child;
  final bool busy;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => WorkScaffold(
    title: title,
    backEnabled: !busy,
    onBack: onBack,
    handleSystemBack: false,
    body: child,
  );
}

class ProfileSecurityPage extends ConsumerStatefulWidget {
  const ProfileSecurityPage({super.key});
  @override
  ConsumerState<ProfileSecurityPage> createState() =>
      _ProfileSecurityPageState();
}

class _ProfileSecurityPageState extends ConsumerState<ProfileSecurityPage> {
  String current = '';
  String next = '';
  String confirmation = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(securityViewModelProvider);
    });
  }

  void _back() {
    if (ref.read(securityViewModelProvider).busy) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      GoRouter.maybeOf(context)?.go('/account');
    }
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final changed = await ref
        .read(securityViewModelProvider.notifier)
        .change(current, next, confirmation);
    if (!mounted || !changed) return;
    setState(() {
      current = '';
      next = '';
      confirmation = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Senha alterada com sucesso.',
          style: TextStyle(color: AppColors.surface),
        ),
        backgroundColor: AppColors.success,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    _back();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityViewModelProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: WorkScaffold(
        title: 'Segurança',
        backEnabled: !state.busy,
        handleSystemBack: false,
        onBack: _back,
        body: AbsorbPointer(
          absorbing: state.busy,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const Text(
                  'Escolha uma senha forte que você não usa em outros serviços.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 24),
                CoreventField(
                  label: 'Senha atual',
                  password: true,
                  initialValue: current,
                  enabled: !state.busy,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  onChanged: (value) => current = value,
                ),
                CoreventField(
                  label: 'Nova senha',
                  password: true,
                  initialValue: next,
                  enabled: !state.busy,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  onChanged: (value) => setState(() => next = value),
                ),
                PasswordRequirements(password: next),
                CoreventField(
                  label: 'Confirmar nova senha',
                  password: true,
                  initialValue: confirmation,
                  enabled: !state.busy,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  onChanged: (value) => confirmation = value,
                ),
              ],
            ),
          ),
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            CoreventButton(
              label: 'Alterar senha',
              busy: state.busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
