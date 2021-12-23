import 'package:flutter/material.dart';

class AnimatedRoute extends PageRouteBuilder {
  final Widget page;

  AnimatedRoute(this.page, settings)
      : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                  position:
                      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                          .chain(CurveTween(curve: Curves.decelerate))
                          .animate(animation),
                  child: child),
          transitionDuration: const Duration(milliseconds: 300),
        );
}
