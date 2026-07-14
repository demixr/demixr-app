import 'package:demixr_app/models/duration_adapter.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/providers/model_provider.dart';
import 'package:demixr_app/providers/player_provider.dart';
import 'package:demixr_app/screens/demixing/demixing_screen.dart';
import 'package:demixr_app/screens/demixing/processing/processing_screen.dart';
import 'package:demixr_app/screens/download/download_screen.dart';
import 'package:demixr_app/screens/error/error_screen.dart';
import 'package:demixr_app/screens/home/home_screen.dart';
import 'package:demixr_app/screens/player/player_screen.dart';
import 'package:demixr_app/screens/youtube/youtube_screen.dart';
import 'package:demixr_app/services/system_media_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:demixr_app/constants.dart' show BoxesNames, ColorPalette;
import 'package:flutter/services.dart';
import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'dart:async';
import 'dart:io';

import 'constants.dart' show Models;
import 'helpers/separation/executorch_demixing_engine.dart';
import 'hive_registrar.g.dart';
import 'models/model.dart';
import 'repositories/preferences_repository.dart';
import 'providers/preferences_provider.dart';

late final SystemMediaHandler systemMediaHandler;

bool get _supportsSystemMediaControls =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FFmpegKitExtended.initialize();

  await Hive.initFlutter();

  // Hive CE already registers its built-in Duration adapter. Register only
  // the app's generated model adapters here.
  Hive.registerAdapters();

  await Hive.openBox<dynamic>(BoxesNames.preferences);
  await _openLibraryWithLegacyDurationMigration();

  if (_supportsSystemMediaControls) {
    await AudioService.init(
      builder: () {
        systemMediaHandler = SystemMediaHandler();
        return systemMediaHandler;
      },
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.demixr.demixrApp.playback',
        androidNotificationChannelName: 'Music playback',
        androidNotificationOngoing: true,
      ),
    );

    // Advertise Demixr as a music player on platforms where audio_service and
    // audio_session provide a native implementation. Windows still gets the
    // in-app handler below, but system media controls are a later integration.
    final audioSession = await AudioSession.instance;
    await audioSession.configure(const AudioSessionConfiguration.music());
  } else {
    systemMediaHandler = SystemMediaHandler();
  }

  runApp(const MyApp());

  // Warm up the GPU engine for an already-downloaded model so the first demix
  // of the session isn't stalled by the one-time CoreML compile. Background +
  // best-effort.
  unawaited(_warmUpSelectedModel());
}

Future<void> _openLibraryWithLegacyDurationMigration() async {
  try {
    await Hive.openBox<UnmixedSong>(BoxesNames.library);
  } on HiveError catch (error) {
    // Older Demixr versions stored Duration with the app adapter typeId 1,
    // encoded by Hive CE as on-disk typeId 33. Read that format once, then
    // recreate the box so Hive's built-in Duration adapter is used afterward.
    if (!error.message.contains('unknown typeId: 33')) rethrow;

    Hive.registerAdapter<Duration>(DurationAdapter());
    final legacyBox = await Hive.openBox<UnmixedSong>(BoxesNames.library);
    final songs = legacyBox.toMap();
    await legacyBox.deleteFromDisk();

    final migratedBox = await Hive.openBox<UnmixedSong>(BoxesNames.library);
    await migratedBox.putAll(songs);
  }
}

Future<void> _warmUpSelectedModel() async {
  try {
    final repo = PreferencesRepository();
    final name = repo.getModel();
    if (name == null) return;
    final model = Models.fromName(name);
    if (model.engine != DemixingEngine.executorch) return;
    final path = repo.getModelPath(name);
    if (path == null || !File(path).existsSync()) return;
    await ExecuTorchDemixingEngine.warmUp(path);
  } catch (_) {
    // best-effort; the first demix will compile on demand
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    // Free the resident GPU model when the OS signals memory pressure; it
    // re-warms on the next demix/selection. Keeps the common-case no-stall
    // benefit while not pinning ~270 MB under pressure.
    ExecuTorchDemixingEngine.disposeCache();
  }

  @override
  Widget build(BuildContext context) {
    // Lock rotation on Android devices
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PreferencesProvider>(
          create: (_) => PreferencesProvider(),
        ),
        ChangeNotifierProxyProvider<PreferencesProvider, ModelProvider>(
          create: (context) => ModelProvider(),
          update: (context, preferences, modelProvider) =>
              (modelProvider ?? ModelProvider())..setPreferences(preferences),
        ),
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => LibraryProvider(),
        ),
        ChangeNotifierProxyProvider<LibraryProvider, PlayerProvider>(
          create: (context) => PlayerProvider(systemMediaHandler),
          update: (context, library, player) =>
              (player ?? PlayerProvider(systemMediaHandler))..update(library),
        ),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Demixr',
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: ColorPalette.surface,
          colorScheme: const ColorScheme.dark(
            primary: ColorPalette.primary,
            onPrimary: ColorPalette.onPrimary,
            secondary: ColorPalette.tertiary,
            onSecondary: ColorPalette.onTertiary,
            surface: ColorPalette.surface,
            onSurface: ColorPalette.onSurface,
            outline: ColorPalette.outline,
          ),
          fontFamily: Platform.isMacOS || Platform.isIOS
              ? '.SF Pro Text'
              : null,
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              color: ColorPalette.onSurface,
              fontSize: 56,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -2.2,
            ),
            headlineMedium: TextStyle(
              color: ColorPalette.onSurface,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
            titleLarge: TextStyle(
              color: ColorPalette.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: TextStyle(
              color: ColorPalette.onSurfaceVariant,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          dividerColor: ColorPalette.outline,
          iconTheme: const IconThemeData(color: ColorPalette.onSurface),
          tooltipTheme: const TooltipThemeData(
            decoration: BoxDecoration(
              color: ColorPalette.surfaceContainerHigh,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: buildHome(),
        initialRoute: '/',
        unknownRoute: GetPage(
          name: '/notfound',
          page: () => const ErrorScreen(),
        ),
        getPages: [
          GetPage(
            name: '/',
            page: () => const HomeScreen(),
            transition: Transition.downToUp,
          ),
          GetPage(
            name: '/demixing',
            page: () => const DemixingScreen(),
            transition: Transition.downToUp,
          ),
          GetPage(
            name: '/demixing/processing',
            page: () => const ProcessingScreen(),
            transitionDuration: const Duration(milliseconds: 180),
            transition: Transition.fadeIn,
          ),
          GetPage(
            name: '/player',
            page: () => const PlayerScreen(),
            transition: Transition.downToUp,
          ),
          GetPage(
            name: '/demixing/youtube',
            page: () => const YoutubeScreen(),
            transition: Transition.downToUp,
          ),
          GetPage(
            name: '/model/download',
            page: () => const DownloadScreen(),
            transition: Transition.circularReveal,
          ),
        ],
        supportedLocales: const [Locale('en')],
      ),
    );
  }

  AnnotatedRegion<SystemUiOverlayStyle> buildHome() {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: HomeScreen(),
    );
  }
}
