import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/error_toast.dart';

class ScannerCameraActions extends StatefulWidget {
  const ScannerCameraActions({
    super.key,
    required this.controller,
    required this.enabled,
    required this.switching,
    required this.onSwitch,
    this.showTorch = true,
  });

  final MobileScannerController controller;
  final bool enabled;
  final bool switching;
  final VoidCallback onSwitch;
  final bool showTorch;

  @override
  State<ScannerCameraActions> createState() => _ScannerCameraActionsState();
}

class _ScannerCameraActionsState extends State<ScannerCameraActions> {
  Future<bool>? _switchSupported;

  @override
  void didUpdateWidget(covariant ScannerCameraActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _switchSupported = null;
  }

  Future<bool> _hasFrontAndBackCamera() async {
    try {
      // Multiple lenses on the same side do not imply a front/back pair.
      final lenses = await Future.wait([
        widget.controller.getSupportedLenses(facing: CameraFacing.front),
        widget.controller.getSupportedLenses(facing: CameraFacing.back),
      ]);
      return lenses.every((side) => side.isNotEmpty);
    } on Exception {
      return false;
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await widget.controller.toggleTorch();
    } on MobileScannerException {
      if (mounted) {
        showErrorToast(context, 'Não foi possível alterar a lanterna.');
      }
    } on PlatformException {
      if (mounted) {
        showErrorToast(context, 'Não foi possível alterar a lanterna.');
      }
    }
  }

  Widget _buttons(MobileScannerState state, {required bool canSwitch}) {
    final enabled =
        widget.enabled &&
        !widget.switching &&
        state.isRunning &&
        !state.isStarting;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canSwitch)
          IconButton(
            tooltip: state.cameraDirection == CameraFacing.front
                ? 'Usar câmera traseira'
                : 'Usar câmera frontal',
            onPressed: enabled ? widget.onSwitch : null,
            icon: const Icon(RemixIcons.camera_switch_line),
          ),
        if (widget.showTorch && state.torchState != TorchState.unavailable)
          IconButton(
            tooltip: state.torchState == TorchState.on
                ? 'Desligar lanterna'
                : 'Ligar lanterna',
            onPressed: enabled ? _toggleTorch : null,
            icon: Icon(
              state.torchState == TorchState.on
                  ? RemixIcons.flashlight_fill
                  : RemixIcons.flashlight_line,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<MobileScannerState>(
        valueListenable: widget.controller,
        builder: (context, state, _) {
          if (!state.hasCameraPermission || state.error != null) {
            _switchSupported = null;
            return const SizedBox.shrink();
          }
          final internalCamera =
              state.cameraDirection == CameraFacing.front ||
              state.cameraDirection == CameraFacing.back;
          if (!internalCamera || (state.availableCameras ?? 2) < 2) {
            return _buttons(state, canSwitch: false);
          }
          return FutureBuilder<bool>(
            future: _switchSupported ??= _hasFrontAndBackCamera(),
            builder: (context, result) =>
                _buttons(state, canSwitch: result.data == true),
          );
        },
      );
}
