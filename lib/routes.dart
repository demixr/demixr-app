import 'package:demixr_app/screens/demixing/demixing_screen.dart';
import 'package:demixr_app/screens/error/error_screen.dart';
import 'package:demixr_app/screens/home/home_screen.dart';
import 'package:flutter/material.dart';

import 'components/animated_route.dart';

Route generateRoute(settings) {
  switch (settings.name) {
    case 'home':
      return AnimatedRoute(const HomeScreen(), settings);
    case 'demixing':
      return AnimatedRoute(const DemixingScreen(), settings);
    default:
      return AnimatedRoute(const ErrorScreen(), settings);
  }
}
