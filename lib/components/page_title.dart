import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class PageTitle extends StatelessWidget {
  final String title;

  const PageTitle(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: ColorPalette.primary,
      ),
    );
  }
}
