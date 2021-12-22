import 'package:flutter/material.dart';
import 'package:demixr_app/constants.dart';

class Button extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String text;
  final Widget? icon;
  final double radius;

  const Button(this.text,
      {Key? key,
      this.color = ColorPalette.primary,
      this.textColor = ColorPalette.onPrimary,
      this.icon,
      this.radius = 100})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      backgroundColor: color,
      minimumSize: const Size(75, 50),
      padding: const EdgeInsets.only(left: 20, top: 12, right: 20, bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
    final textWidget = Text(
      text,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    );

    const space = SizedBox(width: 10);
    final buttonChildren =
        icon != null ? [icon!, space, textWidget] : [textWidget];
    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: buttonChildren,
    );

    return TextButton(style: style, onPressed: () {}, child: buttonContent);
  }
}
