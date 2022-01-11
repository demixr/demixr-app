import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CancelButton({required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      'Cancel',
      icon: const Icon(
        Icons.cancel,
        color: ColorPalette.onError,
      ),
      color: ColorPalette.errorContainer,
      textColor: ColorPalette.onError,
      textSize: 18,
      onPressed: onPressed,
    );
  }
}
