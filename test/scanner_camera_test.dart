import 'dart:async';

import 'package:corevent_work_app/core/network/api_models.dart';
import 'package:corevent_work_app/core/theme/app_colors.dart';
import 'package:corevent_work_app/core/theme/app_theme.dart';
import 'package:corevent_work_app/features/checkin/data/checkin_api.dart';
import 'package:corevent_work_app/features/checkin/data/checkin_repository.dart';
import 'package:corevent_work_app/features/checkin/domain/checkin_outcome.dart';
import 'package:corevent_work_app/features/checkin/presentation/checkin_pages.dart';
import 'package:corevent_work_app/features/participants/data/participant.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_event.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_events_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remixicon/remixicon.dart';

class _CheckinRepository extends Mock implements CheckinRepository {}

class _StaffRepository extends Mock implements StaffEventsRepository {}

class _CameraPlatform extends MobileScannerPlatform {
  final captures = StreamController<BarcodeCapture?>.broadcast();
  final starts = <CameraFacing>[];
  final lensQueries = <CameraFacing?>[];
  int? cameraCount = 2;
  bool hasFront = true;
  bool failLensQuery = false;
  bool failFront = false;
  bool denyPermission = false;
  bool running = false;
  Completer<void>? frontStart;

  @override
  Stream<BarcodeCapture?> get barcodesStream => captures.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.black);
  @override
  Future<Set<CameraLensType>> getSupportedLenses({CameraFacing? facing}) async {
    lensQueries.add(facing);
    if (failLensQuery) throw PlatformException(code: 'camera-unavailable');
    return facing == CameraFacing.front && !hasFront
        ? <CameraLensType>{}
        : {CameraLensType.normal};
  }

  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    starts.add(options.cameraDirection);
    if (denyPermission) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    if (options.cameraDirection == CameraFacing.front) {
      await frontStart?.future;
      if (failFront) {
        throw const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        );
      }
    }
    running = true;
    return MobileScannerViewAttributes(
      cameraDirection: options.cameraDirection,
      currentTorchMode: options.cameraDirection == CameraFacing.front
          ? TorchState.unavailable
          : TorchState.off,
      size: const Size(640, 480),
      numberOfCameras: cameraCount,
    );
  }

  @override
  Future<void> stop() async => running = false;
  @override
  Future<void> dispose() async => running = false;

  void readQr() =>
      captures.add(BarcodeCapture(barcodes: [Barcode(rawValue: 'a' * 64)]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('pt_BR'));
  late MobileScannerPlatform originalPlatform;
  late _CameraPlatform camera;
  late _CheckinRepository checkin;
  late _StaffRepository staff;
  const wakeChannel =
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';
  final event = StaffEvent(
    id: 'event',
    title: 'Evento para credenciamento',
    startDate: DateTime(2026, 11, 7),
    endDate: DateTime(2026, 11, 8),
    accessLevel: StaffAccess.checkin,
  );
  final record = CheckinRecord(
    ticketId: 'ticket',
    status: 'checked_in',
    checkinAt: DateTime(2026, 11, 7, 10),
    user: const PersonSummary(id: 'user', name: 'Participante'),
    ticketType: const TicketType(id: 'type', name: 'Ingresso gratuito'),
    checkedInBy: const PersonSummary(id: 'staff', name: 'Colaborador'),
  );

  setUp(() {
    originalPlatform = MobileScannerPlatform.instance;
    camera = _CameraPlatform();
    MobileScannerPlatform.instance = camera;
    checkin = _CheckinRepository();
    staff = _StaffRepository();
    when(() => checkin.submit('event', any()))
        .thenAnswer((_) async => CheckinOutcome.success(record));
    when(() => staff.membership('event')).thenAnswer((_) async => event);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          wakeChannel,
          (_) async => const StandardMessageCodec().encodeMessage([null]),
        );
  });
  tearDown(() async {
    await camera.captures.close();
    MobileScannerPlatform.instance = originalPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(wakeChannel, null);
  });

  Future<void> open(WidgetTester tester, {bool totem = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventAccessProvider('event').overrideWith((ref) async => event),
          staffEventsRepositoryProvider.overrideWithValue(staff),
          checkinRepositoryProvider.overrideWithValue(checkin),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: CheckinPage(eventId: 'event', totem: totem),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (!totem) {
      expect(find.byIcon(RemixIcons.camera_switch_line), findsNothing);
      await tester.ensureVisible(find.text('Permitir acesso à câmera'));
      await tester.tap(find.text('Permitir acesso à câmera'));
      await tester.pumpAndSettle();
    }
  }

  for (final totem in [false, true]) {
    testWidgets(
      '${totem ? 'totem' : 'normal'} mantém câmera frontal entre leituras e ao retomar',
      (tester) async {
        await open(tester, totem: totem);
        expect(camera.starts, [CameraFacing.back]);
        expect(find.byTooltip('Usar câmera frontal'), findsOneWidget);
        await tester.tap(find.byTooltip('Usar câmera frontal'));
        await tester.pumpAndSettle();
        expect(camera.starts.last, CameraFacing.front);
        expect(find.byTooltip('Usar câmera traseira'), findsOneWidget);
        expect(find.byTooltip('Ligar lanterna'), findsNothing);

        camera.readQr();
        await tester.pumpAndSettle();
        expect(find.text('Check-in confirmado'), findsOneWidget);
        expect(find.byIcon(RemixIcons.camera_switch_line), findsNothing);
        verify(() => checkin.submit('event', 'a' * 64)).called(1);
        if (totem) {
          await tester.pump(const Duration(seconds: 5));
          expect(find.text('Check-in confirmado'), findsOneWidget);
          expect(camera.running, isFalse);
          await tester.pump(const Duration(seconds: 1));
        } else {
          await tester.tap(find.text('Ler próximo ingresso'));
        }
        await tester.pumpAndSettle();
        expect(camera.starts.last, CameraFacing.front);
        expect(find.byTooltip('Usar câmera traseira'), findsOneWidget);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pumpAndSettle();
        expect(camera.running, isFalse);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(camera.running, isTrue);
        expect(camera.starts.last, CameraFacing.front);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('apenas uma câmera não oferece troca', (tester) async {
    camera.cameraCount = 1;
    camera.hasFront = false;
    await open(tester);
    expect(find.byIcon(RemixIcons.camera_switch_line), findsNothing);
    expect(find.byTooltip('Ligar lanterna'), findsOneWidget);
    expect(camera.lensQueries, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('várias lentes traseiras sem frontal não oferecem troca', (
    tester,
  ) async {
    camera.hasFront = false;
    await open(tester);
    expect(find.byIcon(RemixIcons.camera_switch_line), findsNothing);
    expect(
      camera.lensQueries,
      containsAll([CameraFacing.front, CameraFacing.back]),
    );
    expect(camera.running, isTrue);
  });

  testWidgets('falha ao consultar câmeras mantém leitura sem oferecer troca', (
    tester,
  ) async {
    camera.failLensQuery = true;
    await open(tester, totem: true);
    expect(find.byIcon(RemixIcons.camera_switch_line), findsNothing);
    expect(camera.running, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('troca pendente bloqueia repetição e leitura do QR', (
    tester,
  ) async {
    camera.frontStart = Completer<void>();
    await open(tester, totem: true);
    await tester.tap(find.byTooltip('Usar câmera frontal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Trocando câmera…'), findsOneWidget);
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, RemixIcons.camera_switch_line),
    );
    expect(button.onPressed, isNull);
    camera.readQr();
    await tester.pump();
    verifyNever(() => checkin.submit(any(), any()));
    camera.frontStart!.complete();
    await tester.pumpAndSettle();
    expect(
      camera.starts.where((facing) => facing == CameraFacing.front),
      hasLength(1),
    );
    expect(find.byTooltip('Usar câmera traseira'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'falha de troca recupera câmera anterior e apresenta toast vermelho',
    (tester) async {
      camera.failFront = true;
      await open(tester);
      await tester.tap(find.byTooltip('Usar câmera frontal'));
      await tester.pumpAndSettle();
      expect(camera.starts, [
        CameraFacing.back,
        CameraFacing.front,
        CameraFacing.back,
      ]);
      expect(camera.running, isTrue);
      expect(
        find.text('Não foi possível trocar de câmera. Tente novamente.'),
        findsOneWidget,
      );
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
        AppColors.error,
      );
      expect(find.text('Trocando câmera…'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sem permissão de câmera não oferece troca', (tester) async {
    camera.denyPermission = true;
    await open(tester, totem: true);
    expect(find.byIcon(RemixIcons.camera_switch_line), findsNothing);
    expect(camera.lensQueries, isEmpty);
    expect(camera.running, isFalse);
    expect(tester.takeException(), isNull);
  });
}
