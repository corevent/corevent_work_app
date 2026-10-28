import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remixicon/remixicon.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/design_system/work_widgets.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../participants/data/participants_repository.dart';
import '../../participants/presentation/participants_view_model.dart';
import '../../staff_events/data/staff_event.dart';
import '../../staff_events/data/staff_events_repository.dart';
import '../../staff_events/presentation/event_access_gate.dart';
import '../data/checkin_repository.dart';
import '../domain/checkin_outcome.dart';
import 'checkin_view_model.dart';
import 'scanner_camera_actions.dart';

class TotemSetupPage extends StatelessWidget {
  const TotemSetupPage({super.key, required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context) => EventAccessGate(
    eventId: eventId,
    checkin: true,
    builder: (event) => WorkScaffold(
      title: 'Modo totem',
      body: WorkScroll(
        children: [
          WorkHeading(
            'Pronto para receber',
            description:
                'O dispositivo fará leituras automáticas para ${event.title}.',
          ),
          const SizedBox(height: 32),
          const WorkFact(
            icon: RemixIcons.camera_line,
            label: 'Posicione o dispositivo',
            value: 'Use um suporte estável com a câmera acessível.',
          ),
          const WorkFact(
            icon: RemixIcons.battery_line,
            label: 'Mantenha conectado',
            value: 'Conecte à energia durante o atendimento.',
          ),
          const WorkFact(
            icon: RemixIcons.wifi_line,
            label: 'Confira a conexão',
            value: 'Cada ingresso será validado pela API. Sem conexão, o atendimento será pausado.',
          ),
          const WorkNotice(
            title: 'Permissão de check-in',
            description: 'O totem usa seu acesso neste evento para registrar as entradas. A tela permanecerá ligada durante o atendimento.',
          ),
        ],
      ),
      footer: CoreventButton(
        label: 'Iniciar modo totem',
        onPressed: () => context.push('/events/$eventId/totem'),
      ),
    ),
  );
}

class CheckinPage extends StatelessWidget {
  const CheckinPage({super.key, required this.eventId, this.totem = false});
  final String eventId;
  final bool totem;
  @override
  Widget build(BuildContext context) => EventAccessGate(
    eventId: eventId,
    checkin: true,
    builder: (event) => _ScannerScreen(
      key: ValueKey('$eventId/$totem'),
      event: event,
      totem: totem,
    ),
  );
}

class _ScannerScreen extends ConsumerStatefulWidget {
  const _ScannerScreen({super.key, required this.event, required this.totem});
  final StaffEvent event;
  final bool totem;
  @override
  ConsumerState<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<_ScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _cameraController;
  late final CheckinViewModel _model;
  Future<void> _cameraOperation = Future<void>.value();
  Timer? _resultTimer;
  bool _active = true;
  bool _scanLock = false;
  bool _exitDialog = false;
  bool _covered = false;
  bool _requested = false;
  bool _switchingCamera = false;
  CameraFacing _selectedCamera = CameraFacing.back;
  MobileScannerException? _cameraError;

