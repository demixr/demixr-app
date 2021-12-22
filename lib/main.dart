import 'package:demixr_app/routes.dart';
import 'package:demixr_app/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:demixr_app/constants.dart' show ColorPalette;
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      onGenerateRoute: (settings) => generateRoute(settings),
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
