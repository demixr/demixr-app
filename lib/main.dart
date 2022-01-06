import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/unmixed_song.dart';
import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/providers/player_provider.dart';
import 'package:demixr_app/screens/demixing/demixing_screen.dart';
import 'package:demixr_app/screens/error/error_screen.dart';
import 'package:demixr_app/screens/home/home_screen.dart';
import 'package:demixr_app/screens/player/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:demixr_app/constants.dart' show BoxesNames, ColorPalette;
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

Future<void> main() async {
  await Hive.initFlutter();
  Hive.registerAdapter<UnmixedSong>(UnmixedSongAdapter());
  Hive.registerAdapter<Song>(SongAdapter());
  await Hive.openBox<UnmixedSong>(BoxesNames.library);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryProvider>(
            create: (_) => LibraryProvider()),
        ChangeNotifierProxyProvider<LibraryProvider, PlayerProvider>(
          create: (context) => PlayerProvider(),
          update: (context, library, player) =>
              (player ?? PlayerProvider())..update(library),
        ),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Demixr',
        theme: ThemeData(
          scaffoldBackgroundColor: ColorPalette.surface,
          primaryColor: ColorPalette.primary,
          textTheme: Theme.of(context).textTheme.apply(
              bodyColor: ColorPalette.onSurface,
              displayColor: ColorPalette.onSurface),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: buildHome(),
        initialRoute: '/',
        unknownRoute:
            GetPage(name: '/notfound', page: () => const ErrorScreen()),
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
            name: '/player',
            page: () => const PlayerScreen(),
            transition: Transition.downToUp,
          ),
        ],
      ),
    );
  }

  AnnotatedRegion<SystemUiOverlayStyle> buildHome() {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
        child: HomeScreen(),
        value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light));
  }
}