  bool get _busy => _model.busy || _scanLock;
  bool get _interactionLocked => _busy || _switchingCamera;
  bool get _canScan =>
      _active &&
      !_covered &&
      !_exitDialog &&
      !_interactionLocked &&
      _requested &&
      _model.outcome == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
    );
    _model = CheckinViewModel(
      ref.read(checkinRepositoryProvider),
      widget.event.id,
    )..addListener(_changed);
    _requested = widget.totem;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _requested) unawaited(_camera(true));
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _wake(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled && widget.totem);
    } on PlatformException {
      /* The scanner remains usable if wake lock is unavailable. */
    }
  }

  // Camera operations are serialized; permission dialogs may change lifecycle
  // while start() is still pending.
  Future<void> _camera(bool start, {bool onlyWhenInactive = false}) {
    final operation = _cameraOperation.then((_) async {
      if (!mounted) return;
      if (onlyWhenInactive && _active) return;
      if (start && !_canScan) return;
      try {
        if (start) {
          if (!_cameraController.value.isRunning) {
            await _cameraController.start(cameraDirection: _selectedCamera);
            final error = _cameraController.value.error;
            if (error != null) throw error;
          }
          if (mounted) {
            setState(() => _cameraError = null);
            await _wake(true);
          }
        } else {
          if (_cameraController.value.isRunning) await _cameraController.stop();
          await _wake(_active && !_exitDialog && !_covered);
        }
      } on MobileScannerException catch (error) {
        if (mounted && start) setState(() => _cameraError = error);
      }
    });
    _cameraOperation = operation;
    return operation;
  }

  Future<void> _switchCamera() {
    if (!_canScan || _cameraError != null) return Future<void>.value();
    final previous = _selectedCamera;
    setState(() => _switchingCamera = true);
    final operation = _cameraOperation.then((_) async {
      try {
        if (!mounted ||
            !_active ||
            _covered ||
            _exitDialog ||
            _busy ||
            !_requested ||
            _model.outcome != null) {
          return;
        }
        final state = _cameraController.value;
        if (!state.isRunning || state.isStarting) return;
        await _cameraController.switchCamera();
        final updated = _cameraController.value;
        final error = updated.error;
        if (error != null) throw error;
        if (!updated.isRunning || updated.cameraDirection == previous) {
          throw const MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
          );
        }
        _selectedCamera = updated.cameraDirection;
        if (mounted) setState(() => _cameraError = null);
      } on Exception {
        // A lens can become unavailable between detection and switching.
        // Restore the previous camera without resubmitting any QR code.
        _selectedCamera = previous;
        if (mounted &&
            _active &&
            !_covered &&
            !_exitDialog &&
            !_busy &&
            _requested &&
            _model.outcome == null) {
          try {
            await _cameraController.stop();
            await _cameraController.start(cameraDirection: previous);
            if (mounted) {
              setState(() => _cameraError = _cameraController.value.error);
            }
          } on MobileScannerException catch (error) {
            if (mounted) setState(() => _cameraError = error);
          } on PlatformException {
            if (mounted) {
              setState(
                () => _cameraError = const MobileScannerException(
                  errorCode: MobileScannerErrorCode.genericError,
                ),
              );
            }
          }
          if (mounted) {
            showErrorToast(
              context,
              'Não foi possível trocar de câmera. Tente novamente.',
            );
          }
        }
      } finally {
        if (mounted) setState(() => _switchingCamera = false);
      }
    });
    _cameraOperation = operation;
    return operation;
  }

  Future<void> _read(BarcodeCapture capture) async {
    if (!_canScan) return;
    final codes = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .where((code) => code.trim().isNotEmpty);
    if (codes.isEmpty) return;
    if (!_model.canScanToken(codes.first.trim())) return;
    setState(() => _scanLock = true);
    try {
      await _camera(false);
      if (!mounted) return;
      await _model.scan(codes.first.trim());
      if (!mounted) return;
      if (_model.outcome?.success ?? false) {
        ref.invalidate(participantsViewModelProvider(widget.event.id));
        ref.invalidate(participantDetailsProvider);
        unawaited(HapticFeedback.lightImpact());
      }
    } finally {
      if (mounted) {
        setState(() => _scanLock = false);
        if (_model.outcome == null) {
          unawaited(_camera(true));
        } else {
          _scheduleNext();
        }
      }
    }
  }

  void _scheduleNext() {
    _resultTimer?.cancel();
    if (!widget.totem ||
        !_active ||
        _covered ||
        _exitDialog ||
        _model.outcome?.autoResume != true) {
      return;
    }
    _resultTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _active && !_exitDialog && !_covered) unawaited(_next());
    });
  }

  Future<void> _next() async {
    _resultTimer?.cancel();
    _model.next(manual: !widget.totem);
    await _camera(true);
  }

  Future<void> _retry() async {
    if (_interactionLocked) return;
    await _model.retry();
    if (mounted) _scheduleNext();
  }

  Future<void> _resume() async {
    if (!mounted ||
        !_requested ||
        _interactionLocked ||
        _covered ||
        _exitDialog) {
      return;
    }
    try {
      final membership = await ref
          .read(staffEventsRepositoryProvider)
          .membership(widget.event.id);
      if (!mounted) return;
      if (!membership.accessLevel.canCheckin) {
        _blockAccess();
        return;
      }
    } catch (error) {
      if (!mounted) return;
      if (isAccessDenied(error)) {
        _blockAccess();
        return;
      }
      // Do not restart the camera if membership could not be verified.
      setState(
        () => _cameraError = MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        ),
      );
      return;
    }
    if (_model.outcome != null) {
      _scheduleNext();
    } else {
      await _camera(true);
    }
  }

  void _blockAccess() {
    _resultTimer?.cancel();
    _model.blockAccess();
    unawaited(_camera(false));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      _resultTimer?.cancel();
      unawaited(_camera(false, onlyWhenInactive: true));
    } else if (_cameraController.value.hasCameraPermission) {
      unawaited(_resume());
    }
  }

  Future<void> _exit() async {
    if (_interactionLocked || _exitDialog) return;
    if (!widget.totem) {
      context.go('/events/${widget.event.id}');
      return;
    }
    _resultTimer?.cancel();
    setState(() => _exitDialog = true);
    await _camera(false);
    if (!mounted) return;
    final confirmed = await confirmDestructive(
      context,
      title: 'Encerrar modo totem?',
      message: 'A câmera será fechada e este dispositivo deixará de registrar entradas automaticamente.',
      action: 'Encerrar',
    );
    if (!mounted) return;
    setState(() => _exitDialog = false);
    if (confirmed) {
      context.go('/events/${widget.event.id}');
    } else if (_model.outcome == null) {
      await _camera(true);
    } else {
      _scheduleNext();
    }
  }

  Future<void> _participants() async {
    if (_interactionLocked || _covered) return;
    _resultTimer?.cancel();
    _covered = true;
    await _camera(false);
    if (!mounted) return;
    await context.push('/events/${widget.event.id}/participants');
    if (!mounted) return;
    _covered = false;
    await _resume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resultTimer?.cancel();
    _model.removeListener(_changed);
    _model.dispose();
    unawaited(_cameraOperation.whenComplete(_cameraController.dispose));
    unawaited(_wake(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _model.outcome;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_exit());
      },
      child: WorkScaffold(
        title: widget.totem ? 'Modo totem' : 'Ler ingresso',
        backEnabled: !_interactionLocked,
        handleSystemBack: false,
        onBack: () => unawaited(_exit()),
        actions: [
          if (outcome == null)
            ScannerCameraActions(
              controller: _cameraController,
              enabled: _canScan && _cameraError == null,
              switching: _switchingCamera,
              showTorch: !widget.totem,
              onSwitch: () => unawaited(_switchCamera()),
            ),
        ],
        body: Stack(
          children: [
            Offstage(
              offstage: outcome != null || _busy,
              child: WorkScroll(
                children: [
                  if (widget.totem) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: WorkBadge('Modo totem ativo'),
                    ),
                    const SizedBox(height: 24),
                    const WorkHeading(
                      'Apresente seu ingresso',
                      description: 'Aproxime o QR Code da câmera e aguarde.',
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.totem
                        ? 'A leitura será realizada automaticamente.'
                        : 'Aponte para o ingresso do participante.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 320,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: _cameraController,
                            useAppLifecycleState: false,
                            onDetect: (capture) => unawaited(_read(capture)),
                            errorBuilder: (context, error) => _CameraFailure(
                              error: error,
                              onRetry: () => unawaited(_resume()),
                            ),
                            overlayBuilder: (context, constraints) =>
                                IgnorePointer(
                                  child: Center(
                                    child: Container(
                                      width: math.min(
                                        constraints.maxWidth - 64,
                                        230,
                                      ),
                                      height: 230,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                          if (!_requested)
                            ColoredBox(
                              color: AppColors.textPrimary,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        RemixIcons.camera_line,
                                        color: AppColors.surface,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Precisamos da câmera para ler os ingressos. Nenhuma foto será salva.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.surface,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      FilledButton(
                                        onPressed: () {
                                          setState(() => _requested = true);
                                          unawaited(_camera(true));
                                        },
                                        child: const Text(
                                          'Permitir acesso à câmera',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_switchingCamera)
                            ColoredBox(
                              color: AppColors.surface,
                              child: Center(
                                child: Semantics(
                                  liveRegion: true,
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Trocando câmera…'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_cameraError != null)
                            _CameraFailure(
                              error: _cameraError!,
                              onRetry: () => unawaited(_resume()),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!widget.totem)
                    const WorkNotice(
                      title: 'Uma leitura por vez',
                      description: 'Aguarde o resultado antes de escanear o próximo ingresso.',
                    ),
                ],
              ),
            ),
            if (_busy)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Validando ingresso…',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            if (outcome != null)
              CheckinResultView(
                outcome: outcome,
                eventTitle: widget.event.title,
                totem: widget.totem,
              ),
          ],
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (outcome?.blocksScanner == true)
              CoreventButton(
                label: 'Voltar aos meus eventos',
                onPressed: () => context.go('/events'),
              )
            else if (outcome?.canRetry == true)
              CoreventButton(
                label: 'Tentar novamente',
                onPressed: _interactionLocked
                    ? null
                    : () => unawaited(_retry()),
                busy: _busy,
              )
            else if (outcome != null && !widget.totem)
              CoreventButton(
                label: 'Ler próximo ingresso',
                onPressed: () => unawaited(_next()),
              ),
            const SizedBox(height: 6),
            if (!widget.totem && outcome?.blocksScanner != true)
              CoreventTextAction(
                label: 'Consultar participantes',
                onPressed: _interactionLocked
                    ? null
                    : () => unawaited(_participants()),
              ),
            if (widget.totem)
              CoreventTextAction(
                label: 'Encerrar atendimento',
                onPressed: _interactionLocked ? null : () => unawaited(_exit()),
              ),
          ],
        ),
      ),
    );
  }
}

class _CameraFailure extends StatelessWidget {
  const _CameraFailure({required this.error, required this.onRetry});
  final MobileScannerException error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: AppColors.backgroundSecondary,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                RemixIcons.camera_off_line,
                size: 36,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                denied
                    ? 'A câmera está sem permissão.'
                    : 'Não foi possível iniciar a leitura.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                denied ? 'Habilite a câmera nas configurações do aplicativo.' : 'Confira sua conexão, seu acesso ao evento e a disponibilidade da câmera.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: denied ? () => openAppSettings() : onRetry,
                child: Text(
                  denied ? 'Abrir configurações' : 'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckinResultView extends StatelessWidget {
  const CheckinResultView({
    super.key,
    required this.outcome,
    required this.eventTitle,
    this.totem = false,
  });
  final CheckinOutcome outcome;
  final String eventTitle;
  final bool totem;
  @override
  Widget build(BuildContext context) {
    final record = outcome.record;
    return Semantics(
      liveRegion: true,
      child: WorkScroll(
        children: [
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: outcome.success
                    ? AppColors.successSoft
                    : AppColors.errorSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                outcome.success
                    ? RemixIcons.checkbox_circle_line
                    : outcome.failure == CheckinFailure.connection
                    ? RemixIcons.wifi_off_line
                    : RemixIcons.close_circle_line,
                size: totem ? 48 : 38,
                color: outcome.success ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 24),
          WorkHeading(outcome.title, description: outcome.description),
          const SizedBox(height: 24),
          if (record != null)
            WorkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    record.ticketType.name,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Entrada registrada em ${fullDate(record.checkinAt)} por ${record.checkedInBy.name}.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            eventTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (totem && outcome.autoResume) ...[
            const SizedBox(height: 14),
            const Text(
              'A leitura será retomada automaticamente.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
