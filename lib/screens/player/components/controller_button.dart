import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants.dart';

class ControllerButton extends StatelessWidget {
  final Widget icon;
  final double size;
  final List<Color> gradient;

  const ControllerButton(this.icon,
      {Key? key, this.size = 60, this.gradient = ColorPalette.primaryGradient})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
      ),
      child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: gradient,
              begin: const Alignment(-3, -3),
              end: Alignment.bottomCenter,
            ),
          ),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: icon,
          )),
    );
  }
}
