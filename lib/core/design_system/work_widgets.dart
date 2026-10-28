import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../presentation/paged_view_model.dart';
import '../theme/app_colors.dart';
import 'app_dialog_styles.dart';
import 'app_tokens.dart';
import 'error_toast.dart';

String shortDate(DateTime date) =>
    DateFormat("EEE, d MMM · HH'h'mm", 'pt_BR').format(date.toLocal());
String fullDate(DateTime date) =>
    DateFormat("d 'de' MMMM · HH:mm", 'pt_BR').format(date.toLocal());
String initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((s) => s.isNotEmpty)
    .take(2)
    .map((s) => s.characters.first.toUpperCase())
    .join();

enum BadgeTone { brand, neutral, success, error }

class WorkBadge extends StatelessWidget {
  const WorkBadge(this.label, {super.key, this.tone = BadgeTone.brand});
  final String label;
  final BadgeTone tone;
  @override
  Widget build(BuildContext context) {
    final (ink, fill) = switch (tone) {
      BadgeTone.brand => (AppColors.primaryDark, AppColors.orangeSoft),
      BadgeTone.neutral => (
        AppColors.textSecondary,
        AppColors.backgroundSecondary,
      ),
      BadgeTone.success => (AppColors.success, AppColors.successSoft),
      BadgeTone.error => (AppColors.error, AppColors.errorSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
      ),
    );
  }
}

class WorkCard extends StatelessWidget {
  const WorkCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.backgroundSecondary),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class WorkScaffold extends StatelessWidget {
  const WorkScaffold({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.backEnabled = true,
    this.handleSystemBack = true,
  });
  final String title;
  final Widget body;
  final Widget? footer;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBack;
  final bool backEnabled;
  final bool handleSystemBack;
  bool _canPop(BuildContext context) =>
      GoRouter.maybeOf(context)?.canPop() ?? Navigator.of(context).canPop();
  void _back(BuildContext context) {
    if (!backEnabled) return;
    if (onBack != null) {
      onBack!();
    } else if (_canPop(context)) {
      context.pop();
    } else {
      context.go('/events');
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !handleSystemBack || !showBack || (backEnabled && _canPop(context)),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && handleSystemBack && showBack && backEnabled) {
        _back(context);
      }
    },
    child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                tooltip: 'Voltar',
                onPressed: backEnabled ? () => _back(context) : null,
                icon: const Icon(RemixIcons.arrow_left_line),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: footer == null
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.backgroundSecondary),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: SizedBox(width: double.infinity, child: footer),
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}

class WorkScroll extends StatelessWidget {
  const WorkScroll({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class WorkHeading extends StatelessWidget {
  const WorkHeading(this.title, {super.key, this.description});
  final String title;
  final String? description;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      if (description != null) ...[
        const SizedBox(height: 12),
        Text(
          description!,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ],
  );
}

class WorkNotice extends StatelessWidget {
  const WorkNotice({
    super.key,
    required this.title,
    required this.description,
    this.icon = RemixIcons.information_line,
  });
  final String title;
  final String description;
  final IconData icon;
  @override
  Widget build(BuildContext context) => WorkCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

class WorkFact extends StatelessWidget {
  const WorkFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class WorkState extends StatelessWidget {
  const WorkState({
    super.key,
    required this.title,
    required this.description,
    this.icon = RemixIcons.calendar_event_line,
    this.action,
    this.onAction,
    this.error = false,
  });
  final String title;
  final String description;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  final bool error;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: error
                    ? AppColors.errorSoft
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 32,
                color: error ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          WorkHeading(title, description: description),
          if (action != null) ...[
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

class PagedBody<T> extends StatefulWidget {
  const PagedBody({
    super.key,
    required this.model,
    required this.itemBuilder,
    required this.emptyTitle,
    required this.emptyDescription,
    this.header,
    this.emptyAction,
    this.onEmptyAction,
    this.onRefresh,
  });
  final PagedViewModel<T> model;
  final Widget Function(T item) itemBuilder;
  final Widget? header;
  final String emptyTitle;
  final String emptyDescription;
  final String? emptyAction;
  final VoidCallback? onEmptyAction;
  final Future<void> Function()? onRefresh;
  @override
  State<PagedBody<T>> createState() => _PagedBodyState<T>();
}

class _PagedBodyState<T> extends State<PagedBody<T>> {
  String? _lastError;
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_changed);
    Future.microtask(widget.model.load);
  }

  @override
  void didUpdateWidget(covariant PagedBody<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      oldWidget.model.removeListener(_changed);
      widget.model.addListener(_changed);
      Future.microtask(widget.model.load);
    }
  }

  void _changed() {
    if (!mounted) return;
    final error = widget.model.state.actionError;
    if (error != null && error != _lastError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showErrorToast(context, error);
      });
    }
    _lastError = error;
    setState(() {});
  }

  @override
  void dispose() {
    widget.model.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.model.state;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: widget.onRefresh ?? () => widget.model.load(refresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.header != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              sliver: SliverToBoxAdapter(child: widget.header),
            ),
          if (state.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.accessDenied)
            SliverFillRemaining(
              hasScrollBody: false,
              child: WorkState(
                title: 'Seu acesso mudou',
                description: 'Você não tem mais acesso a este evento.',
                error: true,
                icon: RemixIcons.lock_line,
                action: 'Voltar aos meus eventos',
                onAction: () => context.go('/events'),
              ),
            )
          else if (state.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: WorkState(
                title: 'Vamos tentar novamente?',
                description: state.error!,
                error: true,
                icon: RemixIcons.wifi_off_line,
                action: 'Tentar novamente',
                onAction: () => widget.model.load(),
              ),
            )
          else if (state.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: WorkState(
                title: widget.emptyTitle,
                description: widget.emptyDescription,
                action: widget.emptyAction,
                onAction: widget.onEmptyAction,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList.separated(
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) =>
                    widget.itemBuilder(state.items[index]),
              ),
            ),
          if (state.hasMore && !state.loading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton(
                  onPressed: state.loadingMore ? null : widget.model.loadMore,
                  child: Text(
                    state.loadingMore ? 'Carregando…' : 'Carregar mais',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(title, style: AppDialogStyles.title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              action,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ) ??
    false;

class WorkFade extends StatelessWidget {
  const WorkFade({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.duration(context, AppMotion.standard),
    builder: (context, value, child) => Opacity(opacity: value, child: child),
    child: child,
  );
}
