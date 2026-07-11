import 'package:flutter/material.dart';

import '../../../constants.dart';

class ControllerButton extends StatelessWidget {
  final Widget icon;
  final double size;
  final List<Color> gradient;
  final VoidCallback? onPressed;

  const ControllerButton(
    this.icon, {
    super.key,
    this.size = 60,
    this.gradient = ColorPalette.primaryGradient,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: icon,
        ),
      ),
    );
  }
}
