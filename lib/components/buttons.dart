import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:demixr_app/constants.dart';

class Button extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String text;
  final double textSize;
  final Widget? icon;
  final double radius;
  final EdgeInsets padding;
  final VoidCallback? onPressed;

  const Button(
    this.text, {
    Key? key,
    this.color = ColorPalette.primary,
    this.textColor = ColorPalette.onPrimary,
    this.textSize = 14,
    this.icon,
    this.radius = 100,
    this.padding =
        const EdgeInsets.only(left: 24, top: 10, right: 24, bottom: 10),
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      backgroundColor: color,
      minimumSize: const Size(75, 40),
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
    final textWidget = AutoSizeText(
      text,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w700,
        fontSize: textSize,
      ),
      maxLines: 1,
      minFontSize: 6,
    );

    const space = SizedBox(width: 10);
    final buttonChildren =
        icon != null ? [icon!, space, textWidget] : [textWidget];
    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: buttonChildren,
    );

    return TextButton(style: style, onPressed: onPressed, child: buttonContent);
  }
}
